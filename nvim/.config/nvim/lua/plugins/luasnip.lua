local SNIPPET_PATH = "~/.config/nvim/lua/plugins/luasnip"
return {
  {
    "L3MON4D3/LuaSnip",
    -- dependencies = { "rafamadriz/friendly-snippets" },
    opts = function(_, opts)
      require("luasnip.loaders.from_lua").lazy_load({ paths = { SNIPPET_PATH } })
      opts.history = true
      opts.region_check_events = "InsertEnter"
      opts.delete_check_events = "TextChanged,InsertLeave"
      opts.update_events = "TextChanged,TextChangedI"
      opts.enable_autosnippets = true
      opts.cut_selection_keys = "<BS>"
      return opts
    end,
    keys = {
      {
        "<leader>ml",
        function()
          require("luasnip.loaders.from_lua").lazy_load({ paths = { SNIPPET_PATH } })
          print("Snippets refreshed!")
          return true
        end,
        desc = "Reload snippets",
      },
      --- <leader>ms is the snippets group
      {
        "<leader>mss",
        function()
          return "<Cmd> edit" .. SNIPPET_PATH .. "/" .. vim.bo.filetype .. ".lua" .. " <CR>"
        end,
        expr = true,
        desc = "Open snippet for current filetype",
      },
      {
        "<leader>msf",
        function()
          local files = vim.fs.find(function(name, path)
            return name:match(".*%.lua$")
          end, { limit = math.huge, type = "file", path = SNIPPET_PATH })
          vim.ui.select(files, {}, function(item)
            vim.cmd.edit(item)
          end)
        end,
        desc = "Browse your snippet files",
      },
    },
  },
}
