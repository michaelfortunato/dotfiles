return {
  "mfussenegger/nvim-dap",
  dependencies = {
    -- fancy UI for the debugger
    {
      "rcarriga/nvim-dap-ui",
      opts = {},
      config = function(_, opts)
        local dap = require("dap")
        dap.configurations.cpp = {
          {
            type = "cppdbg",
            request = "attach",
            program = "/Users/mfortuna/Instances/BASIC/bin/irisdb",
            MIMode = "lldb",
            miDebuggerPath = "/Users/mfortuna/.iscdev/lldb-mi",
            name = "New",
            processId = "${command:pickProcess}",
          },
        }
        dap.configurations.c = {
          {
            type = "cppdbg",
            request = "attach",
            program = "/Users/mfortuna/Instances/BASIC/bin/irisdb",
            MIMode = "lldb",
            miDebuggerPath = "/Users/mfortuna/.iscdev/lldb-mi",
            name = "New",
            processId = "${command:pickProcess}",
          },
        }
        -- setup dap config by VsCode launch.json file
        -- require("dap.ext.vscode").load_launchjs()
        local dapui = require("dapui")
        dapui.setup(opts)
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open({})
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
          dapui.close({})
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
          dapui.close({})
        end
      end,
    },
  },
  config = function()
    -- "Joakker/lua-json5",
    -- require("dap.ext.vscode").json_decode = require("json5").parse
    -- /Users/mfortuna/Perforce/Users/mfortuna/iris/latest/.vscode/launch.json
    -- require("dap.ext.vscode" ).load_launchjs("/Users/mfortuna/.iscdev/launch.json", { cppdbg = { "c", "cpp" } })
  end,
}
