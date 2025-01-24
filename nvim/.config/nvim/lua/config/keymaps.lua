-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
-- floating terminal add ctrl-\
-- NOTE: This keymap is overridden by kitty
-- As well as <C-/>, <C-;>
map("n", "<c-\\>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
map("t", "<C-\\>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("n", "<localleader><localleader>", require("telescope.builtin").buffers, { desc = "Telescope buffers" })

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

-- map({ "n", "v", "o" }, "<leader>r", "<Cmd>make<CR>", { desc = "Run build command" })

-- WARN: We are remapping LazyVim's <Tab> Commands
-- TODO:  local wk = require("which-key")
-- How do I delete a group mapping? { "<leader><tab>", group = "tabs" },
-- del({"n", "v"}, "<leader><tab>")
vim.keymap.del("n", "<leader><tab>l", { desc = "Last Tab" })
-- TODO: Remap me: map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
vim.keymap.del("n", "<leader><tab>o")
---- TODO: Remap me: map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
vim.keymap.del("n", "<leader><tab>f", { desc = "First Tab" })
--- TODO: Remap me: map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
vim.keymap.del("n", "<leader><tab><tab>", { desc = "New Tab" })
--- TODO: Remap me: map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
vim.keymap.del("n", "<leader><tab>]", { desc = "Next Tab" })
--- TODO: Remap me: map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
vim.keymap.del("n", "<leader><tab>d", { desc = "Close Tab" })
--- TODO: Remap me: map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
vim.keymap.del("n", "<leader><tab>[", { desc = "Previous Tab" })

map({ "n", "v", "o" }, "<leader><Tab>", "<Cmd>e #<CR>", { desc = "Switch to Other Buffer" })

--- kitty splits
map("n", "<C-h>", require("smart-splits").move_cursor_left)
map("n", "<C-j>", require("smart-splits").move_cursor_down)
map("n", "<C-k>", require("smart-splits").move_cursor_up)
map("n", "<C-l>", require("smart-splits").move_cursor_right)

-- Personal key map system?
local wk = require("which-key")
wk.add({
  { "<leader>m", group = "personal" }, -- group
})
