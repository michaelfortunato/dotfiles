-- Scratch runner UX for Python scratch buffers.
--
-- Goal: replicate Folke's "inline ghost output" + visual selection semantics from
-- `snacks/debug.lua:Snacks.debug.run()`, but keep all code in your config.
--
-- Default execution backend uses Neovim's Python provider (`:python3`), which
-- gives us a persistent Python interpreter inside the running Neovim instance.
-- (State persists across runs; we scope globals per scratch buffer id.)
--
-- If you later want a true Jupyter kernel, keep the same `ctx` interface and
-- replace `M.exec`.

---@class MNF.Scratch.Python
local M = {}

local ns = vim.api.nvim_create_namespace("mnf_scratch_python")

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
local function diag_error(buf, line, message, trace)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.diagnostic.set(ns, buf, {
      { col = 0, lnum = math.max(line - 1, 0), message = message, severity = vim.diagnostic.severity.ERROR },
    })
    if type(trace) == "table" and #trace > 0 then
      vim.notify(table.concat(trace, "\n"), vim.log.levels.ERROR, { title = "Python error" })
    else
      vim.notify(message, vim.log.levels.ERROR, { title = "Python error" })
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
    -- Anchor at column 0 and render below the line via Snacks.image placeholder grid.
    -- We use a zero-width range at (line,0) so the code line stays intact.
    pcall(snacks.image.placement.new, buf, file, {
      inline = true,
      auto_resize = true,
      type = "chart",
      pos = { line, 0 },
      range = { line, 0, line, 0 },
      conceal = false,
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
    end,
  })
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
local function ensure_python_backend()
  if vim.g.mnf_scratch_python_provider_ready == 1 then
    return true
  end
  if vim.fn.exists(":python3") == 0 then
    vim.notify(
      "Python scratch: `:python3` is not available. Run `:checkhealth provider`.",
      vim.log.levels.ERROR,
      { title = "Python scratch" }
    )
    return false
  end

  local path = vim.fn.stdpath("config") .. "/python/mnf_scratch_python.py"
  local ok, err = pcall(function()
    vim.cmd("py3file " .. vim.fn.fnameescape(path))
  end)
  if not ok then
    vim.notify(
      ("Python scratch: failed to load backend `%s`\n%s"):format(path, tostring(err)),
      vim.log.levels.ERROR,
      { title = "Python scratch" }
    )
    return false
  end

  return vim.g.mnf_scratch_python_provider_ready == 1
end

---@type fun(ctx:{buf:number,code:string,anchor:number,out:fun(text:string,line?:number,stream?:"stdout"|"stderr"),err:fun(message:string,line?:number,trace?:string[])})|nil
M.exec = function(ctx)
  if not ensure_python_backend() then
    return
  end

  vim.g.mnf_scratch_python__buf = ctx.buf
  vim.g.mnf_scratch_python__anchor = ctx.anchor
  vim.g.mnf_scratch_python__filename = ("<mnf-scratch-%d>"):format(ctx.buf)
  vim.g.mnf_scratch_python__code = ctx.code
  vim.g.mnf_scratch_python__last = nil

  local ok, err = pcall(vim.cmd, "python3 _mnf_scratch_python_run_from_vim()")
  if not ok then
    ctx.err(("python3 failed: %s"):format(tostring(err)), ctx.anchor)
    return
  end

  local payload = vim.g.mnf_scratch_python__last
  vim.g.mnf_scratch_python__code = nil
  vim.g.mnf_scratch_python__last = nil

  if type(payload) ~= "string" or payload == "" then
    return
  end

  local decoded_ok, events = pcall(vim.json.decode, payload)
  if not decoded_ok or type(events) ~= "table" then
    ctx.err("Failed to decode python results", ctx.anchor)
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

---@param opts? {buf?:number}
function M.run(opts)
  opts = opts or {}
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

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
    out = function(text, line, stream)
      ghost(buf, tonumber(line) or anchor, tostring(text or ""), stream)
    end,
    err = function(message, line, trace)
      diag_error(buf, tonumber(line) or anchor, tostring(message or "Python error"), trace)
    end,
  })
end

---@param opts? {buf?:number}
function M.clear(opts)
  opts = opts or {}
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  if vim.api.nvim_buf_is_valid(buf) then
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
  if not ensure_python_backend() then
    return
  end
  vim.g.mnf_scratch_python__buf = buf
  local ok, err = pcall(vim.cmd, "python3 _mnf_scratch_python_reset_from_vim()")
  if not ok then
    vim.notify(("Python reset failed: %s"):format(tostring(err)), vim.log.levels.ERROR, { title = "Python scratch" })
    return
  end
  reset(buf)
  vim.notify("Python scratch session reset", vim.log.levels.INFO, { title = "Python scratch" })
end

return M
