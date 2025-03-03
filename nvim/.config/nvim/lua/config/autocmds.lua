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

vim.api.nvim_create_user_command("Make", function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
  if num_subs == 0 then
    cmd = cmd .. " " .. params.args
  end
  local task = require("overseer").new_task({
    cmd = vim.fn.expandcmd(cmd),
    components = {
      { "on_output_quickfix", open = not params.bang, open_height = 8 },
      "default",
    },
  })
  task:start()
end, {
  desc = "Run makeprg asynchronously (using Overseer)",
  nargs = "*",
  bang = true,
})

local function kitty_exec(args)
  local arguments = vim.deepcopy(args)
  table.insert(arguments, 1, "kitty")
  table.insert(arguments, 2, "@")
  -- local password = vim.g.smart_splits_kitty_password or require("smart-splits.config").kitty_password or ""
  -- if #password > 0 then
  --   table.insert(arguments, 3, "--password")
  --   table.insert(arguments, 4, password)
  -- end
  return vim.system(arguments)
end

local function run_in_system_terminal(cmd)
  local ok, _ = pcall(kitty_exec, { "kitten", "run_command_in_window.py", cmd })
end

vim.api.nvim_create_user_command("Run", function(params)
  -- Insert args at the '$*' in the makeprg
  local cmd, num_subs = vim.g.runprg:gsub("%$%*", params.args)
  if num_subs == 0 then
    cmd = cmd .. " " .. params.args
  end
  cmd = vim.fn.expandcmd(cmd)
  run_in_system_terminal(cmd)
end, {
  desc = "Run runprg asynchronously in your computers terminal emulator",
  nargs = "*",
  bang = true,
})

local function run_in_integrated_terminal(cmd, shell)
  return Snacks.terminal.get(cmd, {
    shell = shell or vim.o.shell,
    win = {
      position = "bottom",
      height = 0.3,
      width = 0.4,
    },
    -- interactive = true,
    auto_insert = false,
    start_insert = false,
    auto_close = false,
  })
end

vim.api.nvim_create_user_command("IntegratedTerminalRun", function(params)
  local cmd = vim.fn.expandcmd(params.args)
  run_in_integrated_terminal(cmd)
end, {
  desc = "Run a terminal command asynchronously in your integrated terminal emulator",
  nargs = "*",
  bang = true,
})
-- --- Return the visually selected text as an array with an entry for each line
--- @see https://www.reddit.com/r/neovim/comments/1b1sv3a/function_to_get_visually_selected_text/--
--- @return string[]|nil lines The selected text as an array of lines.
local function get_visual_selection_text()
  local _, srow, scol = unpack(vim.fn.getpos("v"))
  local _, erow, ecol = unpack(vim.fn.getpos("."))

  -- visual line mode
  if vim.fn.mode() == "V" then
    if srow > erow then
      return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
    else
      return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
    end
  end

  -- regular visual mode
  if vim.fn.mode() == "v" then
    if srow < erow or (srow == erow and scol <= ecol) then
      return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    else
      return vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
    end
  end

  -- visual block mode
  if vim.fn.mode() == "\22" then
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

-- -- Make sure we RE-enter terminal mode when focusing back on terminal
vim.api.nvim_create_autocmd({ "BufEnter", "TermOpen" }, {
  callback = function()
    vim.cmd("startinsert")
  end,
  pattern = { "term://*" },
  group = vim.api.nvim_create_augroup("TermGroup", { clear = true }),
})

vim.api.nvim_create_autocmd("FileType", {
  --- TODO: Problably should be moved into an ftpluin
  pattern = { "python" },
  callback = function(ev)
    --- NOTE: :lua also works I believe and works in any buffer.
    --- But since this is buffer local, just use the original
    vim.api.nvim_buf_set_keymap(
      ev.buf,
      "n",
      "<localleader>s",
      "<Cmd>IntegratedTerminalRun python3 " .. ev.file .. "<CR>",
      { desc = "Source lua file" }
    )
    -- FIXME: This is close but not right. I am getting more convinced
    -- to use my system emulator for anew window? I do not know for sure.
    vim.keymap.set("v", "<localleader>s", function()
      local window = run_in_integrated_terminal("python3")
      local lines = get_visual_selection_text()
      if lines == nil then
        return
      end
      vim.api.nvim_chan_send(window.buf, table.concat(lines, "\r\n"))
      vim.api.nvim_chan_send(window.buf, "\r\n") -- NOTE: Send a last one in case we are on a single line
    end, { desc = "Run visually selected code", buffer = ev.buf })
  end,
})
