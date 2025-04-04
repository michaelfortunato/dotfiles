return {
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
  end,
  ---@class PluginLspOpts
  opts = {
    --- Get that shi out of here!
    inlay_hints = { enabled = false },
    servers = {
      texlab = {
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
          -- formatterMode = "typstfmt",
          formatterMode = "typstyle",
        },
      },
    },
  },
}
