local M = {}
-- Place this in your `init.lua` or another Neovim config file to add:
-- A keymap (<leader>lt) that bootstraps `~/.config/nvim/.lazy.lua` with your template.
M.template = [[ 
-- Example `~/.config/nvim/.lazy.lua` template
-- Everything is commented out; uncomment and tweak as needed.
return {}

-- =========================
-- 1. Key MAPPINGS
-- =========================

-- vim.keymap.set("n", "<leader>h", ":split<CR>", { noremap = true, silent = true, 
--  expr = true, -- treat the Lua return as a key‑sequence
-- })
-- vim.keymap.set("n", "<leader>v", ":vsplit<CR>", { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>rn", function()
--   vim.opt.relativenumber = not vim.opt.relativenumber:get()
-- end, { noremap = true, silent = true })
-- vim.keymap.del("n", "<leader>h")
-- vim.keymap.set("n", "<leader>f", "<cmd>Telescope find_files<CR>", { noremap = true, silent = true })

-- =========================
-- 2. AUTOCOMMANDS
-- =========================

-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = "*.lua",
--   callback = function()
--     vim.lsp.buf.format({ async = false })
--   end,
-- })

-- local pygrp = vim.api.nvim_create_augroup("PythonSettings", { clear = true })
-- vim.api.nvim_create_autocmd("FileType", {
--   group = pygrp,
--   pattern = "python",
--   callback = function()
--     vim.opt_local.shiftwidth = 4
--     vim.opt_local.tabstop   = 4
--   end,
-- })

-- =========================
-- 3. Minimal lazy.nvim SPEC
-- =========================

-- return {
--   {
--     "nvim-treesitter/nvim-treesitter",
--     build = ":TSUpdate",
--     lazy  = false,
--   },
--   {
--     "nvim-lualine/lualine.nvim",
--     event = "VimEnter",
--     opts  = {
--       options = {
--         theme               = "gruvbox",
--         section_separators  = "",
--         component_separators = "|",
--       },
--     },
--   },
--   {
--     "nvim-telescope/telescope.nvim",
--     cmd          = "Telescope",
--     dependencies = { "nvim-lua/plenary.nvim" },
--     opts         = {
--       defaults = { layout_strategy = "horizontal" },
--     },
--   },
-- }
]]
return M
