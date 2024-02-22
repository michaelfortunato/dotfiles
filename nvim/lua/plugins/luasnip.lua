return {
  {
    "L3MON4D3/LuaSnip",
    opts = {
      history = true,
      region_check_events = "InsertEnter",
      delete_check_events = "TextChanged,InsertLeave",
    },
    -- Vitally important as the randomn tab hiccups drive me fucking nuts
    keys = {
      { "<tab>", false, mode = { "i" } },
      { "<tab>", false, mode = { "s" } },
      { "<s-tab>", false, mode = { "i", "s" } },
    },
  },
}
