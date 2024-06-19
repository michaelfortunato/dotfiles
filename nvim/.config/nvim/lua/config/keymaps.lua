-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
-- NOTE: Why does LazyVim use double <esc>? I get maybe there is conflict on
-- one <esc> but I have not experienced the like.
map("t", "<esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
