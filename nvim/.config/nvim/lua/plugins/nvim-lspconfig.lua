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
          },
        },
      },
    },
  },
}
