local M = {}

function M.should_open_startup_terminal()
  if vim.g.mnf_startup_terminal_opened then
    return false
  end
  if vim.fn.argc(-1) > 0 then
    return false
  end

  local uis = vim.api.nvim_list_uis()
  if #uis == 0 then
    return false
  end
  if uis[1].stdout_tty and not uis[1].stdin_tty then
    return false
  end

  local wins = vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative == ""
  end, vim.api.nvim_list_wins())
  if #wins ~= 1 then
    return false
  end

  local buf = vim.api.nvim_win_get_buf(wins[1])
  if vim.api.nvim_buf_get_name(buf) ~= "" then
    return false
  end
  if vim.bo[buf].buftype ~= "" or vim.bo[buf].modified then
    return false
  end
  if vim.api.nvim_buf_line_count(buf) > 1 then
    return false
  end

  return (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == ""
end

function M.open_startup_terminal()
  if not M.should_open_startup_terminal() then
    return
  end

  vim.g.mnf_startup_terminal_opened = true
  local ok, err = pcall(vim.cmd.terminal)
  if not ok then
    vim.g.mnf_startup_terminal_opened = false
    vim.notify("Failed to open startup terminal: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  vim.cmd("startinsert")
end

function M.setup()
  if vim.g.mnf_startup_terminal_checked then
    return
  end
  vim.g.mnf_startup_terminal_checked = true

  vim.api.nvim_create_autocmd("User", {
    group = vim.api.nvim_create_augroup("MNF_StartupTerminal", { clear = true }),
    pattern = "VeryLazy",
    once = true,
    callback = function()
      -- LazyVim loads custom terminal autocmds on VeryLazy; defer until those exist.
      vim.schedule(M.open_startup_terminal)
    end,
  })
end

return M
