-- Standalone Job Manager - Complete, self-contained module
-- No external dependencies, plug and play

local M = {}

M.input = Snacks.input.input or vim.ui.input
-- State
M.state = {
  win = nil,
  current_job_id = nil,
  layout = "vsplit",
  create_window = nil,
  jobs = {}, -- job_id -> job_info
}

-- Layout functions
local layout_functions = {
  floating = function(buf, title)
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
local function serialize_and_create_closure()
  if M.state.layout ~= "floating" and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    local config = vim.api.nvim_win_get_config(M.state.win)
    M.state.create_window = create_serialized_window_function(config)
  else
    M.state.create_window = layout_functions[M.state.layout]
  end
end

-- Get status icon based on job state
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

-- Start a job in its buffer
function M.start_job(id, use_terminal, cmd)
  local old_buf = M.state.jobs[id] and M.state.jobs[id].buffer
  if old_buf and vim.api.nvim_buf_is_valid(old_buf) then
    -- error you should close this buffer
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  cmd = cmd or vim.o.shell
  M.state.jobs[id] = {
    status = "creating",
    use_terminal = use_terminal,
    command = cmd,
    buffer = buf,
  }
  vim.bo[buf].bufhidden = "hide" -- Keep buffer around
  vim.bo[buf].buflisted = false

  -- FIXME: This keymap setup is BROKEN noop
  -- M.setup_terminal_keymaps(buf)
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
    else
      -- Add Ctrl-C mapping to kill the job in non-interactive buffers
      vim.keymap.set("n", "<C-c>", function()
        if M.state.jobs[id] and M.state.jobs[id].system_job_id then
          vim.fn.jobstop(M.state.jobs[id].system_job_id)
          vim.notify("Killed job[" .. id .. "] with Ctrl-C")
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
            vim.notify("Job " .. buf .. ":  finished (exit code: " .. exit_code .. ")")
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
      print("FIRED" .. buf)
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

-- Fancy job configuration UI
local function configure_job_ui(id, callback)
  local config = {
    command = "",
    use_terminal = true,
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

    -- Step 2: Buffer type selection
    local buffer_options = {
      { text = "🖥️  Terminal buffer (interactive)", value = true },
      { text = "📋  Output buffer (capture output)", value = false },
    }

    vim.ui.select(buffer_options, {
      prompt = "Job " .. id .. " buffer type:",
      format_item = function(item)
        return item.text
      end,
    }, function(choice)
      if choice == nil then
        return
      end -- Cancelled

      config.use_terminal = choice.value

      -- Step 3: Show summary and confirm
      local cmd_display = config.command == "" and "shell" or config.command
      local buffer_display = config.use_terminal and "terminal" or "output capture"

      local summary = string.format("Job[%s]: %s (%s)", id, cmd_display, buffer_display)

      vim.ui.select({ "✓ Create and start", "✗ Cancel" }, {
        prompt = summary,
      }, function(confirm)
        if confirm and confirm:match("Create") then
          callback(config)
        end
      end)
    end)
  end)
end

-- Configure or run job
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
          vim.notify("Job[" .. id .. "] is already running. Kill it first with .k", vim.log.levels.WARN)
          return
        end
        M.start_job(id, job_info.use_terminal, job_info.command)
        M.show_job(id)
        vim.notify("Restarted job[" .. id .. "]")
      elseif choice:match("Reconfigure") then
        configure_job_ui(id, function(config)
          -- Remove old job
          if job_info.system_job_id then
            vim.fn.jobstop(job_info.system_job_id)
          end
          if job_info.buffer and vim.api.nvim_buf_is_valid(job_info.buffer) then
            vim.api.nvim_buf_delete(job_info.buffer, { force = true })
          end

          M.start_job(id, config.use_terminal, config.command)
          M.show_job(id)

          local cmd_display = config.command == "" and "shell" or config.command
          local buffer_str = config.use_terminal and " (terminal)" or " (output capture)"
          vim.notify("Reconfigured job[" .. id .. "]: " .. cmd_display .. buffer_str)
        end)
      end
    end)
  else
    -- New job, configure it
    configure_job_ui(id, function(config)
      config.command = vim.fn.expandcmd(config.command)
      M.start_job(id, config.use_terminal, config.command)
      M.show_job(id)

      local cmd_display = config.command == "" and "shell" or config.command
      local buffer_str = config.use_terminal and " (terminal)" or " (output capture)"
      vim.notify("Created job[" .. id .. "]: " .. cmd_display .. buffer_str)
    end)
  end
end

-- Show job in the window
function M.show_job(job_id)
  local job_info = M.state.jobs[job_id]
  if not job_info then
    vim.notify("Job[" .. job_id .. "] not found", vim.log.levels.ERROR)
    return
  end
  local original_win = vim.api.nvim_get_current_win()
  -- Create window if it doesn't exist
  if not (M.state.win and vim.api.nvim_win_is_valid(M.state.win)) then
    local title = "Job " .. job_id
    M.state.win = M.state.create_window(job_info.buffer, title)
  else
    -- Switch buffer in existing window
    vim.api.nvim_win_set_buf(M.state.win, job_info.buffer)
  end
  M.state.current_job_id = job_id
  if job_info.use_terminal then
    vim.api.nvim_set_current_win(M.state.win)
  else
    vim.api.nvim_set_current_win(original_win)
  end
end

-- List jobs and pick one
function M.list_jobs()
  local items = {}

  for job_id, job_info in pairs(M.state.jobs) do
    if vim.api.nvim_buf_is_valid(job_info.buffer) then
      local status_icon = get_status_icon(job_info)
      local pty_icon = job_info.use_terminal and "🖥️" or "📋"
      local current_dot = (M.state.current_job_id == job_id) and "• " or "  "

      local cmd_display = job_info.command or "shell"

      -- Add exit code to display if job exited with error
      local exit_info = ""
      if job_info.status == "exited" and job_info.exit_code and job_info.exit_code ~= 0 then
        exit_info = " (exit:" .. job_info.exit_code .. ")"
      end

      local display =
        string.format("%s%s %s Job[%s]: %s%s", current_dot, status_icon, pty_icon, job_id, cmd_display, exit_info)

      table.insert(items, {
        display = display,
        job_id = job_id,
        job_info = job_info,
      })
    end
  end

  if #items == 0 then
    vim.notify("No jobs available", vim.log.levels.WARN)
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
    vim.notify("Job layout: " .. M.state.layout)
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

  vim.notify("Job layout: " .. M.state.layout)
end

-- Send text to current job (only works for terminal buffers)
function M.send_text(text)
  if not M.state.current_job_id then
    vim.notify("No current job selected", vim.log.levels.WARN)
    return
  end

  local job_info = M.state.jobs[M.state.current_job_id]
  if not job_info then
    vim.notify("Current job not found", vim.log.levels.ERROR)
    return
  end

  if not job_info.use_terminal then
    vim.notify("Current job is not interactive (not a terminal buffer)", vim.log.levels.WARN)
    return
  end

  -- Send to terminal buffer
  vim.api.nvim_chan_send(vim.bo[job_info.buffer].channel, text)
end

-- Send visual selection to current job
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
    local bracketed_text = "\027[200~" .. text .. "\027[201~"
    M.send_text(bracketed_text)
  end
end

-- Send current line to current job
function M.send_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, true)
  local text = table.concat(lines, "\n") .. "\n"
  M.send_text(text)
end

-- Send entire file to current job
function M.send_file()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local text = table.concat(lines, "\n") .. "\n"
  local bracketed_text = "\027[200~" .. text .. "\027[201~"
  M.send_text(bracketed_text)
end

function M.kill_current_job()
  if not M.state.current_job_id then
    vim.notify("No current job selected", vim.log.levels.WARN)
    return
  end

  local job_info = M.state.jobs[M.state.current_job_id]
  if job_info and job_info.system_job_id then
    vim.fn.jobstop(job_info.system_job_id)
    vim.notify("Killed job[" .. M.state.current_job_id .. "]")
  end
end

function M.kill_job(id)
  -- TODO: Return an exit code or some indicator that it was killed
  local job_info = M.state.jobs[id]
  if job_info then
    if job_info.system_job_id then
      vim.fn.jobstop(job_info.system_job_id)
      vim.api.nvim_buf_delete(job_info.buffer, { force = true })
    else
      vim.api.nvim_buf_delete(job_info.buffer, { force = true })
    end
    vim.notify("Killed job " .. id)
  else
    vim.notify("Job " .. id .. " Does Not Exist")
  end
end
-- Kill current job
function M.restart_job(id, quiet)
  local job_info = M.state.jobs[id]
  if job_info then
    if job_info.system_job_id then
      vim.fn.jobstop(job_info.system_job_id)
      vim.api.nvim_buf_delete(job_info.buffer, { force = true })
    else
      vim.api.nvim_buf_delete(job_info.buffer, { force = true })
    end
    vim.notify("Killed job " .. id)
    M.start_job(id, job_info.use_terminal, job_info.command)
    vim.notify("Restarting job " .. id .. " ...")
    if not quiet then
      M.show_job(id)
    end
  else
    vim.notify("Job " .. id .. " Does Not Exist")
  end
end
function M.setup_terminal_keymaps(buf)
  local PLUGIN_LEADER = "."
  local opts = { buffer = buf, nowait = true }

  -- Use shorter timeout for these specific mappings to avoid delays
  vim.keymap.set("t", PLUGIN_LEADER .. "l", function()
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
  -- vim.keymap.set({ "t", "n" }, PLUGIN_LEADER .. "k", M.kill_current_job, { desc = "Kill current job" })
  vim.keymap.set({ "n" }, PLUGIN_LEADER .. "k", M.kill_current_job, { desc = "Kill current job" })

  -- Send mappings (visual mode)
  vim.keymap.set("v", PLUGIN_LEADER .. PLUGIN_LEADER, M.send_selection, { desc = "Send selection to job" })
  -- Send mappings (normal mode)
  vim.keymap.set({ "v", "n" }, PLUGIN_LEADER .. "a", M.send_line, { desc = "Send line to job" })
  vim.keymap.set({ "n", "v" }, PLUGIN_LEADER .. "s", M.send_file, { desc = "Send file to job" })

  -- Commands
  vim.api.nvim_create_user_command("JobList", M.list_jobs, { desc = "List all jobs" })
  vim.api.nvim_create_user_command("JobToggle", M.toggle, { desc = "Toggle job window" })
  vim.api.nvim_create_user_command("JobLayout", M.toggle_layout, { desc = "Toggle job layout" })
  vim.api.nvim_create_user_command("JobKill", M.kill_current_job, { desc = "Kill current job" })
end

return M
