---@module "snacks"
return {
  "michaelfortunato/snacks.nvim",
  ---@type snacks.Config
  opts = {
    dashboard = {
      preset = {
        header = [[mnf.]],
        -- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
        ---@type fun(cmd:string, opts:table)|nil
        pick = nil,
        -- Used by the `keys` section to show keymaps.
        -- Set your custom keymaps here.
        -- When using a function, the `items` argument are the default keymaps.
        ---@type snacks.dashboard.Item[]
        keys = {
          -- Enable once fff gets better?
          -- { icon = " ", key = "f", desc = "Find File", action = ":lua require('fff').find_files()" },
          {
            icon = " ",
            key = "f",
            desc = "Find File",
            -- action = ":Telescope find_files sort_mru=true sort_lastused=true ignore_current_buffer=true",
            action = function()
              Snacks.picker.smart()
            end,
          },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          {
            icon = " ",
            key = "c",
            desc = "Config",
            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
          },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
    -- For quarto plugins, but also keep here so I can centrally
    -- manage this monoltith plugin and disable it for typst
    -- Also though this is a pretty sick plugin
    image = {
      enabled = true,
      doc = {
        enabled = true,
        max_width = 300,
        max_height = 300,
      },
      math = { enabled = false },
    },
    --
    -- Concepts
    --
    -- - Finders: sources that produce items. Common ones: files, buffers, recent, git_files, grep, plus LSP pickers.
    -- - Smart: a convenience wrapper over pickers; by default it aggregates multiple finders (buffers, recent, files) and applies a
    --   matcher and transform.
    -- - Filter/matcher/transform:
    --     - matcher: scoring/heuristics (e.g., cwd_bonus, frecency).
    --     - filter: prune items (directory, include/exclude, etc.).
    --     - transform: post-process (e.g., unique_file to dedupe).
    -- image = {},
    picker = {
      win = {
        input = {
          keys = {
            -- TODO: Theres a way to get <Esc> to close the hlep window
            -- window if its showing?
            -- local function close_help_or_picker(picker)
            --   for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            --     local buf = vim.api.nvim_win_get_buf(win)
            --     if vim.bo[buf].filetype == "snacks_win_help" then
            --       picker:action("hide_help")
            --       return
            --     end
            --   end
            --   picker:action("close")
            -- end
            ["<Esc>"] = { "close", mode = { "n", "i" } },
            ["<c-h>"] = { "toggle_hidden", mode = { "i", "n" } },
            ["<c-y>"] = { "confirm", mode = { "i", "n" } },
            ["<c-g>i"] = { "toggle_ignored", mode = { "i", "n" } },
            ["<c-o>"] = { "edit_split", mode = { "i", "n" } },
            ["<c-o>"] = { "edit_split", mode = { "i", "n" } },
            ["?"] = { "toggle_help_input", mode = { "i", "n" } },
            ["<c-u>"] = false,
            ["<c-a>"] = false,
            ["<c-d>"] = { "bufdelete", mode = { "n", "i" } },
            ["<c-c>"] = { "yank", mode = { "n", "i" } },
            ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
            ["<D-c>"] = { "yank", mode = { "n", "i" } },
            ["<D-p>"] = { "paste", mode = { "n", "i" } },
            -- Probably won't work given this is Tab
            ["<c-i>"] = { "print_path", mode = { "n", "i" } },
            ["<c-.>"] = { "cd", mode = { "n", "i" } },
            ["<c-;>"] = { "terminal", mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            ["?"] = { "toggle_help_list", mode = { "i", "n" } },
            ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
          },
        },
        preview = {
          keys = {
            ["?"] = { "toggle_help_list", mode = { "i", "n" } },
            ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
          },
        },
      },
    },
  },

  --    -- preset = {
  --    --   header = [[mnf]],
  --    -- },
  -- opts = function(_, opts)
  --  ---@class snacks.dashboard.Config
  --  opts.dashboard = {
  --    -- preset = {
  --    --   header = [[mnf]],
  --    -- },
  --    sections = {
  --      {
  --        section = "terminal",
  --        -- cmd = "kitten icat ~/mnf3.png",
  --        cmd = "kitten icat --use-window-size 1,1,100,100 ~/mnf3.png",
  --      },
  --    },
  --  }
  --  return opts
  --end,
}
