-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("formatting", { clear = true }),
  pattern = {
    "c",
    "cpp",
  },
  callback = function(event)
    if event.filetype == "c" then
      vim.bo[event.buf].tabstop = 8
      vim.bo[event.buf].shiftwidth = 4
      vim.bo[event.buf].expandtab = true
    elseif event.filetype == "cpp" then
      vim.bo[event.buf].tabstop = 4
      vim.bo[event.buf].shiftwidth = 4
      vim.bo[event.buf].expandtab = true
    end
  end,
})

if vim.fn.has("nvim") == 1 then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait"
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "gitrebase", "gitconfig" },
  command = "set bufhidden=delete",
})

vim.api.nvim_create_autocmd("FileType", {
  --- TODO: Problably should be moved into an ftpluin
  pattern = { "lua" },
  callback = function(ev)
    vim.api.nvim_buf_set_keymap(ev.buf, "n", "<localleader>s", "<Cmd>source %<CR>", { desc = "Source lua file" })
    --- NOTE: :lua also works I believe and works in any buffer.
    --- But since this is buffer local, just use the original
    vim.api.nvim_buf_set_keymap(ev.buf, "v", "<localleader>s", ":'<,'>lua<CR>", { desc = "Run visually selected code" })
  end,
})

vim.api.nvim_create_user_command("Make", function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
  if num_subs == 0 then
    cmd = cmd .. " " .. params.args
  end
  local task = require("overseer").new_task({
    cmd = vim.fn.expandcmd(cmd),
    components = {
      { "on_output_quickfix", open = not params.bang, open_height = 8 },
      "default",
    },
  })
  task:start()
end, {
  desc = "Run makeprg asynchronously (using Overseer)",
  nargs = "*",
  bang = true,
})

local function kitty_exec(args)
  local arguments = vim.deepcopy(args)
  table.insert(arguments, 1, "kitty")
  table.insert(arguments, 2, "@")
  -- local password = vim.g.smart_splits_kitty_password or require("smart-splits.config").kitty_password or ""
  -- if #password > 0 then
  --   table.insert(arguments, 3, "--password")
  --   table.insert(arguments, 4, password)
  -- end
  return vim.system(arguments)
end

local function run_in_system_terminal(cmd)
  local ok, _ = pcall(kitty_exec, { "kitten", "run_command_in_window.py", cmd })
end

vim.api.nvim_create_user_command("Run", function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.g.runprg:gsub("%$%*", params.args)
  if num_subs == 0 then
    cmd = cmd .. " " .. params.args
  end
  run_in_system_terminal(cmd)
end, {
  desc = "Run runprg asynchronously in your computers terminal emulator",
  nargs = "*",
  bang = true,
})

-- See here: https://github.com/neovim/neovim/pull/13896
local function region_to_text(region)
  local text = ""
  local maxcol = vim.v.maxcol
  for line, cols in vim.spairs(region) do
    local endcol = cols[2] == maxcol and -1 or cols[2]
    local chunk = vim.api.nvim_buf_get_text(0, line, cols[1], line, endcol, {})[1]
    text = ("%s%s\n"):format(text, chunk)
  end
  return text
end

local function run_in_integrated_terminal(cmd)
  Snacks.terminal.get(cmd, {
    shell = vim.o.shell,
    win = {
      position = "bottom",
      height = 0.3,
      width = 0.4,
    },
    -- interactive = true,
    auto_insert = false,
    start_insert = false,
    auto_close = false,
  })
end

vim.api.nvim_create_user_command("IntegratedTerminalRun", function(params)
  local cmd = params.args
  run_in_integrated_terminal(cmd)
end, {
  desc = "Run a terminal command asynchronously in your integrated terminal emulator",
  nargs = "*",
  bang = true,
})
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

-- -- Make sure we RE-enter terminal mode when focusing back on terminal
vim.api.nvim_create_autocmd({ "BufEnter", "TermOpen" }, {
  callback = function()
    vim.cmd("startinsert")
  end,
  pattern = { "term://*" },
  group = vim.api.nvim_create_augroup("TermGroup", { clear = true }),
})

vim.api.nvim_create_autocmd("FileType", {
  --- TODO: Problably should be moved into an ftpluin
  pattern = { "python" },
  callback = function(ev)
    vim.api.nvim_buf_set_keymap(
      ev.buf,
      "n",
      "<localleader>s",
      "<Cmd>IntegratedTerminalRun python3 " .. ev.file .. "<CR>",
      { desc = "Source lua file" }
    )
    --- NOTE: :lua also works I believe and works in any buffer.
    --- But since this is buffer local, just use the original
    vim.keymap.set("v", "<localleader>s", function()
      -- local r = vim.region(ev.buf, "'<", "'>", vim.fn.visualmode(), true)
      -- local cmd = {}
      -- cmd[#cmd + 1] = vim.o.shell
      -- cmd[#cmd + 1] = "-c"
      -- cmd[#cmd + 1] = "python3"
      -- --cmd[#cmd + 1] = "<<"
      -- --cmd[#cmd + 1] = "EOF"
      -- cmd[#cmd + 1] = region_to_text(r)
      -- cmd[#cmd + 1] = "EOF"
      -- cmd[#cmd + 1] = "\\n"
      -- run_in_integrated_terminal(cmd)
    end, { desc = "Run visually selected code", buffer = ev.buf })
  end,
})
