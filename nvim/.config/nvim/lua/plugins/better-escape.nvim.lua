return {
  "max397574/better-escape.nvim",
  config = function()
    require("better_escape").setup({
      timeout = 150, -- after `timeout` passes, you can press the escape key and the plugin will ignore it
      default_mappings = false, -- setting this to false removes all the default mappings
      mappings = {
        t = {
          ["<Tab>"] = {
            -- ["<Tab>"] = "<Cmd>tabnext #<CR>",
            ["l"] = "<Cmd>tabnext<CR>",
            ["h"] = "<Cmd>tabprev<CR>",
          },
          [";"] = {
            -- [";"] = "<Cmd>close!<CR>",
            -- -- local mnf_terminal = require("mnf.terminal.managed")
            -- -- local last_used_term = mnf_terminal.get_last_used_terminal()
            -- -- mnf_terminal.toggle_terminal(last_used_term)
            [";"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                local last_used_term = mnf_terminal.get_last_used_terminal()
                mnf_terminal.toggle_terminal(last_used_term)
              end)
            end,
            ["g"] = function()
              vim.schedule(function()
                require("mnf.terminal.managed").pick_and_focus_terminal_buffer()
              end)
            end,
            ["f"] = function()
              vim.schedule(function()
                require("mnf.terminal.managed").toggle_layout()
              end)
            end,
            ["1"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(1)
              end)
            end,
            ["2"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(2)
              end)
            end,
            ["3"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(3)
              end)
            end,
            ["4"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(4)
              end)
            end,
            ["5"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(5)
              end)
            end,
            ["6"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(6)
              end)
            end,
            ["7"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(7)
              end)
            end,
            ["8"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(8)
              end)
            end,
            ["9"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(9)
              end)
            end,
            ["0"] = function()
              vim.schedule(function()
                local mnf_terminal = require("mnf.terminal.managed")
                mnf_terminal.toggle_terminal(1)
              end)
            end,
          },
          --   ["f"] = function()
          --     require("mnf.terminal.managed").toggle_layout()
          --   end,
          --   ["g"] = function()
          --     require("mnf.terminal.managed").pick_and_focus_terminal_buffer()
          --   end,
          -- },
        },
      },
    })
  end,
}
