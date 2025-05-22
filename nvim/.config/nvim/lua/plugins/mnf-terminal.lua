-- lua/plugins/mnf.lua (with optional configuration)
return {
  {
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
  },
}
