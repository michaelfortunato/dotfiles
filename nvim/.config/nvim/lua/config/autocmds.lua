-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("formatting", { clear = true }),
  pattern = {
    "c",
    "cpp",
  },
  callback = function(event)
    if event.filetype == "c" then
      vim.bo[event.buf].tabstop = 8
      vim.bo[event.buf].shiftwidth = 4
      vim.bo[event.buf].expandtab = true
    elseif event.filetype == "cpp" then
      vim.bo[event.buf].tabstop = 4
      vim.bo[event.buf].shiftwidth = 4
      vim.bo[event.buf].expandtab = true
    end
  end,
})

if vim.fn.has("nvim") == 1 then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait"
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "gitcommit", "gitrebase", "gitconfig" },
  command = "set bufhidden=delete",
})

vim.api.nvim_create_user_command("Make", function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
  if num_subs == 0 then
    cmd = cmd .. " " .. params.args
  end

  local output_lines = {}

  local function push_output(lines)
    for _, line in ipairs(lines) do
      if type(line) == "string" then
        table.insert(output_lines, line)
      end
    end
  end

  local function format_output()
    local lines = { unpack(output_lines) }
    while #lines > 0 and lines[#lines]:match("^%s*$") do
      table.remove(lines)
    end
    if #lines == 0 then
      return nil
    end
    return table.concat(lines, "\n")
  end

  local function format_output_tail(max_lines)
    if #output_lines == 0 then
      return nil
    end

    max_lines = math.max(max_lines or 0, 0)
    if max_lines == 0 then
      return nil
    end

    local start_idx = math.max(1, #output_lines - max_lines + 1)
    local tail = {}
    for i = start_idx, #output_lines do
      table.insert(tail, output_lines[i])
    end
    while #tail > 0 and tail[#tail]:match("^%s*$") do
      table.remove(tail)
    end
    if #tail == 0 then
      return nil
    end
    return table.concat(tail, "\n")
  end

  vim.g.mnf_make_verbose = vim.g.mnf_make_verbose or false
  local verbose = vim.b.mnf_make_verbose
  if verbose == nil then
    verbose = vim.g.mnf_make_verbose
  end
  verbose = verbose == true

  local stream_notify = params.bang and verbose
  local stream_notify_id = nil
  local stream_debounced = false

  local function notify_running(t)
    local msg = ("🛠️ Make: Running %s"):format(t.name)

    if stream_notify then
      local out = format_output_tail(12)
      if out and out ~= "" then
        msg = msg .. "\n" .. out
      end
    end

    local ret = vim.notify(msg, vim.log.levels.INFO, {
      replace = stream_notify_id,
      timeout = false,
    })
    stream_notify_id = (ret and ret.id) or ret or stream_notify_id
  end

  local expanded_cmd = vim.fn.expandcmd(cmd)
  local task = require("overseer").new_task({
    cmd = expanded_cmd,
    components = {
      {
        "on_output_quickfix",
        open = false,
        open_on_exit = params.bang and "never" or "failure",
        open_height = 8,
      },
      "on_exit_set_status",
    },
  })

  task:subscribe("on_start", function(t)
    notify_running(t)
  end)

  task:subscribe("on_output_lines", function(_, lines)
    push_output(lines)
    if not stream_notify or stream_debounced then
      return
    end
    stream_debounced = true
    vim.defer_fn(function()
      stream_debounced = false
      if task:is_running() then
        notify_running(task)
      end
    end, 100)
  end)

  task:subscribe("on_complete", function(t, status)
    vim.schedule(function()
      local out = format_output()

      local status_str = type(status) == "string" and status or "FAILURE"
      local status_name = status_str:lower()
      local header, level
      if status_name == "success" then
        header = ("✅ Make: Success %s"):format(t.name)
        level = vim.log.levels.INFO
      elseif status_name == "canceled" then
        header = ("⏹️ Make: Canceled %s"):format(t.name)
        level = vim.log.levels.WARN
      else
        header = ("❌ Make: Failure (exit %s) %s"):format(t.exit_code ~= nil and t.exit_code or "?", t.name)
        level = vim.log.levels.ERROR
      end

      local msg = header
      if out and out ~= "" then
        msg = msg .. "\n" .. out
      end

      local ret = vim.notify(msg, level, {
        replace = stream_notify_id,
      })
      stream_notify_id = (ret and ret.id) or ret or stream_notify_id
      pcall(t.dispose, t, true)
    end)
  end)

  task:start()
end, {
  desc = "Run makeprg asynchronously (using Overseer)",
  nargs = "*",
  bang = true,
})

-- TODO: Its possible the persistence load screws up refresh for Vimtex
vim.api.nvim_create_user_command(
  "Restart",
  'restart lua require("persistence").load({ last = true })',
  { desc = "Restart Neovim and reload last session on reopen" }
)

-- stylua: ignore
vim.api.nvim_create_user_command("R", "Restart", { desc = "(Restart Alias) Restart Neovim and reload last session on reopen" })
vim.api.nvim_create_user_command("RR", "restart", { desc = "(Restart [Hard]) Restart Neovim" })
vim.api.nvim_create_user_command("Q", "quitall", { desc = "(quitall Alias) Quit Neovim If No Pending Changes" })

--- Get the particular terminal to remember its last mode
local term_group = vim.api.nvim_create_augroup("MNF_TermGroup", { clear = true })
vim.api.nvim_create_autocmd("ModeChanged", {
  group = term_group,
  callback = function(ev)
    local buf = ev.buf
    if not buf or vim.bo[buf].buftype ~= "terminal" then
      return
    end
    vim.b[buf].mnf_term_last_mode = vim.fn.mode()
  end,
})
vim.api.nvim_create_autocmd("TermOpen", {
  group = term_group,
  pattern = { "term://*" },
  callback = function(ev)
    vim.b[ev.buf].mnf_term_last_mode = "terminal"
    local name = vim.api.nvim_buf_get_name(ev.buf)
    if name:match("lazygit") then
      vim.keymap.set("n", "<Esc>", "<Cmd>close<CR>", { buffer = ev.buf, desc = "Exit terminal mode" })
      vim.cmd("startinsert")
      return
    end
    vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = ev.buf, desc = "Exit terminal mode" })
    vim.cmd("startinsert")
  end,
})

local function apc_payload(seq, term)
  local ESC = "\027"
  local ST7 = ESC .. "\\" -- 7-bit ST
  local ST8 = "\x9c" -- 8-bit ST (rare, but cheap to accept)
  -- Neovim splits terminator out into ev.data.terminator
  if seq:sub(1, 2) ~= ESC .. "_" then
    return nil
  end
  if term ~= ST7 and term ~= ST8 then
    return nil
  end
  return seq:sub(3) -- payload is the rest of the sequence (no terminator included)
end

vim.api.nvim_create_autocmd("TermRequest", {
  group = vim.api.nvim_create_augroup("term_tui", { clear = true }),
  desc = "Toggle :terminal TUI via APC ([appname:]tui=0|1)",
  callback = function(ev)
    local payload = apc_payload(ev.data.sequence, ev.data.terminator)
    if not payload then
      return
    end

    local app, state = payload:match("^([%w_.-]+):tui=([01])$")
    if not state then
      state = payload:match("^tui=([01])$")
    end
    if not state then
      return
    end

    local buf = ev.buf
    if state == "1" then
      vim.b[buf].is_tui_job = true
      vim.b[buf].tui_name = app or "unknown"
      vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = buf })
      vim.keymap.set(
        "t",
        "<S-Esc>",
        "<C-\\><C-n>",
        { buffer = buf, desc = "A hidden way to enter normal mode in a TUI" }
      )
      vim.keymap.set("t", "<C-h>", "<C-h>", { buffer = buf })
      vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = buf })
      vim.keymap.set("t", "<C-j>", "<C-j>", { buffer = buf })
      vim.keymap.set("t", "<C-k>", "<C-k>", { buffer = buf })
      -- For debugging: vim.notify(("Terminal buf %d marked as TUI (%s)"):format(buf, vim.b[buf].tui_name))
    else
      vim.b[buf].is_tui_job = nil
      vim.b[buf].tui_name = nil
      pcall(vim.keymap.del, "t", "<Esc>", { buffer = buf })
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = ev.buf, desc = "Exit terminal mode" })
      vim.keymap.set("t", "<C-h>", "<C-\\><C-h>", { buffer = buf })
      vim.keymap.set("t", "<C-l>", "<C-\\><C-l>", { buffer = buf })
      vim.keymap.set("t", "<C-j>", "<C-\\><C-j>", { buffer = buf })
      vim.keymap.set("t", "<C-k>", "<C-\\><C-k>", { buffer = buf })
      -- Go to <C-w>h right? ? I forget..
      -- vim.keymap.set("t", "<C-h>", "<C-h>", { buffer = buf })
      -- vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = buf })
      -- vim.keymap.set("t", "<C-j>", "<C-j>", { buffer = buf })
      -- vim.keymap.set("t", "<C-k>", "<C-k>", { buffer = buf })
      -- For debugging: vim.notify(("Terminal buf %d unmarked as TUI"):format(buf))
    end
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = term_group,
  pattern = { "term://*" },
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "terminal" then
      return
    end
    local last_mode = vim.b[ev.buf].mnf_term_last_mode
    last_mode = last_mode and last_mode:sub(1, 1) or "t"
    if last_mode == "t" or last_mode == "i" then
      vim.cmd("startinsert")
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "typst" },
  callback = function()
    --- TODO: Consider invoking the pin on this event
    vim.keymap.set("n", "<localleader>p", function()
      ---@diagnostic disable-next-line: deprecated
      vim.lsp.buf.execute_command({ command = "tinymist.pinMain", arguments = { vim.api.nvim_buf_get_name(0) } })
      -- -- unpin the main file
      -- ---@diagnostic disable-next-line: deprecated
      -- vim.lsp.buf.execute_command({ command = "tinymist.pinMain", arguments = { nil } })
    end, { desc = "Pin Typst file for LSP", buffer = true })
    -- pin the main file
  end,
})

-- ALL CUSTOM FILE TYPE autocommands here
vim.api.nvim_create_autocmd("FileType", {
  --- TODO: Problably should be moved into an ftpluin
  pattern = { "lua" },
  callback = function(ev)
    vim.api.nvim_buf_set_keymap(ev.buf, "n", "<localleader>s", "<Cmd>source %<CR>", { desc = "Source lua file" })
    --- FIXME: There is some error where input flashes quickly, this
    --- doesn't work
    vim.api.nvim_buf_set_keymap(
      ev.buf,
      "v",
      "<localleader>s",
      "<Cmd>source<CR>",
      { desc = "Run visually selected code" }
    )
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python" },
  callback = function(ev)
    vim.keymap.set("n", "<localleader><localleader>", function()
      require("mnf.scratch.python").run({ buf = ev.buf })
    end, { buffer = ev.buf, desc = "Source python file" })
    vim.keymap.set("n", "<localleader>s", function()
      require("mnf.scratch.python").run({ buf = ev.buf })
    end, { buffer = ev.buf, desc = "Source python file" })

    vim.keymap.set("v", "<localleader><localleader>", function()
      require("mnf.scratch.python").run({ buf = ev.buf })
    end, { buffer = ev.buf, desc = "Run visually selected code" })
    vim.keymap.set("v", "<localleader>s", function()
      require("mnf.scratch.python").run({ buf = ev.buf })
    end, { buffer = ev.buf, desc = "Run visually selected code" })

    vim.keymap.set("n", "<localleader>r", function()
      require("mnf.scratch.python").reset({ buf = ev.buf })
    end, { buffer = ev.buf, desc = "Reset Python session" })
    vim.keymap.set("n", "<localleader>c", function()
      require("mnf.scratch.python").clear({ buf = ev.buf })
    end, { buffer = ev.buf, desc = "Clear output" })
  end,
})

-- Auto-trust local config files on save (Neovim 0.12+)
-- Neovim maintainer was mean to my comment on the PR adding this security
-- feature--well at least I fixed it now.
local grp = vim.api.nvim_create_augroup("AutoTrustLocalConfigs", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = grp,
  pattern = { ".nvim.lua", ".lazy.lua" },
  desc = "Trust local .nvim.lua/.lazy.lua on save",
  callback = function(args)
    vim.cmd("trust")
  end,
})

vim.api.nvim_create_user_command("PrintPath", function(opts)
  local arg = opts.args
  local path

  if arg == "rel" or arg == "cwd" then
    -- relative to current working directory
    path = vim.fn.expand("%:.")
  elseif arg == "rootdir" then
    -- relative to LSP root dir (or current cwd if no LSP)
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local root
    for _, client in ipairs(clients) do
      if client.config.root_dir then
        root = client.config.root_dir
        break
      end
    end
    if root then
      local fullpath = vim.fn.expand("%:p")
      path = vim.fn.fnamemodify(fullpath, ":." .. root)
    else
      path = vim.fn.expand("%:.")
    end
  else
    -- default: absolute path
    path = vim.fn.expand("%:p")
  end

  print(path)
end, {
  nargs = "?",
  complete = function(_, _, _)
    return { "rel", "cwd", "rootdir" }
  end,
  desc = "Print current buffer path (abs by default, or rel/cwd/rootdir)",
})

------------------------------------------------------------------------------
--- Restore the cursors postiion for things like yaq my god so much better
--- AI generated so not sure iif good yet. Update MNF_EXPERIMENTAL_RESTORE
--- if you want the feature flag
------------------------------------------------------------------------------
-- Yank restore (stable, universal)
-- local function setup_restore_yank()
--   local grp = vim.api.nvim_create_augroup("mnf_restore_cursor_yank", { clear = true })
--
--   local function is_visual_mode(m)
--     return m == "v" or m == "V" or m == "\22" -- CTRL-V
--   end
--
--   local function capture()
--     return {
--       winid = vim.api.nvim_get_current_win(),
--       bufnr = vim.api.nvim_get_current_buf(),
--       view = vim.fn.winsaveview(),
--     }
--   end
--
--   local function restore(state)
--     if not (state and state.winid and state.view) then
--       return
--     end
--     vim.schedule(function()
--       if not vim.api.nvim_win_is_valid(state.winid) then
--         return
--       end
--       vim.api.nvim_win_call(state.winid, function()
--         if state.bufnr and vim.api.nvim_get_current_buf() ~= state.bufnr then
--           return
--         end
--         pcall(vim.fn.winrestview, state.view)
--       end)
--     end)
--   end
--
--   vim.api.nvim_create_autocmd("ModeChanged", {
--     group = grp,
--     desc = "Capture view for yank restore",
--     callback = function()
--       local old = vim.v.event.old_mode or ""
--       local new = vim.v.event.new_mode or ""
--
--       if new:sub(1, 2) == "no" and vim.v.operator == "y" then
--         vim.w._mnf_yank_restore_op = capture()
--       elseif is_visual_mode(new) and not is_visual_mode(old) then
--         vim.w._mnf_yank_restore_visual_enter = capture()
--       end
--     end,
--   })
--
--   vim.api.nvim_create_autocmd("TextYankPost", {
--     group = grp,
--     desc = "Restore view after yank",
--     callback = function()
--       if vim.v.event.operator ~= "y" then
--         return
--       end
--
--       local state
--       if vim.v.event.visual ~= 0 then
--         state = vim.w._mnf_yank_restore_visual_enter
--         vim.w._mnf_yank_restore_visual_enter = nil
--       else
--         state = vim.w._mnf_yank_restore_op
--       end
--
--       vim.w._mnf_yank_restore_op = nil
--       restore(state)
--     end,
--   })
-- end
local MNF_EXPERIMENTAL_RESTORE = true

if MNF_EXPERIMENTAL_RESTORE then
  -- setup_restore_yank()

  local grp = vim.api.nvim_create_augroup("restore_cursor_after_visual_or_yank", { clear = true })

  local view_before_visual = nil
  local view_before_yank = nil

  local function is_visual_mode(m)
    return m == "v" or m == "V" or m == "\22" -- \22 = CTRL-V (visual block)
  end

  local function winsave()
    return vim.fn.winsaveview()
  end

  local function winrestore(view)
    vim.schedule(function()
      pcall(vim.fn.winrestview, view)
    end)
  end

  local function t(keys)
    return vim.api.nvim_replace_termcodes(keys, true, false, true)
  end

  -- Capture the view when entering Visual mode (for `viw` preview-cancel behavior)
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = grp,
    callback = function()
      local old = vim.v.event.old_mode or ""
      local new = vim.v.event.new_mode or ""

      if is_visual_mode(new) and not is_visual_mode(old) then
        view_before_visual = winsave()
      end

      -- Capture the view when entering operator-pending *for yank* (for `yaq`, `yiw`, etc.)
      if new:sub(1, 2) == "no" and vim.v.operator == "y" then
        view_before_yank = winsave()
      end
    end,
  })

  -- Yank: restore cursor after the yank completes.
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = grp,
    callback = function()
      if vim.v.event.operator ~= "y" then
        return
      end
      local view = view_before_yank or view_before_visual
      view_before_yank = nil
      view_before_visual = nil
      if view then
        winrestore(view)
      end
    end,
  })
end

-- if MNF_EXPERIMENTAL_RESTORE then
--   local grp = vim.api.nvim_create_augroup("restore_cursor_after_visual_or_yank", { clear = true })
--
--   local view_before_visual = nil
--   local view_before_yank = nil
--
--   local function is_visual_mode(m)
--     return m == "v" or m == "V" or m == "\22" -- \22 = CTRL-V (visual block)
--   end
--
--   local function winsave()
--     return vim.fn.winsaveview()
--   end
--
--   local function winrestore(view)
--     vim.schedule(function()
--       pcall(vim.fn.winrestview, view)
--     end)
--   end
--
--   local function t(keys)
--     return vim.api.nvim_replace_termcodes(keys, true, false, true)
--   end
--
--   -- Capture the view when entering Visual mode (for `viw` preview-cancel behavior)
--   vim.api.nvim_create_autocmd("ModeChanged", {
--     group = grp,
--     callback = function()
--       local old = vim.v.event.old_mode or ""
--       local new = vim.v.event.new_mode or ""
--
--       if is_visual_mode(new) and not is_visual_mode(old) then
--         view_before_visual = winsave()
--       end
--
--       -- Capture the view when entering operator-pending *for yank* (for `yaq`, `yiw`, etc.)
--       if new:sub(1, 2) == "no" and vim.v.operator == "y" then
--         view_before_yank = winsave()
--       end
--     end,
--   })
--
--   -- Yank: restore cursor after the yank completes.
--   vim.api.nvim_create_autocmd("TextYankPost", {
--     group = grp,
--     callback = function()
--       if vim.v.event.operator ~= "y" then
--         return
--       end
--       local view = view_before_yank or view_before_visual
--       view_before_yank = nil
--       view_before_visual = nil
--       if view then
--         winrestore(view)
--       end
--     end,
--   })
--
--   -- local grp = vim.api.nvim_create_augroup("visual_exit_restore_to_last_normal", { clear = true })
--   -- local last_normal_view = nil
--   --
--   -- local function winsave()
--   -- 	return vim.fn.winsaveview()
--   -- end
--   -- local function winrestore(view)
--   -- 	vim.schedule(function()
--   -- 		pcall(vim.fn.winrestview, view)
--   -- 	end)
--   -- end
--   --
--   -- -- Track last Normal-mode cursor/view.
--   -- vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
--   -- 	group = grp,
--   -- 	callback = function()
--   -- 		local m = vim.fn.mode(1) -- e.g. "n", "no", "v", ...
--   -- 		if m:sub(1, 1) == "n" then
--   -- 			last_normal_view = winsave()
--   -- 		end
--   -- 	end,
--   -- })
--   --
--   -- local function t(keys)
--   -- 	return vim.api.nvim_replace_termcodes(keys, true, false, true)
--   -- end
--   --
--   -- -- Restore ONLY when you press this key in Visual mode.
--   -- vim.keymap.set("x", "<leader>v", function()
--   -- 	local view = last_normal_view
--   --
--   -- 	-- Exit Visual immediately.
--   -- 	vim.api.nvim_feedkeys(t("<Esc>"), "nx", false)
--   --
--   -- 	-- Then restore.
--   -- 	if view then
--   -- 		winrestore(view)
--   -- 	end
--   -- end, { silent = true, noremap = true, nowait = true, desc = "Exit Visual + restore to last Normal pos" })
-- end

-- We are never cviring this out are we
-- local grp = vim.api.nvim_create_augroup("ScrollInit", { clear = true })
-- vim.api.nvim_create_autocmd("WinNew", {
--   group = grp,
--   callback = function(ev)
--     vim.api.nvim_set_option_value("scroll", 15, { scope = "local", win = ev.win })
--   end,
--   desc = "Set scroll once for new windows",
-- })
--

-- -- Example `~/.config/nvim/.lazy.lua` template
-- -- Everything is commented out; uncomment and tweak as needed.
-- -- Keep cursor/view fixed after yanks (works with mini.ai textobjects like `yaq`)
-- -- Restore cursor/view after:
-- --   (A) cancelling Visual mode (Esc)
-- --   (B) yanking (operator-pending or Visual yank)
-- -- Restore cursor/view after:
-- --   (A) cancelling Visual mode (Esc)
-- --   (B) yanking (operator-pending yank OR visual yank)
--
-- local M = {}
--
-- function M.setup(opts)
-- 	opts = opts or {}
--
-- 	-- Restore after yanks?
-- 	local restore_yank = (opts.restore_yank ~= false)
--
-- 	-- Enable Visual restore mapping? If false, we avoid Normal-mode tracking entirely (efficiency).
-- 	local enable_visual_restore = (opts.enable_visual_restore == true)
--
-- 	-- Track scroll position for visual restore (WinScrolled). Ignored if enable_visual_restore=false.
-- 	local track_scroll = (opts.track_scroll ~= false)
--
-- 	-- Key that exits Visual AND restores to last Normal position.
-- 	-- Only used if enable_visual_restore=true.
-- 	local visual_exit_key = opts.visual_exit_key or "<leader>v"
-- 	local visual_exit_nowait = (opts.visual_exit_nowait ~= false)
--
-- 	local grp = vim.api.nvim_create_augroup("mnf_restore_cursor", { clear = true })
--
-- 	-- Per-window state (keyed by winid)
-- 	local last_normal_view = {} ---@type table<number, table>
-- 	local op_view = {} ---@type table<number, table>
-- 	local visual_enter_view = {} ---@type table<number, table>  -- fallback for visual yanks
--
-- 	local function winsave()
-- 		return vim.fn.winsaveview()
-- 	end
-- 	local function winrestore(view)
-- 		vim.schedule(function()
-- 			pcall(vim.fn.winrestview, view)
-- 		end)
-- 	end
--
-- 	local function t(keys)
-- 		return vim.api.nvim_replace_termcodes(keys, true, false, true)
-- 	end
--
-- 	local function curwin()
-- 		return vim.api.nvim_get_current_win()
-- 	end
--
-- 	-- Optional: track last Normal-mode view per-window (ONLY needed for visual restore mapping).
-- 	if enable_visual_restore then
-- 		local track_events = { "CursorMoved", "WinEnter" }
-- 		if track_scroll then
-- 			table.insert(track_events, "WinScrolled")
-- 		end
--
-- 		vim.api.nvim_create_autocmd(track_events, {
-- 			group = grp,
-- 			callback = function()
-- 				-- Only record in *plain* Normal mode, not operator-pending ("no")
-- 				if vim.fn.mode() ~= "n" then
-- 					return
-- 				end
-- 				local win = curwin()
-- 				last_normal_view[win] = winsave()
-- 			end,
-- 		})
-- 	end
--
-- 	-- Capture view on entry to operator-pending, per-window (pattern-filtered).
-- 	vim.api.nvim_create_autocmd("ModeChanged", {
-- 		group = grp,
-- 		pattern = "*:no*",
-- 		callback = function()
-- 			local win = curwin()
-- 			op_view[win] = winsave()
-- 		end,
-- 	})
--
-- 	-- Clear stale op state when leaving operator-pending (e.g. you cancel).
-- 	vim.api.nvim_create_autocmd("ModeChanged", {
-- 		group = grp,
-- 		pattern = "no*:*",
-- 		callback = function()
-- 			local win = curwin()
-- 			op_view[win] = nil
-- 		end,
-- 	})
--
-- 	-- Also capture view when entering Visual as a fallback for visual-yanks
-- 	-- (since visual yanks may not go through operator-pending in a way we can capture).
-- 	vim.api.nvim_create_autocmd("ModeChanged", {
-- 		group = grp,
-- 		pattern = "*:[vV\22]*",
-- 		callback = function()
-- 			local win = curwin()
-- 			visual_enter_view[win] = winsave()
-- 		end,
-- 	})
--
-- 	-- Restore after yanks (operator/textobject/visual-yank).
-- 	if restore_yank then
-- 		vim.api.nvim_create_autocmd("TextYankPost", {
-- 			group = grp,
-- 			callback = function()
-- 				if vim.v.event.operator ~= "y" then
-- 					return
-- 				end
-- 				local win = curwin()
--
-- 				-- Prefer operator-pending capture; else fallback to visual-entry capture; else last-normal (if enabled).
-- 				local view = op_view[win]
-- 					or visual_enter_view[win]
-- 					or (enable_visual_restore and last_normal_view[win] or nil)
--
-- 				op_view[win] = nil
-- 				visual_enter_view[win] = nil
--
-- 				if view then
-- 					winrestore(view)
-- 				end
-- 			end,
-- 		})
-- 	end
--
-- 	-- Custom Visual exit mapping that restores ONLY on that key (if enabled).
-- 	if enable_visual_restore and visual_exit_key and visual_exit_key ~= "" then
-- 		vim.keymap.set("x", visual_exit_key, function()
-- 			local win = curwin()
-- 			local view = last_normal_view[win]
--
-- 			-- Exit Visual immediately (execute now, no remap)
-- 			vim.api.nvim_feedkeys(t("<Esc>"), "nx", false)
--
-- 			if view then
-- 				winrestore(view)
-- 			end
-- 		end, {
-- 			silent = true,
-- 			noremap = true,
-- 			nowait = visual_exit_nowait,
-- 			desc = "Exit Visual + restore to last Normal position",
-- 		})
-- 	end
--
-- 	-- Cleanup per-window state on close.
-- 	vim.api.nvim_create_autocmd("WinClosed", {
-- 		group = grp,
-- 		callback = function(ev)
-- 			local win = tonumber(ev.match)
-- 			if win then
-- 				last_normal_view[win] = nil
-- 				op_view[win] = nil
-- 				visual_enter_view[win] = nil
-- 			end
-- 		end,
-- 	})
-- end
--
-- M.setup({
-- 	restore_yank = true,
-- 	track_scroll = false, -- set false if you want less tracking
-- 	visual_exit_key = "<leader>v", -- your dedicated “restore-exit” key
-- 	visual_exit_nowait = true,
-- 	enable_visual_restore = false,
-- })
--
-- return {}
--
-- -- do
-- -- 	local grp = vim.api.nvim_create_augroup("visual_exit_restore_to_last_normal", { clear = true })
-- -- 	local last_normal_view = nil
-- --
-- -- 	local function winsave()
-- -- 		return vim.fn.winsaveview()
-- -- 	end
-- -- 	local function winrestore(view)
-- -- 		vim.schedule(function()
-- -- 			pcall(vim.fn.winrestview, view)
-- -- 		end)
-- -- 	end
-- --
-- -- 	-- Track last Normal-mode cursor/view.
-- -- 	vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
-- -- 		group = grp,
-- -- 		callback = function()
-- -- 			local m = vim.fn.mode(1) -- e.g. "n", "no", "v", ...
-- -- 			if m:sub(1, 1) == "n" then
-- -- 				last_normal_view = winsave()
-- -- 			end
-- -- 		end,
-- -- 	})
-- --
-- -- 	local function t(keys)
-- -- 		return vim.api.nvim_replace_termcodes(keys, true, false, true)
-- -- 	end
-- --
-- -- 	-- Restore ONLY when you press this key in Visual mode.
-- -- 	vim.keymap.set("x", "<leader>v", function()
-- -- 		local view = last_normal_view
-- --
-- -- 		-- Exit Visual immediately.
-- -- 		vim.api.nvim_feedkeys(t("<Esc>"), "nx", false)
-- --
-- -- 		-- Then restore.
-- -- 		if view then
-- -- 			winrestore(view)
-- -- 		end
-- -- 	end, { silent = true, noremap = true, nowait = true, desc = "Exit Visual + restore to last Normal pos" })
-- -- end
--
-- -- do
-- -- 	local grp = vim.api.nvim_create_augroup("restore_cursor_after_visual_or_yank", { clear = true })
-- --
-- -- 	local view_before_visual = nil
-- -- 	local view_before_op = nil
-- --
-- -- 	local function is_visual_mode(m)
-- -- 		return m == "v" or m == "V" or m == "\22" -- \22 = CTRL-V
-- -- 	end
-- --
-- -- 	local function winsave()
-- -- 		return vim.fn.winsaveview()
-- -- 	end
-- --
-- -- 	local function winrestore(view)
-- -- 		vim.schedule(function()
-- -- 			pcall(vim.fn.winrestview, view)
-- -- 		end)
-- -- 	end
-- --
-- -- 	local function t(keys)
-- -- 		return vim.api.nvim_replace_termcodes(keys, true, false, true)
-- -- 	end
-- --
-- -- 	-- Capture view when entering Visual, and when entering operator-pending (any operator).
-- -- 	vim.api.nvim_create_autocmd("ModeChanged", {
-- -- 		group = grp,
-- -- 		callback = function()
-- -- 			local old = vim.v.event.old_mode or ""
-- -- 			local new = vim.v.event.new_mode or ""
-- --
-- -- 			if is_visual_mode(new) and not is_visual_mode(old) then
-- -- 				view_before_visual = winsave()
-- -- 			end
-- --
-- -- 			-- operator-pending modes start with "no" (e.g. "no", "nov", "noV")
-- -- 			if new:sub(1, 2) == "no" then
-- -- 				view_before_op = winsave()
-- -- 			end
-- -- 		end,
-- -- 	})
-- --
-- -- 	-- After a yank completes, restore the saved view.
-- -- 	vim.api.nvim_create_autocmd("TextYankPost", {
-- -- 		group = grp,
-- -- 		callback = function()
-- -- 			if vim.v.event.operator ~= "y" then
-- -- 				return
-- -- 			end
-- --
-- -- 			local view = view_before_op or view_before_visual
-- -- 			view_before_op = nil
-- -- 			view_before_visual = nil
-- --
-- -- 			if view then
-- -- 				winrestore(view)
-- -- 			end
-- -- 		end,
-- -- 	})
-- --
-- -- 	-- -- If you used Visual just to "peek" (`viw`, `viq`, etc) then hit Esc,
-- -- 	-- -- return to where you were before entering Visual.
-- -- 	-- vim.keymap.set("x", "<Esc>", function()
-- -- 	-- 	local view = view_before_visual
-- -- 	-- 	view_before_visual = nil
-- -- 	--
-- -- 	-- 	-- Leave Visual without remapping (so this mapping doesn't recurse).
-- -- 	-- 	vim.api.nvim_feedkeys(t("<Esc>"), "n", false)
-- -- 	--
-- -- 	-- 	if view then
-- -- 	-- 		winrestore(view)
-- -- 	-- 	end
-- -- 	-- end, { silent = true, buffer = 0 })
-- -- end
--
-- -- do
-- -- 	local grp = vim.api.nvim_create_augroup("restore_cursor_after_visual_or_yank", { clear = true })
-- --
-- -- 	local view_before_visual = nil
-- -- 	local view_before_yank = nil
-- --
-- -- 	local function is_visual_mode(m)
-- -- 		return m == "v" or m == "V" or m == "\22" -- \22 = CTRL-V (visual block)
-- -- 	end
-- --
-- -- 	local function winsave()
-- -- 		return vim.fn.winsaveview()
-- -- 	end
-- --
-- -- 	local function winrestore(view)
-- -- 		vim.schedule(function()
-- -- 			pcall(vim.fn.winrestview, view)
-- -- 		end)
-- -- 	end
-- --
-- -- 	local function t(keys)
-- -- 		return vim.api.nvim_replace_termcodes(keys, true, false, true)
-- -- 	end
-- --
-- -- 	-- Capture the view when entering Visual mode (for `viw` preview-cancel behavior)
-- -- 	vim.api.nvim_create_autocmd("ModeChanged", {
-- -- 		group = grp,
-- -- 		callback = function()
-- -- 			local old = vim.v.event.old_mode or ""
-- -- 			local new = vim.v.event.new_mode or ""
-- --
-- -- 			if is_visual_mode(new) and not is_visual_mode(old) then
-- -- 				view_before_visual = winsave()
-- -- 			end
-- --
-- -- 			-- Capture the view when entering operator-pending *for yank* (for `yaq`, `yiw`, etc.)
-- -- 			if new:sub(1, 2) == "no" and vim.v.operator == "y" then
-- -- 				view_before_yank = winsave()
-- -- 			end
-- -- 		end,
-- -- 	})
-- --
-- -- 	-- Yank: restore cursor after the yank completes.
-- -- 	vim.api.nvim_create_autocmd("TextYankPost", {
-- -- 		group = grp,
-- -- 		callback = function()
-- -- 			if vim.v.event.operator ~= "y" then
-- -- 				return
-- -- 			end
-- -- 			local view = view_before_yank or view_before_visual
-- -- 			view_before_yank = nil
-- -- 			view_before_visual = nil
-- -- 			if view then
-- -- 				winrestore(view)
-- -- 			end
-- -- 		end,
-- -- 	})
-- --
-- -- 	-- Visual preview: pressing Esc should return to where you were before `viw`.
-- -- 	vim.keymap.set("x", "<Esc>", function()
-- -- 		local view = view_before_visual
-- -- 		view_before_visual = nil
-- -- 		vim.api.nvim_feedkeys(t("<Esc>"), "n", false) -- leave visual, no remap
-- -- 		if view then
-- -- 			winrestore(view)
-- -- 		end
-- -- 	end, { silent = true })
-- -- end
--
-- -- =========================
-- -- 1. Key MAPPINGS
-- -- =========================
--
-- -- vim.keymap.set("n", "<leader>h", ":split<CR>", { noremap = true, silent = true,
-- --  expr = true, -- treat the Lua return as a key‑sequence
-- -- })
-- -- vim.keymap.set("n", "<leader>v", ":vsplit<CR>", { noremap = true, silent = true })
-- -- vim.keymap.set("n", "<leader>rn", function()
-- --   vim.opt.relativenumber = not vim.opt.relativenumber:get()
-- -- end, { noremap = true, silent = true })
-- -- vim.keymap.del("n", "<leader>h")
-- -- vim.keymap.set("n", "<leader>f", "<cmd>Telescope find_files<CR>", { noremap = true, silent = true })
--
-- -- =========================
-- -- 2. AUTOCOMMANDS
-- -- =========================
--
-- -- vim.api.nvim_create_autocmd("BufWritePre", {
-- --   pattern = "*.lua",
-- --   callback = function()
-- --     vim.lsp.buf.format({ async = false })
-- --   end,
-- -- })
--
-- -- local pygrp = vim.api.nvim_create_augroup("PythonSettings", { clear = true })
-- -- vim.api.nvim_create_autocmd("FileType", {
-- --   group = pygrp,
-- --   pattern = "python",
-- --   callback = function()
-- --     vim.opt_local.shiftwidth = 4
-- --     vim.opt_local.tabstop   = 4
-- --   end,
-- -- })
--
-- -- =========================
-- -- 3. Minimal lazy.nvim SPEC
-- -- =========================
--
-- -- return {
-- --   {
-- --     "nvim-treesitter/nvim-treesitter",
-- --     build = ":TSUpdate",
-- --     lazy  = false,
-- --   },
-- --   {
-- --     "nvim-lualine/lualine.nvim",
-- --     event = "VimEnter",
-- --     opts  = {
-- --       options = {
-- --         theme               = "gruvbox",
-- --         section_separators  = "",
-- --         component_separators = "|",
-- --       },
-- --     },
-- --   },
-- --   {
-- --     "nvim-telescope/telescope.nvim",
-- --     cmd          = "Telescope",
-- --     dependencies = { "nvim-lua/plenary.nvim" },
-- --     opts         = {
-- --       defaults = { layout_strategy = "horizontal" },
-- --     },
-- --   },
-- -- }
