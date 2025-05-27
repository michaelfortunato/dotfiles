local M = {}

-- State tracking
M.state = {
  last_used_global_system_terminal_id = nil,
  global_system_terminal_command = nil,
  global_integrated_terminal_command = nil,
  global_integrated_terminal_id = nil,
}

-- Kitty integration
function M.kitty_exec(args)
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

-- Get kitty layout
local function get_kitty_layout()
  local _, value = pcall(function()
    local sc, output = M.kitty_exec({ "ls", "--self" })
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

-- Helper functions
function M.does_system_terminal_exist(id)
  local sc, _ = M.kitty_exec({ "ls", "--match=id:" .. id })
  return sc
end

function M.does_integrated_terminal_exist(id)
  local valid_terms = vim.tbl_filter(function(item)
    return item.buf == id
  end, Snacks.terminal.list())
  return #valid_terms > 0
end
-- System terminal functions
function M.new_system_terminal(cmd, direction)
  local sc, value
  local layout = get_kitty_layout()
  if layout == "stack" then
    sc, value = M.kitty_exec({ "goto-layout", "fat" })
    if not sc then
      vim.notify(value, vim.log.levels.ERROR)
    end
  end

  direction = direction or "down"
  if direction == "up" or direction == "down" then
    sc, value = M.kitty_exec({ "launch", "--keep-focus", "--cwd=current", "--location=hsplit", "--bias=30", cmd })
  else
    sc, value = M.kitty_exec({ "launch", "--keep-focus", "--cwd=current", "--location=vsplit", "--bias=30", cmd })
  end

  if direction == "up" or direction == "left" then
    local move_sc, error_msg = M.kitty_exec({ "action", "move_window", direction })
    if not move_sc then
      vim.notify(error_msg, vim.log.levels.ERROR)
      return move_sc, error_msg
    end
  end

  if not sc then
    vim.notify(value, vim.log.levels.ERROR)
  end
  return sc, value
end

function M.run_system_terminal(id, cmd)
  local sc, value
  sc, value = M.kitty_exec({ "send-text", "--match=id:" .. id, "--exclude-active", cmd })
  if not sc then
    vim.notify(value, vim.log.levels.ERROR)
    return sc, value
  end
  sc, value = M.kitty_exec({ "send-key", "--match=id:" .. id, "--exclude-active", "enter" })
  if not sc then
    vim.notify(value, vim.log.levels.ERROR)
    return sc, value
  end
  return sc, value
end

function M.close_system_terminal(id)
  return M.kitty_exec({ "close-window", "--match=id:" .. id })
end

-- Integrated terminal functions
function M.new_integrated_terminal(cmd)
  local window, created = Snacks.terminal.get(cmd, {
    create = true,
    shell = vim.o.shell,
    win = {
      position = "float",
      height = 0.3,
      width = 0.4,
    },
    auto_insert = false,
    start_insert = false,
    auto_close = false,
  })
  if window ~= nil and window.buf ~= nil then
    return true, window.buf
  else
    return false, "new_integrated_terminal error!"
  end
end

function M.run_integrated_terminal(buf_id, cmd)
  local channel_id = vim.api.nvim_get_option_value("channel", { buf = buf_id })
  vim.api.nvim_chan_send(channel_id, cmd .. "\n")
  return true, nil
end

-- Setters and getters
function M.set_global_system_terminal_command(cmd)
  M.state.global_system_terminal_command = cmd
end

function M.get_global_system_terminal_command()
  return M.state.global_system_terminal_command
end

function M.set_global_system_terminal_id(id)
  M.state.last_used_global_system_terminal_id = id
  return id
end

function M.get_global_system_terminal_id()
  return M.state.last_used_global_system_terminal_id
end

function M.set_global_integrated_terminal_command(cmd)
  M.state.global_integrated_terminal_command = cmd
end

function M.get_global_integrated_terminal_command()
  return vim.fn.expandcmd(M.state.global_integrated_terminal_command or "")
end

function M.set_global_integrated_terminal_id(id)
  M.state.global_integrated_terminal_id = id
end

function M.get_global_integrated_terminal_id()
  return M.state.global_integrated_terminal_id
end

-- High-level terminal functions (moved from autocmds)
function M.run_global_system_terminal()
  local cmd = M.get_global_system_terminal_command()
  cmd = vim.fn.expandcmd(cmd)

  if M.state.last_used_global_system_terminal_id ~= nil then
    if not M.does_system_terminal_exist(M.state.last_used_global_system_terminal_id) then
      local sc, id = M.new_system_terminal(nil, "down")
      if not sc then
        vim.notify(id, vim.log.levels.ERROR)
        return sc, id
      end
      M.state.last_used_global_system_terminal_id = id
    end
  else
    local sc, id = M.new_system_terminal(nil, "down")
    if not sc then
      vim.notify(id, vim.log.levels.ERROR)
      return sc, id
    end
    M.state.last_used_global_system_terminal_id = id
  end

  if cmd == nil or cmd == "v:null" then
    return true, nil
  end

  local run_sc, error = M.run_system_terminal(M.state.last_used_global_system_terminal_id, cmd)
  if not run_sc then
    vim.notify(error, vim.log.levels.ERROR)
    return run_sc
  end
  return true, nil
end

function M.close_global_system_terminal()
  local id = M.state.last_used_global_system_terminal_id
  if id ~= nil then
    M.close_system_terminal(id)
  end
  M.state.last_used_global_system_terminal_id = nil
end

function M.new_global_system_terminal()
  M.close_global_system_terminal()
  M.run_global_system_terminal()
end

function M.run_global_integrated_terminal()
  local cmd = M.get_global_integrated_terminal_command()
  cmd = vim.fn.expandcmd(cmd)

  if M.get_global_integrated_terminal_id() ~= nil then
    if not M.does_integrated_terminal_exist(M.get_global_integrated_terminal_id()) then
      local sc, id = M.new_integrated_terminal(nil)
      if not sc then
        vim.notify(id, vim.log.levels.ERROR)
        return sc, id
      end
      M.set_global_integrated_terminal_id(id)
    else
      M.show_global_integrated_terminal()
    end
  else
    local sc, id = M.new_integrated_terminal(nil)
    if not sc then
      vim.notify(id, vim.log.levels.ERROR)
      return sc, id
    end
    M.set_global_integrated_terminal_id(id)
  end

  if cmd == nil or cmd == "v:null" then
    return true, nil
  end

  local run_sc, error = M.run_integrated_terminal(M.get_global_integrated_terminal_id(), cmd)
  if not run_sc then
    vim.notify(error, vim.log.levels.ERROR)
    return run_sc
  end
  return true, nil
end

function M.show_global_integrated_terminal()
  if
    M.get_global_integrated_terminal_id() ~= nil
    and M.does_integrated_terminal_exist(M.get_global_integrated_terminal_id())
  then
    local infos = vim.fn.getbufinfo(M.get_global_integrated_terminal_id())
    if infos[1].hidden == 1 then
      Snacks.win.new({
        buf = M.get_global_integrated_terminal_id(),
        position = "bottom",
        height = 0.3,
        width = 0.4,
      })
    end
  end
end

function M.close_global_integrated_terminal()
  if
    M.get_global_integrated_terminal_id() ~= nil
    and M.does_integrated_terminal_exist(M.get_global_integrated_terminal_id())
  then
    vim.api.nvim_buf_delete(M.get_global_integrated_terminal_id(), { force = true })
  end
  M.set_global_integrated_terminal_id(nil)
end

-- Helper function for visual selection
function M.get_visual_selection_text()
  local _, srow, scol = unpack(vim.fn.getpos("v"))
  local _, erow, ecol = unpack(vim.fn.getpos("."))

  if vim.fn.mode() == "V" then
    if srow > erow then
      return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
    else
      return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
    end
  elseif vim.fn.mode() == "v" then
    if srow < erow or (srow == erow and scol <= ecol) then
      return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    else
      return vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
    end
  elseif vim.fn.mode() == "\22" then
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

-- Setup functions for plugin-like behavior
function M.setup_commands()
  vim.api.nvim_create_user_command("RunGlobalSystemTerminal", function()
    M.close_global_system_terminal()
    M.run_global_system_terminal()
  end, {
    desc = "Run command in globally dedicated system terminal",
  })

  vim.api.nvim_create_user_command("NewGlobalSystemTerminal", function()
    M.new_global_system_terminal()
  end, {
    desc = "Create new global system terminal",
  })

  vim.api.nvim_create_user_command("CloseGlobalSystemTerminal", function()
    M.close_global_system_terminal()
  end, {
    desc = "Close global system terminal",
  })

  vim.api.nvim_create_user_command("RunGlobalIntegratedTerminal", function()
    M.run_global_integrated_terminal()
  end, {
    desc = "Run command in global integrated terminal",
  })

  vim.api.nvim_create_user_command("CloseGlobalIntegratedTerminal", function()
    M.close_global_integrated_terminal()
  end, {
    desc = "Close global integrated terminal",
  })
end

function M.setup_keymaps()
  local ui_input = Snacks.input or vim.ui.input

  -- System terminal keymaps
  vim.keymap.set("n", ";;", function()
    M.run_global_system_terminal()
  end, { desc = "Run command in globally dedicated system terminal" })

  vim.keymap.set("n", ";c", function()
    ui_input({ prompt = "Set global system terminal command: " }, function(input)
      if input and input ~= "" then
        M.set_global_system_terminal_command(input)
        vim.notify("Set command: " .. input)
      else
        local current = M.get_global_system_terminal_command()
        if current then
          vim.notify("Current command: " .. current)
        else
          vim.notify("No command set")
        end
      end
    end)
  end, { desc = "Set/view global system terminal command" })

  -- Integrated terminal keymaps
  vim.keymap.set("n", ",,", function()
    M.run_global_integrated_terminal()
  end, { desc = "Run command in global integrated terminal" })

  vim.keymap.set("n", ",c", function()
    ui_input({ prompt = "Set global integrated terminal command: " }, function(input)
      if input and input ~= "" then
        M.set_global_integrated_terminal_command(input)
        vim.notify("Set command: " .. input)
      else
        local current = M.get_global_integrated_terminal_command()
        if current then
          vim.notify("Current command: " .. current)
        else
          vim.notify("No command set")
        end
      end
    end)
  end, { desc = "Set/view global integrated terminal command" })

  -- Main toggle
  -- vim.keymap.set("n", "<C-\\>", function()
  --   M.run_global_integrated_terminal()
  -- end, { desc = "Toggle integrated terminal" })

  -- vim.keymap.set("t", "<C-\\>", "<cmd>close<cr>", { desc = "Hide terminal" })
end

function M.setup_autocmds()
  -- File-type specific setup
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "python" },
    callback = function(ev)
      vim.keymap.set("n", "..", function()
        M.set_global_integrated_terminal_command("python3 " .. ev.file)
        M.run_global_integrated_terminal()
      end, { buffer = ev.buf, desc = "Run Python file" })

      -- Visual selection execution
      vim.keymap.set("v", "..", function()
        local lines = M.get_visual_selection_text()
        if lines then
          -- Ensure we have a python terminal
          local sc, id = M.new_integrated_terminal("python3")
          if sc then
            M.run_integrated_terminal(id, table.concat(lines, "\n"))
          end
        end
      end, { buffer = ev.buf, desc = "Run selected Python code" })
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua" },
    callback = function(ev)
      vim.keymap.set("n", "..", "<Cmd>source %<CR>", { buffer = ev.buf, desc = "Source Lua file" })
    end,
  })
end

function M.setup(opts)
  opts = opts or {}

  -- You can add configuration options here if you want
  -- For example:
  -- if opts.default_system_command then
  --   M.set_global_system_terminal_command(opts.default_system_command)
  -- end
  -- if opts.default_integrated_command then
  --   M.set_global_integrated_terminal_command(opts.default_integrated_command)
  -- end

  -- Setup all functionality
  -- M.setup_commands()
  -- M.setup_keymaps()
  -- M.setup_autocmds()

  -- vim.notify("MNF Terminal plugin loaded", vim.log.levels.INFO)
end

return M
