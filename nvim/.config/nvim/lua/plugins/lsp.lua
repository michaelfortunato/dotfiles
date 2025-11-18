-- FIXME: Try to gut LazyVim from this, it does too many hidden things,
-- such as starting the server
-- FIXME: Python LSP servers only! LSP rename fails with "change_annotations must be provided for annotated text edits"
--- Includes lsp, linting, and formatter configurations
vim.lsp.set_log_level("ERROR")
-- NOTE: vim.lsp.config does not start the lsp server. Simply configures it.
-- no need to call vim.lsp.config if we are good with their defaults
vim.lsp.enable("pyrefly")
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

vim.lsp.config["rune"] = {
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
}
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

--- AI SLOP completion code
-- Key mappings for inline completion
-- Three main mappings:

vim.lsp.inline_completion.enable(false)
-- 1) Cycle suggestions
vim.keymap.set("i", "<C-l>", function()
  vim.lsp.inline_completion.select({ count = 1 }) -- next candidate
end, { desc = "Inline: next suggestion" })

vim.keymap.set("i", "<C-h>", function()
  vim.lsp.inline_completion.select({ count = -1 }) -- previous candidate
end, { desc = "Inline: previous suggestion" })

-- 2) Accept current suggestion (falls back if none is showing)
vim.keymap.set("i", "<C-;>", function()
  return vim.lsp.inline_completion.get() and "" or "<C-;>"
end, { expr = true, desc = "Inline: accept suggestion" })

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
      keys[#keys + 1] = {
        "gi",
        function()
          return vim.lsp.buf.implementation()
        end,
        desc = "Goto Implementation",
      }
      keys[#keys + 1] = { "K", false }
      keys[#keys + 1] = {
        "gai",
        function()
          ---@diagnostic disable-next-line: undefined-global
          Snacks.picker.lsp_incoming_calls()
        end,
        desc = "C[a]lls Incoming",
        has = "callHierarchy/incomingCalls",
      }
      keys[#keys + 1] = {
        "gao",
        function()
          ---@diagnostic disable-next-line: undefined-global
          Snacks.picker.lsp_outgoing_calls()
        end,
        desc = "C[a]lls Outgoing",
        has = "callHierarchy/outgoingCalls",
      }
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
}
