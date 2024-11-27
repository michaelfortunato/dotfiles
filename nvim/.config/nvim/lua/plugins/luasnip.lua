return {
  {
    "rafamadriz/friendly-snippets",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load({ include = "tex" })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      history = true,
      region_check_events = "InsertEnter",
      delete_check_events = "TextChanged,InsertLeave",
    },
    -- Maybe?  -- Vitally important as the randomn tab hiccups drive me fucking nuts
    --  keys = {
    --    { "<tab>", false, mode = { "i" } },
    --    { "<tab>", false, mode = { "s" } },
    --    { "<s-tab>", false, mode = { "i", "s" } },
    --  },
  },
}
