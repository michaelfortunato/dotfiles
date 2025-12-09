local M = {
  show_statusline = true,
}
vim.g.lazyvim_picker = "snacks"
return {
  {
    "michaelfortunato/LazyVim",
    dependencies = {
      { "projekt0n/github-nvim-theme", name = "github-theme" },
    },
    opts = {
      -- colorscheme = "github_dark_high_contrast",
      -- colorscheme = "github_light",
      colorscheme = "catppuccin-mocha",
      -- colorscheme = "tokyonight-night",
      -- colorscheme = "default",
    },
  },
  ---  Install and/or configure the color scheme by uncommenting out the
  ---  object then set the LazyVim/LazyVim  = opts.colorscheme=<your-scheme>
  -- {
  --   "tokyonight.nvim",
  --   lazy = true,
  --   -- lazy = false,
  --   -- priority = 1000,
  --   opts = { style = "night" },
  -- }
  -- {
  --   "rebelot/kanagawa.nvim",
  -- lazy = false,
  -- priority = 1000,
  -- config = function()
  --   require('kanagawa').setup()
  -- end,
  -- }
  -- {
  --   "AlexvZyl/nordic.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("nordic").load()
  --   end,
  -- }
  {
    "lewis6991/gitsigns.nvim",
    enabled = false,
  },
  {
    -- Make sure that catppuccin/nvim is pinned to cb56659 v1.11 release
    -- subseqeunt commits fucked up the highlihghting for python its horrible
    "catppuccin/nvim",
    name = "catppuccin",
    -- NOTE: I am concnerened with the direction catppuccinn is going in,
    -- I am pinning to v1.10.0, and not v1.11.0 out of paranoia, though my change
    -- this
    tag = "v1.10.0",
    opts = {
      -- For neovide, I was really hoping to keep neovide
      -- contained but it leaks here and I do not have time to fix it now
      -- Hopefully this is fine. I do not see me being able to add this to
      -- the neovide plugin
      term_colors = vim.g.neovide,
    },
  },
  {
    -- FIXME: Doesn't really work lol
    "declancm/maximize.nvim",
    config = true,
    lazy = false,
    keys = {
      {

        -- change a keymap
        mode = { "n" },
        "<leader>wm",
        "<cmd>Maximize<cr>",
        desc = "Toggle Maximize",
      },
    },
  },
}
