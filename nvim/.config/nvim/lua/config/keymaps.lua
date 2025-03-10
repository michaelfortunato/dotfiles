-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
--local del = vim.keymap.del
--NOTE: makes me safe
local del = function(...)
  return pcall(vim.keymap.del, ...)
end
local ui_input = Snacks.input or vim.ui.input
local ui_notify = Snacks.notify or print

-- map({ "n", "v", "o" }, "[s", "(", { desc = "For backwards (s)entece object navigation" })
-- map({ "n", "v", "o" }, "]s", ")", { desc = "For forwards (s)entece object navigation" })

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

del({ "n" }, ";") --NOTE: This makes it hard to use else where, but makes sure which key comes up
map({ "n" }, ";1", function()
  ---@diagnostic disable-next-line: missing-fields
  Snacks.scratch.open({ ft = "lua" })
end, { desc = "Open Scratch Lua Buffer" })
map({ "n" }, ";2", function()
  ---@diagnostic disable-next-line: missing-fields
  Snacks.scratch.open({ ft = "python" })
end, { desc = "Open Scratch Python Buffer" })
map({ "n" }, ";<Tab>", function()
  local buf_list = Snacks.scratch.list()
  if #buf_list < 2 then
    ui_notify("No previous scratch buffer for which to switch.")
    return
  end
  local buf = buf_list[2]
  ---@diagnostic disable-next-line: missing-fields
  Snacks.scratch.open({ ft = buf.ft, name = buf.name, file = buf.file, icon = buf.icon })
end, { desc = "Previous Scratch Buffer" })

map({ "n" }, ";l", function()
  Snacks.scratch.select()
end, { desc = "Open Scratch Buffer Picker" })

-- Personal key map system?
map("n", "..", "<Cmd>Make!<CR>", { desc = "Run Make" })
local wk = require("which-key")
wk.add({
  { "<leader>m", group = "personal" }, -- group
})
map(
  { "n", "v" },
  "<leader>mp",
  "<Cmd>edit " .. LazyVim.root() .. "/.lazy.lua" .. "<CR>",
  { desc = "Open .lazy.lua project local config" }
)
map({ "n", "v" }, "<leader>mm", "<Cmd>Make<CR>", { desc = "Run Make" })

map("n", "<leader>mc", function()
  return ui_input({ prompt = "Set makeprg" }, function(input)
    if input == nil or input == "" then
      vim.cmd("set makeprg?")
    else
      vim.cmd("let &makeprg='" .. input .. "'")
    end
    return
  end)
end, { desc = "Set makeprg" })

map("n", ".c", function()
  return ui_input({ prompt = "Set makeprg" }, function(input)
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

--- TODO: Sometimes the UI doesn't return

-- Big if true
map("n", ";;", "<Cmd>RunGlobalSystemTerminal<CR>", { desc = "Run command in globally dedicated system terminal split" })
map("n", ";c", function()
  return ui_input({ prompt = "Set vim.MNF.global_system_terminal_command" }, function(input)
    if input == nil or input == "" then
      print(vim.MNF.get_global_system_terminal_command())
    else
      vim.MNF.set_global_system_terminal_command(input)
    end
    return
  end)
end, { desc = "Set vim.MNF.global_system_terminal_command" })

map(
  "n",
  ",,",
  "<Cmd>RunGlobalIntegratedTerminal<CR>",
  { desc = "TODO: Run command in globally dedicated system terminal split" }
)

map("n", ",c", function()
  return ui_input({ prompt = "Set vim.MNF.global_system_terminal_command" }, function(input)
    if input == nil or input == "" then
      print(vim.MNF.get_global_system_terminal_command())
    else
      vim.MNF.set_global_system_terminal_command(input)
    end
    return
  end)
end, { desc = "Set vim.MNF.global_system_terminal_command" })

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
-- core adds here, you should try to stick with > but still
map("v", "<Tab>", "<gv")
map("v", "<S-Tab>", ">gv")

del({ "n" }, "<C-/>")
map("n", "<c-\\>", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
map("t", "<C-\\>", "<cmd>close<cr>", { desc = "Hide Terminal" })
del({ "n" }, "<leader>wm")

wk.add({
  { "<leader>t", group = "Task" }, -- group
})
--- Let t (as in "task") namespace all of the various runner combinations
map({ "n", "v" }, "<leader>tm", "<Cmd>Make<CR>", { desc = "Run Make" })
vim.keymap.set("n", "<leader>tmc", function()
  return ui_input({ prompt = "Set makeprg" }, function(input)
    if input == nil or input == "" then
      vim.cmd("set makeprg?")
    else
      vim.cmd("let &makeprg='" .. input .. "'")
    end
  end)
end, { desc = "Set makeprg" })
map("n", "<leader>tr", "<Cmd>RunGlobalSystemTerminal<CR>", { desc = "Run :Run" })
vim.keymap.set("n", "<leader>trc", function()
  return ui_input({ prompt = "Set vim.MNF.global_system_terminal_command" }, function(input)
    if input == nil or input == "" then
      print(vim.MNF.get_global_system_terminal_command())
    else
      vim.MNF.set_global_system_terminal_command(input)
    end
    return
  end)
end, { desc = "Set vim.MNF.global_system_terminal_command" })
map("n", "<leader>ty", "<Cmd>RunGlobalIntegratedTerminal<CR>", { desc = "Run :Run" })
vim.keymap.set("n", "<leader>tyc", function()
  ---
end, { desc = "Set vim.MNF.global_system_terminal_command" })

if vim.g.neovide then
  vim.keymap.set("n", "<D-s>", ":w<CR>") -- Save
  vim.keymap.set("v", "<D-c>", '"+y') -- Copy
  vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
  vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
  vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
  vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode

  vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })

  vim.g.neovide_scale_factor = 1.0
  local change_scale_factor = function(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
  end
  vim.keymap.set("n", "<D-=>", function()
    change_scale_factor(1.25)
  end)
  vim.keymap.set("n", "<D-->", function()
    change_scale_factor(1 / 1.25)
  end)

  map("n", "<C-/>", function()
    Snacks.terminal(nil, { cwd = LazyVim.root() })
  end, { desc = "Terminal (Root Dir)" })
  map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
  vim.g.neovide_cursor_trail_size = 0.0
  vim.g.neovide_cursor_animation_length = 0.0
end
