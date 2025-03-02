-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
--local del = vim.keymap.del
--NOTE: makes me safe
local del = function(...)
  return pcall(vim.keymap.del, ...)
end

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
del("n", "<leader><tab>l", { desc = "Last Tab" })
-- TODO: Remap me: map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
del("n", "<leader><tab>o")
---- TODO: Remap me: map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
del("n", "<leader><tab>f", { desc = "First Tab" })
--- TODO: Remap me: map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
del("n", "<leader><tab><tab>", { desc = "New Tab" })
--- TODO: Remap me: map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
del("n", "<leader><tab>]", { desc = "Next Tab" })
--- TODO: Remap me: map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
del("n", "<leader><tab>d", { desc = "Close Tab" })
--- TODO: Remap me: map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
del("n", "<leader><tab>[", { desc = "Previous Tab" })
--- TODO: Remap me: map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
del("n", "<leader>ql")
del("n", "<leader>qd")
del("n", "<leader>qq")
del("n", "<leader>qs")
del("n", "<leader>qS")

map({ "n", "v", "o" }, "<leader><Tab>", "<Cmd>e #<CR>", { desc = "Switch to Other Buffer" })

--- kitty splits
map("n", "<C-h>", require("smart-splits").move_cursor_left)
map("n", "<C-j>", require("smart-splits").move_cursor_down)
map("n", "<C-k>", require("smart-splits").move_cursor_up)
map("n", "<C-l>", require("smart-splits").move_cursor_right)

-- Personal key map system?
map("n", "<localleader><localleader>", "<Cmd>Make!<CR>", { desc = "Run Make" })
local wk = require("which-key")
wk.add({
  { "<leader>m", group = "personal" }, -- group
})
map(
  { "n", "v" },
  "<leader>mp",
  "<Cmd>edit " .. LazyVim.root() .. "/.nvim.lua" .. "<CR>",
  { desc = "Open .lazy.lua project local config" }
)
map({ "n", "v" }, "<leader>mm", "<Cmd>Make<CR>", { desc = "Run Make" })

local ui_input = Snacks.input or vim.ui.input

vim.keymap.set("n", "<leader>mc", function()
  ui_input({ prompt = "Set makeprg" }, function(input)
    if input == nil or input == "" then
      vim.cmd("set makeprg?")
    else
      vim.cmd("let &makeprg='" .. input .. "'")
    end
  end)
end, { desc = "Set makeprg" })
wk.add({
  { "<leader>t", group = "Task" }, -- group
})
map({ "n", "v" }, "<leader>tm", "<Cmd>Make<CR>", { desc = "Run Make" })
map({ "n", "v" }, "<leader>tt", "<Cmd>Make<CR>", { desc = "Run Make" })
vim.keymap.set("n", "<leader>tc", function()
  ui_input({ prompt = "Set makeprg" }, function(input)
    if input == nil or input == "" then
      vim.cmd("set makeprg?")
    else
      vim.cmd("let &makeprg='" .. input .. "'")
    end
  end)
end, { desc = "Set makeprg" })

-- quickfix list
map("n", "<leader>q", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

local function close_quickfix_if_open()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.schedule(function()
        vim.cmd("cclose")
      end)
      return ""
    end
  end
  return "q"
end
--- Close quickfix list if open
vim.keymap.set("n", "q", close_quickfix_if_open, { expr = true, silent = true })

del({ "n" }, ";")
map({ "n" }, ";1", function()
  print("TODO: lua")
end, { desc = "Open Scratch Lua Buffer" })
map({ "n" }, ";1", function()
  print("TODO: lua")
end, { desc = "Open Scratch Lua Buffer" })
map({ "n" }, ";2", function()
  print("TODO: python")
end, { desc = "Open Scratch Python Buffer" })
map({ "n" }, ";<Tab>", function()
  print("TODO: previous buffer")
end, { desc = "Open Previous Scratch Buffer" })

vim.keymap.set("n", "<leader>rr", function()
  ui_input({ prompt = "Set runprg" }, function(input)
    if input == nil or input == "" then
      print(vim.g.runprg)
    else
      vim.g.runprg = input
    end
  end)
end, { desc = "Run :Run, which invokes vim.g.runprg in your system terminal window" })

vim.keymap.set("n", "<leader>rc", function()
  ui_input({ prompt = "Set runprg" }, function(input)
    if input == nil or input == "" then
      print(vim.g.runprg)
    else
      vim.g.runprg = input
    end
  end)
end, { desc = "Set vim.g.runprg, :Run uses to invoke the command in your system terminal window" })

local function kitty_exec(args)
  local arguments = vim.deepcopy(args)
  table.insert(arguments, 1, "kitty")
  table.insert(arguments, 2, "@")
  -- local password = vim.g.smart_splits_kitty_password or require("smart-splits.config").kitty_password or ""
  -- if #password > 0 then
  --   table.insert(arguments, 3, "--password")
  --   table.insert(arguments, 4, password)
  -- end
  return vim.fn.system(arguments)
end
--
-- local function toggle_term()
--   vim.o.lazyredraw = true
--   vim.schedule(function()
--     local ok, _ = pcall(kitty_exec, { "kitten", "toggle_term.py" })
--   end)
--   vim.o.lazyredraw = false
--   --- vim.o.lazyredraw = true
--   --- local ok, _ = pcall(kitty_exec, { "kitten", "toggle_term.py" })
--   --- vim.o.lazyredraw = false
-- end
--
-- -- floating terminal add ctrl-\
-- -- NOTE: This keymap is overridden by kitty
-- -- As well as <C-/>, <C-;>
--- vim.keymap.del("n", "<c-\\>", function()
---   Snacks.terminal(nil, { cwd = LazyVim.root() })
--- end, { desc = "Terminal (Root Dir)" })
--- vim.keympap.del("t", "<C-\\>", "<cmd>close<cr>", { desc = "Hide Terminal" })
-- # TODO: (MNF-7000) not confident yet vim.keymap.set({ "n", "v" }, "<C-/>", function()
--   return toggle_term()
-- end, { desc = "Toggle Terminal (Cwd)" })
--
del({ "n" }, "<C-/>")
