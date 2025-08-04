-- External Kitty Terminal Management
-- IMPORTANT: Kitty terminals are COMPLETELY SEPARATE from neovim buffers/windows
-- They exist as external OS windows managed by kitty, not neovim

---@class KittyTerminal
local M = {}

-- Execute kitty command with proper authentication
---@param args string[]
---@return boolean success, string output_or_error
function M.kitty_exec(args)
  local arguments = vim.deepcopy(args)
  table.insert(arguments, 1, "kitten")
  table.insert(arguments, 2, "@")

  local password = vim.g.smart_splits_kitty_password or require("smart-splits.config").kitty_password or ""
  if #password > 0 then
    table.insert(arguments, 3, "--password")
    table.insert(arguments, 4, password)
  end

  local output = vim.fn.system(arguments)
  local success = (vim.v.shell_error == 0)
  return success, output
end

-- Get current kitty layout
---@return string? layout
local function get_kitty_layout()
  local success, output = M.kitty_exec({ "ls", "--self" })
  if not success then
    return nil
  end

  local ok, json = pcall(vim.json.decode, output)
  if not ok or #json ~= 1 or #json[1]["tabs"] ~= 1 then
    return nil
  end

  return json[1]["tabs"][1]["layout"]
end

-- Check if external kitty window exists (NO neovim buffer involved)
---@param window_id integer
---@return boolean exists
function M.window_exists(window_id)
  local success, _ = M.kitty_exec({ "ls", "--match=id:" .. window_id })
  return success
end

-- Create new external kitty terminal window (NO neovim buffer created)
---@param cmd? string Command to run in terminal
---@param direction? string "up"|"down"|"left"|"right"
---@return boolean success, integer|string window_id_or_error
function M.create_window(cmd, direction)
  direction = direction or "down"

  -- Handle stack layout
  local layout = get_kitty_layout()
  if layout == "stack" then
    local success, error_msg = M.kitty_exec({ "goto-layout", "fat" })
    if not success then
      return false, error_msg
    end
  end

  -- Launch new window
  local launch_args = { "launch", "--keep-focus", "--cwd=current", "--hold=yes" }

  if direction == "up" or direction == "down" then
    table.insert(launch_args, "--location=hsplit")
    table.insert(launch_args, "--bias=30")
  else
    table.insert(launch_args, "--location=vsplit")
    table.insert(launch_args, "--bias=30")
  end

  if cmd then
    table.insert(launch_args, cmd)
  end

  local success, output = M.kitty_exec(launch_args)
  if not success then
    return false, output
  end

  -- Parse window ID from output (kitty returns integer window ID)
  local window_id = tonumber(output:match("%d+"))
  if not window_id then
    return false, "Could not parse window ID from: " .. output
  end

  -- Move window if needed
  if direction == "up" or direction == "left" then
    local move_success, move_error = M.kitty_exec({ "action", "move_window", direction })
    if not move_success then
      return false, move_error
    end
  end

  return true, window_id
end

-- Send command to external kitty window (NO neovim buffer interaction)
---@param window_id integer
---@param cmd string
---@return boolean success, string? error
function M.send_command(window_id, cmd)
  local success, error_msg = M.kitty_exec({
    "send-text",
    "--match=id:" .. window_id,
    "--exclude-active",
    cmd,
  })
  if not success then
    return false, error_msg
  end

  success, error_msg = M.kitty_exec({
    "send-key",
    "--match=id:" .. window_id,
    "--exclude-active",
    "enter",
  })
  if not success then
    return false, error_msg
  end

  return true, nil
end

-- Send text to external kitty window (NO neovim buffer interaction)
---@param window_id integer
---@param text string
---@return boolean success, string? error
function M.send_text(window_id, text)
  local success, error_msg = M.kitty_exec({
    "send-text",
    "--match=id:" .. window_id,
    "--exclude-active",
    text,
  })
  return success, error_msg
end

-- Close external kitty window (NO neovim buffer cleanup needed)
---@param window_id integer
---@return boolean success, string? error
function M.close_window(window_id)
  return M.kitty_exec({ "close-window", "--match=id:" .. window_id })
end

-- Focus external kitty window (switches OS focus, not neovim)
---@param window_id integer
---@return boolean success, string? error
function M.focus_window(window_id)
  return M.kitty_exec({ "focus-window", "--match=id:" .. window_id })
end

-- Get window title (for status display)
---@param window_id integer
---@return boolean success, string title_or_error
function M.get_window_title(window_id)
  local success, output = M.kitty_exec({
    "ls",
    "--match=id:" .. window_id,
    "--format=json",
  })
  if not success then
    return false, output
  end

  local ok, json = pcall(vim.json.decode, output)
  if not ok or not json[1] or not json[1].tabs or not json[1].tabs[1] or not json[1].tabs[1].windows then
    return false, "Could not parse window info"
  end

  local window = json[1].tabs[1].windows[1]
  return true, window.title or "External Terminal"
end

return M
