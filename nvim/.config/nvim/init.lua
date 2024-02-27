-- bootstrap lazy.nvim, LazyVim and your plugins
vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct
-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
-- vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
-- To disable root detection set to just "cwd"
vim.g.root_spec = { "cwd" }
require("config.lazy")
