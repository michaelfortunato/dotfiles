-- LSP keymaps
return {
  "neovim/nvim-lspconfig",
  init = function()
    local keys = require("lazyvim.plugins.lsp.keymaps").get()
    -- add a keymap
    keys[#keys + 1] = { "gh", vim.lsp.buf.hover }
  end,
  ---@class PluginLspOpts
  opts = { inlay_hints = { enabled = false } },
}
