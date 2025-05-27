-- lua/plugins/mnf.lua (with optional configuration)
return {
  name = "mnf.terminal",
  dir = vim.fn.stdpath("config"),
  main = "mnf.terminal", -- This tells lazy.nvim which module to call
  -- config = function()
  --   require("mnf.terminal").setup({
  --     -- You could add default commands here if you implement that feature
  --     -- default_system_command = "npm run dev",
  --     -- default_integrated_command = "python3",
  --   })
  -- end,
  opts = {},
  dependencies = {
    "folke/snacks.nvim",
  },
  lazy = false,
  ---@type LazyKeysSpec[]
  keys = {
    {
      ";;",
      function()
        local mnf_terminal = require("mnf.terminal.managed")
        mnf_terminal.toggle_terminal(mnf_terminal.terminal_state.current or 1)
      end,
      mode = { "n", "t" },
      desc = "Toggle Terminal",
    },
    {
      ";1",
      function()
        local mnf_terminal = require("mnf.terminal.managed")
        mnf_terminal.toggle_terminal(1)
      end,
      mode = { "n", "t" },
      desc = "Toggle Terminal 1",
    },
    {
      ";2",
      function()
        local mnf_terminal = require("mnf.terminal.managed")
        mnf_terminal.toggle_terminal(2)
      end,
      mode = { "n", "t" },
      desc = "Toggle Terminal 2",
    },
    {
      ";3",
      function()
        local mnf_terminal = require("mnf.terminal.managed")
        mnf_terminal.toggle_terminal(3)
      end,
      mode = { "n", "t" },
      desc = "Toggle Terminal 3",
    },
    {
      ";f",
      function()
        local mnf_terminal = require("mnf.terminal.managed")
        mnf_terminal.toggle_layout()
      end,
      mode = { "n", "t" },
      desc = "Toggle Terminal Layout",
    },
  },
}
