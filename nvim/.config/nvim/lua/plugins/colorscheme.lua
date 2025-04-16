return {
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
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "tokyonight-night",
      colorscheme = "default",
    },
  },
}
