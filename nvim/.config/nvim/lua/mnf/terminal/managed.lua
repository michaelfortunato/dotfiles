local M = {}
-- Base layout creators
local function create_floating_window(buf, title)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local config = {
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
    title = { { title, "TerminalTitle" } },
    title_pos = "center",
    noautocmd = true,
  }

  local win = vim.api.nvim_open_win(buf, true, config)

  -- Set floating window options
  vim.wo[win].winhighlight = "Normal:FloatBorder,FloatBorder:FloatBorder"
  vim.wo[win].winblend = 0
  vim.wo[win].wrap = false
  vim.wo[win].sidescrolloff = 0
  vim.wo[win].scrolloff = 0

  return win
end

local function create_vsplit_window(buf, title)
  local config = {
    width = math.floor(vim.o.columns * 0.5),
    split = "right",
  }

  local win = vim.api.nvim_open_win(buf, true, config)

  -- Set split window options (same as horizontal split)
  vim.wo[win].winhighlight = "Normal:Normal"
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].colorcolumn = ""

  return win
end

local function create_split_window(buf, title)
  local config = {
    height = math.floor(vim.o.lines * 0.3),
    split = "below",
  }

  local win = vim.api.nvim_open_win(buf, true, config)

  -- Set split window options
  vim.wo[win].winhighlight = "Normal:Normal"
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].colorcolumn = ""

  return win
end

-- Create a closure that recreates a window with serialized config (splits only)
local function create_serialized_window_function(serialized_config)
  return function(buf, title)
    local config = vim.deepcopy(serialized_config)

    local win = vim.api.nvim_open_win(buf, true, config)

    -- Apply split window options (no need to check config.relative)
    vim.wo[win].winhighlight = "Normal:Normal"
    vim.wo[win].wrap = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].colorcolumn = ""

    return win
  end
end

local function serialize_and_create_closure()
  -- Only serialize for split layouts - floating windows don't need it
  if
    M.terminal_state.layout ~= "floating"
    and M.terminal_state.win
    and vim.api.nvim_win_is_valid(M.terminal_state.win)
  then
    local config = vim.api.nvim_win_get_config(M.terminal_state.win)
    M.terminal_state.create_window = create_serialized_window_function(config)
  else
    M.terminal_state.create_window = create_floating_window
  end
end

-- Layout functions table - elements can refer to other elements
M.layout_functions = {
  floating = create_floating_window,
  split = create_split_window,
  vsplit = create_vsplit_window,
  -- You can add cross-references like this:
  -- bottom = function(...) return M.layout_functions.split(...) end,
}

-- Terminal state
M.terminal_state = {
  win = nil,
  buffers = {},
  current = nil,
  layout = "vsplit",
  create_window = create_vsplit_window,
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
      vim.opt_local.spell = false
      vim.cmd("terminal")
    end)
  end
  return M.terminal_state.buffers[id]
end

-- Toggle terminal
function M.toggle_terminal(id)
  -- If same terminal is open, close it
  if M.terminal_state.current == id and M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win) then
    serialize_and_create_closure()
    vim.api.nvim_win_close(M.terminal_state.win, true)
    M.terminal_state.current = nil
    return
  end

  local buf = get_or_create_terminal_buffer(id)
  -- Reuse existing window if it's valid and same layout type
  if M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win) then
    vim.api.nvim_win_set_buf(M.terminal_state.win, buf)
    -- TODO: WHY?
    -- vim.api.nvim_set_current_win(M.terminal_state.win)
    if M.terminal_state.layout == "floating" then
      vim.api.nvim_win_set_config(M.terminal_state.win, {
        title = { { " Terminal " .. id .. " ", "TerminalTitle" } },
      })
    end
  else
    -- New window
    M.terminal_state.win = M.terminal_state.create_window(buf, " Terminal " .. id .. " ")
  end

  M.terminal_state.current = id
  -- FIXME: Move this to create_<layout>_window
  vim.cmd("startinsert")
end

-- Toggle layout with smooth transition
-- TODO: Make this cycle layout instead
function M.toggle_layout()
  if M.terminal_state.layout == "floating" then
    M.terminal_state.layout = "split"
    --vim.notify("Terminal: horizontal", vim.log.levels.DEBUG, { title = "Layout" })
  elseif M.terminal_state.layout == "split" then
    -- In this case consider serializing the M.layout_functions[bottom] variant!
    -- If you do not want the toggle to destory the prior layout
    M.terminal_state.layout = "vsplit"
    -- vim.notify("Terminal: vertical", vim.log.levels.DEBUG, { title = "Layout" })
  else
    -- In this case consider serializing the M.layout_functions[bottom] variant!
    -- If you do not want the toggle to destory the prior layout
    M.terminal_state.layout = "floating"
    -- vim.notify("Terminal: floating", vim.log.levels.DEBUG, { title = "Layout" })
  end
  M.terminal_state.create_window = M.layout_functions[M.terminal_state.layout]
  -- Path 1 if the terminal is closed no need to do anything else
  if not M.terminal_state.current then
    return
  end

  local buf = M.terminal_state.buffers[M.terminal_state.current]
  -- Path 2 if the terminal is open close the current window and
  -- Close current window
  if M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win) then
    vim.api.nvim_win_close(M.terminal_state.win, false)
  end
  -- Open new one
  M.terminal_state.win = M.terminal_state.create_window(buf, "Terminal " .. M.terminal_state.current .. " ")
  vim.cmd("startinsert")
end

-- Helper function for visual selection
local function get_visual_selection_text()
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

-- Send visual selection to terminal
function M.send_to_terminal(id)
  -- Get visual selection
  local lines = get_visual_selection_text()

  -- Join lines and add newline
  local text = table.concat(lines, "\n") .. "\n"
  -- for python 3.13 repl
  -- TODO: Probably want to make this more extensible
  local bracketed_text = "\027[200~" .. text .. "\027[201~\n"
  -- Get or create terminal buffer
  local buf = get_or_create_terminal_buffer(id)

  -- Send text to terminal
  vim.api.nvim_chan_send(vim.bo[buf].channel, bracketed_text)

  -- Optional: open terminal to see result
  -- if not (M.terminal_state.current == id and M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win)) then
  --   M.toggle_terminal(id)
  -- end
end

-- Terminal picker function
--- @param callback function(int)
function M.pick_terminal(callback)
  local items = {}
  -- Collect all terminal buffers and their info
  for id, buf in pairs(M.terminal_state.buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local last_line = "TODO"
      local is_current = (M.terminal_state.current == id) and "● " or "  "
      local display = string.format("%sTerminal %s: %s", is_current, id, last_line)

      table.insert(items, { display = display, id = id })
    end
  end

  -- If no terminals exist, create a default option
  if #items == 0 then
    items = { { display = "  Terminal 1: New terminal", id = 1 } }
  end

  -- Show picker
  vim.ui.select(items, {
    prompt = "Select Terminal:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      -- Toggle to selected terminal (even if it's current - will just close/reopen)
      -- NOTE: If current terminal is selected, it will close then reopen
      callback(choice.id)
    end
  end)
end

return M
