-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = function(...)
  return pcall(vim.keymap.set, ...)
end
--local del = vim.keymap.del
--NOTE: makes me safe
local del = function(...)
  return pcall(vim.keymap.del, ...)
end
local ui_input = Snacks.input or vim.ui.input
local ui_notify = Snacks.notify or print

local function paste()
  local pasted = require("img-clip").paste_image()
  if not pasted then
    vim.cmd("normal! p")
  end
end

vim.keymap.set({ "n" }, "<leader>cR", "<CMD>LspRestart<CR>", { desc = "Restart All LSPs" })
--- FIXME: Eh not great
map("n", "p", paste, { noremap = true, silent = true })
-- map("i", "<C-v>", paste, { noremap = true, silent = true })
-- map("i", "<M-v>", paste, { noremap = true, silent = true })

-- map({ "n", "v", "o" }, "[s", "(", { desc = "For backwards (s)entece object navigation" })
-- map({ "n", "v", "o" }, "]s", ")", { desc = "For forwards (s)entece object navigation" })

-- map({ "n", "v", "o" }, "<leader>r", "<Cmd>make<CR>", { desc = "Run build command" })
--

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

map({ "n", "v", "o" }, "<leader><Tab>", "<Cmd>e #<CR>", { desc = "Switch to Other Buffer" })

--- kitty splits
map({ "n", "t", "v" }, "<C-h>", require("smart-splits").move_cursor_left)
map({ "n", "t", "v" }, "<C-j>", require("smart-splits").move_cursor_down)
map({ "n", "t", "v" }, "<C-k>", require("smart-splits").move_cursor_up)
map({ "n", "t", "v" }, "<C-l>", require("smart-splits").move_cursor_right)

map({ "n", "t", "v" }, "<C-q>", "<cmd>qa<cr>", { desc = "Quit All" })

del("n", "m")
map("n", "mm", "<Cmd>Make!<CR>", { desc = "Run Make" })
local wk = require("which-key")
wk.add({
  { "<leader>m", group = "personal" }, -- group
})

-- HACK: This lets my mnf-terminal register the ';' prefix with which-key
-- so I get a preview
-- because otherwise it will conflict with mini.ai or something like that
-- @see ../plugins/mnf-terminal.lua
del("n", ";")

local exrc_helper = require("config.exrc-helper")
local template = exrc_helper.template
map({ "n", "v" }, "<leader>mp", function()
  local filepath = LazyVim.root() .. "/.lazy.lua"
  -- Check if file already exists
  if vim.loop.fs_stat(filepath) then
    -- vim.notify(".lazy.lua already exists, skipping creation.", vim.log.levels.TRACE)
    return "<Cmd>edit " .. filepath .. "<CR>"
  end
  local fd = io.open(filepath, "w")
  if not fd then
    vim.notify("Failed to create .lazy.lua", vim.log.levels.ERROR)
    return
  end
  fd:write(template)
  fd:close()
  return "<Cmd>edit " .. filepath .. "<CR>"
end, {
  expr = true, -- treat the Lua return as a key‑sequence
  noremap = true,
  silent = true,
  desc = "Open .lazy.lua project local config",
})
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

-- quickfix list
-- del("n", "<leader>ql")
-- del("n", "<leader>qd")
-- del("n", "<leader>qq")
-- del("n", "<leader>qs")
-- del("n", "<leader>qS")
-- map("n", "<leader>q", function()
--   local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
--   if not success and err then
--     vim.notify(err, vim.log.levels.ERROR)
--   end
-- end, { desc = "Quickfix List" })

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
-- map("n", ";;", "<Cmd>RunGlobalSystemTerminal<CR>", { desc = "Run command in globally dedicated system terminal split" })
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
-- apprently x makes it so that <Tab> does not done is select mode
map("x", "<Tab>", ">gv", { silent = true })
map("x", "<S-Tab>", "<gv", { silent = true })
vim.keymap.set("v", "H", "J") -- Map H to Join lines to J can be used below
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true }) -- Shift visual selected line down
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true }) -- Shift visual selected line up

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

map("n", "<leader>sp", function()
  Snacks.picker.grep({ rtp = true })
end, { desc = "Grep RTP (3rd-Party Plugin) Directory" })

map({ "n", "t" }, "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map({ "n", "t" }, "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map({ "n", "t" }, "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map({ "n", "t" }, "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- map("n", "<C-/>", function()
--   Snacks.terminal(nil, { cwd = LazyVim.root() })
-- end, { desc = "Terminal (Root Dir)" })
-- map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
-- --TODO: I cannot get Folke's maximze to work without going through here
-- LazyVim.ui.maximize():map("<C-S-Space>")
-- map({ "n", "t", "v" }, "<C-S-l>", "<C-w>R", { desc = "Toggle Maximize Window" })
-- map({ "n", "t", "v" }, "<C-S-h>", "<C-w>r", { desc = "Toggle Maximize Window" })

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
