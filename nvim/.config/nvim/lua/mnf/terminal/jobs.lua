-- Standalone Job Manager - Complete, self-contained module
-- No external dependencies, plug and play

---@class JobInfo
---@field status string
---@field use_terminal boolean
---@field external_terminal boolean
---@field command string
---@field buffer integer -- neovim buffer ID OR kitty window ID
---@field silent boolean
---@field system_job_id integer?
---@field exit_code integer?

---@class JobConfig
---@field command string
---@field use_terminal boolean
---@field external_terminal boolean
---@field silent boolean

---@class JobManager
local M = {}

---@type fun(opts: table, on_confirm: fun(input: string?)): nil
M.input = Snacks.input.input or vim.ui.input

-- Import kitty terminal manager for external terminals
local kitty = require("mnf.terminal.kitty")
-- State
---@class JobState
---@field win integer?
---@field current_job_id integer?
---@field layout string
---@field create_window fun(buf: integer, title: string): integer
---@field jobs table<integer, JobInfo>
M.state = {
  win = nil,
  current_job_id = nil,
  layout = "vsplit",
  create_window = nil,
  jobs = {}, -- job_id -> job_info
}

-- Layout functions
---@type table<string, fun(buf: integer, title: string): integer>
local layout_functions = {
  floating = function(buf, title)
    ---@param buf integer
    ---@param title string
    ---@return integer
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
      title = { { title, "FloatTitle" } },
      title_pos = "center",
      noautocmd = true,
    }

    local win = vim.api.nvim_open_win(buf, true, config)
    vim.wo[win].winhighlight = "Normal:FloatBorder,FloatBorder:FloatBorder"
    vim.wo[win].winblend = 0
    vim.wo[win].wrap = false
    vim.wo[win].sidescrolloff = 0
    vim.wo[win].scrolloff = 0
    return win
  end,

  vsplit = function(buf, title)
    ---@param buf integer
    ---@param title string
    ---@return integer
    local config = {
      width = math.floor(vim.o.columns * 0.5),
      split = "right",
    }
    local win = vim.api.nvim_open_win(buf, true, config)
    vim.wo[win].winhighlight = "Normal:Normal"
    vim.wo[win].wrap = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].colorcolumn = ""
    return win
  end,

  split = function(buf, title)
    ---@param buf integer
    ---@param title string
    ---@return integer
    local config = {
      height = math.floor(vim.o.lines * 0.3),
      split = "below",
    }
    local win = vim.api.nvim_open_win(buf, true, config)
    vim.wo[win].winhighlight = "Normal:Normal"
    vim.wo[win].wrap = false
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].colorcolumn = ""
    return win
  end,
}

M.state.create_window = layout_functions.vsplit

-- Create a closure that recreates a window with serialized config
---@param serialized_config table
---@return fun(buf: integer, title: string): integer
local function create_serialized_window_function(serialized_config)
  return function(buf, title)
    local config = vim.deepcopy(serialized_config)
    local win = vim.api.nvim_open_win(buf, true, config)

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

-- Serialize window config for layout preservation
---@return nil
local function serialize_and_create_closure()
  if M.state.layout ~= "floating" and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    local config = vim.api.nvim_win_get_config(M.state.win)
    M.state.create_window = create_serialized_window_function(config)
  else
    M.state.create_window = layout_functions[M.state.layout]
  end
end

-- Get status icon based on job state
---@param job_info JobInfo
---@return string
local function get_status_icon(job_info)
  if job_info.status == "running" then
    return "⚡" -- Lightning bolt for running
  elseif job_info.status == "exited" then
    if job_info.exit_code == 0 then
      return "✓" -- Checkmark for success (exit code 0)
    else
      return "✗" -- X for any error code (non-zero)
    end
  else
    return "🔶" -- Glass/diamond for other states (created, etc.)
  end
end

-- Start a job (in neovim buffer OR external kitty window)
---@param id integer
---@param use_terminal boolean
---@param cmd? string
---@param silent? boolean
---@param external_terminal? boolean
---@return nil
function M.start_job(id, use_terminal, cmd, silent, external_terminal)
  external_terminal = external_terminal or false
  cmd = cmd or vim.o.shell

  -- Check if job already exists and clean up
  local old_job = M.state.jobs[id]
  if old_job then
    if external_terminal and old_job.external_terminal then
      -- Check if external kitty window exists
      if old_job.buffer and kitty.window_exists(old_job.buffer) then
        return -- External window still exists, don't recreate
      end
    elseif not external_terminal and old_job.buffer and vim.api.nvim_buf_is_valid(old_job.buffer) then
      return -- Neovim buffer still exists, don't recreate
    end
  end

  if external_terminal then
    -- EXTERNAL TERMINAL: Create kitty window (NO neovim buffer)
    local success, window_id = kitty.create_window(use_terminal and vim.o.shell or cmd, "down")
    if not success then
      vim.notify_once("Failed to create external terminal: " .. window_id, vim.log.levels.ERROR)
      return
    end

    M.state.jobs[id] = {
      status = "running",
      use_terminal = use_terminal,
      external_terminal = true,
      command = cmd,
      buffer = window_id, -- Store kitty window ID in buffer field
      silent = silent or false,
    }

    -- For non-interactive external jobs, send command after window creation
    if use_terminal and cmd ~= vim.o.shell then
      local send_success, send_error = kitty.send_command(window_id, cmd)
      if not send_success then
        vim.notify_once("Failed to send command to external terminal: " .. (send_error or ""), vim.log.levels.WARN)
      end
    end

    if not silent then
      kitty.focus_window(window_id)
    end

    return
  end

  -- INTERNAL TERMINAL: Create neovim buffer (existing logic)
  local buf = vim.api.nvim_create_buf(false, true)
  M.state.jobs[id] = {
    status = "creating",
    use_terminal = use_terminal,
    external_terminal = false,
    command = cmd,
    buffer = buf,
    silent = silent or false,
  }
  vim.bo[buf].bufhidden = "hide" -- Keep buffer around
  vim.bo[buf].buflisted = false

  -- Set up keymaps for this job buffer (terminal or nofile)
  M.setup_terminal_keymaps(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.spell = false

    if use_terminal then
      -- Terminal buffer - always starts with shell, then optionally runs command
      vim.cmd("terminal")
      --
      -- -- If we have a command, send it to the shell after terminal is ready
      if cmd ~= "" and cmd ~= nil and cmd ~= vim.o.shell then
        -- Wait for terminal to be ready and get valid channel
        local function send_command()
          local channel = vim.bo[buf].channel
          if channel and channel > 0 then
            vim.api.nvim_chan_send(channel, cmd .. "\n")
          else
            -- Terminal not ready yet, try again
            vim.defer_fn(send_command, 50)
          end
        end
        vim.defer_fn(send_command, 200)
      end
      --
      M.state.jobs[id].status = "running"

      -- ., to toggle job window in terminal mode (short timeout for cd .. compatibility)
      vim.keymap.set("t", ".,", function()
        M.toggle()
      end, {
        buffer = buf,
        desc = "Toggle job window",
        nowait = true, -- Short timeout so cd .. works normally
      })

      -- .f to toggle layout in terminal mode
      vim.keymap.set("t", ".f", function()
        M.toggle_layout()
      end, {
        buffer = buf,
        desc = "Toggle job layout",
        nowait = true,
      })

      -- NOTE: Its possible that this would work now. Not sure
      -- vim.opt_local.timeoutlen = 100 -- Much shorter timeout (default is usually 1000ms)
    else
      -- Add Ctrl-C mapping to kill the job in non-interactive buffers
      vim.keymap.set("n", "<C-c>", function()
        if M.state.jobs[id] and M.state.jobs[id].system_job_id then
          vim.fn.jobstop(M.state.jobs[id].system_job_id)
          vim.notify_once("Killed job[" .. id .. "] with Ctrl-C")
        end
      end, {
        buffer = buf,
        desc = "Kill job with Ctrl-C",
      })
      -- q to close the job window
      vim.keymap.set("n", "q", function()
        if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
          serialize_and_create_closure() -- Preserve layout
          vim.api.nvim_win_close(M.state.win, false)
          M.state.win = nil
        end
      end, {
        buffer = buf,
        desc = "Close job window",
      })

      -- ESC as alternative to close window (common pattern)
      vim.keymap.set("n", "<ESC>", function()
        if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
          serialize_and_create_closure()
          vim.api.nvim_win_close(M.state.win, false)
          M.state.win = nil
        end
      end, { buffer = buf, desc = "Close job window" })

      -- ., to toggle job window (short timeout for cd .. compatibility)
      vim.keymap.set("n", ".,", function()
        M.toggle()
      end, {
        buffer = buf,
        desc = "Toggle job window",
        nowait = true, -- Short timeout so cd .. works normally
      })

      -- .f to toggle layout in normal mode
      vim.keymap.set("n", ".f", function()
        M.toggle_layout()
      end, {
        buffer = buf,
        desc = "Toggle job layout",
        nowait = true,
      })

      -- NOTE: Its possible that this would work now. Not sure
      -- vim.opt_local.timeoutlen = 100 -- Much shorter timeout (default is usually 1000ms)

      -- Output capture buffer - non-interactive
      vim.bo.buftype = "nofile"
      vim.bo.modifiable = false

      M.state.jobs[id].system_job_id = vim.fn.jobstart(cmd, {
        on_stdout = function(job_id, data, event)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              vim.bo[buf].modifiable = true
              vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
              vim.bo[buf].modifiable = false

              -- Auto-scroll if this buffer is currently displayed
              if M.state.current_job_id == id and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
                local line_count = vim.api.nvim_buf_line_count(buf)
                vim.api.nvim_win_set_cursor(M.state.win, { line_count, 0 })
              end
            end
          end)
        end,
        on_stderr = function(job_id, data, event)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              vim.bo[buf].modifiable = true
              -- Prefix stderr with [ERROR]
              local prefixed_data = {}
              for _, line in ipairs(data) do
                if line ~= "" then
                  table.insert(prefixed_data, "[ERROR] " .. line)
                else
                  table.insert(prefixed_data, line)
                end
              end
              vim.api.nvim_buf_set_lines(buf, -1, -1, false, prefixed_data)
              vim.bo[buf].modifiable = false
            end
          end)
        end,
        --FIXME: On exist is calleda after so does not refelect the state
        on_exit = function(job_id, exit_code, event)
          M.state.jobs[id].status = "exited"
          M.state.jobs[id].exit_code = exit_code
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              vim.bo[M.state.jobs[id].buffer].modifiable = true
              vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", "=== Job exited with code " .. exit_code .. " ===" })
              vim.bo[buf].modifiable = false
            end
            vim.notify_once("Job " .. buf .. ":  finished (exit code: " .. exit_code .. ")", vim.log.levels.DEBUG)
          end)
        end,
      })
      M.state.jobs[id].status = "running"
    end
  end)
  vim.api.nvim_create_autocmd({ "BufWipeout" }, {
    buffer = buf,
    once = true,
    callback = function(ev)
      -- print("FIRED" .. buf)
      --
      serialize_and_create_closure()
      -- TODO: Remove this commented out debug code
      -- vim.print(ev)
      -- vim.print(M.state)
      -- vim.print(M.state.jobs)
      -- -- Kill job if still running
      local system_job_id = M.state.jobs[id].system_job_id
      if system_job_id then
        vim.fn.jobstop(system_job_id)
      end
      -- Remove from jobs list
      M.state.jobs[id] = nil
      if M.state.current_job_id == id then
        M.state.current_job_id = nil
      end
    end,
  })
end

-- Improved job configuration UI with single navigatable menu
---@param id integer
---@param callback fun(config: JobConfig): nil
---@return nil
local function configure_job_ui(id, callback)
  local config = {
    command = "",
    use_terminal = true,
    external_terminal = false,
    silent = false,
  }

  -- Step 1: Get command
  M.input({
    prompt = "Command for job " .. id .. "  (empty for shell): ",
    default = "",
  }, function(command_str)
    if command_str == nil then
      return
    end -- Cancelled

    config.command = command_str

    -- Step 2: Single menu for all options
    local menu_options = {
      { text = "✓  Create and start job", type = "action", value = "create" },
      { text = "✗  Cancel", type = "action", value = "cancel" },
      { text = "🖥️  Terminal buffer (interactive)", type = "buffer", value = { use_terminal = true } },
      { text = "📋  Output buffer (capture output)", type = "buffer", value = { use_terminal = false } },
      { text = "🏠  Internal (neovim buffer/window)", type = "location", value = { external_terminal = false } },
      { text = "🌐  External (kitty window)", type = "location", value = { external_terminal = true } },
      { text = "🔇  Silent mode (no window popup)", type = "mode", value = { silent = true } },
      { text = "🔊  Normal mode (show window)", type = "mode", value = { silent = false } },
    }

    local function show_menu()
      local cmd_display = config.command == "" and "shell" or config.command
      local buffer_display = config.use_terminal and "terminal" or "output capture"
      local location_display = config.external_terminal and "external" or "internal"
      local mode_display = config.silent and "silent" or "normal"
      local prompt =
        string.format("Job[%s]: %s (%s, %s, %s)", id, cmd_display, buffer_display, location_display, mode_display)

      vim.ui.select(menu_options, {
        prompt = prompt,
        format_item = function(item)
          local prefix = ""
          if item.type == "buffer" then
            prefix = config.use_terminal == item.value.use_terminal and "● " or "○ "
          elseif item.type == "location" then
            prefix = config.external_terminal == item.value.external_terminal and "● " or "○ "
          elseif item.type == "mode" then
            prefix = config.silent == item.value.silent and "● " or "○ "
          end
          return prefix .. item.text
        end,
      }, function(choice)
        if choice == nil then
          return
        end -- Cancelled

        if choice.type == "buffer" then
          config.use_terminal = choice.value.use_terminal
          show_menu() -- Show menu again
        elseif choice.type == "location" then
          config.external_terminal = choice.value.external_terminal
          show_menu() -- Show menu again
        elseif choice.type == "mode" then
          config.silent = choice.value.silent
          show_menu() -- Show menu again
        elseif choice.type == "action" then
          if choice.value == "create" then
            callback(config)
          end
          -- For cancel, just return (do nothing)
        end
      end)
    end

    show_menu()
  end)
end

-- Configure or run job
---@param id integer
---@return nil
function M.configure_job(id)
  local job_info = M.state.jobs[id]

  if job_info then
    -- Job exists, show options
    local options = {
      "🔄 Restart job",
      "⚙️ Reconfigure job",
      "❌ Cancel",
    }

    vim.ui.select(options, {
      prompt = "Job[" .. id .. "] already exists:",
    }, function(choice)
      if not choice then
        return
      end

      if choice:match("Restart") then
        if job_info.status == "running" and job_info.system_job_id then
          vim.notify_once("Job[" .. id .. "] is already running. Kill it first with .k", vim.log.levels.WARN)
          return
        end
        M.start_job(id, job_info.use_terminal, job_info.command, job_info.silent, job_info.external_terminal)
        -- Always set current job ID for tracking
        M.state.current_job_id = id
        if not job_info.silent then
          M.show_job(id)
        end
        vim.notify_once("Restarted job[" .. id .. "]")
      elseif choice:match("Reconfigure") then
        configure_job_ui(id, function(config)
          -- Remove old job
          if job_info.system_job_id then
            vim.fn.jobstop(job_info.system_job_id)
          end
          if job_info.buffer and vim.api.nvim_buf_is_valid(job_info.buffer) then
            vim.api.nvim_buf_delete(job_info.buffer, { force = true })
          end

          config.command = vim.fn.expandcmd(config.command)
          M.start_job(id, config.use_terminal, config.command, config.silent, config.external_terminal)
          -- Always set current job ID for tracking
          M.state.current_job_id = id
          if not config.silent then
            M.show_job(id)
          end

          local cmd_display = config.command == "" and "shell" or config.command
          local buffer_str = config.use_terminal and " (terminal)" or " (output capture)"
          local mode_str = config.silent and " (silent)" or " (normal)"
          vim.notify_once(
            "Reconfigured job[" .. id .. "]: " .. cmd_display .. buffer_str .. mode_str,
            vim.log.levels.DEBUG
          )
        end)
      end
    end)
  else
    -- New job, configure it
    configure_job_ui(id, function(config)
      config.command = vim.fn.expandcmd(config.command)
      M.start_job(id, config.use_terminal, config.command, config.silent, config.external_terminal)
      -- Always set current job ID for tracking
      M.state.current_job_id = id
      if not config.silent then
        M.show_job(id)
      end

      local cmd_display = config.command == "" and "shell" or config.command
      local buffer_str = config.use_terminal and " (terminal)" or " (output capture)"
      local mode_str = config.silent and " (silent)" or " (normal)"
      vim.notify_once("Created job [" .. id .. "]: " .. cmd_display .. buffer_str .. mode_str, vim.log.levels.DEBUG)
    end)
  end
end

-- Show job in the window (internal only - external jobs focus kitty window)
---@param job_id integer
---@return nil
function M.show_job(job_id)
  local job_info = M.state.jobs[job_id]
  if not job_info then
    vim.notify_once("Job [" .. job_id .. "] not found", vim.log.levels.ERROR)
    return
  end

  M.state.current_job_id = job_id

  -- Handle external terminals - focus kitty window instead of showing in neovim
  if job_info.external_terminal then
    if job_info.buffer and kitty.window_exists(job_info.buffer) then
      local success, error_msg = kitty.focus_window(job_info.buffer)
      if not success then
        vim.notify_once("Failed to focus external terminal: " .. (error_msg or ""), vim.log.levels.WARN)
      end
    else
      vim.notify_once("External terminal window not found", vim.log.levels.WARN)
    end
    return
  end

  -- Handle internal terminals - show in neovim window
  local original_win = vim.api.nvim_get_current_win()
  -- Create window if it doesn't exist
  if not (M.state.win and vim.api.nvim_win_is_valid(M.state.win)) then
    local title = "Job " .. job_id
    M.state.win = M.state.create_window(job_info.buffer, title)
  else
    -- Switch buffer in existing window
    vim.api.nvim_win_set_buf(M.state.win, job_info.buffer)
  end

  if job_info.use_terminal then
    vim.api.nvim_set_current_win(M.state.win)
  else
    vim.api.nvim_set_current_win(original_win)
  end
end

-- List jobs and pick one
---@return nil
function M.list_jobs()
  local items = {}

  for job_id, job_info in pairs(M.state.jobs) do
    -- Check if job is valid (neovim buffer OR kitty window)
    local is_valid = false
    if job_info.external_terminal then
      is_valid = job_info.buffer and kitty.window_exists(job_info.buffer)
    else
      is_valid = job_info.buffer and vim.api.nvim_buf_is_valid(job_info.buffer)
    end

    if is_valid then
      local status_icon = get_status_icon(job_info)
      local pty_icon = job_info.use_terminal and "🖥️" or "📋"
      local location_icon = job_info.external_terminal and "🌐" or "🏠"
      local silent_icon = job_info.silent and "🔇" or ""
      local current_dot = (M.state.current_job_id == job_id) and "• " or "  "

      local cmd_display = job_info.command or "shell"

      -- Add exit code to display if job exited with error
      local exit_info = ""
      if job_info.status == "exited" and job_info.exit_code and job_info.exit_code ~= 0 then
        exit_info = " (exit:" .. job_info.exit_code .. ")"
      end

      local display = string.format(
        "%s%s %s%s%s Job[%s]: %s%s",
        current_dot,
        status_icon,
        pty_icon,
        location_icon,
        silent_icon,
        job_id,
        cmd_display,
        exit_info
      )

      table.insert(items, {
        display = display,
        job_id = job_id,
        job_info = job_info,
      })
    end
  end

  if #items == 0 then
    vim.notify_once("No jobs available", vim.log.levels.WARN)
    return
  end

  -- Sort by job_id
  table.sort(items, function(a, b)
    return a.job_id < b.job_id
  end)

  vim.ui.select(items, {
    prompt = "Select Job:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if choice then
      M.show_job(choice.job_id)
    end
  end)
end

-- Toggle job window
---@return nil
function M.toggle()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    serialize_and_create_closure()
    vim.api.nvim_win_close(M.state.win, false)
    M.state.win = nil
  else
    if M.state.current_job_id then
      M.show_job(M.state.current_job_id)
    else
      M.list_jobs()
    end
  end
end

-- Toggle layout with smooth transition
---@return nil
function M.toggle_layout()
  if M.state.layout == "floating" then
    M.state.layout = "split"
  elseif M.state.layout == "split" then
    M.state.layout = "vsplit"
  else
    M.state.layout = "floating"
  end

  M.state.create_window = layout_functions[M.state.layout]

  -- If no window is open, just return
  if not (M.state.win and vim.api.nvim_win_is_valid(M.state.win)) then
    vim.notify_once("Job layout: " .. M.state.layout)
    return
  end

  local current_job = M.state.jobs[M.state.current_job_id]
  if not current_job then
    return
  end

  -- Close current window and open with new layout
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    serialize_and_create_closure()
    vim.api.nvim_win_close(M.state.win, false)
  end
  M.state.win = M.state.create_window(current_job.buffer, "Job[" .. M.state.current_job_id .. "]")

  -- Focus appropriately
  if current_job.use_terminal then
    vim.api.nvim_set_current_win(M.state.win)
    vim.cmd("startinsert")
  end

  vim.notify_once("Job layout: " .. M.state.layout)
end

-- Send text to current job (works for both internal and external terminals)
---@param text string
---@return nil
function M.send_text(text)
  if not M.state.current_job_id then
    vim.notify_once("No current job selected", vim.log.levels.WARN)
    return
  end

  local job_info = M.state.jobs[M.state.current_job_id]
  if not job_info then
    vim.notify_once("Current job not found", vim.log.levels.ERROR)
    return
  end

  if not job_info.use_terminal then
    vim.notify_once("Current job is not interactive (not a terminal)", vim.log.levels.WARN)
    return
  end

  if job_info.external_terminal then
    -- Send to external kitty terminal
    if job_info.buffer and kitty.window_exists(job_info.buffer) then
      local success, error_msg = kitty.send_text(job_info.buffer, text)
      if not success then
        vim.notify_once("Failed to send text to external terminal: " .. (error_msg or ""), vim.log.levels.ERROR)
      end
    else
      vim.notify_once("External terminal window not found", vim.log.levels.ERROR)
    end
  else
    -- Send to internal neovim terminal buffer
    vim.api.nvim_chan_send(vim.bo[job_info.buffer].channel, text)
  end
end

-- Send visual selection to current job
---@return nil
function M.send_selection()
  -- Get visual selection
  local _, srow, scol = unpack(vim.fn.getpos("v"))
  local _, erow, ecol = unpack(vim.fn.getpos("."))

  local lines
  if vim.fn.mode() == "V" then
    if srow > erow then
      lines = vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
    else
      lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
    end
  elseif vim.fn.mode() == "v" then
    if srow < erow or (srow == erow and scol <= ecol) then
      lines = vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    else
      lines = vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
    end
  elseif vim.fn.mode() == "\22" then
    lines = {}
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
  end

  if lines then
    local text = table.concat(lines, "\n") .. "\n"
    -- Add bracketed paste for better handling in terminals
    local bracketed_text = "\027[200~" .. text .. "\027[201~" .. "\n"
    M.send_text(bracketed_text)
  end
end

-- Send current line to current job
---@return nil
function M.send_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, true)
  local text = table.concat(lines, "\n") .. "\n"
  M.send_text(text)
end

-- Send entire file to current job
---@return nil
function M.send_file()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local text = table.concat(lines, "\n") .. "\n"
  local bracketed_text = "\027[200~" .. text .. "\027[201~" .. "\n"
  M.send_text(bracketed_text)
end

---@return nil
function M.kill_current_job()
  if not M.state.current_job_id then
    vim.notify_once("No current job selected", vim.log.levels.WARN)
    return
  end

  local job_info = M.state.jobs[M.state.current_job_id]
  if job_info and job_info.system_job_id then
    vim.fn.jobstop(job_info.system_job_id)
    vim.notify_once("Killed job[" .. M.state.current_job_id .. "]")
  end
end

---@param id integer
---@return nil
function M.kill_job(id)
  -- TODO: Return an exit code or some indicator that it was killed
  local job_info = M.state.jobs[id]
  if job_info then
    if job_info.external_terminal then
      -- Kill external kitty window (NO neovim buffer cleanup)
      if job_info.buffer and kitty.window_exists(job_info.buffer) then
        local success, error_msg = kitty.close_window(job_info.buffer)
        if not success then
          vim.notify_once("Failed to close external terminal: " .. (error_msg or ""), vim.log.levels.WARN)
        end
      end
    else
      -- Kill internal neovim job/buffer
      if job_info.system_job_id then
        vim.fn.jobstop(job_info.system_job_id)
        vim.api.nvim_buf_delete(job_info.buffer, { force = true })
      else
        vim.api.nvim_buf_delete(job_info.buffer, { force = true })
      end
    end
    vim.notify_once("Killed job " .. id, vim.log.levels.DEBUG)
  else
    vim.notify_once("Job " .. id .. " Does Not Exist", vim.log.levels.WARN)
  end
end
-- Kill current job
---@param id integer
---@param quiet? boolean
---@return nil
function M.restart_job(id, quiet)
  local job_info = M.state.jobs[id]
  if job_info then
    if job_info.external_terminal then
      -- Kill external kitty window (NO neovim buffer cleanup)
      if job_info.buffer and kitty.window_exists(job_info.buffer) then
        local success, error_msg = kitty.close_window(job_info.buffer)
        if not success then
          vim.notify_once("Failed to close external terminal: " .. (error_msg or ""), vim.log.levels.WARN)
        end
      end
    else
      -- Kill internal neovim job/buffer
      if job_info.system_job_id then
        vim.fn.jobstop(job_info.system_job_id)
        vim.api.nvim_buf_delete(job_info.buffer, { force = true })
      else
        vim.api.nvim_buf_delete(job_info.buffer, { force = true })
      end
    end
    vim.notify_once("Killed job " .. id, vim.log.levels.DEBUG)
    M.start_job(id, job_info.use_terminal, job_info.command, job_info.silent, job_info.external_terminal)
    -- Always set current job ID for tracking
    M.state.current_job_id = id
    vim.notify_once("Restarting job " .. id .. " ...", vim.log.levels.DEBUG)
    if not quiet and not job_info.silent then
      M.show_job(id)
    end
  else
    vim.notify_once("Job " .. id .. " Does Not Exist")
  end
end
---@param buf integer
---@return nil
function M.setup_terminal_keymaps(buf)
  local PLUGIN_LEADER = "."
  local opts = { buffer = buf, nowait = true }

  -- Use shorter timeout for these specific mappings to avoid delays
  vim.keymap.set("t", PLUGIN_LEADER .. "g", function()
    vim.cmd("stopinsert")
    M.list_jobs()
  end, vim.tbl_extend("force", opts, { desc = "List jobs" }))

  vim.keymap.set("t", PLUGIN_LEADER .. ",", function()
    vim.cmd("stopinsert")
    M.toggle()
  end, vim.tbl_extend("force", opts, { desc = "Show/Hide Job Window" }))

  vim.keymap.set("t", PLUGIN_LEADER .. "f", function()
    vim.cmd("stopinsert")
    M.toggle_layout()
  end, vim.tbl_extend("force", opts, { desc = "Toggle job layout" }))

  vim.keymap.set("t", PLUGIN_LEADER .. "k", function()
    vim.cmd("stopinsert")
    M.kill_current_job()
  end, vim.tbl_extend("force", opts, { desc = "Kill current job" }))

  -- Numbered job mappings
  for i = 1, 9 do
    vim.keymap.set("t", PLUGIN_LEADER .. i, function()
      vim.cmd("stopinsert")
      M.configure_job(tostring(i))
    end, vim.tbl_extend("force", opts, { desc = "Configure/run job " .. i }))
  end

  vim.keymap.set("t", PLUGIN_LEADER .. PLUGIN_LEADER, function()
    vim.cmd("stopinsert")
    if not M.state.current_job_id then
      M.configure_job("1")
    else
      M.restart_job(M.state.current_job_id)
    end
  end, vim.tbl_extend("force", opts, { desc = "Restart job" }))
end
-- TODO: Make sure focus does not go to output buffer
-- Find a way to kill the output buffer whiile focused on it. Let ctrl-c
-- be an option
-- Fix output buffer restart
-- Setup keymaps
---@return nil
function M.setup()
  -- .<id> configures or reruns job
  local PLUGIN_LEADER = "."
  for i = 1, 9 do
    -- vim.keymap.set({ "n", "t" }, PLUGIN_LEADER .. i, function()
    vim.keymap.set({ "n" }, PLUGIN_LEADER .. i, function()
      M.configure_job(tostring(i))
    end, { desc = "Configure/run job " .. i })
  end

  --- TODO Makes these buffer local with a timeout
  -- .g lists jobs
  -- vim.keymap.set({ "t", "n" }, PLUGIN_LEADER .. "l", M.list_jobs, { desc = "List jobs" })
  vim.keymap.set({ "n" }, PLUGIN_LEADER .. "g", M.list_jobs, { desc = "List jobs" })
  vim.keymap.set({ "n" }, PLUGIN_LEADER .. PLUGIN_LEADER, function()
    if not M.state.current_job_id then
      M.configure_job("1")
    else
      M.restart_job(M.state.current_job_id)
    end
  end, { desc = "Restart job" })
  -- ., toggles job window
  -- vim.keymap.set({ "t", "n" }, ".,", M.toggle, { desc = "Show/Hide Job Window" })
  vim.keymap.set({ "n" }, ".,", M.toggle, { desc = "Show/Hide Job Window" })

  -- .l toggles layout
  -- vim.keymap.set({ "t", "n" }, PLUGIN_LEADER .. "f", M.toggle_layout, { desc = "Toggle job layout" })
  vim.keymap.set({ "n" }, PLUGIN_LEADER .. "f", M.toggle_layout, { desc = "Toggle job layout" })

  -- .k kills current job
  vim.keymap.set({ "n" }, PLUGIN_LEADER .. "k", M.kill_current_job, { desc = "Kill current job" })

  -- Send mappings (visual mode)
  vim.keymap.set("v", PLUGIN_LEADER .. PLUGIN_LEADER, M.send_selection, { desc = "Send selection to job" })
  -- Send mappings (normal mode)
  vim.keymap.set({ "v", "n" }, PLUGIN_LEADER .. "l", M.send_line, { desc = "Send line to job" })
  vim.keymap.set({ "n", "v" }, PLUGIN_LEADER .. "a", M.send_file, { desc = "Send file to job" })

  -- Commands
  vim.api.nvim_create_user_command("JobList", M.list_jobs, { desc = "List all jobs" })
  vim.api.nvim_create_user_command("JobToggle", M.toggle, { desc = "Toggle job window" })
  vim.api.nvim_create_user_command("JobLayout", M.toggle_layout, { desc = "Toggle job layout" })
  vim.api.nvim_create_user_command("JobKill", M.kill_current_job, { desc = "Kill current job" })
end

return M
