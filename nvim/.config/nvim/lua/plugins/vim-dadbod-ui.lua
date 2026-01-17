-- This could be worth looking into as a lua native
-- https://github.com/kndndrj/nvim-dbee?tab=readme-ov-file-- So sick
-- vim.g.dbs = {
-- 	{ name = "exp1", url = "sqlite:///Users/michaelfortunato/projects/SymD/data/Exp1/output.db" },
-- }

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("sql-dadbod", { clear = true }),
  pattern = "sql",
  callback = function(event)
    vim.keymap.set("n", "<Enter>", "<Plug>(DBUI_ExecuteQuery)", { buffer = event.buf })
  end,
})
return {
  "kristijanhusak/vim-dadbod-ui",
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    -- { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  init = function()
    -- Your DBUI configuration
    vim.g.db_ui_use_nerd_fonts = 1
  end,
}
