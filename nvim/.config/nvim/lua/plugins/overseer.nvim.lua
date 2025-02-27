--- FIXME: I am not a fan of this plugin. I think I can do
--- something much simpler.
return {
  ---@module "overseer"
  "stevearc/overseer.nvim",
  opts = {},
  -- dependencies = {
  --   "folke/which-key.nvim",
  --   optional = true,
  --   opts = {
  --     defaults = {
  --       ["<leader>t"] = { name = "+task" },
  --     },
  --   },
  -- },
  --
  cmd = {
    "OverseerOpen",
    "OverseerClose",
    "OverseerToggle",
    "OverseerSaveBundle",
    "OverseerLoadBundle",
    "OverseerDeleteBundle",
    "OverseerRunCmd",
    "OverseerRun",
    "OverseerInfo",
    "OverseerBuild",
    "OverseerQuickAction",
    "OverseerTaskAction",
    "OverseerClearCache",
  },
  -- keys = {
  --   -- group
  --   { "<leader>t", group = "task", desc = "Task Runner" },
  --   { "<leader>tt", "<cmd>OverseerToggle<cr>", desc = "Task toggle" },
  --   { "<leader>tr", "<cmd>OverseerRun<cr>", desc = "Run task" },
  --   { "<leader>ts", "<cmd>OverseerQuickAction<cr>", desc = "Action recent task" },
  --   { "<leader>ti", "<cmd>OverseerInfo<cr>", desc = "Overseer Info" },
  --   { "<leader>tb", "<cmd>OverseerBuild<cr>", desc = "Task builder" },
  --   { "<leader>ta", "<cmd>OverseerTaskAction<cr>", desc = "Task action" },
  --   { "<leader>tc", "<cmd>OverseerClearCache<cr>", desc = "Clear cache" },
  -- },
}
