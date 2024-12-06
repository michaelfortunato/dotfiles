return {
  "folke/snacks.nvim",
  opts = {
    ---@class snacks.dashboard.Config
    dashboard = {
      preset = { header = [[mnf.]] },
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
