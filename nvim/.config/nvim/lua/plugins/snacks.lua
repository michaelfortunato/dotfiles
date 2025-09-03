return {
  "michaelfortunato/snacks.nvim",
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
            action = ":Telescope find_files sort_mru=true sort_lastused=true ignore_current_buffer=true",
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
    -- image = {},
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
