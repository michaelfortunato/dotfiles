-- FIXME: Try to gut LazyVim from this, it does too many hidden things,
-- such as starting the server
-- FIXME: Python LSP servers only! LSP rename fails with "change_annotations must be provided for annotated text edits"
--- Includes lsp, linting, and formatter configurations
vim.lsp.set_log_level("ERROR")

-- Keep every LSP client on the protocol's broadly supported position encoding.
-- Without this, servers choose independently from the default
-- UTF-8/UTF-16/UTF-32 list, which can leave one buffer attached to clients
-- using different encodings.
local lsp_capabilities = vim.lsp.protocol.make_client_capabilities()
lsp_capabilities.general = vim.tbl_deep_extend("force", lsp_capabilities.general or {}, {
  positionEncodings = { "utf-16" },
})
vim.lsp.config("*", { capabilities = lsp_capabilities })

local function lsp_diagnostic_namespace_client_id(name)
  return tonumber(name:match("^nvim%.lsp%..+%.(%d+)%.") or name:match("^nvim%.lsp%..+%.(%d+)$"))
end

local function reset_lsp_diagnostics(buf, is_stale)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return
  end

  for ns, meta in pairs(vim.diagnostic.get_namespaces()) do
    local client_id = lsp_diagnostic_namespace_client_id(meta.name or "")
    if client_id and is_stale(client_id) then
      vim.diagnostic.reset(ns, buf)
    end
  end
end

local function is_snacks_scratch_buf(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return false
  end

  local root = vim.fs.normalize(vim.fn.stdpath("data") .. "/scratch")
  name = vim.fs.normalize(name)
  return name == root or name:find(root .. "/", 1, true) == 1
end

local function lsp_workspace_edit_uris(workspace_edit)
  local uris = {}

  if type(workspace_edit.changes) == "table" then
    for uri in pairs(workspace_edit.changes) do
      uris[uri] = true
    end
  end

  if type(workspace_edit.documentChanges) == "table" then
    for _, change in ipairs(workspace_edit.documentChanges) do
      local text_document = change.textDocument
      if text_document and text_document.uri then
        uris[text_document.uri] = true
      elseif change.kind == "rename" and change.newUri then
        uris[change.newUri] = true
      end
    end
  end

  return uris
end

local function write_workspace_edit_buffers(workspace_edit, include_uri)
  local saved = 0
  local failed = {}

  for uri in pairs(lsp_workspace_edit_uris(workspace_edit)) do
    local buf = vim.uri_to_bufnr(uri)
    if
      (not include_uri or include_uri(uri))
      and vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_buf_get_name(buf) ~= ""
      and vim.bo[buf].buftype == ""
      and vim.bo[buf].modified
    then
      local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd("silent update")
      end)
      if ok then
        saved = saved + 1
      else
        failed[#failed + 1] = ("%s: %s"):format(vim.uri_to_fname(uri), err)
      end
    end
  end

  if #failed > 0 then
    vim.notify("LSP rename save failed:\n" .. table.concat(failed, "\n"), vim.log.levels.WARN)
  elseif saved > 0 then
    vim.notify(("LSP rename saved %d file%s"):format(saved, saved == 1 and "" or "s"), vim.log.levels.INFO)
  end
end

vim.lsp.handlers["textDocument/rename"] = function(err, result, ctx)
  if err then
    vim.notify("LSP rename failed: " .. (err.message or tostring(err)), vim.log.levels.WARN)
    return
  end
  if not result then
    vim.notify("Language server couldn't provide rename result", vim.log.levels.INFO)
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if not client then
    vim.notify("LSP rename failed: client disappeared", vim.log.levels.WARN)
    return
  end

  local ok, apply_err = pcall(vim.lsp.util.apply_workspace_edit, result, client.offset_encoding)
  if not ok then
    vim.notify("LSP rename failed: " .. tostring(apply_err), vim.log.levels.ERROR)
    return
  end

  write_workspace_edit_buffers(result)
end

local function setup_snacks_rename_autosave()
  local snacks_rename = require("snacks.rename")
  if snacks_rename["_mnf_saves_lsp_file_rename_edits"] then
    return
  end
  snacks_rename["_mnf_saves_lsp_file_rename_edits"] = true

  snacks_rename.on_rename_file = function(from, to, rename)
    local changes = {
      files = {
        {
          oldUri = vim.uri_from_fname(from),
          newUri = vim.uri_from_fname(to),
        },
      },
    }
    local clients = (vim.lsp.get_clients or vim.lsp.get_active_clients)()
    local workspace_edits = {}

    for _, client in ipairs(clients) do
      if client.supports_method("workspace/willRenameFiles") then
        local response = client.request_sync("workspace/willRenameFiles", changes, 1000, 0)
        if response and response.result ~= nil then
          local ok, err = pcall(vim.lsp.util.apply_workspace_edit, response.result, client.offset_encoding)
          if ok then
            workspace_edits[#workspace_edits + 1] = response.result
          else
            vim.notify("LSP file rename failed: " .. tostring(err), vim.log.levels.ERROR)
          end
        end
      end
    end

    -- An edit to the renamed file must reach disk before Snacks moves it.
    for _, workspace_edit in ipairs(workspace_edits) do
      write_workspace_edit_buffers(workspace_edit, function(uri)
        return uri == changes.files[1].oldUri
      end)
    end

    if rename then
      rename()
    end

    for _, client in ipairs(clients) do
      if client.supports_method("workspace/didRenameFiles") then
        client.notify("workspace/didRenameFiles", changes)
      end
    end

    -- Save only the reference buffers changed by the LSP workspace edit.
    for _, workspace_edit in ipairs(workspace_edits) do
      write_workspace_edit_buffers(workspace_edit, function(uri)
        return uri ~= changes.files[1].oldUri
      end)
    end
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = setup_snacks_rename_autosave,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("MnfLspDiagnostics", { clear = true }),
  desc = "Clear stale LSP diagnostics when a client detaches",
  callback = function(ev)
    local detached_client_id = ev.data and ev.data.client_id
    reset_lsp_diagnostics(ev.buf, function(client_id)
      return client_id == detached_client_id
    end)
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = "MnfLspDiagnostics",
  desc = "Clear diagnostics left behind by inactive LSP clients",
  callback = function(ev)
    local active = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
      active[client.id] = true
    end
    reset_lsp_diagnostics(ev.buf, function(client_id)
      return not active[client_id]
    end)
  end,
})

-- NOTE: vim.lsp.config does not start the lsp server. Simply configures it.
-- no need to call vim.lsp.config if we are good with their defaults
-- FIXME: For some reason some program is enabling ruff, mason automatic enable
-- did not fix it.
-- vim.lsp.enable("ruff") UPDATE: its LazyVim's fault. Please see tinymist
-- enabled = false. you can see it here: https://www.lazyvim.org/plugins/lsp,
-- NOTE: Because I am using LazyVim, but now know about LSPs, mason is doing
-- a few hidden things that might prove bothersome for some of my lsps
-- I want to manage manually. mason-lsp-config is likely responsible for both
-- of the following
-- 1. For a server, mason will automaticaly install it.
--  1.a. To prevent this, add servers = {<server> = {mason = false}}
-- 2. mason-lsp-config autostarts lsps servers.
vim.lsp.config("tombi", {
  cmd = { "tombi", "lsp" },
})
vim.lsp.enable("tombi")

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("MnfMiseTombiSemanticTokens", { clear = true }),
  desc = "Let injected shell highlighting win inside Mise TOML strings",
  callback = function(ev)
    local client = ev.data and vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or client.name ~= "tombi" then
      return
    end

    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":t")
    if filename:match("^%.?mise.*%.toml$") then
      vim.lsp.semantic_tokens.enable(false, { bufnr = ev.buf, client_id = client.id })
    end
  end,
})

vim.lsp.config("tinymist", {
  settings = {
    -- do not fallb back to lsp formatting, as tinymist
    -- runs its own fork of typstyle (I believe this is still true)
    -- which confuses me. Might as well manage it myself anyhow
    -- formatterMode = "typstyle",
    -- formatterPrintWidth = 80,
    formatterMode = "disable",
    typstExtraArgs = {
      "--features=html",
    },
    lint = { enabled = true },
  },
})
vim.lsp.enable("tinymist")
vim.lsp.config("rust_analyzer", {
  settings = {
    ["rust-analyzer"] = {
      check = {
        command = "clippy",
      },
    },
  },
})
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("ty")
vim.lsp.config("ty", {
  root_markers = { "uv.lock" },
})

vim.lsp.enable("rlsp-yaml")
vim.lsp.config("rlsp-yaml", {
  filetypes = { "yaml" },
})
-- vim.lsp.enable("ruff")
-- vim.lsp.config("ruff", {
--   root_markers = { "uv.lock" },
-- })

vim.lsp.inline_completion.enable(false)

-- 3) Toggle automatic ghost text (enable/disable capability)
vim.keymap.set({ "n" }, "<leader>mi", function()
  vim.lsp.enable("copilot")
  local new_state = not vim.lsp.inline_completion.is_enabled()
  vim.lsp.inline_completion.enable(new_state)
  vim.notify(("Inline completion: %s"):format(new_state and "Enabled" or "Disabled"))
end, { desc = "Inline: toggle automatic ghost text" })
-- AI Slop Completion End
--
--Replace the default `gd` with an auto-cleaning version.
-- vim.keymap.set("n", "gd", function()
--   local before = vim.api.nvim_get_current_buf()
--   vim.lsp.buf.definition()
--
--   -- If a jump occurred into a different buffer, mark it "transient":
--   local after = vim.api.nvim_get_current_buf()
--   if after ~= before then
--     -- Make it disappear from :ls and auto-wipe on leave:
--     vim.bo[after].buflisted = false
--     vim.bo[after].bufhidden = "wipe"
--
--     -- Extra safety: if you *do* switch away, delete it once.
--     vim.api.nvim_create_autocmd("BufLeave", {
--       buffer = after,
--       once = true,
--       callback = function()
--         if vim.api.nvim_buf_is_valid(after) and not vim.bo[after].modified then
--           vim.api.nvim_buf_delete(after, { force = true })
--         end
--       end,
--     })
--   end
-- end)

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyLoad",
  callback = function(event)
    if event.data ~= "nvim-lspconfig" then
      return
    end
    vim.api.nvim_create_user_command("LspLogDelete", function()
      local log_path = vim.lsp.get_log_path()
      if vim.fn.filereadable(log_path) == 1 then
        os.remove(log_path)
        vim.notify("Deleted LSP log: " .. log_path, vim.log.levels.INFO)
      else
        vim.notify("No LSP log found at " .. log_path, vim.log.levels.WARN)
      end
    end, { desc = "Delete (rotate) the Neovim LSP log file" })
    vim.api.nvim_create_user_command("LspInfo", function()
      vim.cmd("checkhealth vim.lsp")
    end, { force = true, desc = "Alias to `:checkhealth vim.lsp` (no tab)" })
    vim.api.nvim_create_user_command("LspLog", function()
      vim.cmd("edit " .. vim.lsp.get_log_path())
    end, { force = true, desc = "Open LSP log in current window" })
  end,
})

return {
  {
    -- LSP Configuration, note that some LSPs do formatting. It is
    -- entirely up to them
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      -- add a keymap
      keys[#keys + 1] = {
        "gh",
        function()
          return vim.lsp.buf.hover()
        end,
        desc = "Hover",
      }
      keys[#keys + 1] = { "K", false }

      --- Maybe...
      --- Yeah don't use thiis rn until its better
      local function transient_jump(picker_fn)
        return function()
          local actions = require("snacks.picker.actions")

          picker_fn({
            confirm = function(picker, item, action)
              -- Was the destination already an existing *listed* buffer?
              local dest = item and (item.buf or (item.file and vim.fn.bufnr(item.file, false))) or -1
              local was_listed = (dest ~= -1) and vim.bo[dest].buflisted

              actions.jump(picker, item, action)

              vim.schedule(function()
                local b = vim.api.nvim_get_current_buf()
                if vim.bo[b].buftype ~= "" then
                  return
                end
                if was_listed then
                  return
                end

                -- Make it "navigation-only"
                vim.bo[b].buflisted = false

                -- This is optional see the wipe code below
                -- vim.bo[b].bufhidden = "wipe"

                -- If you actually start editing, promote it back to a real buffer
                vim.api.nvim_create_autocmd("BufModifiedSet", {
                  buffer = b,
                  once = true,
                  callback = function()
                    vim.bo[b].buflisted = true
                    -- if vim.bo[b].bufhidden == "wipe" then
                    --   vim.bo[b].bufhidden = "" -- or "hide"
                    -- end
                  end,
                })
              end)
            end,
          })
        end
      end

      -- stylua: ignore
      vim.list_extend(keys, {
          -- TODO: See if we/should add an autocmd to these buffers that removes them on close so my list of opened does not get polluted
          -- Though, right now I have ff to show only modified buffeers which might be the right way to do it.
          {
            "gd",
            function()
              -- NOTE: A little concerned this is slow. Though it did achove wahat I wanted
              --   local pick = Snacks.picker.lsp_definitions()
              --   if pick ~= nil and pick.finder:count() == 0 then
              --    pcall(vim.cmd.normal, { args = { "gF" }, bang = true })
              --   end
              -- if pcall(vim.cmd.normal, { args = { "gF" }, bang = true }) then return end
              Snacks.picker.lsp_definitions()
            end,
            desc = "Goto Definition",
            has = "definition",
          },
          { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
          { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
          { "gi", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
          { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
          { "<leader>ss", function() Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP Symbols", has = "documentSymbol" },
          { "fs", function() Snacks.picker.lsp_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP Symbols", has = "documentSymbol" },
          { "<leader>si", function() Snacks.picker.lsp_workspace_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP Workspace Symbols", has = "workspace/symbols" },
          { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols({ filter = LazyVim.config.kind_filter }) end, desc = "LSP Workspace Symbols", has = "workspace/symbols" },
          { "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "C[a]lls Incoming", has = "callHierarchy/incomingCalls" },
          { "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "C[a]lls Outgoing", has = "callHierarchy/outgoingCalls" },
      })
    end,
    ---@class PluginLspOpts
    opts = {
      -- TODO: we still have to use this old API as LazyVim uses
      -- it. Note that vim.diagnostic.config({}) would be preferable.
      diagnostics = {
        virtual_text = false, -- no inline text
        underline = false, -- no squiggles
        update_in_insert = false,
        severity_sort = true,
        signs = true, -- we still want gutter signs
        float = { -- when we open the popup
          border = "rounded",
          source = "if_many",
          focusable = true,
        },
      },
      --- Get that shi out of here!
      inlay_hints = { enabled = false },
      --- Ideally we do not have these enabled for it.
      servers = {
        rust_analyzer = {
          enabled = false,
        },
        tinymist = {
          enabled = false,
        },
        tombi = { enabled = false },
        texlab = {
          settings = {
            texlab = {
              diagnostics = {
                ignoredPatterns = { "Unused label" },
              },
            },
          },
          --  keys = {
          --    { "<Leader>K", "<plug>(vimtex-doc-package)", desc = "Vimtex Docs", silent = true },
          --    -- Override [[ goto reference
          --    { "[[", mode = { "n", "x", "o" }, "<plug>(vimtex-[[)", desc = "Vimtex Docs", silent = true },
          --    { "]]", mode = { "n", "x", "o" }, "<plug>(vimtex-]])", desc = "Vimtex Docs", silent = true },
          --  },
        },
        nixd = {
          -- https://github.com/NixOS/nixfmt
          settings = {
            nixd = {
              formatting = {
                command = { "nixfmt" },
              },
              nixpkgs = {
                -- For flake.
                -- This expression will be interpreted as "nixpkgs" toplevel
                -- Nixd provides package, lib completion/information from it.
                -- Resource Usage: Entries are lazily evaluated, entire nixpkgs takes 200~300MB for just "names".
                -- Package documentation, versions, are evaluated by-need.
                -- Thanks! https://sbulav.github.io/vim/neovim-setting-up-nixd/
                expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }",
              },
            },
          },
        },
      },
    },
  },
  -- Formatting Configuration
  {
    ---@module "conform"
    "stevearc/conform.nvim",
    ---@type conform.setupOpts
    opts = {
      formatters_by_ft = {
        typst = { "typstyle" },
        json = { "jq" },
        tex = { "tex-fmt" },
        toml = { "tombi" },
        sql = { "sqruff" },
        python = function(bufnr)
          if is_snacks_scratch_buf(bufnr) then
            return { "ruff_format" }
          end

          return {
            -- To fix auto-fixable lint errors.
            "ruff_fix",
            -- To run the Ruff formatter.
            "ruff_format",
            -- To organize the imports.
            "ruff_organize_imports",
          }
        end,
        quarto = { "injected" },
        markdown = { "rumdl" },
      },
      formatters = {
        typstyle = {
          --- Note that for 0.13.7 --line-width will replace --column
          prepend_args = { "--wrap-text", "--line-width", "79" },
        },
        ["tex-fmt"] = {
          prepend_args = { "--wraplen", "79" },
        },
        -- Explicit restatements of conform's builtin tombi/sqruff definitions.
        -- NOTE: `command` must be the bare executable; args go in `args`
        -- (e.g. command = "tombi format" fails with "Command not found").
        tombi = {
          command = "tombi",
          args = { "format", "--stdin-filename", "$FILENAME", "-" },
          stdin = true,
        },
        sqruff = {
          command = "sqruff",
          args = { "fix", "$FILENAME" },
          stdin = false,
        },
        injected = {
          options = {
            -- Map fence languages -> conform formatters to run on the cell content
            lang_to_formatters = {
              -- python = { "ruff_fix", "ruff_format", "ruff_organize_imports" }, -- or just { "ruff_format" }
              -- Remove ruff_fix so that it does not remove unused imports
              python = { "ruff_format", "ruff_organize_imports" }, -- or just { "ruff_format" }
              typescript = { "biome" },
              javascript = { "biome" },
              -- add more if you like:
              -- r = { "styler" },        -- if you use an R formatter
              -- bash = { "shfmt" },
              -- yaml = { "prettierd", "prettier" },
            },
            -- You can set these if you want:
            -- ignore_errors = true, -- don’t abort if one cell fails
            -- trailing_newline = false,
          },
        },
      },
    },
  },
  {
    ---@module "mason"
    "mason-org/mason.nvim",
    version = "^1.0.0",
    ---@type MasonSettings
    opts = {
      PATH = "skip",
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    version = "^1.0.0",
    -- LazyVim overrides this ugh!
    opts = {
      automatic_installation = false,
    },
  },
  -- https://github.com/Bekaboo/dropbar.nvim
  {
    "SmiteshP/nvim-navic",
    lazy = true,
    init = function()
      vim.g.navic_silence = true
    end,
    opts = function()
      Snacks.util.lsp.on({ method = "textDocument/documentSymbol" }, function(buffer, client)
        require("nvim-navic").attach(client, buffer)
      end)
      return {
        separator = " › ",
        highlight = true,
        depth_limit = 5,
        icons = LazyVim.config.icons.kinds,
        lazy_update_context = false,
      }
    end,
  },
  -- FIXME: Godamnit this plugin is bugger as shit
  -- consider forking.
  {
    "michaelfortunato/goto-preview",
    dependencies = { "rmagatti/logger.nvim" },
    dev = true,
    event = "BufEnter",
    keys = {
      ---@type LazyKeysSpec
      {
        "gp",
        function()
          require("goto-preview").goto_preview_definition()
        end,
        desc = "Peak definition preview",
      },
    },
    -- UPDATE: Honest to god, AI Fixed it.
    -- Gotdamnit this plugin is bugger as shit, nothing works. see the FIXMEs
    -- me now: ummm what were they again ?
    config = function()
      require("goto-preview").setup({
        default_mappings = false, -- Bind default mappings
        width = 120, -- Width of the floating window
        height = 15, -- Height of the floating window
        border = { "↖", "─", "┐", "│", "┘", "─", "└", "│" }, -- Border characters of the floating window
        debug = false, -- Print debug information
        opacity = nil, -- 0-100 opacity level of the floating window where 100 is fully transparent.
        resizing_mappings = false, -- Binds arrow keys to resizing the floating window.
        -- NOTE: goto-preview uses `WinClosed *` and `remove_win()` inspects the *current* window, so the plugin's
        -- close hooks can fire for unrelated window closes (e.g. hover float) while the preview is still open.
        -- See `~/.local/share/nvim/lazy/goto-preview/lua/goto-preview/lib.lua` (`setup_aucmds` / `remove_win`).
        -- NOTE: Nested previews: opening goto-preview inside a preview and hitting `q` twice can return focus to the
        -- wrong split. The plugin manages a preview-window stack but doesn't track the original caller window.
        post_open_hook = function(buf, win)
          --- This flag is checked in my global q map whihc will close this window
          vim.api.nvim_win_set_var(win, "mnf-close-on-q", true)
          return true
        end, -- A function taking two arguments, a buffer and a window to be ran as a hook.
        references = { -- Configure the telescope UI for slowing the references cycling window.
          provider = "snacks", -- telescope|fzf_lua|snacks|mini_pick|default
          -- telescope = require("telescope.themes").get_dropdown({ hide_preview = false }),
        },
        -- These two configs can also be passed down to the goto-preview definition and implementation calls for one off "peak" functionality.
        focus_on_open = true, -- Focus the floating window when opening it.
        dismiss_on_move = false, -- Dismiss the floating window when moving the cursor.
        force_close = true, -- passed into vim.api.nvim_win_close's second argument. See :h nvim_win_close
        bufhidden = "wipe", -- the bufhidden option to set on the floating window. See :h bufhidden
        stack_floating_preview_windows = true, -- Whether to nest floating windows
        same_file_float_preview = true, -- Whether to open a new floating window for a reference within the current file
        preview_window_title = { enable = true, position = "center" }, -- Whether to set the preview window title as the filename
        zindex = 60, -- Keep previews above Snacks floats/Zen, below completion popups.
        vim_ui_input = false, -- Whether to override vim.ui.input with a goto-preview floating window
      })
    end,
  },
}
