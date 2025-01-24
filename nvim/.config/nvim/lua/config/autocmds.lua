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
  pattern = { "tex" },
  callback = function(ev)
    local cmp = require("cmp")
    cmp.setup({
      sources = {
        { name = "luasnip", option = { show_autosnippets = false } },
        --  NOTE:  Commenting this out is helpful for performance  { name = "nvim_lsp" },
        -- { name = "buffer" },
        -- { name = "emoji" },
      },
      completion = { autocomplete = { cmp.TriggerEvent.TextChanged } },
    })
  end,
})

-- vim.api.nvim_create_autocmd("FileType", {
--   --- TODO: Problably should be moved into an ftpluin or a snippet
--   --- Going to make this a snippet
--   pattern = { "tex" },
--   callback = function(ev)
--     local MiniPairs = require("mini.pairs")
--     MiniPairs.map_buf(0, "i", "$", { action = "closeopen", pair = "$$" })
--     MiniPairs.map_buf(0, "i", "(", { action = "open", pair = "()" })
--     MiniPairs.map_buf(0, "i", "[", { action = "open", pair = "[]" })
--     MiniPairs.map_buf(0, "i", "{", { action = "open", pair = "{}" })
--   end,
-- })

vim.api.nvim_create_autocmd("FileType", {
  --- TODO: Problably should be moved into an ftpluin
  pattern = { "lua" },
  callback = function(ev)
    vim.api.nvim_buf_set_keymap(ev.buf, "n", "<leader>ll", "<Cmd>source %<CR>", { desc = "Source lua file" })
  end,
})

-- -- Make sure we RE-enter terminal mode when focusing back on terminal
-- vim.api.nvim_create_autocmd({ "BufEnter", "TermOpen" }, {
--   callback = function()
--     vim.cmd("startinsert")
--   end,
--   pattern = { "term://*" },
--   group = vim.api.nvim_create_augroup("TermGroup", { clear = true }),
-- })
