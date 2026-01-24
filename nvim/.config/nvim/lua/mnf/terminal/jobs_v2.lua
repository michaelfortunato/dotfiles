-- Scratch refactor of `mnf.terminal.jobs`.
--
-- Goals:
-- - Separate job *definition* (config) from job *runtime* (buffer/job id / kitty window).
-- - Allow saving/editing jobs without starting them.
-- - Add per-job "focus on start/show" control (default: focus for terminal jobs, no focus for non-terminal).

---@alias JobId string|integer
---@alias JobStatus "defined"|"creating"|"running"|"exited"|"killing"|"killed"

---@class JobConfig
---@field command string
---@field use_terminal boolean
---@field external_terminal boolean
---@field silent boolean
---@field focus "auto"|boolean

---@class JobRuntime
---@field buffer integer? -- neovim buffer ID OR kitty window ID
---@field system_job_id integer?
---@field config JobConfig -- snapshot at start time
---@field generation integer

---@class JobInfo
---@field status JobStatus
---@field config JobConfig
---@field runtime JobRuntime?
---@field exit_code integer?
---@field generation integer
---@field dirty boolean

---@class JobManager
local M = {}

local kitty = require("mnf.terminal.kitty")

---@type fun(msg: string, level?: integer): nil
local function notify(msg, level)
  vim.notify_once(msg, level or vim.log.levels.INFO)
end

---@param config? JobConfig
---@return JobConfig
local function normalize_config(config)
  local cfg = {
    command = "",
    use_terminal = true,
    external_terminal = false,
    silent = false,
    focus = "auto",
  }
  if config then
    if config.command ~= nil then
      cfg.command = config.command
    end
    if config.use_terminal ~= nil then
      cfg.use_terminal = config.use_terminal
    end
    if config.external_terminal ~= nil then
      cfg.external_terminal = config.external_terminal
    end
    if config.silent ~= nil then
      cfg.silent = config.silent
    end
    if config.focus ~= nil then
      cfg.focus = config.focus
    end
  end
  cfg.command = vim.trim(cfg.command or "")
  if cfg.focus ~= "auto" and type(cfg.focus) ~= "boolean" then
    cfg.focus = "auto"
  end
  return cfg
end

---@param a JobConfig?
---@param b JobConfig?
---@return boolean
local function configs_equal(a, b)
  if not a or not b then
    return false
  end
  return a.command == b.command
    and a.use_terminal == b.use_terminal
    and a.external_terminal == b.external_terminal
    and a.silent == b.silent
    and a.focus == b.focus
end

---@param cfg JobConfig
---@return boolean
local function should_focus(cfg)
  if cfg.focus == "auto" or cfg.focus == nil then
    return cfg.use_terminal
  end
  return cfg.focus == true
end

---@class JobState
---@field win integer?
---@field current_job_id JobId?
---@field layout string
---@field create_window fun(buf: integer, title: string): integer
---@field jobs table<JobId, JobInfo>
M.state = {
  win = nil,
  current_job_id = nil,
  layout = "vsplit",
  create_window = nil,
  jobs = {},
}

-- Input helper (Snacks if available, otherwise vim.ui.input)
---@type fun(opts: table, on_confirm: fun(input: string?)): nil
M.input = (Snacks and Snacks.input and Snacks.input.input) or vim.ui.input

---@param buf integer
---@return string? abspath
local function buf_abspath(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if not name or name == "" then
    return nil
  end
  local abs = vim.fn.fnamemodify(name, ":p")
  return vim.uv.fs_realpath(abs) or abs
end

---@param origin_buf integer
---@return string
local function cmdline_insert_with_bufpath(origin_buf)
  local path = buf_abspath(origin_buf)
  if not path then
    notify("jobs_refactor: current buffer has no file path", vim.log.levels.WARN)
    return ""
  end

  local line = vim.fn.getcmdline()
  local pos = vim.fn.getcmdpos()

  -- If the cursor is just after a %, replace it; otherwise insert at cursor.
  if pos > 1 and line:sub(pos - 1, pos - 1) == "%" then
    local new = line:sub(1, pos - 2) .. path .. line:sub(pos)
    vim.fn.setcmdline(new)
    vim.fn.setcmdpos((pos - 1) + #path)
    return ""
  end

  local new = line:sub(1, pos - 1) .. path .. line:sub(pos)
  vim.fn.setcmdline(new)
  vim.fn.setcmdpos(pos + #path)
  return ""
end

---@param lhs string
---@return table? mapping
local function get_cmdline_map(lhs)
  local ok, map = pcall(vim.fn.maparg, lhs, "c", false, true)
  if not ok or type(map) ~= "table" or next(map) == nil then
    return nil
  end
  return map
end

---@param lhs string
---@param map table?
---@return nil
local function restore_cmdline_map(lhs, map)
  if not map then
    pcall(vim.keymap.del, "c", lhs)
    return
  end

  local opts = {
    noremap = map.noremap == 1,
    expr = map.expr == 1,
    silent = map.silent == 1,
    nowait = map.nowait == 1,
  }

  if type(map.callback) == "function" then
    vim.keymap.set("c", lhs, map.callback, opts)
    return
  end

  if type(map.rhs) == "string" and map.rhs ~= "" then
    vim.keymap.set("c", lhs, map.rhs, opts)
    return
  end

  pcall(vim.keymap.del, "c", lhs)
end

---@param origin_buf integer
---@param fn fun(): string
---@return string
local function with_cmdline_bufpath_maps(origin_buf, fn)
  local keys = { "<Tab>", "<C-Space>", "<C-@>" }
  local prev = {}
  for _, lhs in ipairs(keys) do
    prev[lhs] = get_cmdline_map(lhs)
  end

  local tab_key = vim.api.nvim_replace_termcodes("<Tab>", true, false, true)
  vim.keymap.set("c", "<Tab>", function()
    local line = vim.fn.getcmdline()
    local pos = vim.fn.getcmdpos()
    if pos > 1 and line:sub(pos - 1, pos - 1) == "%" then
      return cmdline_insert_with_bufpath(origin_buf)
    end
    return tab_key
  end, { expr = true, noremap = true, silent = true })

  vim.keymap.set("c", "<C-Space>", function()
    return cmdline_insert_with_bufpath(origin_buf)
  end, { expr = true, noremap = true, silent = true })

  vim.keymap.set("c", "<C-@>", function()
    return cmdline_insert_with_bufpath(origin_buf)
  end, { expr = true, noremap = true, silent = true })

  local ok, result = pcall(fn)

  for _, lhs in ipairs(keys) do
    restore_cmdline_map(lhs, prev[lhs])
  end

  if not ok then
    error(result)
  end
  return result
end

---@param opts { prompt: string, default?: string, completion?: string, origin_buf?: integer }
---@param cb fun(input: string?)
---@return nil
function M.input_command(opts, cb)
  local origin_buf = opts.origin_buf or vim.api.nvim_get_current_buf()
  vim.schedule(function()
    local ok, result = pcall(function()
      return with_cmdline_bufpath_maps(origin_buf, function()
        return vim.fn.input({
          prompt = opts.prompt,
          default = opts.default or "",
          completion = opts.completion or "file",
        })
      end)
    end)
    if not ok then
      cb(nil) -- interrupted (e.g. Ctrl-C)
      return
    end
    cb(result)
  end)
end

-- Layout functions (same semantics as existing module)
---@type table<string, fun(buf: integer, title: string): integer>
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

  vsplit = function(buf, _)
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

  split = function(buf, _)
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

---@param serialized_config table
---@return fun(buf: integer, title: string): integer
local function create_serialized_window_function(serialized_config)
  return function(buf, _)
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

local function serialize_and_create_closure()
  if M.state.layout ~= "floating" and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    local config = vim.api.nvim_win_get_config(M.state.win)
    M.state.create_window = create_serialized_window_function(config)
  else
    M.state.create_window = layout_functions[M.state.layout]
  end
end

---@param id JobId
---@return JobId
local function resolve_job_id(id)
  if M.state.jobs[id] ~= nil then
    return id
  end
  return tostring(id)
end

---@param runtime? JobRuntime
---@return boolean
local function runtime_is_valid(runtime)
  if not runtime or not runtime.buffer then
    return false
  end
  if runtime.config.external_terminal then
    return kitty.window_exists(runtime.buffer)
  end
  return vim.api.nvim_buf_is_valid(runtime.buffer)
end

---@param id JobId
---@return JobId key, JobInfo job
local function ensure_job(id)
  local key = resolve_job_id(id)
  local job = M.state.jobs[key]
  if not job then
    ---@type JobInfo
    job = {
      status = "defined",
      config = normalize_config(nil),
      runtime = nil,
      exit_code = nil,
      generation = 0,
      dirty = false,
    }
    M.state.jobs[key] = job
  end
  return key, job
end

---@param id JobId
---@return JobInfo?
function M.get_job(id)
  local _, job = ensure_job(id)
  return job
end

---@param id JobId
---@param config JobConfig
---@return JobInfo
function M.define_job(id, config)
  local _, job = ensure_job(id)
  job.config = normalize_config(config)
  job.dirty = job.runtime ~= nil and not configs_equal(job.config, job.runtime.config) or false
  if job.status == "killed" then
    job.status = "defined"
  end
  return job
end

---@param id JobId
---@return nil
function M.delete_job(id)
  local key = resolve_job_id(id)
  local job = M.state.jobs[key]
  if not job then
    return
  end
  -- Best-effort cleanup of runtime
  if job.runtime and runtime_is_valid(job.runtime) then
    if job.runtime.config.external_terminal then
      kitty.close_window(job.runtime.buffer)
    else
      pcall(vim.api.nvim_buf_delete, job.runtime.buffer, { force = true })
    end
  end
  M.state.jobs[key] = nil
  if M.state.current_job_id == key then
    M.state.current_job_id = nil
  end
end

-- Public API parity helpers -------------------------------------------------

---@param include_killed? boolean
function M.count(include_killed)
  local n = 0
  for _, job in pairs(M.state.jobs) do
    if include_killed or job.status ~= "killed" then
      n = n + 1
    end
  end
  return n
end

function M.get_current()
  return M.state.current_job_id
end

-- Status / display ----------------------------------------------------------

---@param job JobInfo
---@return string
local function get_status_icon(job)
  if job.dirty then
    return "✱"
  end
  if job.status == "running" then
    return "⚡"
  elseif job.status == "exited" then
    if job.exit_code == 0 then
      return "✓"
    end
    return "✗"
  elseif job.status == "defined" then
    return "○"
  elseif job.status == "killed" then
    return "❌"
  end
  return "?"
end

---@param cfg JobConfig
---@return string
local function focus_display(cfg)
  if cfg.focus == "auto" then
    return "auto"
  end
  return cfg.focus and "yes" or "no"
end

-- Runtime start/stop --------------------------------------------------------

---@param id JobId
---@param job JobInfo
---@return nil
local function attach_buf_cleanup(id, job)
  local runtime = job.runtime
  if not runtime or not runtime.buffer or runtime.config.external_terminal then
    return
  end
  local buf = runtime.buffer
  local gen = runtime.generation

  vim.api.nvim_buf_set_var(buf, "mnf_job_id", tostring(id))
  vim.api.nvim_buf_set_var(buf, "mnf_job_gen", gen)

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      local _, j = ensure_job(id)
      if not j.runtime or j.runtime.generation ~= gen or j.runtime.buffer ~= buf then
        return
      end
      serialize_and_create_closure()
      j.runtime = nil
      j.status = (j.status == "killing") and "killed" or "killed"
      j.dirty = false
      if M.state.current_job_id == id then
        M.state.current_job_id = nil
      end
    end,
  })
end

---@param id JobId
---@param job JobInfo
---@param cmd_expanded string
---@return nil
local function start_internal_terminal(id, job, cmd_expanded)
  local cfg = job.config
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false

  job.status = "creating"
  job.generation = job.generation + 1
  job.exit_code = nil
  job.runtime = {
    buffer = buf,
    system_job_id = nil,
    config = vim.deepcopy(cfg),
    generation = job.generation,
  }
  job.dirty = false

  -- Make this buffer "terminal-ready" without forcing a split.
  vim.api.nvim_buf_call(buf, function()
    vim.opt_local.spell = false
    local term_job_id = vim.fn.termopen(vim.o.shell, {
      on_exit = function(_, exit_code, _)
        local _, j = ensure_job(id)
        if not j.runtime or j.runtime.generation ~= job.generation then
          return
        end
        j.status = "exited"
        j.exit_code = exit_code
      end,
    })
    job.runtime.system_job_id = term_job_id
  end)

  job.status = "running"
  attach_buf_cleanup(id, job)

  -- Send initial command (if provided).
  if cmd_expanded ~= "" and cmd_expanded ~= vim.o.shell then
    vim.defer_fn(function()
      if not job.runtime or not runtime_is_valid(job.runtime) then
        return
      end
      local channel = vim.bo[buf].channel
      if channel and channel > 0 then
        vim.api.nvim_chan_send(channel, cmd_expanded .. "\n")
      end
    end, 100)
  end
end

---@param id JobId
---@param job JobInfo
---@param cmd_expanded string
---@return nil
local function start_internal_capture(id, job, cmd_expanded)
  local cfg = job.config
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = false

  job.status = "creating"
  job.generation = job.generation + 1
  job.exit_code = nil
  job.runtime = {
    buffer = buf,
    system_job_id = nil,
    config = vim.deepcopy(cfg),
    generation = job.generation,
  }
  job.dirty = false

  local function append(lines, prefix)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.bo[buf].modifiable = true
    local out = lines
    if prefix then
      out = {}
      for _, line in ipairs(lines) do
        if line ~= "" then
          out[#out + 1] = prefix .. line
        else
          out[#out + 1] = line
        end
      end
    end
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, out)
    vim.bo[buf].modifiable = false

    if M.state.current_job_id == id and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
      local line_count = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_win_set_cursor(M.state.win, { line_count, 0 })
    end
  end

  job.runtime.system_job_id = vim.fn.jobstart(cmd_expanded, {
    on_stdout = function(_, data, _)
      vim.schedule(function()
        if job.runtime and job.runtime.generation == job.generation then
          append(data)
        end
      end)
    end,
    on_stderr = function(_, data, _)
      vim.schedule(function()
        if job.runtime and job.runtime.generation == job.generation then
          append(data, "[ERROR] ")
        end
      end)
    end,
    on_exit = function(_, exit_code, _)
      local _, j = ensure_job(id)
      if not j.runtime or j.runtime.generation ~= job.generation then
        return
      end
      j.status = "exited"
      j.exit_code = exit_code
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.bo[buf].modifiable = true
          vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", "=== Job exited with code " .. exit_code .. " ===" })
          vim.bo[buf].modifiable = false
        end
      end)
    end,
  })

  job.status = "running"
  attach_buf_cleanup(id, job)
end

---@param id JobId
---@param job JobInfo
---@param cmd_expanded string
---@return nil
local function start_external(id, job, cmd_expanded)
  local cfg = job.config
  local launch_cmd = cfg.use_terminal and vim.o.shell or cmd_expanded
  local ok, window_id = kitty.create_window(launch_cmd, "down")
  if not ok then
    notify("Failed to create external terminal: " .. tostring(window_id), vim.log.levels.ERROR)
    return
  end

  job.status = "running"
  job.generation = job.generation + 1
  job.exit_code = nil
  job.runtime = {
    buffer = window_id,
    system_job_id = nil,
    config = vim.deepcopy(cfg),
    generation = job.generation,
  }
  job.dirty = false

  if cfg.use_terminal and cmd_expanded ~= "" and cmd_expanded ~= vim.o.shell then
    kitty.send_command(window_id, cmd_expanded)
  end
end

---@param id JobId
---@return nil
function M.start_job(id)
  local key, job = ensure_job(id)
  id = key

  if job.status == "running" and job.runtime and runtime_is_valid(job.runtime) then
    notify("Job[" .. id .. "] is already running", vim.log.levels.WARN)
    return
  end

  if job.runtime and not runtime_is_valid(job.runtime) then
    job.runtime = nil
    job.status = "defined"
  end

  local origin_buf = vim.api.nvim_get_current_buf()
  local cmd_raw = job.config.command
  local cmd_expanded = vim.api.nvim_buf_call(origin_buf, function()
    return vim.fn.expandcmd(cmd_raw)
  end)

  if job.config.external_terminal then
    start_external(id, job, cmd_expanded)
  elseif job.config.use_terminal then
    start_internal_terminal(id, job, cmd_expanded)
  else
    if cmd_expanded == "" then
      notify("Job[" .. id .. "]: capture mode requires a command", vim.log.levels.WARN)
      return
    end
    start_internal_capture(id, job, cmd_expanded)
  end

  M.state.current_job_id = id

  if not job.config.silent then
    M.show_job(id)
  end
end

---@param id JobId
---@return nil
function M.kill_job(id)
  local key, job = ensure_job(id)
  id = key

  if not job.runtime or not runtime_is_valid(job.runtime) then
    job.runtime = nil
    job.status = "killed"
    job.dirty = false
    return
  end

  job.status = "killing"
  if job.runtime.config.external_terminal then
    kitty.close_window(job.runtime.buffer)
    job.runtime = nil
    job.status = "killed"
    job.dirty = false
  else
    local buf = job.runtime.buffer
    if job.runtime.system_job_id then
      vim.fn.jobstop(job.runtime.system_job_id)
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

---@param id JobId
---@param quiet? boolean
---@return nil
function M.restart_job(id, quiet)
  local key, job = ensure_job(id)
  id = key
  M.kill_job(id)
  -- If it was internal, BufWipeout will clean runtime; external is immediate.
  vim.defer_fn(function()
    local _, j = ensure_job(id)
    M.start_job(id)
    if quiet or j.config.silent then
      return
    end
    M.show_job(id)
  end, 50)
end

function M.kill_current_job()
  if not M.state.current_job_id then
    notify("No current job selected", vim.log.levels.WARN)
    return
  end
  M.kill_job(M.state.current_job_id)
end

-- Show / list / toggle ------------------------------------------------------

---@param id JobId
---@return nil
function M.show_job(id)
  local key, job = ensure_job(id)
  id = key
  M.state.current_job_id = id

  if not job.runtime or not runtime_is_valid(job.runtime) then
    notify("Job[" .. id .. "] is not running (or has no buffer yet)", vim.log.levels.WARN)
    return
  end

  -- External terminals: optionally focus kitty window.
  if job.runtime.config.external_terminal then
    if should_focus(job.runtime.config) then
      kitty.focus_window(job.runtime.buffer)
    else
      notify("Job[" .. id .. "] is external (focus disabled by config)", vim.log.levels.INFO)
    end
    return
  end

  local original_win = vim.api.nvim_get_current_win()
  if not (M.state.win and vim.api.nvim_win_is_valid(M.state.win)) then
    M.state.win = M.state.create_window(job.runtime.buffer, "Job[" .. id .. "]")
  else
    vim.api.nvim_win_set_buf(M.state.win, job.runtime.buffer)
  end

  if should_focus(job.runtime.config) then
    vim.api.nvim_set_current_win(M.state.win)
    if job.runtime.config.use_terminal then
      vim.cmd("startinsert")
    end
  else
    vim.api.nvim_set_current_win(original_win)
  end
end

function M.list_jobs()
  local items = {}
  for job_id, job in pairs(M.state.jobs) do
    -- Refresh validity (external windows can be closed out-of-band)
    if job.runtime and not runtime_is_valid(job.runtime) then
      job.runtime = nil
      job.status = (job.status == "running") and "killed" or job.status
    end
    job.dirty = job.runtime ~= nil and not configs_equal(job.config, job.runtime.config) or false

    local cfg = job.config
    local status_icon = get_status_icon(job)
    local pty_icon = cfg.use_terminal and "🖥️" or "📋"
    local location_icon = cfg.external_terminal and "🌐" or "🏠"
    local silent_icon = cfg.silent and "🔇" or ""
    local focus_icon = should_focus(cfg) and "🎯" or ""
    local current_dot = (M.state.current_job_id == job_id) and "• " or "  "

    local cmd_display = cfg.command ~= "" and cfg.command or "shell"
    local exit_info = ""
    if job.status == "exited" and job.exit_code and job.exit_code ~= 0 then
      exit_info = " (exit:" .. job.exit_code .. ")"
    end

    local display = string.format(
      "%s%s %s%s%s%s Job[%s]: %s (%s)%s",
      current_dot,
      status_icon,
      pty_icon,
      location_icon,
      silent_icon,
      focus_icon,
      job_id,
      cmd_display,
      job.status,
      exit_info
    )

    items[#items + 1] = { display = display, job_id = job_id }
  end

  if #items == 0 then
    notify("No jobs defined", vim.log.levels.WARN)
    return
  end

  table.sort(items, function(a, b)
    return tostring(a.job_id) < tostring(b.job_id)
  end)

  vim.ui.select(items, {
    prompt = "Select Job:",
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if not choice then
      return
    end
    local _, job = ensure_job(choice.job_id)
    if job.runtime and runtime_is_valid(job.runtime) then
      M.show_job(choice.job_id)
    else
      M.configure_job(choice.job_id)
    end
  end)
end

function M.toggle()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    serialize_and_create_closure()
    vim.api.nvim_win_close(M.state.win, false)
    M.state.win = nil
    return
  end

  if M.state.current_job_id then
    M.show_job(M.state.current_job_id)
  else
    M.list_jobs()
  end
end

function M.toggle_layout()
  if M.state.layout == "floating" then
    M.state.layout = "split"
  elseif M.state.layout == "split" then
    M.state.layout = "vsplit"
  else
    M.state.layout = "floating"
  end
  M.state.create_window = layout_functions[M.state.layout]
  if not (M.state.win and vim.api.nvim_win_is_valid(M.state.win)) then
    notify("Job layout: " .. M.state.layout)
    return
  end

  local _, job = ensure_job(M.state.current_job_id)
  if not job.runtime or not runtime_is_valid(job.runtime) or job.runtime.config.external_terminal then
    return
  end

  serialize_and_create_closure()
  vim.api.nvim_win_close(M.state.win, false)
  M.state.win = M.state.create_window(job.runtime.buffer, "Job[" .. tostring(M.state.current_job_id) .. "]")
  if should_focus(job.runtime.config) and job.runtime.config.use_terminal then
    vim.api.nvim_set_current_win(M.state.win)
    vim.cmd("startinsert")
  end
  notify("Job layout: " .. M.state.layout)
end

-- Configure UI --------------------------------------------------------------

---@param id JobId
---@param initial JobConfig
---@param opts { running: boolean }
---@param callback fun(action: "save"|"save_start"|"save_restart"|"cancel", config: JobConfig): nil
local function configure_job_ui(id, initial, opts, callback)
  local config = normalize_config(initial)
  local origin_buf = vim.api.nvim_get_current_buf()

  M.input_command({
    prompt = "Command for job " .. tostring(id) .. " (empty for shell; % + <Tab>/<C-Space> = buffer path): ",
    default = config.command,
    completion = "file",
    origin_buf = origin_buf,
  }, function(command_str)
    if command_str == nil then
      callback("cancel", config)
      return
    end
    config.command = vim.trim(command_str)

    local menu_options = {
      { text = "💾 Save (don't start)", type = "action", value = "save" },
      { text = opts.running and "🔁 Save & restart" or "▶️ Save & start", type = "action", value = "run" },
      { text = "✗ Cancel", type = "action", value = "cancel" },

      { text = "🖥️  Terminal buffer (interactive)", type = "buffer", value = { use_terminal = true } },
      { text = "📋  Output buffer (capture output)", type = "buffer", value = { use_terminal = false } },

      { text = "🏠  Internal (neovim buffer/window)", type = "location", value = { external_terminal = false } },
      { text = "🌐  External (kitty window)", type = "location", value = { external_terminal = true } },

      { text = "🔇  Silent (don't auto-open)", type = "open", value = { silent = true } },
      { text = "🔊  Open on start", type = "open", value = { silent = false } },

      { text = "🎯  Focus: auto (term=yes, capture=no)", type = "focus", value = { focus = "auto" } },
      { text = "🎯  Focus: yes", type = "focus", value = { focus = true } },
      { text = "🎯  Focus: no", type = "focus", value = { focus = false } },
    }

    local function show_menu()
      local cmd_display = config.command == "" and "shell" or config.command
      local buffer_display = config.use_terminal and "terminal" or "capture"
      local location_display = config.external_terminal and "external" or "internal"
      local open_display = config.silent and "silent" or "open"
      local focus_mode = focus_display(config)
      local prompt = string.format(
        "Job[%s]: %s (%s, %s, %s, focus=%s)",
        tostring(id),
        cmd_display,
        buffer_display,
        location_display,
        open_display,
        focus_mode
      )

      vim.ui.select(menu_options, {
        prompt = prompt,
        format_item = function(item)
          local prefix = ""
          if item.type == "buffer" then
            prefix = (config.use_terminal == item.value.use_terminal) and "● " or "○ "
          elseif item.type == "location" then
            prefix = (config.external_terminal == item.value.external_terminal) and "● " or "○ "
          elseif item.type == "open" then
            prefix = (config.silent == item.value.silent) and "● " or "○ "
          elseif item.type == "focus" then
            prefix = (config.focus == item.value.focus) and "● " or "○ "
          end
          return prefix .. item.text
        end,
      }, function(choice)
        if not choice then
          callback("cancel", config)
          return
        end

        if choice.type == "buffer" then
          config.use_terminal = choice.value.use_terminal
          show_menu()
        elseif choice.type == "location" then
          config.external_terminal = choice.value.external_terminal
          show_menu()
        elseif choice.type == "open" then
          config.silent = choice.value.silent
          show_menu()
        elseif choice.type == "focus" then
          config.focus = choice.value.focus
          show_menu()
        elseif choice.type == "action" then
          if choice.value == "save" then
            callback("save", normalize_config(config))
          elseif choice.value == "run" then
            callback(opts.running and "save_restart" or "save_start", normalize_config(config))
          else
            callback("cancel", config)
          end
        end
      end)
    end

    show_menu()
  end)
end

---@param id JobId
---@return nil
function M.configure_job(id)
  local key, job = ensure_job(id)
  id = key

  -- Quick menu when job exists (parity with existing module)
  local running = job.runtime ~= nil and runtime_is_valid(job.runtime) and job.status == "running"
  if job.config and job.config.command ~= nil then
    local options = {
      running and "🔄 Restart job" or "▶️ Start job",
      "🔎 View job",
      "⚙️ Configure job",
      "🗑️ Delete job definition",
      "❌ Cancel",
    }
    vim.ui.select(options, { prompt = "Job[" .. tostring(id) .. "]" }, function(choice)
      if not choice or choice:match("Cancel") then
        return
      end

      if choice:match("Start") then
        M.start_job(id)
        return
      end
      if choice:match("Restart") then
        M.restart_job(id)
        return
      end
      if choice:match("View") then
        M.show_job(id)
        return
      end
      if choice:match("Delete") then
        M.delete_job(id)
        return
      end

      configure_job_ui(id, job.config, { running = running }, function(action, cfg)
        if action == "cancel" then
          return
        end
        M.define_job(id, cfg)
        if action == "save_start" then
          M.start_job(id)
        elseif action == "save_restart" then
          M.restart_job(id)
        else
          notify("Saved Job[" .. tostring(id) .. "] (not started)")
        end
      end)
    end)
    return
  end

  -- Should not happen (ensure_job always sets config), but keep for safety.
  configure_job_ui(id, normalize_config(nil), { running = false }, function(action, cfg)
    if action == "cancel" then
      return
    end
    M.define_job(id, cfg)
    if action == "save_start" then
      M.start_job(id)
    else
      notify("Saved Job[" .. tostring(id) .. "] (not started)")
    end
  end)
end

-- Send helpers --------------------------------------------------------------

---@param text string
---@return nil
function M.send_text(text)
  if not M.state.current_job_id then
    notify("No current job selected", vim.log.levels.WARN)
    return
  end

  local _, job = ensure_job(M.state.current_job_id)
  if not job.runtime or not runtime_is_valid(job.runtime) then
    notify("Current job is not running", vim.log.levels.WARN)
    return
  end

  if not job.runtime.config.use_terminal then
    notify("Current job is not interactive (not a terminal)", vim.log.levels.WARN)
    return
  end

  if job.runtime.config.external_terminal then
    kitty.send_text(job.runtime.buffer, text)
    return
  end

  local channel = vim.bo[job.runtime.buffer].channel
  if not channel or channel <= 0 then
    notify("Terminal channel not ready", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_chan_send(channel, text)
end

function M.send_selection()
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

  if not lines then
    return
  end
  local text = table.concat(lines, "\n") .. "\n"
  local bracketed = "\027[200~" .. text .. "\027[201~" .. "\n"
  M.send_text(bracketed)
end

function M.send_line()
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, true)
  M.send_text(table.concat(lines, "\n") .. "\n")
end

function M.send_file()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  local text = table.concat(lines, "\n") .. "\n"
  local bracketed = "\027[200~" .. text .. "\027[201~" .. "\n"
  M.send_text(bracketed)
end

-- Session persistence --------------------------------------------------------
-- Semantics:
-- - Save *definitions* (JobConfig) + minimal UI state (layout/current id).
-- - Do NOT save/restore runtimes (terminal buffers, external kitty windows, running processes).

local SESSION_VERSION = 1

---@param session_path? string
---@return string? sidecar_path
local function session_sidecar_path(session_path)
  session_path = session_path or vim.v.this_session
  if not session_path or session_path == "" then
    return nil
  end
  if session_path:sub(-4) == ".vim" then
    session_path = session_path:sub(1, -5)
  end
  return session_path .. ".mnf-jobs.json"
end

---@return boolean
local function has_running_jobs()
  for _, job in pairs(M.state.jobs) do
    if job.runtime and runtime_is_valid(job.runtime) and job.status == "running" then
      return true
    end
  end
  return false
end

---@class MnfJobsSessionPayload
---@field version integer
---@field jobs table<string, JobConfig>
---@field state { layout?: string, current_job_id?: string }

---@return MnfJobsSessionPayload
function M.session_encode()
  ---@type table<string, JobConfig>
  local jobs = {}
  for id, job in pairs(M.state.jobs) do
    jobs[tostring(id)] = normalize_config(job.config)
  end

  return {
    version = SESSION_VERSION,
    jobs = jobs,
    state = {
      layout = M.state.layout,
      current_job_id = M.state.current_job_id and tostring(M.state.current_job_id) or nil,
    },
  }
end

---@param payload MnfJobsSessionPayload
---@param opts? { replace?: boolean, force?: boolean }
---@return nil
function M.session_apply(payload, opts)
  opts = opts or {}
  if type(payload) ~= "table" then
    notify("jobs_refactor: invalid session payload", vim.log.levels.WARN)
    return
  end
  if payload.version ~= SESSION_VERSION then
    notify(
      ("jobs_refactor: session payload version mismatch (got %s, expected %s)"):format(
        tostring(payload.version),
        tostring(SESSION_VERSION)
      ),
      vim.log.levels.WARN
    )
  end

  local replace = opts.replace ~= false
  if replace and has_running_jobs() and not opts.force then
    replace = false
    notify("jobs_refactor: running jobs detected; session load merged (use force=true to replace)", vim.log.levels.WARN)
  end

  if replace then
    if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
      serialize_and_create_closure()
      pcall(vim.api.nvim_win_close, M.state.win, false)
    end
    M.state.win = nil
    M.state.current_job_id = nil
    M.state.jobs = {}
  end

  for id, cfg in pairs(payload.jobs or {}) do
    M.define_job(id, normalize_config(cfg))
  end

  if payload.state and type(payload.state) == "table" then
    local layout = payload.state.layout
    if type(layout) == "string" and layout_functions[layout] then
      M.state.layout = layout
      M.state.create_window = layout_functions[layout]
    end
    local current = payload.state.current_job_id
    if current and payload.jobs and payload.jobs[current] then
      M.state.current_job_id = current
    end
  end
end

---@param opts? { session_path?: string, quiet?: boolean }
---@return boolean ok, string? path_or_error
function M.session_save(opts)
  opts = opts or {}
  local sidecar = session_sidecar_path(opts.session_path)
  if not sidecar then
    local msg = "jobs_refactor: no active session (vim.v.this_session is empty)"
    if not opts.quiet then
      notify(msg, vim.log.levels.WARN)
    end
    return false, msg
  end

  local ok, json = pcall(vim.json.encode, M.session_encode())
  if not ok then
    notify("jobs_refactor: failed to encode session payload", vim.log.levels.ERROR)
    return false, "encode failed"
  end

  local write_ok, err = pcall(vim.fn.writefile, { json }, sidecar)
  if not write_ok then
    notify("jobs_refactor: failed to write " .. sidecar .. ": " .. tostring(err), vim.log.levels.ERROR)
    return false, tostring(err)
  end

  if not opts.quiet then
    notify("jobs_refactor: saved jobs to " .. sidecar, vim.log.levels.DEBUG)
  end
  return true, sidecar
end

---@param opts? { session_path?: string, replace?: boolean, force?: boolean, quiet?: boolean }
---@return boolean ok, string? path_or_error
function M.session_load(opts)
  opts = opts or {}
  local sidecar = session_sidecar_path(opts.session_path)
  if not sidecar then
    local msg = "jobs_refactor: no active session (vim.v.this_session is empty)"
    if not opts.quiet then
      notify(msg, vim.log.levels.WARN)
    end
    return false, msg
  end

  local ok, lines = pcall(vim.fn.readfile, sidecar)
  if not ok or not lines or #lines == 0 then
    local msg = "jobs_refactor: no saved jobs found at " .. sidecar
    if not opts.quiet then
      notify(msg, vim.log.levels.DEBUG)
    end
    return false, msg
  end

  local json = table.concat(lines, "\n")
  local decode_ok, payload = pcall(vim.json.decode, json)
  if not decode_ok then
    notify("jobs_refactor: failed to decode " .. sidecar, vim.log.levels.ERROR)
    return false, "decode failed"
  end

  M.session_apply(payload, { replace = opts.replace, force = opts.force })
  if not opts.quiet then
    notify("jobs_refactor: loaded jobs from " .. sidecar, vim.log.levels.DEBUG)
  end
  return true, sidecar
end

---@param opts? { autosave?: boolean, autoload?: boolean }
---@return nil
function M.setup_session(opts)
  opts = opts or {}
  local autosave = opts.autosave ~= false
  local autoload = opts.autoload ~= false

  local group = vim.api.nvim_create_augroup("mnf_jobs_refactor_session", { clear = true })

  if autosave then
    vim.api.nvim_create_autocmd("SessionWritePost", {
      group = group,
      callback = function(event)
        M.session_save({ quiet = true, session_path = event.file })
      end,
      desc = "Persist jobs_refactor definitions alongside :mksession",
    })
  end

  if autoload then
    vim.api.nvim_create_autocmd("SessionLoadPost", {
      group = group,
      callback = function(event)
        M.session_load({ quiet = true, replace = true, session_path = event.file })
      end,
      desc = "Restore jobs_refactor definitions after loading a session",
    })
  end
end

return M
