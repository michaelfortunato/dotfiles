return {
  "shortcuts/no-neck-pain.nvim",
  config = function(_, opts)
    require("no-neck-pain").setup(opts)
    vim.keymap.set("n", "<leader>uM", "<Cmd>NoNeckPain<CR>")
  end,
}
