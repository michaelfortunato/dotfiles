-- FIXME: Python LSP servers only! LSP rename fails with "change_annotations must be provided for annotated text edits"
--- Includes lsp, linting, and formatter configurations
vim.lsp.set_log_level("ERROR")
vim.diagnostic.config({
  virtual_text = {
    source = true, -- or "if_many"
  },
  float = {
    source = true,
  },
})

vim.lsp.enable("pyrefly")
vim.lsp.enable("ruff")
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
    end,
    ---@class PluginLspOpts
    opts = {
      --- Get that shi out of here!
      inlay_hints = { enabled = false },
      servers = {
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
        tinymist = {
          settings = {
            formatterMode = "",
            -- formatterMode = "typstfmt",
            -- do not fallb back to lsp formatting, as tinymist
            -- runs its own fork of typstyle which confuses me
            -- formatterMode = "typstyle",
            -- formatterPrintWidth = 80,
            -- TODO: Does this use typststyle?
            lint = { enabled = true },
          },
        },
      },
    },
  },
  -- Formatting Configuration
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        typst = { "typstyle" },
        tex = { "tex-fmt" },
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
        injected = {
          options = {
            -- Map fence languages -> conform formatters to run on the cell content
            lang_to_formatters = {
              python = { "ruff_fix", "ruff_format", "ruff_organize_imports" }, -- or just { "ruff_format" }
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
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "danymat/neogen",
    },
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = {
          -- NeoGen Code Action
          {
            name = "neogen", -- Custom name instead of "null-ls"
            method = null_ls.methods.CODE_ACTION,
            filetypes = { "lua", "python", "javascript", "typescript", "go", "rust", "java", "c", "cpp" },
            generator = {
              fn = function(params)
                return {
                  {
                    title = "Generate Documentation",
                    action = function()
                      require("neogen").generate()
                    end,
                  },
                }
              end,
            },
          },
        },
      })
    end,
  },
}
