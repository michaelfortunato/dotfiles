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

-- TODO: Get proper pasting in
-- local function paste()
--   local pasted = require("img-clip").paste_image()
--   if not pasted then
--     vim.cmd("normal! p")
--   end
-- end

vim.keymap.set({ "n" }, "<leader>.", function()
  local bufpath = vim.api.nvim_buf_get_name(0)
  if bufpath == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN)
    return
  end
  local dir = vim.fs.dirname(bufpath)
  Snacks.picker.files({ cwd = dir })
end, { desc = "Search files in this buffer's cwd" })
vim.keymap.set("n", "<Enter>", "za", { desc = "Toggle fold under cursor" })
vim.keymap.set({ "n" }, "<C-q>", "<Cmd>copen<CR>", { desc = "Open Quickfix List" })
---
vim.keymap.set({ "c", "i" }, "<C-a>", "<Home>")
-- NOTE: blink overrides it with cmap <c-e> but should handle fallback
-- if it doesnt, add this explicilty { 'cancel', 'fallback' } to the new
-- entry in your nvim-cmp.lua
vim.keymap.set({ "c", "i" }, "<C-e>", "<End>")
vim.keymap.set({ "c", "i" }, "<C-Left>", "<S-Left>")
vim.keymap.set({ "c", "i" }, "<C-Right>", "<S-Right>")
vim.keymap.set({ "c", "i" }, "<A-Left>", "<S-Right>")
vim.keymap.set({ "c", "i" }, "<A-Right>", "<S-Right>")

--- Close quickfix list if open
vim.keymap.set("n", "q", function()
  -- Note, wrap it around vim.schedule if you want it an expression mapping
  -- but honestly this works well.
  if require("trouble").is_open() then
    require("trouble").close()
  end
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      vim.schedule(function()
        vim.cmd("cclose")
      end)
    end
  end
end, {
  silent = true,
  -- Note do not make it an expression mapping unless you want to wrap
  -- it around vim.schedule
  desc = [[I do not like this for entering macro
    recording mode as I often hit q by accident with tab
  ]],
})
del("v", "q")

vim.keymap.set({ "n" }, "<C-S-[>", function()
  if require("trouble").is_open() then
    -- TODO: Would be nice if there was a wraparound behavior or something
    require("trouble").prev({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cprev)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, { desc = "Previous Trouble/Quickfix Item" })
-- WARN: Overriding "<C-]>" might effect goto tag functionality, hence
-- why I make it an expression and return <C-]>, still I do the
-- pcall(vim.cmd.cnext) regardless, which might not be ideal.
-- This might be handleable via an autocmd QuickfixPostCmd
--
vim.keymap.set("n", "<C-]>", function()
  local trouble = require("trouble")

  if trouble.is_open() then
    -- Trouble handles jump internally, no expr return needed
    trouble.next({ skip_groups = true, jump = true })
    return "" -- prevent inserting anything
  else
    if vim.fn.getqflist({ size = 0 }).size > 0 then
      -- feed `:cnext<CR>` as a key sequence
      return "<Cmd>cnext<CR>"
    else
      -- no quickfix items, fall back to literal <C-]>
      return "<C-]>"
    end
  end
end, {
  expr = true,
  desc = "Next Trouble/Quickfix Item",
})
-- The "n" is necesasry to continue the keymap
-- TODO: Update for ghossty
vim.keymap.set({ "t", "n" }, "<C-S-Up>", [[<C-\><C-n>5<C-y>]], { silent = true })
vim.keymap.set({ "t", "n" }, "<C-S-Down>", [[<C-\><C-n>5<C-e>]], { silent = true })

vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-S-k>", "kzz")
vim.keymap.set("n", "<C-S-j>", "jzz")
-- vim.keymap.set("n", "<C-d>", function()
--   local lines = math.max(1, math.floor(vim.fn.winheight(0) / 3))
--   local raw = string.format("%d<C-e>zz", lines)
--   return vim.api.nvim_replace_termcodes(raw, true, false, true)
-- end, { expr = true, silent = true, desc = "Scroll down 1/3 page" })
-- vim.keymap.set("n", "<C-u>", function()
--   local lines = math.max(1, math.floor(vim.fn.winheight(0) / 3))
--   local raw = string.format("%d<C-y>zz", lines)
--   return vim.api.nvim_replace_termcodes(raw, true, false, true)
-- end, { expr = true, silent = true, desc = "Scroll up 1/3 page" })

-- like the shell
-- FIXME: Would be nice if this deleted the whole word in `word/`
-- like it does in zsh
vim.keymap.set({ "i", "c" }, "<C-BS>", "<C-w>")
-- FIXME: Would be nice if this deleted the whole word in `word/`
-- like it does in zsh
vim.keymap.set({ "i", "c" }, "<M-BS>", "<C-w>")

-- This is so fucking key
vim.keymap.set({ "n", "x" }, "<C-e>", function()
  return (vim.v.count1 * 5) .. "<C-e>"
end, { expr = true, silent = true, desc = "Scroll down faster" })
vim.keymap.set({ "n", "x" }, "<C-y>", function()
  return (vim.v.count1 * 5) .. "<C-y>"
end, { expr = true, silent = true, desc = "Scroll up faster" })

vim.keymap.set({ "n" }, "<leader>cR", "<CMD>LspRestart<CR>", { desc = "Restart All LSPs" })
del({ "n" }, "<leader><leader>") -- lazyvim shenanigans
-- - Files only in your config folder:
--     - Snacks.picker.smart({ finders = { "files" }, cwd = vim.fn.stdpath("config") })
-- - Files only under git root’s src:
--     - Snacks.picker.smart({ finders = { "files" }, cwd = (LazyVim.root() or vim.uv.cwd()) .. "/src" })
vim.keymap.set(
  { "n" },
  "<leader><leader>",
  -- "<Cmd>Telescope find_files sort_mru=true sort_lastused=true ignore_current_buffer=true<CR>",
  function()
    Snacks.picker.smart()
  end,
  { desc = "Find files (Cwd dir)" }
)
vim.keymap.set(
  { "n" },
  "<leader>,",
  -- "<Cmd>Telescope find_files sort_mru=true sort_lastused=true ignore_current_buffer=true<CR>",
  function()
    Snacks.picker.buffers()
  end,
  { desc = "Find files (Cwd dir)" }
)
vim.keymap.del({ "n" }, "f")
-- This is causing a ton of tabs to be created
-- vim.keymap.set(
--   { "n" },
--   "<Tab>",
--   "<CMD>tab split<CR>",
--   { desc = "Open buffer in new tab", noremap = true, silent = true }
-- )

-- WARN: overloaded a really nice key combo for buffer search not sure how I feel
-- abt it.
vim.keymap.set({ "n" }, "fb", "<Cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<CR>")
vim.keymap.set({ "n" }, "f<Tab>", function()
  Snacks.picker.tabs()
end, { desc = "Search open tabs", noremap = true, silent = true })

-- Find something else for tabmove. Well tabmove is not too helpful rn so leave it later.
-- vim.keymap.set({ "n" }, "<Tab>h", "<Cmd>-tabmove<CR>", { desc = "Move tab left" })
-- vim.keymap.set({ "n" }, "<Tab>l", "<Cmd>+tabmove<CR>", { desc = "Move tab right" })

-- NOTE: It could be worth it to reconsider using tabs at all
-- neovim just might not be made for the feature. I like the idea
-- of having persistent layout I can do , but at the end of the day,
-- buffers are NOT scoped to the tab. This one fact alone makes it impossible
-- to comfrotably work with tabs in a meaningful way. I often find myself
-- loading a buffer into tab y when that buffer is already placed--intentionally
-- mind you-- into tab x.
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
vim.keymap.set({ "n" }, "<Tab>h", "<Cmd>tabprev<CR>", { desc = "Goto left tab" })
vim.keymap.set({ "n" }, "<Tab>l", "<Cmd>tabnext<CR>", { desc = "Goto rightl tab" })

vim.keymap.set({ "n" }, "<Tab>1", "<Cmd>tabn 1<CR>", { desc = "Go to tab 1", noremap = true })
vim.keymap.set({ "n" }, "<Tab>2", "<Cmd>tabn 2<CR>", { desc = "Go to tab 2", noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Tab>3", "<Cmd>tabn 3<CR>", { desc = "Go to tab 3", noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Tab>4", "<Cmd>tabn 4<CR>", { desc = "Go to tab 4", noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Tab>5", "<Cmd>tabn 5<CR>", { desc = "Go to tab 5", noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Tab>6", "<Cmd>tabn 6<CR>", { desc = "Go to tab 6", noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Tab>7", "<Cmd>tabn 7<CR>", { desc = "Go to tab 7", noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Tab>8", "<Cmd>tabn 8<CR>", { desc = "Go to tab 8", noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Tab>9", "<Cmd>tabn 9<CR>", { desc = "Go to tab 9", noremap = true, silent = true })
vim.keymap.set({ "n" }, "<Tab>0", "<Cmd>tabn 10<CR>", { desc = "Go to tab 10", noremap = true, silent = true })
------------------------------------------------------------------------------
--                         MNF-TABDISCIPLINE
--                         You get these keymaps back when
--                         you start to learn to use stab sparingly
------------------------------------------------------------------------------
-- vim.keymap.set("n", "<C-t>", "<Cmd>tabnew<CR>", { desc = "New Tab" })
-- WARN: Mapping <Tab> might conflict with <C-i>
-- vim.keymap.set({ "n" }, "<Tab><Tab>", "<Cmd>tabnext #<CR>", { desc = "Last Accessed Tab" })
-- Consider this
-- vim.keymap.set("n", "<Tab>c", "<Cmd>tabnew<CR>", { desc = "New Tab" })
vim.keymap.set("n", "<Tab>d", "<Cmd>tabclose<CR>", { desc = "Close Tab" })
vim.keymap.set({ "n" }, "<Tab>p", "<Cmd>tabprev<CR>", { desc = "Previous Tab" })
vim.keymap.set({ "n" }, "<Tab>n", "<Cmd>tabnext<CR>", { desc = "Nest Tab" })
-- WARN: SUPER IMPORTANT, <Tab> and <C-i> are the same, its important therefore
-- to get neovim to distinguish it. THis works on ghostty at least.
vim.keymap.set({ "n", "t", "x", "o" }, "<C-i>", "<C-i>")

-- map({ "n", "v", "o" }, "[s", "(", { desc = "For backwards (s)entece object navigation" })
-- map({ "n", "v", "o" }, "]s", ")", { desc = "For forwards (s)entece object navigation" })

-- map({ "n", "v", "o" }, "<leader>r", "<Cmd>make<CR>", { desc = "Run build command" })
--
--

vim.keymap.set({ "n", "v", "o" }, "<leader><Tab>", "<Cmd>e #<CR>", { desc = "Last Accessed Buffer" })
--- TODO: Try to settle on <leader>bd for delete buffer and some other
--- <leader><lowercase><lowercase> keymap. Find such a keymap
vim.keymap.set("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer (Not Window)" })
-- TODO: Make this smart so that we only delete the buffer and the window
-- if there is at least one other window in the tab that holds a regular buffer
vim.keymap.set("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- NOTE: We are remapping LazyVim's <Tab> Commands
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

--- kitty section
--- -- Kitty Splits
-- FIXME: There is some bug in kitty where the cursor is flickering
-- in neovim. It coudl be on the neovim side or the kitty size.
-- Look at it later.
map({ "n", "v" }, "<C-h>", function()
  require("smart-splits").move_cursor_left()
end)
map({ "n", "v" }, "<C-j>", function()
  require("smart-splits").move_cursor_down()
end)
map({ "n", "v" }, "<C-k>", function()
  require("smart-splits").move_cursor_up()
end)
map({ "n", "v" }, "<C-l>", function(e)
  require("smart-splits").move_cursor_right()
end)
--- The splits in insert mode
map({ "i", "t" }, "<C-h>", function()
  vim.cmd("stopinsert")
  require("smart-splits").move_cursor_left()
end)
map({ "t", "i" }, "<C-j>", function()
  vim.cmd("stopinsert")
  require("smart-splits").move_cursor_down()
end)
map({ "t", "i" }, "<C-k>", function()
  vim.cmd("stopinsert")
  require("smart-splits").move_cursor_up()
end)
map({ "t", "i" }, "<C-l>", function(e)
  local ls = require("luasnip")
  if ls.choice_active() then
    ls.change_choice(1)
    return true
  end
  vim.cmd("stopinsert")
  require("smart-splits").move_cursor_right()
end)
vim.keymap.set({ "n", "i", "v" }, "<C-S-l>", function()
  local ls = require("luasnip")
  if ls.choice_active() then
    ls.change_choice(-1)
    return true
  end
  return "<C-w>r"
end, { desc = "Rotate windows backward", silent = true })
-- Rotate windows forward (like <C-w>r) while staying in terminal mode
vim.keymap.set("t", "<C-S-l>", function()
  vim.cmd("silent! wincmd r")
end, { silent = true, desc = "Rotate windows forward (terminal)" })
-- --- Kitty like layout rotation keybinding
vim.keymap.set({ "n", "i", "v" }, "<C-S-h>", "<C-w>R", { desc = "Rotate windows forward", silent = true })

-- Optional: rotate backward (like <C-w>R)
vim.keymap.set("t", "<C-S-h>", function()
  vim.cmd("silent! wincmd R")
end, { silent = true, desc = "Rotate windows backward (terminal)" })

del("n", "m")
map("n", "mm", "<Cmd>Make!<CR>", { desc = "Run Make" })
local wk = require("which-key")
wk.add({
  { "<leader>a", group = "Alerts" }, -- group
})
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
-- From ChatGPT “silent = true” only suppresses Neovim’s echo of the mapping
-- itself.
-- The dedent operator (<) still runs exactly as if you typed it by hand,
-- and it’s the operator—not the mapping—that prints “4 lines <ed 1 time.”
-- Wrap the action in a silent! normal! call
--  so the operator runs quietly:
--
--  vim.keymap.set("x", "<S-Tab>", function()
--    vim.cmd("silent! normal! <gv")
--  end, { desc = "Dedent selection", silent = true })
map("x", "<Tab>", ">gv", { silent = true })
map("x", "<S-Tab>", "<gv", { silent = true })
vim.keymap.set("v", "H", "J") -- Map H to Join lines to J can be used below
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true }) -- Shift visual selected line down
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true }) -- Shift visual selected line up
vim.keymap.set({ "n" }, "<leader>si", function()
  -- require("snacks").picker.lsp_workspace_symbols({
  --   -- filter = {
  --   --   -- [vim.bo.filetype] = LazyVim.config.get_kind_filter() or true,
  --   -- },
  -- })
  -- These behave a bit differently
  require("telescope.builtin").lsp_dynamic_workspace_symbols({
    symbols = LazyVim.config.get_kind_filter(),
  })
end, { desc = "Goto Symbol (Workspace)" })

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
