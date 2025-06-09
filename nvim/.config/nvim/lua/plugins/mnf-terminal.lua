-- lua/plugins/mnf.lua (with optional configuration)
local last_used_term = 1
return {
  name = "mnf.terminal",
  dir = vim.fn.stdpath("config"),
  main = "mnf.terminal", -- This tells lazy.nvim which module to call
  config = function()
    local mnf_terminal = require("mnf.terminal.managed")
    for i = 1, 3 do
      vim.keymap.set({ "n", "t" }, ";" .. i, function()
        mnf_terminal.toggle_terminal(i)
        last_used_term = i
      end, { desc = "Toggle Terminal" .. i })
      vim.keymap.set({ "v" }, ";" .. i, function()
        mnf_terminal.send_to_terminal(i)
      end, { desc = "Send To Terminal" .. i })
    end
    vim.keymap.set({ "n", "t" }, ";;", function()
      mnf_terminal.toggle_terminal(last_used_term)
    end, { desc = "Toggle Terminal" })
    vim.keymap.set({ "n", "t" }, ";f", function()
      mnf_terminal.toggle_layout()
    end, { desc = "Toggle Terminal Layout" })
    vim.keymap.set({ "n", "t" }, ";l", function()
      mnf_terminal.pick_terminal(function(id)
        mnf_terminal.toggle_terminal(id)
        last_used_term = id
      end)
    end, { desc = "Toggle Terminal Layout" })
    vim.keymap.set({ "n" }, ";s", function()
      mnf_terminal.send_to_terminal(last_used_term, "FILE")
    end, { desc = "Send File To Current Terminal" })
    vim.keymap.set({ "v" }, ";s", function()
      mnf_terminal.send_to_terminal(last_used_term)
    end, { desc = "Send File To Current Terminal" })
  end,
  opts = {},
  lazy = false,
}
