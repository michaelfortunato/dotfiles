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

-- TODO: Its possible the persistence load screws up refresh for Vimtex
vim.api.nvim_create_user_command(
  "Restart",
  'restart lua require("persistence").load({ last = true })',
  { desc = "Restart Neovim and reload last session on reopen" }
)

-- stylua: ignore
vim.api.nvim_create_user_command("R", "Restart", { desc = "(Restart Alias) Restart Neovim and reload last session on reopen" })
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
    vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { buffer = ev.buf, desc = "Exit terminal mode" })
    -- This is so insert mode gets hit if the pattern matches
    vim.cmd("startinsert")
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
    vim.keymap.set("n", "<localleader>s", function()
      require("mnf.scratch.python").run({ buf = ev.buf })
    end, { buffer = ev.buf, desc = "Source python file" })

    vim.keymap.set("v", "<localleader>s", function()
      require("mnf.scratch.python").run({ buf = ev.buf })
    end, { buffer = ev.buf, desc = "Run visually selected code" })
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

-- We are never cviring this out are we
-- local grp = vim.api.nvim_create_augroup("ScrollInit", { clear = true })
-- vim.api.nvim_create_autocmd("WinNew", {
--   group = grp,
--   callback = function(ev)
--     vim.api.nvim_set_option_value("scroll", 15, { scope = "local", win = ev.win })
--   end,
--   desc = "Set scroll once for new windows",
-- })
