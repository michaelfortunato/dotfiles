-- Scratch runner UX for Python scratch buffers.
--
-- Goal: replicate Folke's "inline ghost output" + visual selection semantics from
-- `snacks/debug.lua:Snacks.debug.run()`, but keep all code in your config.
--
-- Default execution backend uses `uv run`, so it does NOT depend on Neovim's
-- Python provider (`:python3` / `:checkhealth provider`).
--
-- If you later want a true Jupyter kernel, keep the same `ctx` interface and
-- replace `M.exec`.

---@class MNF.Scratch.Python
local M = {}

local ns = vim.api.nvim_create_namespace("mnf_scratch_python_v2")

---@class MNF.Scratch.Python.BufState
---@field run_id integer
local buf_state = {} ---@type table<number, MNF.Scratch.Python.BufState>

---@param buf number
---@return integer
local function bump_run_id(buf)
  local state = buf_state[buf]
  if not state then
    state = { run_id = 0 }
    buf_state[buf] = state
  end
  state.run_id = state.run_id + 1
  return state.run_id
end

---@param buf number
---@param run_id integer
---@return boolean
local function is_current_run(buf, run_id)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local state = buf_state[buf]
  return state and state.run_id == run_id or false
end

---@type fun(buf:number):integer
local drop_queued_for_buf

local function setup_hl()
  vim.api.nvim_set_hl(0, "MnfScratchPythonIndent", { link = "LineNr", default = true })
  vim.api.nvim_set_hl(0, "MnfScratchPythonPrint", { link = "NonText", default = true })
  vim.api.nvim_set_hl(0, "MnfScratchPythonError", { link = "DiagnosticError", default = true })
end

setup_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  desc = "MNF scratch python highlights",
  callback = setup_hl,
})

---@param buf number
local function reset(buf)
  vim.diagnostic.reset(ns, buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if vim.g.mnf_scratch_python_plots ~= 0 then
    pcall(function()
      require("snacks").image.placement.clean(buf)
    end)
  end
end

---@param buf number
---@param line integer 1-based
---@param text string
---@param stream? "stdout"|"stderr"
local function ghost(buf, line, text, stream)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local hl = stream == "stderr" and "MnfScratchPythonError" or "MnfScratchPythonPrint"
  ---@type string[][][]
  local virt_lines = {}
  for _, l in ipairs(vim.split(text, "\n", { plain = true })) do
    virt_lines[#virt_lines + 1] = { { "  │ ", "MnfScratchPythonIndent" }, { l, hl } }
  end
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, math.max(line - 1, 0), 0, { virt_lines = virt_lines })
    end
  end)
end

---@param buf number
---@param line integer 1-based
---@param message string
---@param trace? string[]
---@param meta? {run_id?:integer}
local function diag_error(buf, line, message, trace, meta)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local diag_message = message
  if meta and type(meta.run_id) == "number" then
    diag_message = ("run %d: %s"):format(meta.run_id, diag_message)
  end
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.diagnostic.set(ns, buf, {
      { col = 0, lnum = math.max(line - 1, 0), message = diag_message, severity = vim.diagnostic.severity.ERROR },
    })
    if type(trace) == "table" and #trace > 0 then
      ghost(buf, line, table.concat(trace, "\n"), "stderr")
    else
      ghost(buf, line, diag_message, "stderr")
    end
  end)
end

---@param buf number
---@param line integer 1-based
---@param file string
local function render_image(buf, line, file)
  if vim.g.mnf_scratch_python_plots == 0 then
    return
  end
  if type(file) ~= "string" or file == "" then
    return
  end
  if vim.fn.filereadable(file) ~= 1 then
    ghost(buf, line, ("[plot missing] %s"):format(file), "stderr")
    return
  end

  local ok_snacks, snacks = pcall(require, "snacks")
  if not ok_snacks then
    ghost(buf, line, "[plot] snacks.nvim not available", "stderr")
    return
  end

  -- Ensure terminal capabilities are detected before placing images.
  snacks.image.terminal.detect(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local win = vim.fn.win_findbuf(buf)[1]
    local win_w = win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_width(win) or vim.o.columns
    local win_h = win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_height(win) or vim.o.lines
    local max_w = vim.g.mnf_scratch_python_plot_max_width or math.max(20, math.floor(win_w * 0.5))
    local max_h = vim.g.mnf_scratch_python_plot_max_height or math.max(6, math.floor(win_h * 0.35))

    -- Anchor at column 0 and render below the line via Snacks.image placeholder grid.
    -- We use a zero-width range at (line,0) so the code line stays intact.
    pcall(snacks.image.placement.new, buf, file, {
      inline = true,
      auto_resize = true,
      type = "chart",
      pos = { line, 0 },
      range = { line, 0, line, 0 },
      conceal = false,
      max_width = max_w,
      max_height = max_h,
    })
  end)
end

-- Selection semantics copied from `Snacks.debug.run()`:
-- - Normal mode: whole buffer
-- - Visual/Visual-line: exact selection; prepend empty lines so line numbers align
-- - Visual-block: yank selection for ragged blocks; prepend empty lines; restore selection
---@param buf number
---@return string[] lines, integer anchor_line
local function get_lines(buf)
  local lines ---@type string[]
  local anchor = vim.api.nvim_buf_line_count(buf)
  local mode = vim.fn.mode()

  if mode:find("[vV]") then
    if mode == "v" then
      vim.cmd("normal! v")
    elseif mode == "V" then
      vim.cmd("normal! V")
    end
    local from = vim.api.nvim_buf_get_mark(buf, "<")
    local to = vim.api.nvim_buf_get_mark(buf, ">")
    anchor = to[1]

    -- Sometimes the column is off by one (Folke references #190).
    local col_to = math.min(to[2] + 1, #vim.api.nvim_buf_get_lines(buf, to[1] - 1, to[1], false)[1])
    lines = vim.api.nvim_buf_get_text(buf, from[1] - 1, from[2], to[1] - 1, col_to, {})

    for _ = 1, from[1] - 1 do
      table.insert(lines, 1, "")
    end
    vim.fn.feedkeys("gv", "nx")
  elseif mode == "\22" then
    local tmp = vim.fn.getreginfo("*")
    vim.cmd('normal! "*y')
    lines = vim.fn.getreginfo("*").regcontents
    vim.fn.setreg("*", tmp.regcontents, tmp.regtype)

    local from = vim.api.nvim_buf_get_mark(buf, "<")
    local to = vim.api.nvim_buf_get_mark(buf, ">")
    anchor = to[1]

    for _ = 1, from[1] - 1 do
      table.insert(lines, 1, "")
    end
    vim.fn.feedkeys("gv", "nx")
  else
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    anchor = vim.api.nvim_buf_line_count(buf)
  end

  return lines, anchor
end

---@param buf number
local function ensure_reset_autocmd(buf)
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = vim.api.nvim_create_augroup("mnf_scratch_python_reset_" .. buf, { clear = true }),
    buffer = buf,
    callback = function()
      reset(buf)
      bump_run_id(buf)
      if type(drop_queued_for_buf) == "function" then
        drop_queued_for_buf(buf)
      end
    end,
  })
end

---@return string? runner, string? err
local function uv_runner()
  local matches = vim.api.nvim_get_runtime_file("python/mnf_scratch_uv_runner_v2.py", false)
  local runner = matches and matches[1]
  if type(runner) ~= "string" or runner == "" then
    return nil, "python/mnf_scratch_uv_runner_v2.py not found on runtimepath"
  end
  return runner, nil
end

---@class MNF.Scratch.Python.UvSessionItem
---@field ctx {buf:number,code:string,anchor:number,out:fun(text:string,line?:number,stream?:"stdout"|"stderr"),err:fun(message:string,line?:number,trace?:string[])}
---@field request string
---@field root string
---@field runner string
---@field uv_cache_dir string

---@class MNF.Scratch.Python.UvSession
---@field jobid integer|nil
---@field epoch integer
---@field busy boolean
---@field current MNF.Scratch.Python.UvSessionItem|nil
---@field queue MNF.Scratch.Python.UvSessionItem[]
---@field partial string
---@field stderr string[]
---@field stopping boolean
---@field root string|nil
---@field runner string|nil
---@field uv_cache_dir string|nil
local uv_session = {
  jobid = nil,
  epoch = 0,
  busy = false,
  current = nil,
  queue = {},
  partial = "",
  stderr = {},
  stopping = false,
  root = nil,
  runner = nil,
  uv_cache_dir = nil,
}

---@type fun():nil
local drain_uv_queue

drop_queued_for_buf = function(buf)
  if #uv_session.queue == 0 then
    return 0
  end
  local dropped = 0
  local next_queue = {} ---@type MNF.Scratch.Python.UvSessionItem[]
  for _, it in ipairs(uv_session.queue) do
    if it and it.ctx and it.ctx.buf == buf then
      dropped = dropped + 1
    else
      next_queue[#next_queue + 1] = it
    end
  end
  uv_session.queue = next_queue
  return dropped
end

vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
  group = vim.api.nvim_create_augroup("mnf_scratch_python_cleanup", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    buf_state[buf] = nil
    drop_queued_for_buf(buf)
  end,
})

---@param ctx {buf:number,code:string,anchor:number,out:fun(text:string,line?:number,stream?:"stdout"|"stderr"),err:fun(message:string,line?:number,trace?:string[])}
---@param events unknown
local function handle_events(ctx, events)
  if type(events) ~= "table" then
    return
  end

  for _, ev in ipairs(events) do
    if type(ev) == "table" and ev.type == "out" then
      ctx.out(ev.text or "", ev.line, ev.stream)
    elseif type(ev) == "table" and ev.type == "error" then
      ctx.err(ev.message or "Python error", ev.line, ev.trace)
    elseif type(ev) == "table" and ev.type == "image" then
      render_image(ctx.buf, tonumber(ev.line) or ctx.anchor, tostring(ev.file or ""))
    end
  end
end

---@param ctx {buf:number,code:string,anchor:number,out:fun(text:string,line?:number,stream?:"stdout"|"stderr"),err:fun(message:string,line?:number,trace?:string[])}
---@param item {request:string,root:string,runner:string,uv_cache_dir:string}
---@param done? fun():nil
local function exec_oneshot(ctx, item, done)
  done = type(done) == "function" and done or function() end
  if type(vim.system) ~= "function" then
    ctx.err("Python scratch: `vim.system` is not available in this Neovim build.", ctx.anchor)
    done()
    return
  end

  local cmd = { "uv", "-q", "--no-progress", "run", "python", item.runner }
  local run_opts = {
    cwd = item.root,
    text = true,
    env = { UV_CACHE_DIR = item.uv_cache_dir },
    stdin = item.request,
  }

  vim.system(cmd, run_opts, function(result)
    vim.schedule(function()
      if not result or result.code ~= 0 then
        local stderr = result and tostring(result.stderr or "") or ""
        local msg = ("uv run failed%s%s"):format(
          result and (" (exit " .. tostring(result.code) .. ")") or "",
          stderr ~= "" and ("\n" .. stderr) or ""
        )
        ctx.err(msg, ctx.anchor)
        done()
        return
      end

      local payload = vim.trim(tostring(result.stdout or ""))
      local decoded_ok, events = pcall(vim.json.decode, payload)
      if not decoded_ok or type(events) ~= "table" then
        ctx.err(
          ("Failed to decode uv runner results.\nstdout:\n%s\n\nstderr:\n%s"):format(
            payload,
            vim.trim(tostring(result.stderr or ""))
          ),
          ctx.anchor
        )
        done()
        return
      end

      handle_events(ctx, events)
      done()
    end)
  end)
end

---@param opts? {keep_current?:boolean, clear_queue?:boolean}
local function stop_uv_session(opts)
  opts = opts or {}

  if uv_session.jobid then
    uv_session.stopping = true
    local jobid = uv_session.jobid
    uv_session.jobid = nil
    uv_session.epoch = uv_session.epoch + 1
    pcall(vim.fn.jobstop, jobid)
    uv_session.stopping = false
  end

  uv_session.partial = ""
  uv_session.stderr = {}

  if opts.clear_queue then
    uv_session.queue = {}
  end
  if not opts.keep_current then
    uv_session.busy = false
    uv_session.current = nil
  end
end

---@param item {request:string,root:string,runner:string,uv_cache_dir:string}
---@return boolean ok, string? err
local function ensure_uv_session(item)
  if uv_session.jobid and uv_session.root == item.root and uv_session.runner == item.runner then
    return true, nil
  end

  if uv_session.jobid and (uv_session.root ~= item.root or uv_session.runner ~= item.runner) then
    stop_uv_session({ clear_queue = true, keep_current = true })
  end

  uv_session.epoch = uv_session.epoch + 1
  local epoch = uv_session.epoch

  uv_session.partial = ""
  uv_session.stderr = {}
  uv_session.root = item.root
  uv_session.runner = item.runner
  uv_session.uv_cache_dir = item.uv_cache_dir

  uv_session.stopping = false

  local cmd = { "uv", "-q", "--no-progress", "run", "python", item.runner, "--server" }

  local jobid = vim.fn.jobstart(cmd, {
    cwd = item.root,
    env = { UV_CACHE_DIR = item.uv_cache_dir },
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data, _)
      if epoch ~= uv_session.epoch or uv_session.stopping then
        return
      end
      if type(data) ~= "table" or #data == 0 then
        return
      end

      local n = #data
      local has_trailing_nl = data[n] == ""
      local last_complete = n - 1

      for i = 1, math.max(last_complete, 0) do
        local line = tostring(data[i] or "")
        if line ~= "" then
          if uv_session.partial ~= "" then
            line = uv_session.partial .. line
            uv_session.partial = ""
          end
          vim.schedule(function()
            if epoch ~= uv_session.epoch or uv_session.stopping then
              return
            end
            local current = uv_session.current
            if not current then
              return
            end

            local decoded_ok, events = pcall(vim.json.decode, line)
            if not decoded_ok or type(events) ~= "table" then
              local stderr = table.concat(uv_session.stderr, "\n")
              current.ctx.err(
                ("Failed to decode persistent uv runner results.\nstdout:\n%s\n\nstderr:\n%s"):format(line, stderr),
                current.ctx.anchor
              )
              stop_uv_session({ keep_current = true })
              exec_oneshot(current.ctx, current, function()
                uv_session.current = nil
                uv_session.busy = false
                vim.schedule(drain_uv_queue)
              end)
              return
            end

            handle_events(current.ctx, events)
            uv_session.current = nil
            uv_session.busy = false
            vim.schedule(drain_uv_queue)
          end)
        end
      end

      if not has_trailing_nl and n > 0 then
        uv_session.partial = uv_session.partial .. tostring(data[n] or "")
      end
    end,
    on_stderr = function(_, data, _)
      if epoch ~= uv_session.epoch or uv_session.stopping then
        return
      end
      if type(data) ~= "table" then
        return
      end
      for _, line in ipairs(data) do
        line = tostring(line or "")
        if line ~= "" then
          uv_session.stderr[#uv_session.stderr + 1] = line
          if #uv_session.stderr > 50 then
            table.remove(uv_session.stderr, 1)
          end
        end
      end
    end,
    on_exit = function(_, code, _)
      vim.schedule(function()
        if epoch ~= uv_session.epoch then
          return
        end
        uv_session.jobid = nil
        uv_session.stopping = false
        uv_session.partial = ""

        local current = uv_session.current
        if not current then
          vim.schedule(drain_uv_queue)
          return
        end

        current.ctx.err(
          ("Python scratch: persistent uv runner exited (code %s); falling back to one-shot."):format(tostring(code)),
          current.ctx.anchor
        )
        exec_oneshot(current.ctx, current, function()
          uv_session.current = nil
          uv_session.busy = false
          vim.schedule(drain_uv_queue)
        end)
      end)
    end,
  })

  if type(jobid) ~= "number" or jobid <= 0 then
    uv_session.jobid = nil
    return false, ("jobstart failed (%s)"):format(tostring(jobid))
  end

  uv_session.jobid = jobid
  return true, nil
end

drain_uv_queue = function()
  if uv_session.busy then
    return
  end

  local next_item = table.remove(uv_session.queue, 1)
  while next_item and (not next_item.ctx or not vim.api.nvim_buf_is_valid(next_item.ctx.buf)) do
    next_item = table.remove(uv_session.queue, 1)
  end
  if not next_item then
    return
  end

  uv_session.current = next_item
  uv_session.busy = true

  local function finish()
    uv_session.current = nil
    uv_session.busy = false
    vim.schedule(drain_uv_queue)
  end

  local ok = ensure_uv_session(next_item)
  if not ok or not uv_session.jobid then
    exec_oneshot(next_item.ctx, next_item, finish)
    return
  end

  uv_session.stderr = {}
  uv_session.partial = ""

  local ok_send = pcall(vim.fn.chansend, uv_session.jobid, next_item.request .. "\n")
  if not ok_send then
    stop_uv_session({ keep_current = true })
    exec_oneshot(next_item.ctx, next_item, finish)
    return
  end
end

-- Hook point: provide a persistent Jupyter kernel implementation.
--
-- Suggested shape:
-- `M.exec = function(ctx)`
-- where ctx includes:
--   - ctx.buf (scratch buffer)
--   - ctx.code (string; includes prepended empty lines for correct line numbers)
--   - ctx.anchor (1-based line to pin output when you can't map it precisely)
--   - ctx.out(text, line?, stream?) -> renders ghost output
--   - ctx.err(message, line?, traceback_lines?) -> diagnostic + optional notify
--
-- Your Jupyter plumbing can be:
--   - Lua -> python helper job (jupyter_client) -> JSON messages back
--   - or a terminal/job connected to an existing kernel
--   - or pynvim remote plugin
--
-- Important: if you can parse traceback line numbers, pass them to `ctx.err(...)`
-- and outputs to `ctx.out(...)` with those lines. Otherwise use `ctx.anchor`.

---@type fun(ctx:{buf:number,code:string,anchor:number,out:fun(text:string,line?:number,stream?:"stdout"|"stderr"),err:fun(message:string,line?:number,trace?:string[])})|nil
M.exec = function(ctx)
  if vim.fn.executable("uv") ~= 1 then
    ctx.err("Python scratch: `uv` not found on PATH.", ctx.anchor)
    return
  end

  local runner, runner_err = uv_runner()
  if not runner then
    ctx.err(("Python scratch: %s"):format(tostring(runner_err)), ctx.anchor)
    return
  end

  local root = vim.fn.fnamemodify(runner, ":p:h:h")
  local uv_cache_dir = vim.env.UV_CACHE_DIR
  if type(uv_cache_dir) ~= "string" or uv_cache_dir == "" then
    uv_cache_dir = root .. "/.uv_cache"
  end
  pcall(vim.fn.mkdir, uv_cache_dir, "p")

  local filename = ("<mnf-scratch-%d>"):format(ctx.buf)
  local request = vim.json.encode({
    code = ctx.code,
    filename = filename,
    anchor = ctx.anchor,
    cache_dir = vim.fn.stdpath("cache"),
    plots = vim.g.mnf_scratch_python_plots ~= 0,
    mpl = vim.g.mnf_scratch_python_mpl ~= 0,
  })

  local item = {
    ctx = ctx,
    request = request,
    root = root,
    runner = runner,
    uv_cache_dir = uv_cache_dir,
  }

  drop_queued_for_buf(ctx.buf)
  local ahead = (uv_session.busy and 1 or 0) + #uv_session.queue
  uv_session.queue[#uv_session.queue + 1] = item
  if ahead > 0 and type(ctx.run_id) == "number" then
    ctx.out(("▶ python scratch run %d queued (%d ahead)"):format(ctx.run_id, ahead), ctx.anchor, "stdout")
  end
  drain_uv_queue()
end

---@param opts? {buf?:number}
function M.run(opts)
  opts = opts or {}
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local run_id = bump_run_id(buf)

  local lines, anchor = get_lines(buf)
  reset(buf)
  ensure_reset_autocmd(buf)

  if type(M.exec) ~= "function" then
    vim.notify(
      "mnf.scratch.python: set require('mnf.scratch.python').exec = function(ctx) ... end",
      vim.log.levels.WARN,
      { title = "Python scratch" }
    )
    return
  end

  local code = table.concat(lines, "\n")
  M.exec({
    buf = buf,
    code = code,
    anchor = anchor,
    run_id = run_id,
    out = function(text, line, stream)
      if not is_current_run(buf, run_id) then
        return
      end
      ghost(buf, tonumber(line) or anchor, tostring(text or ""), stream)
    end,
    err = function(message, line, trace)
      if not is_current_run(buf, run_id) then
        return
      end
      diag_error(buf, tonumber(line) or anchor, tostring(message or "Python error"), trace, { run_id = run_id })
    end,
  })
end

---@param opts? {buf?:number}
function M.clear(opts)
  opts = opts or {}
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if vim.api.nvim_buf_is_valid(buf) then
    bump_run_id(buf)
    drop_queued_for_buf(buf)
    reset(buf)
  end
end

---@param opts? {buf?:number}
function M.reset(opts)
  opts = opts or {}
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  reset(buf)
  bump_run_id(buf)
  stop_uv_session({ clear_queue = true })
end

return M
