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

-- Make sure we RE-enter terminal mode when focusing back on terminal
vim.api.nvim_create_autocmd({ "BufEnter", "TermOpen" }, {
  callback = function()
    vim.cmd("startinsert")
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { buffer = true, desc = "Exit terminal mode" })
  end,
  pattern = { "term://*" },
  group = vim.api.nvim_create_augroup("TermGroup", { clear = true }),
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
