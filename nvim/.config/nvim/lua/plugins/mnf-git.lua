local function notify_path(path)
  return vim.fn.fnamemodify(path, ":~")
end

local function stage_current_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.notify("No file to stage", vim.log.levels.WARN)
  end
  local cwd = LazyVim.root.get() or vim.loop.cwd()

  vim.fn.jobstart({ "git", "status", "--porcelain", "--", file }, {
    cwd = cwd,
    stdout_buffered = true,
    on_stdout = function(_, data)
      local dirty = data and table.concat(data, ""):match("%S")
      if not dirty then
        return vim.schedule(function()
          vim.notify("Nothing to stage: " .. notify_path(file), vim.log.levels.INFO)
        end)
      end
      vim.fn.jobstart({ "git", "add", file }, {
        cwd = cwd,
        on_exit = function(_, code)
          vim.schedule(function()
            if code == 0 then
              vim.notify("Staged " .. notify_path(file), vim.log.levels.INFO)
            else
              vim.notify("git add failed for " .. file, vim.log.levels.ERROR)
            end
          end)
        end,
      })
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify("git status failed for " .. file, vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

local function commit_current_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
  end
  local cwd = LazyVim.root.get() or vim.loop.cwd()

  vim.ui.input({ prompt = "Commit message: " }, function(msg)
    if not msg or msg == "" then
      return vim.notify("Commit aborted", vim.log.levels.INFO)
    end

    local stderr, stdout = {}, {}
    vim.fn.jobstart({ "git", "commit", "-m", msg, "--only", "--", file }, {
      cwd = cwd,
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(_, data)
        if data then
          vim.list_extend(stdout, data)
        end
      end,
      on_stderr = function(_, data)
        if data then
          vim.list_extend(stderr, data)
        end
      end,
      on_exit = function(_, code)
        vim.schedule(function()
          if code == 0 then
            vim.notify("Committed " .. notify_path(file), vim.log.levels.INFO)
            if next(stdout) then
              vim.notify(table.concat(stdout, "\n"), vim.log.levels.TRACE)
            end
          else
            local msg = table.concat(stderr, "\n"):gsub("^%s+", "")
            if msg == "" then
              msg = table.concat(stdout, "\n")
            end
            vim.notify(
              ("git commit failed for %s\n%s"):format(file, msg ~= "" and msg or "(no output)"),
              vim.log.levels.ERROR
            )
          end
        end)
      end,
    })
  end)
end

vim.keymap.set("n", "<leader>ga", stage_current_file, { desc = "Git: Stage current file" })
vim.keymap.set("n", "<leader>gC", commit_current_file, { desc = "Git: Commit current file only" })
-- NOTE: This is basically the same as putting retunring an empty plugin spec.
-- return {
--   "mnf-git",
--   lazy = false, -- run on startup
--   virtual = true,
--   -- If you really want the keys to show
--   -- keys = {
--   --   { "<leader>ga", stage_current_file },
--   --   { "<leader>gC", commit_current_file },
--   -- },
-- }
return {}
