---@class ManagedTerminal
local M = {}
---@type fun(opts: table, on_confirm: fun(input: string?)): nil
M.input = Snacks.input.input or vim.ui.input
---@type fun(msg: string, level?: integer, opts?: table): nil
M.notify = Snacks.notify.notify or vim.ui.notify
-- Base layout creators
---@param buf integer
---@param title string
---@return integer
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

---@param buf integer
---@param title string
---@return integer
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

---@param buf integer
---@param title string
---@return integer
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
---@param serialized_config table
---@return fun(buf: integer, title: string): integer
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

---@return nil
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
---@type table<string, fun(buf: integer, title: string): integer>
M.layout_functions = {
  floating = create_floating_window,
  split = create_split_window,
  vsplit = create_vsplit_window,
  -- You can add cross-references like this:
  -- bottom = function(...) return M.layout_functions.split(...) end,
}

-- Terminal state
---@class TerminalState
---@field win integer?
---@field buffers table<integer, {buf: integer, safe_to_send_text: boolean}>
---@field current integer?
---@field layout string
---@field create_window fun(buf: integer, title: string): integer
---@field last_used_terminal integer
---@field commands table<integer, string>
M.terminal_state = {
  win = nil,
  buffers = {},
  current = nil,
  layout = "vsplit",
  create_window = create_vsplit_window,
  last_used_terminal = 1,
  commands = {},
}

-- Get or create terminal buffer
---@param id integer
---@return integer
local function get_or_create_terminal_buffer(id)
  if not M.terminal_state.buffers[id] or not vim.api.nvim_buf_is_valid(M.terminal_state.buffers[id].buf) then
    local buf = vim.api.nvim_create_buf(false, true)
    M.terminal_state.buffers[id] = { buf = buf, safe_to_send_text = false }

    -- Set buffer options
    vim.bo[buf].buflisted = false
    vim.bo[buf].bufhidden = "wipe"

    -- Create terminal in buffer
    vim.api.nvim_buf_call(buf, function()
      vim.opt_local.spell = false
      vim.cmd("terminal")
    end)
  end
  return M.terminal_state.buffers[id].buf
end

-- Toggle terminal
---@param id integer
---@return nil
function M.toggle_terminal(id)
  M.terminal_state.last_used_terminal = id
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
  vim.api.nvim_set_current_win(M.terminal_state.win)
  -- FIXME: Move this to create_<layout>_window
  vim.cmd("startinsert")
end

-- Toggle layout with smooth transition
-- TODO: Make this cycle layout instead
---@return nil
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
  -- Path 1 if the terminal is closed no need to do anything else but
  -- notify
  if not M.terminal_state.current then
    M.notify("Layout: " .. M.terminal_state.layout)
    return
  end

  local buf = M.terminal_state.buffers[M.terminal_state.current].buf
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
---@return string[]
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

-- Helper function to get entire buffer contents
---@return string[]
local function get_buffer_text()
  return vim.api.nvim_buf_get_lines(0, 0, -1, true)
end

-- Helper function to get current line
---@return string[]
local function get_current_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  return vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, true)
end
---@param text string
---@return string
function M.make_bracketed_paste(text)
  local bracketed_text = "\027[200~" .. text .. "\027[201~\n"
  return bracketed_text
end

---@param id integer
---@param range string
---@return boolean
function M.check_if_safe_to_send_text(id, range)
  if M.terminal_state.buffers[id].safe_to_send_text then
    return true
  end
  local choice = vim.fn.confirm(
    string.format(
      "Send %s to Terminal %d?\n\nWarning: Cannot verify if this is a REPL or shell.\nSending code to shell can be dangerous!",
      range,
      id
    ),
    "&Once\n&Always for Terminal " .. id .. "\n&Cancel",
    3, -- default choice (Cancel)
    "Warning" -- dialog type (can be "Error", "Warning", "Info", "Question")
  )
  if choice == 1 then
    return true
  elseif choice == 2 then
    M.terminal_state.buffers[id].safe_to_send_text = true
    return true
  else
    return false
  end
end

-- TODO: Create a visual mode keymap that sends the selection
-- with any leading indentation removed
-- Send visual selection to terminal
---@param id integer
---@param range? string
---@return nil
function M.send_to_terminal(id, range)
  -- Get visual selection
  range = range or "VISUAL_SELECTION"
  if not M.check_if_safe_to_send_text(id, range) then
    return
  end
  local lines
  if range == "FILE" then
    lines = get_buffer_text()
  elseif range == "LINE" then
    lines = get_current_line()
  else
    lines = get_visual_selection_text()
  end

  -- Join lines and add newline
  local text = table.concat(lines, "\n") .. "\n"
  -- for python 3.13 repl
  -- TODO: Probably want to make this more extensible
  local bracketed_text = M.make_bracketed_paste(text)
  -- Get or create terminal buffer
  M.terminal_write(id, bracketed_text)

  -- Optional: open terminal to see result
  -- if not (M.terminal_state.current == id and M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win)) then
  --   M.toggle_terminal(id)
  -- end
end

---@param id integer
---@param text string
function M.terminal_write(id, text)
  local buf = get_or_create_terminal_buffer(id)

  -- Send text to terminal
  vim.api.nvim_chan_send(vim.bo[buf].channel, text)
  -- Auto-scroll to bottom if terminal window is visible, without changing focus
  if M.terminal_state.win and vim.api.nvim_win_is_valid(M.terminal_state.win) then
    local current_buf = vim.api.nvim_win_get_buf(M.terminal_state.win)
    if current_buf == buf then
      -- Schedule the scroll to happen after the text is processed
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(M.terminal_state.win) then
          -- Scroll to bottom without changing focus or cursor position
          vim.fn.win_execute(M.terminal_state.win, "normal! G")
        end
      end)
    end
  end
end

-- Terminal picker function
---@param callback fun(id: integer): nil
function M.pick_terminal(callback)
  local items = {}
  -- Collect all terminal buffers and their info
  for id, buf in pairs(M.terminal_state.buffers) do
    if vim.api.nvim_buf_is_valid(buf.buf) then
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

---@return integer
function M.get_last_used_terminal()
  return M.terminal_state.last_used_terminal
end

---@param callback fun(): nil
function M.list_commands(callback)
  -- TODO
end

---@param id integer
---@return nil
function M.run_command(id)
  local cmd = M.terminal_state.commands[id]
  if cmd == nil then
    M.set_command(id, function(input)
      input = vim.api.nvim_replace_termcodes(input, true, false, true)
      if input == nil then
        -- echo something
        return
      end
      M.terminal_state.commands[id] = input
      M.terminal_write(id, input .. "\n")
    end)
    return
  end
  M.terminal_write(id, cmd .. "\n")
end

---@param id integer
---@param callback? fun(input: string?): nil
---@return nil
function M.set_command(id, callback)
  local default_cb = function(input)
    input = vim.api.nvim_replace_termcodes(input, true, false, true)
    if input == nil then
      -- echo something
      return
    end
    M.terminal_state.commands[id] = input
  end
  callback = callback or default_cb
  M.input({ prompt = "Set Command For Terminal " .. id }, callback)
end

return M
