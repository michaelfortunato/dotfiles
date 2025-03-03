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
      {
        "<leader>mst",
        "<Cmd> edit " .. SNIPPET_PATH .. "/tex.lua" .. " <CR>",
        desc = "Open latex snippets",
      },
    },
  },
}
