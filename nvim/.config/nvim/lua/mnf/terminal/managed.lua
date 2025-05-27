local M = {}
-- Terminal state
M.terminal_state = {
  win = nil,
  buffers = {},
  current = nil,
}

-- Get or create terminal buffer
local function get_or_create_terminal_buffer(id)
  if not M.terminal_state.buffers[id] or not vim.api.nvim_buf_is_valid(M.terminal_state.buffers[id]) then
    local buf = vim.api.nvim_create_buf(false, true)
    M.terminal_state.buffers[id] = buf

    -- Set buffer options
    vim.bo[buf].buflisted = false
    vim.bo[buf].bufhidden = "wipe"

    -- Create terminal in buffer
    vim.api.nvim_buf_call(buf, function()
      vim.cmd("terminal")
    end)
  end
  return M.terminal_state.buffers[id]
end

-- Check if current window is floating
local function is_floating()
  if not M.terminal_state.win or not vim.api.nvim_win_is_valid(M.terminal_state.win) then
    -- vim.print(terminal_state)
    -- vim.notify("HUH??????:")
    return true -- default to floating
  end

  local win_config = vim.api.nvim_win_get_config(M.terminal_state.win)
  return win_config.relative ~= ""
end

-- Create floating window with Snacks-like styling
local function create_floating_window(buf, title)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = {
      { "╭", "FloatBorder" },
      { "─", "FloatBorder" },
      { "╮", "FloatBorder" },
      { "│", "FloatBorder" },
      { "╯", "FloatBorder" },
      { "─", "FloatBorder" },
      { "╰", "FloatBorder" },
      { "│", "FloatBorder" },
    },
    title = { { " Terminal " .. title .. " ", "TerminalTitle" } },
    title_pos = "center",
    noautocmd = true,
  })

  -- Set window options for better experience
  vim.wo[win].winhighlight = "Normal:FLoatBoarder,FloatBorder:FloatBorder"
  vim.wo[win].winblend = 0
  vim.wo[win].wrap = false
  vim.wo[win].sidescrolloff = 0
  vim.wo[win].scrolloff = 0

  return win
end

-- Create horizontal split window with Snacks-like styling
local function create_horizontal_window(buf)
  local height = math.floor(vim.o.lines * 0.3)
  vim.cmd("botright " .. height .. "split")
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_buf(win, buf)

  -- Set window options
  vim.wo[win].winhighlight = "Normal:Normal"
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].colorcolumn = ""

  return win
end

-- Toggle terminal
function M.toggle_terminal(id)
  -- If same terminal is open, close it
  if M.terminal_state.current == id and M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win) then
    vim.api.nvim_win_close(M.terminal_state.win, false)
    -- terminal_state.current = nil
    -- terminal_state.win = nil
    return
  end

  local buf = get_or_create_terminal_buffer(id)
  local was_floating = is_floating()
  -- vim.notify(was_floating)

  -- Reuse existing window if it's valid and same layout type
  if M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win) then
    vim.api.nvim_win_set_buf(M.terminal_state.win, buf)
    vim.api.nvim_set_current_win(M.terminal_state.win)

    -- Update title for floating windows
    if was_floating then
      vim.api.nvim_win_set_config(M.terminal_state.win, {
        title = { { " Terminal " .. id .. " ", "TerminalTitle" } },
      })
    end
  else
    -- Create new window
    if was_floating then
      M.terminal_state.win = create_floating_window(buf, id)
    else
      M.terminal_state.win = create_horizontal_window(buf)
    end
  end

  M.terminal_state.current = id
  vim.cmd("startinsert")
end

-- Toggle layout with smooth transition
function M.toggle_layout()
  if not M.terminal_state.current then
    return
  end

  local buf = M.terminal_state.buffers[M.terminal_state.current]
  local was_floating = is_floating()

  -- Close current window
  if M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win) then
    vim.api.nvim_win_close(M.terminal_state.win, false)
  end

  -- Create new window in opposite layout
  if was_floating then
    M.terminal_state.win = create_horizontal_window(buf)
    vim.notify("Terminal: horizontal", vim.log.levels.INFO, { title = "Layout" })
  else
    M.terminal_state.win = create_floating_window(buf, M.terminal_state.current or "IDK")
    vim.notify("Terminal: floating", vim.log.levels.INFO, { title = "Layout" })
  end

  vim.cmd("startinsert")
end

return M
