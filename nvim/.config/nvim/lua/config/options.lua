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
--- vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
if vim.env.SSH_TTY then
  -- Check if we are on one of my own servers?
  -- We're in SSH - use OSC52 for clipboard
  -- NOTE: You need both
  vim.opt.clipboard = "unnamedplus"
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
else
  -- Local - use system clipboard
  vim.opt.clipboard = "unnamedplus"
end
vim.o.exrc = true

vim.ui.open = (function(original_open)
  return function(path)
    if vim.env.SSH_CLIENT or vim.env.SSH_TTY then
      vim.fn.system(string.format("kitten @ action open_url %s", vim.fn.shellescape(path)))
    else
      original_open(path)
    end
  end
end)(vim.ui.open)

-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
-- vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
-- To disable root detection set to just "cwd"
-- vim.g.root_spec = { "cwd" }
