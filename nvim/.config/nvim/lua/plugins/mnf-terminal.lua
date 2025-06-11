-- lua/plugins/mnf.lua (with optional configuration)
local last_command_id = 1
return {
  name = "mnf.terminal",
  dir = vim.fn.stdpath("config"),
  main = "mnf.terminal", -- This tells lazy.nvim which module to call
  -- dependencies = { "folke/snacks.nvim" },
  config = function()
    local mnf_terminal = require("mnf.terminal.managed")
    for i = 1, 3 do
      vim.keymap.set({ "n", "t" }, ";" .. i, function()
        mnf_terminal.toggle_terminal(i)
      end, { desc = "Toggle Terminal " .. i })
      -- vim.keymap.set({ "n", "t" }, ".c" .. i, function()
      --   mnf_terminal.set_command(i)
      -- end, { desc = "Set Command For Terminal " .. i })
      -- vim.keymap.set({ "n", "t" }, "." .. i, function()
      --   mnf_terminal.run_command(i)
      --   last_command_id = i
      -- end, { desc = "Run Command For Terminal " .. i })
      vim.keymap.set({ "v" }, ";" .. i, function()
        mnf_terminal.send_to_terminal(i)
      end, { desc = "Send To Terminal " .. i })
    end
    vim.keymap.set({ "n", "t" }, ";;", function()
      local last_used_term = mnf_terminal.get_last_used_terminal()
      mnf_terminal.toggle_terminal(last_used_term)
    end, { desc = "Toggle Terminal" })
    vim.keymap.set({ "n", "t" }, ";f", function()
      mnf_terminal.toggle_layout()
    end, { desc = "Toggle Terminal Layout" })
    vim.keymap.set({ "n", "t" }, ";g", function()
      mnf_terminal.pick_terminal(function(id)
        mnf_terminal.toggle_terminal(id)
      end)
    end, { desc = "List Terminals" })
    vim.keymap.set({ "n", "v" }, ";s", function()
      local last_used_term = mnf_terminal.get_last_used_terminal()
      mnf_terminal.send_to_terminal(last_used_term, "FILE")
    end, { desc = "Send File To Current Terminal" })
    vim.keymap.set({ "v" }, ";;", function()
      local last_used_term = mnf_terminal.get_last_used_terminal()
      mnf_terminal.send_to_terminal(last_used_term)
    end, { desc = "Send Selection To Current Terminal" })
    -- vim.keymap.set({ "n", "t" }, "..", function()
    --   mnf_terminal.run_command(last_command_id)
    -- end, { desc = "Run Previous Command" })
  end,
  opts = {},
  lazy = false,
}
