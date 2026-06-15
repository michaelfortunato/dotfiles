---@type LazyPluginSpec
return {
  "mistweaverco/kulala.nvim",
  opts = {
    kulala_keymaps = {
      ["Previous tab"] = {
        "<C-S-h>",
        function()
          require("kulala.ui").show_previous_tab()
        end,
        mode = { "n" },
      },
      ["Next tab"] = {
        "<C-S-l>",
        function()
          require("kulala.ui").show_next_tab()
        end,
        mode = { "n" },
      },
    },
  },
  keys = {
    {
      "rr",
      function()
        require("kulala").run()
      end,
      mode = "n",
      ft = { "http", "rest" },
      desc = "Run request",
    },
  },
}
