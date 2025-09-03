-- lua/plugins/mnf.lua (with optional configuration)
-- local last_command_id = 1
return {
  {
    name = "mnf.terminal",
    dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "mnf", "terminal"),
    -- main = "mnf.terminal", -- This tells lazy.nvim which module to call
    dependencies = { "folke/which-key.nvim", "folke/snacks.nvim" },
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

      vim.keymap.set({ "n" }, ";l", function()
        local last_used_term = mnf_terminal.get_last_used_terminal()
        mnf_terminal.send_to_terminal(last_used_term, "LINE")
      end, { desc = "Send Line To Current Terminal" })

      vim.keymap.set({ "v" }, ";l", function()
        local last_used_term = mnf_terminal.get_last_used_terminal()
        mnf_terminal.send_to_terminal(last_used_term)
      end, { desc = "Send Selection To Current Terminal" })

      vim.keymap.set({ "n", "v" }, ";a", function()
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
      local mnf_jobs = require("mnf.terminal.jobs")
      mnf_jobs.setup()

      vim.api.nvim_create_user_command("UseKitty", function()
        require("mnf.terminal.managed").use_kitty()
        -- Only not default
      end, { desc = "Use kitty terminal instead of the integrated one" })
      vim.api.nvim_create_user_command("Useintegrated", function()
        require("mnf.terminal.managed").use_integrated()
        -- Default is set in mnf.terminal.managed
      end, { desc = "(Recommended) Use the integrated terminal instead of kitty." })
    end,
    opts = {},
    lazy = false,
  },
  {
    -- This plugin  was ai generated and is not create sorry claude.
    name = "mnf.scratch",
    lazy = true,
    dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "mnf", "scratch"),
    -- main = "mnf.scratch", -- This tells lazy.nvim which module to call
    -- FIXME: This will make start up slowwer, as these plugins should only
    -- load if they are used
    -- dependencies = { "saghen/blink.cmp", "neovim/nvim-lspconfig", "folke/which-key.nvim", "folke/snacks.nvim" },
    -- dependencies = { "folke/which-key.nvim", "folke/snacks.nvim" },
    config = function()
      local mnf_scratch = require("mnf.scratch")
      mnf_scratch.setup()
    end,
    opts = {},
  },
}
