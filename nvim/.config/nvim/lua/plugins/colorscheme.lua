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
      -- colorscheme = "default",
      colorscheme = "catppuccin-mocha",
    },
  },
  {
    "declancm/maximize.nvim",
    config = true,
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
  {
    "nvim-lualine/lualine.nvim",
    -- TODO: Add maximize status to the lualine
    dependencies = { "LazyVim/LazyVim", "declancm/maximize.nvim" },
    event = "VeryLazy",
    opts = function(_, opts)
      -- Get current colorscheme
      local current_colorscheme = vim.g.colors_name or "default"

      -- Use auto theme by default
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
      })

      -- Only apply custom high-contrast settings for default theme
      if current_colorscheme == "default" then
        -- Custom high-contrast theme for default colorscheme
        local custom_theme = {
          normal = {
            a = { fg = "black", bg = "#a3d4d5", gui = "bold" },
            b = { fg = "#ffffff", bg = "#3c3c3c" },
            c = { fg = "#ffffff", bg = "#222222" },
          },
          insert = {
            a = { fg = "black", bg = "#8ec07c", gui = "bold" },
            b = { fg = "#ffffff", bg = "#3c3c3c" },
          },
          visual = {
            a = { fg = "black", bg = "#d38ebe", gui = "bold" },
            b = { fg = "#ffffff", bg = "#3c3c3c" },
          },
          replace = {
            a = { fg = "black", bg = "#ea6962", gui = "bold" },
            b = { fg = "#ffffff", bg = "#3c3c3c" },
          },
          inactive = {
            a = { fg = "#d4d4d4", bg = "#444444" },
            b = { fg = "#d4d4d4", bg = "#3c3c3c" },
            c = { fg = "#d4d4d4", bg = "#323232" },
          },
        }

        opts.options.theme = custom_theme
      end
    end,
  },
}
