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
        vim.keymap.set({ "n", "t" }, ";" .. i, function()
          local mnf_terminal = require("mnf.terminal.managed")
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
          local mnf_terminal = require("mnf.terminal.managed")
          mnf_terminal.send_to_terminal(i)
        end, { desc = "Send To Terminal " .. i })
      end

      vim.keymap.set({ "n", "t" }, ";;", function()
        local mnf_terminal = require("mnf.terminal.managed")
        local last_used_term = mnf_terminal.get_last_used_terminal()
        mnf_terminal.toggle_terminal(last_used_term)
      end, { desc = "Toggle Terminal" })

      vim.keymap.set({ "n", "t" }, ";f", function()
        local mnf_terminal = require("mnf.terminal.managed")
        mnf_terminal.toggle_layout()
      end, { desc = "Toggle Terminal Layout" })

      vim.keymap.set({ "n", "t" }, ";g", function()
        local mnf_terminal = require("mnf.terminal.managed")
        mnf_terminal.pick_terminal(function(id)
          mnf_terminal.toggle_terminal(id)
        end)
      end, { desc = "List Terminals" })

      vim.keymap.set({ "n" }, ";l", function()
        local mnf_terminal = require("mnf.terminal.managed")
        local last_used_term = mnf_terminal.get_last_used_terminal()
        mnf_terminal.send_to_terminal(last_used_term, "LINE")
      end, { desc = "Send Line To Current Terminal" })

      vim.keymap.set({ "v" }, ";l", function()
        local mnf_terminal = require("mnf.terminal.managed")
        local last_used_term = mnf_terminal.get_last_used_terminal()
        mnf_terminal.send_to_terminal(last_used_term)
      end, { desc = "Send Selection To Current Terminal" })

      vim.keymap.set({ "n", "v" }, ";a", function()
        local mnf_terminal = require("mnf.terminal.managed")
        local last_used_term = mnf_terminal.get_last_used_terminal()
        mnf_terminal.send_to_terminal(last_used_term, "FILE")
      end, { desc = "Send File To Current Terminal" })

      vim.keymap.set({ "v" }, ";;", function()
        local mnf_terminal = require("mnf.terminal.managed")
        local last_used_term = mnf_terminal.get_last_used_terminal()
        mnf_terminal.send_to_terminal(last_used_term)
      end, { desc = "Send Selection To Current Terminal" })

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
        -- vim.keymap.set({ "n", "t" }, PLUGIN_LEADER .. i, function()
        vim.keymap.set({ "n" }, PLUGIN_LEADER .. i, function()
          local mnf_jobs = require("mnf.terminal.jobs")
          mnf_jobs.configure_job(tostring(i))
        end, { desc = "Configure/run job " .. i })
      end

      --- TODO Makes these buffer local with a timeout
      -- .g lists jobs
      -- vim.keymap.set({ "t", "n" }, PLUGIN_LEADER .. "l", M.list_jobs, { desc = "List jobs" })
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
      -- ., toggles job window
      -- vim.keymap.set({ "t", "n" }, ".,", M.toggle, { desc = "Show/Hide Job Window" })
      vim.keymap.set({ "n" }, ".,", function()
        require("mnf.terminal.jobs").toggle()
      end, { desc = "Show/Hide Job Window" })

      -- .l toggles layout
      -- vim.keymap.set({ "t", "n" }, PLUGIN_LEADER .. "f", M.toggle_layout, { desc = "Toggle job layout" })
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
  {
    -- This plugin  was ai generated and is not great sorry claude.
    name = "mnf.scratch",
    lazy = true,
    dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "mnf", "scratch"),
    dependencies = { "michaelfortunato/snacks.nvim" },
    init = function()
      vim.keymap.set("n", "'1", function()
        local M = require("mnf.scratch")
        M.scratch_number(1, "lua")
      end, { desc = "Open scratch buffer 1 (lua)" })
      vim.keymap.set("n", "'2", function()
        local M = require("mnf.scratch")
        M.scratch_number(2, "python")
      end, { desc = "Open scratch buffer 2 (python)" })
      vim.keymap.set("n", "'3", function()
        local M = require("mnf.scratch")
        M.scratch_number(3, "typst")
      end, { desc = "Open scratch buffer 3 (typst)" })
      -- Main scratch operations
      vim.keymap.set("n", "'g", function()
        local M = require("mnf.scratch")
        M.list_scratches()
      end, { desc = "List scratch buffers" })
      -- Commands
      vim.api.nvim_create_user_command("ScratchList", function()
        local M = require("mnf.scratch")
        M.list_scratches()
      end, { desc = "List scratch buffers" })
      vim.api.nvim_create_user_command("ScratchToggle", function()
        local M = require("mnf.scratch")
        M.toggle_scratch()
      end, { desc = "Toggle scratch buffer" })
      vim.api.nvim_create_user_command("ScratchRun", function(opts)
        local M = require("mnf.scratch")
        M.run_scratch(opts.args ~= "" and opts.args or nil)
      end, {
        desc = "Run the current (or named) scratch buffer",
        nargs = "?",
      })
      vim.api.nvim_create_user_command("ScratchNew", function(opts)
        local M = require("mnf.scratch")
        print(opts.args)
        local args = vim.split(opts.args, "%s+")
        local name = args[1] or nil
        local filetype = args[2] or name or nil
        M.create_named_scratch(name, filetype)
      end, {
        desc = "Create named scratch buffer",
        nargs = "*",
        complete = function(_, _, _)
          local M = require("mnf.scratch")
          return vim.tbl_keys(M.extension_to_filetype)
        end,
      })

      vim.api.nvim_create_user_command("ScratchCopy", function(opts)
        local M = require("mnf.scratch")
        M.copy_to_scratch(opts.args ~= "" and opts.args or nil)
      end, {
        desc = "Copy current buffer to scratch",
        nargs = "?",
      })

      vim.keymap.set("n", "''", "<Cmd>ScratchToggle<CR>", { desc = "Toggle scratch buffer" })

      -- Filetype-specific shortcuts
      vim.keymap.set("n", "'py", function()
        local M = require("mnf.scratch")
        M.show_scratch("python", { filetype = "python" })
      end, { desc = "Python scratch buffer" })

      vim.keymap.set("n", "'js", function()
        local M = require("mnf.scratch")
        M.show_scratch("javascript", { filetype = "javascript" })
      end, { desc = "JavaScript scratch buffer" })

      vim.keymap.set("n", "'lua", function()
        local M = require("mnf.scratch")
        M.show_scratch("lua", { filetype = "lua" })
      end, { desc = "Lua scratch buffer" })

      vim.keymap.set("n", "'ty", function()
        local M = require("mnf.scratch")
        M.show_scratch("typst", { filetype = "typst" })
      end, { desc = "Typst scratch buffer" })

      vim.keymap.set("n", "'tex", function()
        local M = require("mnf.scratch")
        M.show_scratch("tex", { filetype = "tex" })
      end, { desc = "TeX scratch buffer" })

      vim.keymap.set("n", "'md", function()
        local M = require("mnf.scratch")
        M.show_scratch("markdown", { filetype = "markdown" })
      end, { desc = "Markdown scratch buffer" })

      vim.keymap.set("n", "'sql", function()
        local M = require("mnf.scratch")
        M.show_scratch("sql", { filetype = "sql" })
      end, { desc = "SQL scratch buffer" })

      vim.keymap.set("n", "'sh", function()
        local M = require("mnf.scratch")
        M.show_scratch("sh", { filetype = "sh" })
      end, { desc = "Shell scratch buffer" })
    end,
    opts = {},
  },
}
