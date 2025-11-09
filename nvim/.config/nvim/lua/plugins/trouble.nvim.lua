-- For quick fixes and such
--
return {
  ---@type LazyPluginSpec
  {
    ---@module "trouble"
    "folke/trouble.nvim",
    lazy = false,
    ---@type trouble.Config
    opts = {
      focus = false,
      win = { type = "split", position = "bottom", size = 18 },
    },

    keys = {
      { "<leader>aa", "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (Buffer)" },
      { "<leader>aA", "<Cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Workspace)" },
      { "<leader>xx", "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (Buffer)" },
      { "<leader>xX", "<Cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Workspace)" },
      { "<leader>aq", "<Cmd>copen<CR>", desc = "Open Quickfix List" },
    },
  },
}
