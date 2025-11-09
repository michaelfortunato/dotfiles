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
