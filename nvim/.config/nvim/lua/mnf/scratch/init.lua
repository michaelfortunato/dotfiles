-- Persistent, project-aware scratch buffers in the same native split used by
-- mnf.terminal and mnf.terminal.jobs.

---@class MNF.Scratch
local M = {}

local native_window = require("mnf.terminal.window")

local WINDOW_VAR = "mnf_scratch_window"

local function current_tab_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local ok, scratch = pcall(vim.api.nvim_win_get_var, win, WINDOW_VAR)
    if ok and scratch == true then
      return win
    end
  end
end

---@param win integer
---@return boolean
function M.is_window(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local ok, scratch = pcall(vim.api.nvim_win_get_var, win, WINDOW_VAR)
  return ok and scratch == true
end

---@param win? integer
---@return boolean
function M.close(win)
  win = win or vim.api.nvim_get_current_win()
  if not M.is_window(win) then
    return false
  end
  local ok = pcall(vim.api.nvim_win_close, win, false)
  return ok
end

---@param buf integer
local function write_when_hidden(buf)
  vim.api.nvim_create_autocmd("BufHidden", {
    group = vim.api.nvim_create_augroup("mnf_scratch_autowrite_" .. buf, { clear = true }),
    buffer = buf,
    callback = function(ev)
      if not (vim.api.nvim_buf_is_valid(ev.buf) and vim.api.nvim_buf_is_loaded(ev.buf)) then
        return
      end
      vim.api.nvim_buf_call(ev.buf, function()
        vim.cmd("silent! write")
        vim.bo[ev.buf].buflisted = false
      end)
    end,
    desc = "Persist MNF scratch buffer",
  })
end

---@param buf integer
local function close_current_scratch_window(buf)
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= buf then
    return
  end

  local ok_close, close_on_q = pcall(vim.api.nvim_win_get_var, win, "mnf-close-on-q")
  local ok_preview, is_preview = pcall(vim.api.nvim_win_get_var, win, "is-goto-preview-window")
  if M.is_window(win) or (ok_close and close_on_q) or (ok_preview and is_preview) then
    pcall(vim.api.nvim_win_close, win, false)
  end
end

---@param buf integer
---@param ft string
local function set_buffer_keys(buf, ft)
  local close = function()
    close_current_scratch_window(buf)
  end
  vim.keymap.set("n", "''", close, { buffer = buf, desc = "Close scratch window" })
  vim.keymap.set("n", "q", close, { buffer = buf, desc = "Close scratch window" })

  -- Remove the old layout cycler from persistent buffers opened before this
  -- module took over scratch window management.
  pcall(vim.keymap.del, "n", "'f", { buffer = buf })

  if ft == "python" then
    vim.keymap.set({ "n", "x" }, "<cr>", function()
      require("mnf.scratch.python").run({ buf = buf })
    end, { buffer = buf, desc = "Run selection (ghost output)" })
    vim.keymap.set("n", ",c", function()
      require("mnf.scratch.python").clear({ buf = buf })
    end, { buffer = buf, desc = "Clear scratch output" })
    vim.keymap.set("n", "R", function()
      require("mnf.scratch.python").reset({ buf = buf })
    end, { buffer = buf, desc = "Reset Python scratch session" })
  elseif ft == "lua" then
    vim.keymap.set({ "n", "x" }, "<cr>", function()
      local name = "scratch." .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":e")
      Snacks.debug.run({ buf = buf, name = name })
    end, { buffer = buf, desc = "Source scratch buffer" })
  end
end

---@param scratch snacks.scratch.File
---@param opts snacks.scratch.Config
---@return integer
local function get_buffer(scratch, opts)
  local is_new = vim.uv.fs_stat(scratch.file) == nil
  local buf = vim.fn.bufadd(scratch.file)
  if not vim.api.nvim_buf_is_loaded(buf) then
    vim.fn.bufload(buf)
  end

  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = scratch.ft

  if is_new and opts.template and vim.api.nvim_buf_line_count(buf) == 1 then
    local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
    if first == "" then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(opts.template, "\n"))
    end
  end

  if opts.autowrite ~= false then
    write_when_hidden(buf)
  end
  set_buffer_keys(buf, scratch.ft)
  return buf
end

---@class MNF.Scratch.OpenResult
---@field buf integer
---@field win integer?
---@field closed? boolean

---Open a persistent scratch in one reusable native right split.
---@param opts? snacks.scratch.Config
---@return MNF.Scratch.OpenResult
function M.open(opts)
  opts = vim.tbl_deep_extend("force", {}, opts or {})
  local snacks_scratch = require("snacks").scratch
  snacks_scratch.migrate()
  local scratch = snacks_scratch.get(opts)
  local buf = get_buffer(scratch, opts)
  local win = current_tab_window()

  if win and vim.api.nvim_win_get_buf(win) == buf then
    local closed = M.close(win)
    local result = { buf = buf, closed = closed }
    if not closed then
      result.win = win
    end
    return result
  end

  if win then
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_set_current_win(win)
  else
    win = native_window.open(buf, {
      position = "right",
      width = 0.45,
      enter = true,
      wo = {
        colorcolumn = "",
        winfixbuf = false,
      },
    })
    vim.w[win][WINDOW_VAR] = true
  end

  return { buf = buf, win = win }
end

return M
