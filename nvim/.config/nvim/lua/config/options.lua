-- Options are automatically loaded before lazy.nvim startupopt
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.wo.colorcolumn = "80" -- TODO: How do I set the actual color?
-- Try this
vim.opt.number = false
vim.opt.relativenumber = false
--- Prepare for lazyvim v14 if I ever decide to go with it.
vim.g.snacks_animate = false

--- "+y$
vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
vim.o.exrc = true

-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
-- vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
-- To disable root detection set to just "cwd"
-- vim.g.root_spec = { "cwd" }
