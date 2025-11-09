-- Options are automatically loaded before lazy.nvim startupopt
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.wo.colorcolumn = "80" -- TODO: How do I set the actual color?
-- Try this
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.cursorline = false -- disable current-line highlight; comment out to restore
--- Prepare for lazyvim v14 if I ever decide to go with it.
vim.g.snacks_animate = false

--- SSH things START
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

vim.ui.open = (function(original_open)
  return function(path)
    if vim.env.SSH_CLIENT or vim.env.SSH_TTY then
      vim.fn.system(string.format("kitten @ action open_url %s", vim.fn.shellescape(path)))
    else
      original_open(path)
    end
  end
end)(vim.ui.open)
--- SSH things END
vim.opt.fillchars:append({
  foldclose = "›", -- or "▸", "⯈", "»", etc.
  foldopen = "⌄", -- pick a matching opener if you like
})

vim.o.exrc = true
-- LazyVim root dir detection
-- Each entry can be:
-- * the name of a detector function like `lsp` or `cwd`
-- * a pattern or array of patterns like `.git` or `lua`.
-- * a function with signature `function(buf) -> string|string[]`
-- vim.g.root_spec = { "lsp", { ".git", "lua" }, "cwd" }
-- To disable root detection set to just "cwd"
-- vim.g.root_spec = { "cwd" }

-- Never show the native tabline (even with multiple tabs)
vim.o.showtabline = 0

-- Don't show pending key sequences (e.g. "^Wc", "gj") in statusline
vim.o.showcmd = false

-- Consider this for C-u c-d nav, a bit more tractable
vim.o.scroll = 15
-- or this idk
-- vim.wo.scroll = 15

-- Note this was all moved the lualine
-- -- Winbar: right-aligned status showing MAX and/or tab count (>1)
-- -- Uses declancm/maximize.nvim's vim.t.maximized flag (per-tabpage)
-- _G.winbar_status = function()
--   local parts = {}
--   if vim.t.maximized then
--     table.insert(parts, "MAX")
--   end
--   local tabs = #vim.api.nvim_list_tabpages()
--   if tabs > 1 then
--     table.insert(parts, tostring(tabs))
--   end
--   return table.concat(parts, " ")
-- end
--
-- -- Back-compat for earlier name if referenced elsewhere
-- _G.maximize_status = function()
--   return _G.winbar_status()
-- end
--
-- -- Right align with %=; empty string hides the winbar content
-- vim.o.winbar = "%=%{%v:lua.winbar_status()%}"
