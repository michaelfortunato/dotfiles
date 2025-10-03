local M = {
  show_statusline = true,
}
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
    "michaelfortunato/LazyVim",
    opts = {
      colorscheme = "github_dark_default",
      -- colorscheme = "catppuccin-mocha",
      -- colorscheme = "tokyonight-night",
      -- colorscheme = "default",
    },
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
  {
    ---@module "lualine"
    "nvim-lualine/lualine.nvim",
    -- TODO: Add maximize status to the lualine
    dependencies = { "michaelfortunato/LazyVim", "declancm/maximize.nvim" },
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
      local icons = LazyVim.config.icons

      opts.sections.lualine_c = {
        LazyVim.lualine.root_dir(),
        {
          "diagnostics",
          symbols = {
            error = icons.diagnostics.Error,
            warn = icons.diagnostics.Warn,
            info = icons.diagnostics.Info,
            hint = icons.diagnostics.Hint,
          },
        },
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        { "filename", path = 2 },
      }
      opts.sections.lualine_z = {
        function()
          local bufnum = vim.api.nvim_get_current_buf()
          return "Buf: " .. bufnum
        end,
      }
      table.insert(opts.sections.lualine_x, {
        function()
          -- if not already loaded, do not load this as lualine is not Lazy
          local curr = require("mnf.terminal.jobs").get_current()
          local count = require("mnf.terminal.jobs").count()
          local label
          if curr ~= nil then
            label = curr .. "/" .. count
          else
            label = count
          end
          return "👷 " .. label
        end,
        cond = function()
          return package.loaded["mnf.terminal.jobs"] and require("mnf.terminal.jobs").count() > 0
        end,
      })
      table.insert(opts.sections.lualine_x, {
        function()
          -- if not already loaded, do not load this as lualine is not Lazy
          local curr = require("mnf.terminal.managed").get_current()
          local count = require("mnf.terminal.managed").count()
          local label
          if curr ~= nil then
            label = curr .. "/" .. count
          else
            label = count
          end
          -- print(label)
          return "📺 " .. label
        end,
        cond = function()
          return package.loaded["mnf.terminal.managed"] and require("mnf.terminal.managed").count() > 0
        end,
      })

      opts.sections.lualine_y = {
        -- LazyVim had this, not a fan.
        -- { "progress", separator = " ", padding = { left = 1, right = 0 } },
        { "location", padding = { left = 0, right = 1 } },
      }
      -- Add a minimal winbar component rendered by lualine (top-right)
      -- Shows "MAX" and/or the tab count when > 1
      -- FIXME: Uncomment whne you get the tabline to actually go away
      -- when tab1 and there is no flash at startup
      -- local function winbar_status()
      --   local parts = {}
      --   if vim.t.maximized then
      --     table.insert(parts, "MAX")
      --   end
      --   local tabs = #vim.api.nvim_list_tabpages()
      --   if tabs > 1 then
      --     table.insert(parts, tostring(tabs))
      --   end
      --   return table.concat(parts, " ")
      -- end
      -- opts.tabline = {}
      -- opts.tabline.lualine_z = opts.tabline.lualine_z or {}
      -- table.insert(opts.tabline.lualine_z, {
      --   winbar_status,
      --   cond = function()
      --     return vim.t.maximized or #vim.api.nvim_list_tabpages() > 1
      --   end,
      -- })
    end,
    ---@type LazyKeysSpec[]
    keys = {
      {
        "<leader>ua",
        function()
          M.show_statusline = not M.show_statusline
          ---@diagnostic disable-next-line: missing-fields
          require("lualine").hide({
            place = {
              "statusline",
              -- The only others could be "tabline", "winbar"
            }, -- The segment this change applies to.
            unhide = M.show_statusline,
          })
          if M.show_statusline == false then
            vim.opt.laststatus = 0
            -- ref: https://github.com/neovim/neovim/issues/18965#issuecomment-1273195466
            -- vim.opt.laststatus = 0
            -- vim.api.nvim_set_hl(0 , 'Statusline', {link = 'Normal'})
            -- vim.api.nvim_set_hl(0 , 'StatuslineNC', {link = 'Normal'})
            -- local str = string.repeat('-', vim.api.nvim_win_get_width(0))
            -- vim.opt.statusline = str
          end
        end,
        desc = "Toggle Statusline",
      },
    },
  },
}
