-- FIXME: Try to gut LazyVim from this, it does too many hidden things,
-- such as starting the server
-- FIXME: Python LSP servers only! LSP rename fails with "change_annotations must be provided for annotated text edits"
--- Includes lsp, linting, and formatter configurations
vim.lsp.set_log_level("ERROR")
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
vim.lsp.config("tinymist", {
  settings = {
    -- do not fallb back to lsp formatting, as tinymist
    -- runs its own fork of typstyle (I believe this is still true)
    -- which confuses me. Might as well manage it myself anyhow
    -- formatterMode = "typstyle",
    -- formatterPrintWidth = 80,
    formatterMode = "",
    lint = { enabled = true },
  },
})
vim.lsp.enable("tinymist")
vim.lsp.enable("rust-analyzer")
vim.lsp.enable("ty") -- vim.lsp.enable("pyrefly")

------------------------------------------------------------------------------
---                                   Rune LSP                             ---
------------------------------------------------------------------------------
vim.lsp.config("rune", {
  cmd = { "rune" },
  filetypes = { "typst" },
  -- Use the file's directory as the root; Rune will optionally walk to VAULT.typ
  root_markers = { "VAULT.typ" },
  init_options = {
    vault_marker = "VAULT.typ",
    default_extension = ".typ",
    ignore = { ".git", "node_modules", "target", ".cache" },

    completionTriggerCharacters = { '"', "(", "#", "[" },
  },
  cmd_env = { RUNE_DEBUG_HTTP = "1" },
})
vim.lsp.enable("rune")
--- @param command lsp.Command
--- @param context? {bufnr?: integer}
local function rune_exec(command, context)
  local clients = vim.lsp.get_clients({ name = "rune", bufnr = 0 })
  if #clients == 0 then
    vim.notify("Rune LSP not attached to this buffer", vim.log.levels.WARN)
    return
  end
  local client = clients[1]
  client:exec_cmd(command, context, function(err, result, ...)
    if err ~= nil then
      vim.notify("Failed with" .. err.message)
    else
      vim.notify("Sucess with" .. vim.inspect(result))
    end
  end)
end
vim.api.nvim_create_user_command("RuneDebugViewer", function()
  rune_exec({ command = "rune.debugViewer.open", title = "Rune Debug Viewer" })
end, {})
------------------------------------------------------------------------------

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
      servers = {
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
        python = {
          -- To fix auto-fixable lint errors.
          "ruff_fix",
          -- To run the Ruff formatter.
          "ruff_format",
          -- To organize the imports.
          "ruff_organize_imports",
        },
        quarto = { "injected" },
      },
      formatters = {
        typstyle = {
          --- Note that for 0.13.7 --line-width will replace --column
          prepend_args = { "--wrap-text", "--line-width", "79" },
        },
        ["tex-fmt"] = {
          prepend_args = { "--wraplen", "79" },
        },
        tombi = {
          command = "tombi format",
          -- So interesting this does not work
          -- Clearly, I misunderstand unix args
          -- prepend_args = { "format" },
        },
        injected = {
          options = {
            -- Map fence languages -> conform formatters to run on the cell content
            lang_to_formatters = {
              -- python = { "ruff_fix", "ruff_format", "ruff_organize_imports" }, -- or just { "ruff_format" }
              -- Remove ruff_fix so that it does not remove unused imports
              python = { "ruff_format", "ruff_organize_imports" }, -- or just { "ruff_format" }
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
    opts = { automatic_installation = false, automatic_enable = false },
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
  {
    "rmagatti/goto-preview",
    dependencies = { "rmagatti/logger.nvim" },
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
    config = function()
      require("goto-preview").setup({
        default_mappings = false, -- Bind default mappings
        width = 120, -- Width of the floating window
        height = 15, -- Height of the floating window
        border = { "↖", "─", "┐", "│", "┘", "─", "└", "│" }, -- Border characters of the floating window
        debug = false, -- Print debug information
        opacity = nil, -- 0-100 opacity level of the floating window where 100 is fully transparent.
        resizing_mappings = false, -- Binds arrow keys to resizing the floating window.
        post_open_hook = function(buf, _)
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
        end, -- A function taking two arguments, a buffer and a window to be ran as a hook.
        post_close_hook = function(buf, _)
          -- NOTE: This will usually fail  if the buffer will close, but
          -- otherwise if the buffer is currently opened somehwere else
          -- we want to remove it incase we use the buffer and want the
          -- keymap freed later. This is a snacks issue too.
          succ, result = pcall(function()
            vim.keymap.del("n", "q", { buffer = buf })
          end)
          -- If you  ever want tracing
          -- if not succ then
          --   vim.notify_once("Goto preview keymap cleanup hook failed: " .. result, "debug")
          -- end
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
        preview_window_title = { enable = true, position = "left" }, -- Whether to set the preview window title as the filename
        zindex = 1, -- Starting zindex for the stack of floating windows
        vim_ui_input = false, -- Whether to override vim.ui.input with a goto-preview floating window
      })
    end,
  },
}
