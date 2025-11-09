local M = {}
--- See if we can fix this https://github.com/catppuccin/nvim/issues/491
local function set_options()
  vim.g.neovide_macos_simple_fullscreen = true
  vim.g.neovide_show_border = false
  vim.g.neovide_scale_factor = 1.0

  -- Animations

  -- Option 1 Before the migration
  local function animation_profile1()
    -- NOTE: vim.g.neovide_cursor_animation_length = 0.07 wasn't horrendous
    vim.g.neovide_cursor_trail_size = 0.0
    vim.g.neovide_cursor_animation_length = 0.0
    vim.g.neovide_scroll_animation_far_lines = 1
    vim.g.neovide_scroll_animation_length = 0.5
    vim.g.neovide_cursor_animation_length = 0
  end

  --- Optoin 2 Moderate
  local function animation_profile2()
    -- vim.g.neovide_position_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0.07
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_cursor_animate_in_insert_mode = true
    vim.g.neovide_cursor_animate_command_line = true
    vim.g.neovide_scroll_animation_far_lines = 0
    vim.g.neovide_scroll_animation_length = 0.00
  end

  --- Option 3 Most Aggressive I can reasonably do without having a annuerism
  local function animation_profile3()
    -- vim.g.neovide_position_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0.07
    vim.g.neovide_cursor_short_animation_length = 0.00 -- This is the time is takes to do short motions
    vim.g.neovide_cursor_trail_size = 0.5
    vim.g.neovide_cursor_animate_in_insert_mode = true
    vim.g.neovide_cursor_animate_command_line = true
    vim.g.neovide_scroll_animation_far_lines = 0 --

    -- vim.g.neovide_scroll_animation_length = 0.00
  end

  --- Option 5 Most Aggressive I can reasonably do without having a annuerism
  local function animation_profile5()
    -- vim.g.neovide_position_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0.07
    vim.g.neovide_cursor_short_animation_length = 0.00 -- This is the time is takes to do short motions
    vim.g.neovide_cursor_trail_size = 0.5
    vim.g.neovide_cursor_animate_in_insert_mode = true
    vim.g.neovide_cursor_animate_command_line = true
    vim.g.neovide_scroll_animation_far_lines = 0 --
    vim.g.neovide_scroll_animation_length = 0.00
  end

  -- Option 4 Everything Disabled
  local function animation_profile4()
    vim.g.neovide_position_animation_length = 0
    vim.g.neovide_cursor_animation_length = 0.00
    vim.g.neovide_cursor_trail_size = 0
    vim.g.neovide_cursor_animate_in_insert_mode = false
    vim.g.neovide_cursor_animate_command_line = false
    vim.g.neovide_scroll_animation_far_lines = 0
    vim.g.neovide_scroll_animation_length = 0.00
  end

  -- you are crazy for ths one!
  -- vim.opt.guifont = "NewComputerModernMono10"
  vim.opt.guifont = "MesloLGS NF"
  animation_profile1()
end

local function set_keymaps()
  -- vim.keymap.set("n", "<D-s>", ":w<CR>", { noremap = true, silent = true }) -- Save
  -- vim.keymap.set("v", "<D-c>", '"+y', { noremap = true, silent = true }) -- Copy
  -- vim.keymap.set("n", "<D-v>", '"+p', { noremap = true, silent = true }) -- Paste normal mode
  -- vim.keymap.set("v", "<D-v>", '"+p', { noremap = true, silent = true }) -- Paste visual mode
  -- -- TODO: !
  -- -- BROKEN
  -- -- vim.keymap.set("c", "<D-v>", "<C-R>+", { noremap = true, silent = true }) -- Paste command mode
  -- -- vim.keymap.set("!", "<D-v>", "<C-R>+", { noremap = true, silent = true }) -- Paste command mode
  -- -- Partially broken
  -- vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli', { noremap = true, silent = true }) -- Paste insert mode

  --  Lets see if the below is better
  vim.keymap.set("n", "<D-s>", ":w<CR>") -- Save
  vim.keymap.set("v", "<D-c>", '"+y') -- Copy
  vim.keymap.set("n", "<D-v>", '"+P') -- Paste normal mode
  vim.keymap.set("v", "<D-v>", '"+P') -- Paste visual mode
  vim.keymap.set("c", "<D-v>", "<C-R>+") -- Paste command mode
  vim.keymap.set("i", "<D-v>", '<ESC>l"+Pli') -- Paste insert mode
  -- Allow clipboard copy paste in neovim
  vim.api.nvim_set_keymap("", "<D-v>", "+p<CR>", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("!", "<D-v>", "<C-R>+", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("t", "<D-v>", "<C-R>+", { noremap = true, silent = true })
  vim.api.nvim_set_keymap("v", "<D-v>", "<C-R>+", { noremap = true, silent = true })

  local change_scale_factor = function(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
  end
  vim.keymap.set("n", "<D-=>", function()
    change_scale_factor(1.25)
  end)
  vim.keymap.set("n", "<D-->", function()
    change_scale_factor(1 / 1.25)
  end)

  vim.keymap.set("n", "<C-/>", function()
    Snacks.terminal(nil, { cwd = LazyVim.root() })
  end, { desc = "Terminal (Root Dir)" })
  vim.keymap.set("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
end

function M.setup()
  if vim.g.neovide then
    set_options()
    set_keymaps()
  end
end

return M
