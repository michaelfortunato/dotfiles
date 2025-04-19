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

vim.MNF = {}
vim.MNF.last_used_global_system_terminal_id = nil
vim.MNF.global_system_terminal_command = nil

vim.MNF.kitty_exec = function(args)
  local arguments = vim.deepcopy(args)
  table.insert(arguments, 1, "kitty")
  table.insert(arguments, 2, "@")
  local password = vim.g.smart_splits_kitty_password or require("smart-splits.config").kitty_password or ""
  if #password > 0 then
    table.insert(arguments, 3, "--password")
    table.insert(arguments, 4, password)
  end
  local output = vim.fn.system(arguments)
  local sc = (vim.v.shell_error == 0)
  return sc, output
end

local kitty_exec = vim.MNF.kitty_exec

local function does_system_terminal_exist(id)
  local sc, value = kitty_exec({ "ls", "--match=id:" .. id })
  return sc
end

local function _get_kitty_layout()
  local _, value = pcall(function()
    local sc, output = kitty_exec({ "ls", "--self" })
    if not sc then
      vim.notify(output, vim.log.levels.ERROR)
      return nil
    end
    local json = vim.json.decode(output)
    if #json ~= 1 or #json[1]["tabs"] ~= 1 then
      vim.notify("More than two tabs detected, not getting layout", vim.log.levels.WARN)
      return nil
    end
    return json[1]["tabs"][1]["layout"]
  end)
  return value
end

--- TODO: cmd must be string for now change it later
--- TODO: remove --bias and figure out how to merge cmd with other options
--- in table
--- NOTE: Consider switching to a fat layout before so the split shows up even if in a stack layout
--- otherwise it'll look like nothing has happend (due to --keep-focus)
vim.MNF.new_system_terminal = function(cmd, direction)
  local sc, value
  local layout = _get_kitty_layout()
  if layout == "stack" then
    sc, value = kitty_exec({ "goto-layout", "fat" })
    if not sc then
      vim.notify(value, vim.log.levels.ERROR)
    end
  end
  direction = direction or "down"
  if direction == "up" or direction == "down" then
    sc, value = kitty_exec({ "launch", "--keep-focus", "--cwd=current", "--location=hsplit", "--bias=30", cmd })
    --- in this case value is the id
  else
    sc, value = kitty_exec({ "launch", "--keep-focus", "--cwd=current", "--location=vsplit", "--bias=30", cmd })
    --- in this case value is the id
  end
  if direction == "up" or direction == "left" then
    local move_sc, error_msg = kitty_exec({ "action", "move_window", direction })
    if not move_sc then
      vim.notify(error_msg, vim.log.levels.ERROR)
      return move_sc, error_msg
    end
  end
  if not sc then
    vim.notify(value, vim.log.levels.ERROR)
  end
  --- in this case value is the id
  return sc, value
end

local new_system_terminal = vim.MNF.new_system_terminal

--- TODO: cmd must be string for now change it later
--- NOTE: this is inherently asynchronous in a sense as we are writing to the process,
--- not waiting to it to finish, it is up to the shell to execute the code, safer this way as well
vim.MNF.run_system_terminal = function(id, cmd)
  local sc, value
  sc, value = kitty_exec({ "send-text", "--match=id:" .. id, "--exclude-active", cmd })
  if not sc then
    vim.notify(value, vim.log.levels.ERROR)
    return sc, value
  end
  sc, value = kitty_exec({ "send-key", "--match=id:" .. id, "--exclude-active", "enter" })
  if not sc then
    vim.notify(value, vim.log.levels.ERROR)
    return sc, value
  end
  return sc, value
end
local run_system_terminal = vim.MNF.run_system_terminal

vim.MNF.close_system_terminal = function(id)
  return kitty_exec({ "close-window", "--match=id:" .. id })
end
local close_system_terminal = vim.MNF.close_system_terminal

--- Integrated terminal API, should match what is above
---
vim.MNF.new_integrated_terminal = function(cmd)
  local window, created = Snacks.terminal.get(cmd, {
    create = true,
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
  if window ~= nil and window.buf ~= nil then
    return true, window.buf
  else
    return false, "new_intergrated_terminal error I do not know why!"
  end
end
local new_integrated_terminal = vim.MNF.new_integrated_terminal

vim.MNF.run_integrated_terminal = function(buf_id, cmd)
  local channel_id = vim.api.nvim_get_option_value("channel", { buf = buf_id })
  vim.api.nvim_chan_send(channel_id, cmd .. "\n")
  return true, nil
  -- TODO: return a status code and error text if any
end

vim.MNF.close_integrated_terminal = function(buf_id, cmd)
  -- TODO: IMPLEMENT ME
  print("NOT IMPLEMENTED")
end

--- 2. User APIs, a combination of
--- <globally/buffer managerd> and <system/integrated>
--- So 4 variants

--- 2.1 Terminal Manager , global variant + system
--- TODO: Ideally we want this manager to be agostic to whether
--- the underlying terminal is a system one or not.
--- global plugin downstream of this functionality
--- This is just a small module for managing the window
vim.MNF.set_global_system_terminal_command = function(cmd)
  vim.MNF.global_system_terminal_command = cmd
end

vim.MNF.get_global_system_terminal_command = function()
  return vim.MNF.global_system_terminal_command
end

vim.MNF.set_global_system_terminal_id = function(id)
  vim.MNF.last_used_global_system_terminal_id = id
  return id
end

vim.MNF.get_global_system_terminal_id = function()
  return vim.MNF.last_used_global_system_terminal_id
end

vim.MNF.set_global_integrated_terminal_command = function(cmd)
  vim.MNF.global_integrated_terminal_command = cmd
end

vim.MNF.get_global_integrated_terminal_command = function()
  local cmd = vim.fn.expandcmd(vim.MNF.global_integrated_terminal_command)
  return cmd
end

vim.MNF.set_global_integrated_terminal_id = function(id)
  vim.MNF.global_integrated_terminal_id = id
end

vim.MNF.get_global_integrated_terminal_id = function()
  return vim.MNF.global_integrated_terminal_id
end

--- NOTE, we launch a posix like shell around the command here so things like
--- bash command liens can be used
vim.MNF.run_global_system_terminal = function()
  local cmd = vim.MNF.get_global_system_terminal_command()
  cmd = vim.fn.expandcmd(cmd)
  if vim.MNF.last_used_global_system_terminal_id ~= nil then
    if not does_system_terminal_exist(vim.MNF.last_used_global_system_terminal_id) then
      local sc, id = new_system_terminal(nil, "down")
      if not sc then
        vim.notify(id, vim.log.levels.ERROR)
        return sc, id
      end
      vim.MNF.last_used_global_system_terminal_id = id
    end
  else
    local sc, id = new_system_terminal(nil, "down")
    if not sc then
      vim.notify(id, vim.log.levels.ERROR)
      return sc, id
    end
    vim.MNF.last_used_global_system_terminal_id = id
  end
  if cmd == nil or cmd == "v:null" then -- We launched the shell, so no need to error
    return true, nil
  end
  local run_sc, error = run_system_terminal(vim.MNF.last_used_global_system_terminal_id, cmd)
  if not run_sc then
    vim.notify(error, vim.log.levels.ERROR)
    return run_sc
  end
  return true, nil
end

local run_global_system_terminal = vim.MNF.run_global_system_terminal

vim.MNF.close_global_system_terminal = function()
  local id = vim.MNF.last_used_global_system_terminal_id
  if id ~= nil then
    close_system_terminal(id)
  end
  vim.MNF.last_used_global_system_terminal_id = nil
end

local close_global_system_terminal = vim.MNF.close_global_system_terminal

vim.MNF.new_global_system_terminal = function()
  close_global_system_terminal()
  vim.MNF.run_global_system_terminal()
end
local new_global_system_terminal = vim.MNF.new_global_system_terminal

--- 2.2 Manager, buffer local + integrated variant
--- TODO: Ideally we want this manager to be agostic to whether
--- the underlying terminal is a system one or not.

function vim.MNF.does_integrated_terminal_exist(id)
  local valid_terms = vim.tbl_filter(function(item)
    return item.buf == id
  end, Snacks.terminal.list())
  return #valid_terms > 0
end
local does_integrated_terminal_exist = vim.MNF.does_integrated_terminal_exist

--- 2.2.3 buffer global integrated

vim.MNF.run_global_integrated_terminal = function()
  local cmd = vim.MNF.get_global_integrated_terminal_command()
  cmd = vim.fn.expandcmd(cmd)
  if vim.MNF.get_global_integrated_terminal_id() ~= nil then
    if not vim.MNF.does_integrated_terminal_exist(vim.MNF.get_global_integrated_terminal_id()) then
      local sc, id = new_integrated_terminal(nil)
      if not sc then
        vim.notify(id, vim.log.levels.ERROR)
        return sc, id
      end
      vim.MNF.set_global_integrated_terminal_id(id)
    else
      vim.MNF.show_global_integrated_terminal()
    end
  else
    local sc, id = new_integrated_terminal(nil)
    if not sc then
      vim.notify(id, vim.log.levels.ERROR)
      return sc, id
    end
    vim.MNF.set_global_integrated_terminal_id(id)
  end
  if cmd == nil or cmd == "v:null" then -- We launched the shell, so no need to error
    -- we need to figure out how to toggle the view here though
    return true, nil
  end
  local run_sc, error = vim.MNF.run_integrated_terminal(vim.MNF.get_global_integrated_terminal_id(), cmd)
  if not run_sc then
    vim.notify(error, vim.log.levels.ERROR)
    return run_sc
  end
  return true, nil
end

vim.MNF.show_global_integrated_terminal = function()
  if
    vim.MNF.get_global_integrated_terminal_id() ~= nil
    and vim.MNF.does_integrated_terminal_exist(vim.MNF.get_global_integrated_terminal_id())
  then
    local infos = vim.fn.getbufinfo(vim.MNF.get_global_integrated_terminal_id())
    if infos[1].hidden == 1 then
      Snacks.win.new({
        buf = vim.MNF.get_global_integrated_terminal_id(),
        position = "bottom",
        height = 0.3,
        width = 0.4,
      })
    else
    end
  end
end

local run_global_integrated_terminal = vim.MNF.run_global_integrated_terminal

vim.MNF.close_global_integrated_terminal = function()
  if
    vim.MNF.get_global_integrated_terminal_id() ~= nil
    and does_integrated_terminal_exist(vim.MNF.get_global_integrated_terminal_id())
  then
    vim.notify(vim.MNF.get_global_integrated_terminal_id())
    vim.api.nvim_buf_delete(vim.MNF.get_global_integrated_terminal_id(), { force = true })
  else
    vim.notify(vim.MNF.get_global_integrated_terminal_id())
    vim.notify(does_integrated_terminal_exist(vim.MNF.get_global_integrated_terminal_id()))
  end
  vim.MNF.set_global_integrated_terminal_id(nil)
end
local close_global_integrated_terminal = vim.MNF.close_global_integrated_terminal

--- 2.3 Command wrappers of downstream

vim.api.nvim_create_user_command("RunGlobalSystemTerminal", function(params)
  close_global_system_terminal()
  run_global_system_terminal()
end, {
  desc = "Run `vim.MNF.global_system_terminal_command` asynchronously in your computer's new or existing terminal emulator",
  nargs = "*",
  bang = true,
})

vim.api.nvim_create_user_command("NewGlobalSystemTerminal", function(params)
  new_global_system_terminal()
end, {
  desc = "Run `vim.MNF.global_system_terminal_command` asynchronously in your computer's new terminal emulator",
  nargs = "*",
  bang = true,
})

vim.api.nvim_create_user_command("CloseGlobalSystemTerminal", function(params)
  close_global_system_terminal()
end, {
  desc = "Run `vim.MNF.global_system_terminal_command` asynchronously in your computer's new terminal emulator",
})

vim.api.nvim_create_user_command("RunLocalIntegratedTerminal", function(params)
  local cmd = vim.fn.expandcmd(params.args)
  -- run_local_integrated_terminal(cmd)
end, {
  desc = "Run a terminal command asynchronously in your integrated terminal emulator",
  nargs = "*",
  bang = true,
})

vim.api.nvim_create_user_command("RunGlobalIntegratedTerminal", function(params)
  run_global_integrated_terminal()
end, {
  desc = "Run a terminal command asynchronously in your integrated terminal emulator",
  nargs = "*",
  bang = true,
})

vim.api.nvim_create_user_command("CloseGlobalIntegratedTerminal", function(params)
  close_global_integrated_terminal()
end, {
  desc = "Run `vim.MNF.global_system_terminal_command` asynchronously in your computer's new terminal emulator",
})

-- Return the visually selected text as an array with an entry for each line
--- @see https://www.reddit.com/r/neovim/comments/1b1sv3a/function_to_get_visually_selected_text/--
--- @return string[]|nil lines The selected text as an array of lines.
local function get_visual_selection_text()
  local _, srow, scol = unpack(vim.fn.getpos("v"))
  local _, erow, ecol = unpack(vim.fn.getpos("."))

  -- visual line mode
  if vim.fn.mode() == "V" then
    if srow > erow then
      return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
    else
      return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
    end
  end

  -- regular visual mode
  if vim.fn.mode() == "v" then
    if srow < erow or (srow == erow and scol <= ecol) then
      return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    else
      return vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
    end
  end

  -- visual block mode
  if vim.fn.mode() == "\22" then
    local lines = {}
    if srow > erow then
      srow, erow = erow, srow
    end
    if scol > ecol then
      scol, ecol = ecol, scol
    end
    for i = srow, erow do
      table.insert(
        lines,
        vim.api.nvim_buf_get_text(0, i - 1, math.min(scol - 1, ecol), i - 1, math.max(scol - 1, ecol), {})[1]
      )
    end
    return lines
  end
end

--- ALL CUSTOM FILE TYPE autocommands here
vim.api.nvim_create_autocmd("FileType", {
  --- TODO: Problably should be moved into an ftpluin
  pattern = { "lua" },
  callback = function(ev)
    vim.api.nvim_buf_set_keymap(ev.buf, "n", "<localleader>s", "<Cmd>source %<CR>", { desc = "Source lua file" })
    --- FIXME: There is some error where input flashes quickly, this
    --- doesn't work
    vim.api.nvim_buf_set_keymap(
      ev.buf,
      "v",
      "<localleader>s",
      "<Cmd>source<CR>",
      { desc = "Run visually selected code" }
    )
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  --- TODO: Problably should be moved into an ftpluin
  pattern = { "python" },
  callback = function(ev)
    --- NOTE: :lua also works I believe and works in any buffer.
    --- But since this is buffer local, just use the original
    vim.api.nvim_buf_set_keymap(
      ev.buf,
      "n",
      "..",
      "<Cmd>RunLocalIntegratedTerminal python3 " .. ev.file .. "<CR>",
      { desc = "Source lua file" }
    )
    -- FIXME: This is close but not right. I am getting more convinced
    -- to use my system emulator for anew window? I do not know for sure.
    vim.keymap.set("v", "..", function()
      local window = __DEPRECATED_run_in_local_integrated_terminal("python3")
      local lines = get_visual_selection_text()
      if lines == nil then
        return
      end
      vim.api.nvim_chan_send(window.buf, table.concat(lines, "\r\n"))
      vim.api.nvim_chan_send(window.buf, "\r\n") -- NOTE: Send a last one in case we are on a single line
    end, { desc = "Run visually selected code", buffer = ev.buf })
  end,
})

-- -- Make sure we RE-enter terminal mode when focusing back on terminal
vim.api.nvim_create_autocmd({ "BufEnter", "TermOpen" }, {
  callback = function()
    vim.cmd("startinsert")
  end,
  pattern = { "term://*" },
  group = vim.api.nvim_create_augroup("TermGroup", { clear = true }),
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typst" },
  callback = function()
    vim.keymap.set("n", "<localleader>p", function()
      ---@diagnostic disable-next-line: deprecated
      vim.lsp.buf.execute_command({ command = "tinymist.pinMain", arguments = { vim.api.nvim_buf_get_name(0) } })
      -- -- unpin the main file
      -- ---@diagnostic disable-next-line: deprecated
      -- vim.lsp.buf.execute_command({ command = "tinymist.pinMain", arguments = { nil } })
    end, { desc = "Pin Typst file for LSP", buffer = true })
    -- pin the main file
  end,
})
