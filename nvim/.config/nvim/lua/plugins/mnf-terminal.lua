-- lua/plugins/mnf.lua (with optional configuration)
-- local last_command_id = 1
return {
  {
    name = "mnf.terminal",
    lazy = true,
    dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "mnf", "terminal"),
    dependencies = { "folke/which-key.nvim", "michaelfortunato/snacks.nvim" },
    init = function()
      -- TODO: makes me safe and fix the operator pending issue
      -- local del = function(...)
      --   return pcall(vim.keymap.del, ...)
      -- end
      -- del("x", ";")
      -- del("o", ";")
      for i = 1, 9 do
        vim.keymap.set({ "n" }, ";" .. i, function()
          local mnf_terminal = require("mnf.terminal.managed")
          mnf_terminal.toggle_terminal(i)
        end, { desc = "Toggle Terminal " .. i })
        vim.keymap.set({ "v" }, ";" .. i, function()
          local mnf_terminal = require("mnf.terminal.managed")
          mnf_terminal.send_to_terminal(i)
        end, { desc = "Send To Terminal " .. i })
      end

      vim.keymap.set("n", "fg", function()
        vim.t.mnf_float = vim.t.mnf_float or { win = nil, buf = nil }
        local state = vim.t.mnf_float
        if state.win and vim.api.nvim_win_is_valid(state.win) then
          vim.api.nvim_win_close(state.win, true)
          vim.notify("Closing " .. state.win)
          state.win = nil
          return
        end

        local cur = vim.api.nvim_get_current_buf()
        state.buf = cur
        local obj = require("snacks").win.new({
          style = "big_float",
          buf = state.buf,
          on_close = function(_)
            -- do NOT overwrite state.buf here
            state.win = nil
          end,
        })
        state.win = obj.win
      end, { desc = "Toggle float for current buffer (tab-scoped)" })

      vim.keymap.set("n", ";;", function()
        require("mnf.terminal.managed").toggle_terminal(1)
      end, { desc = "Send File To Terminal (pick)" })

      -- vim.keymap.set("t", ";;", function()
      --   local mnf_terminal = require("mnf.terminal.managed")
      --   local last_used_term = mnf_terminal.get_last_used_terminal()
      --   mnf_terminal.toggle_terminal(last_used_term)
      -- end, { desc = "Toggle Terminal" })

      vim.keymap.set({ "n" }, ";f", function()
        local mnf_terminal = require("mnf.terminal.managed")
        mnf_terminal.toggle_layout()
      end, { desc = "Toggle Terminal Layout" })

      vim.keymap.set({ "n" }, ";g", function()
        require("mnf.terminal.managed").pick_and_focus_terminal_buffer()
      end, { desc = "List Terminal Buffers" })

      vim.keymap.set("n", ";l", function()
        require("mnf.terminal.managed").send_line_to_terminal_picker()
      end, { desc = "Send Line To Terminal (pick)" })

      vim.keymap.set({ "n" }, ";a", function()
        require("mnf.terminal.managed").send_file_to_terminal_picker()
        --TODO: Ensure we enter intsert mode upon navigating
        --to terminal after execution
      end, { desc = "Send File To Terminal (pick)" })

      vim.keymap.set("v", ";;", function()
        require("mnf.terminal.managed").send_visual_selection_to_terminal_picker()
      end, { desc = "Send Selection To Terminal (pick)" })
      vim.keymap.set("v", ";l", function()
        require("mnf.terminal.managed").send_visual_selection_to_terminal_picker()
      end, { desc = "Send Selection To Terminal (pick)" })
      vim.keymap.set("v", ";a", function()
        require("mnf.terminal.managed").send_visual_selection_to_terminal_picker()
      end, { desc = "Send Selection To Terminal (pick)" })

      vim.api.nvim_create_user_command("UseKitty", function()
        require("mnf.terminal.managed").use_kitty()
        -- Only not default
      end, { desc = "Use kitty terminal instead of the integrated one" })
      vim.api.nvim_create_user_command("Useintegrated", function()
        require("mnf.terminal.managed").use_integrated()
        -- Default is set in mnf.terminal.managed
      end, { desc = "(Recommended) Use the integrated terminal instead of kitty." })

      -- .<id> configures or reruns job
      local PLUGIN_LEADER = "."
      for i = 1, 9 do
        vim.keymap.set({ "n" }, PLUGIN_LEADER .. i, function()
          local mnf_jobs = require("mnf.terminal.jobs")
          mnf_jobs.configure_job(tostring(i))
        end, { desc = "Configure/run job " .. i })
      end

      vim.keymap.set({ "n" }, PLUGIN_LEADER .. "g", function()
        require("mnf.terminal.jobs").list_jobs()
      end, { desc = "List jobs" })
      vim.keymap.set({ "n" }, PLUGIN_LEADER .. PLUGIN_LEADER, function()
        local mnf_jobs = require("mnf.terminal.jobs")
        if not mnf_jobs.state.current_job_id then
          mnf_jobs.configure_job("1")
        else
          mnf_jobs.restart_job(mnf_jobs.state.current_job_id)
        end
      end, { desc = "Restart job" })
      vim.keymap.set({ "n" }, ".,", function()
        require("mnf.terminal.jobs").toggle()
      end, { desc = "Show/Hide Job Window" })

      vim.keymap.set({ "n" }, PLUGIN_LEADER .. "f", function()
        require("mnf.terminal.jobs").toggle_layout()
      end, { desc = "Toggle job layout" })

      -- .k kills current job
      vim.keymap.set({ "n" }, PLUGIN_LEADER .. "k", function()
        require("mnf.terminal.jobs").kill_current_job()
      end, { desc = "Kill current job" })

      -- Send mappings (visual mode)
      vim.keymap.set("v", PLUGIN_LEADER .. PLUGIN_LEADER, function()
        require("mnf.terminal.jobs").send_selection()
      end, { desc = "Send selection to job" })
      -- Send mappings (normal mode)
      vim.keymap.set({ "v", "n" }, PLUGIN_LEADER .. "l", function()
        require("mnf.terminal.jobs").send_line()
      end, { desc = "Send line to job" })
      vim.keymap.set({ "n", "v" }, PLUGIN_LEADER .. "a", function()
        require("mnf.terminal.jobs").send_file()
      end, { desc = "Send file to job" })

      -- Commands
      vim.api.nvim_create_user_command("JobList", function()
        require("mnf.terminal.jobs").list_jobs()
      end, { desc = "List all jobs" })
      vim.api.nvim_create_user_command("JobToggle", function()
        require("mnf.terminal.jobs").toggle()
      end, { desc = "Toggle job window" })
      vim.api.nvim_create_user_command("JobLayout", function()
        require("mnf.terminal.jobs").toggle_layout()
      end, { desc = "Toggle job layout" })
      vim.api.nvim_create_user_command("JobKill", function()
        require("mnf.terminal.jobs").kill_current_job()
      end, { desc = "Kill current job" })
    end,
  },
}
