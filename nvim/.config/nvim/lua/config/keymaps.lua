-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
-- floating terminal add ctrl-\
map("n", "<c-\\>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
map("t", "<C-\\>", "<cmd>close<cr>", { desc = "Hide Terminal" })

-- TODO: Try to get scrolling in integrateered terminal to work
-- See: https://vt100.net/docs/vt510-rm/SD.html
-- This works: `echo -e "\033[5T"`
-- vim.keymap.set("t", "<C-S-Up>", function()
--   -- vim.api.nvim_feedkeys(, "t", false)
--   -- Emit the xterm control sequence for SD (Scroll Down)
--   -- vim.api.nvim_replace_termcodes("\x1b[5T", true, true, true), "t", false)
--   -- \033[5T
--   -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("\x1b[5T", true, true, true), "t", false)
-- end, { noremap = true, silent = true })
-- vim.keymap.set("t", "<C-S-Up>", function()
--   -- vim.api.nvim_feedkeys(, "t", false)
--   -- print(vim.api.nvim_replace_termcodes("<Esc>[5T", true, true, true))
--   -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>[5S", true, true, true), "t", true)
--   -- return "\x1b[5S"
--   -- Emit the xterm control sequence for SD (Scroll Down)
--   -- vim.api.nvim_input("\033[5T")
--   -- \033[5T
--   -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("\x1b[5T", true, true, true), "t", false)
-- end, { noremap = true, silent = true })

-- NOTE: Very important swap. ; -> [ and ' ->]
-- On second though This is a bad idea
-- map({ "n", "v", "s", "o" }, ";", "[", { remap = true, desc = "For backwards textobject navigation" })
-- map({ "n", "v", "s", "o" }, ";;", "[[", { noremap = true, desc = "For backwards textobject navigation" })
-- map({ "n", "v", "s", "o" }, "g;", "g[", { remap = true, desc = "For forwards textobject navigation" })
-- map({ "n", "v", "s", "o" }, "'", "]", { remap = true, desc = "For forwards textobject navigation" })
-- map({ "n", "v", "s", "o" }, "''", "]]", { noremap = true, desc = "For forwards textobject navigation" })
-- map({ "n", "v", "s", "o" }, "g'", "g]", { remap = true, desc = "For forwards textobject navigation" })

map({ "n", "v", "o" }, "[s", "(", { desc = "For backwards (s)entece object navigation" })
map({ "n", "v", "o" }, "]s", ")", { desc = "For forwards (s)entece object navigation" })

local wk = require("which-key")
wk.add({
  { "<leader>m", group = "personal" }, -- group
})
