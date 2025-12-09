local SNIPPET_PATH = "~/.config/nvim/lua/plugins/luasnip"
return {
  {
    "L3MON4D3/LuaSnip",
    -- dependencies = { "rafamadriz/friendly-snippets" },
    opts = function(_, opts)
      require("luasnip.loaders.from_lua").lazy_load({ paths = { SNIPPET_PATH } })
      opts.history = true
      -- ref https://stackoverflow.com/questions/70366949/how-to-change-tab-behaviour-in-neovim-as-specified-luasniplsp-popup
      opts.region_check_events = "InsertEnter"
      opts.delete_check_events = "TextChanged,InsertLeave"
      opts.update_events = "TextChanged,TextChangedI"
      opts.enable_autosnippets = true
      --- NOTE: This does not with luasnip 2.3, so if you use
      --- that use opts.store_selection_keys
      --- NOTE: This also does not work with typst along with the
      --- new version too so you can see if this last-resort fixes it
      --- or if typst is getting a buffer local map
      --- vim.api.nvim_create_autocmd("FileType", {
      --   pattern = "typst",
      --   callback = function(ev)
      --     local cut = require("luasnip.util.select").cut_keys
      --     vim.keymap.set({ "x", "s" }, "<BS>", cut, { buffer = ev.buf, silent = true })
      --   end,
      -- })
      opts.cut_selection_keys = "<BS>"
      opts.store_selection_keys = "<BS>"
      -- NOTE: If you want injected languages, consider this
      --opts.load_ft_func = function()
      --  -- See help luasnip-extras-filetype-functions we need
      --  -- this extend_load_ft because we call lazy_load above
      --  require("luasnip.extras.filetype_functions").extend_load_ft({
      --     python = {"typst", "markdown" }, -- might want rST here to
      --     markdown = {"typst"}
      --     rust = {"markdown", "typst"}
      --  })
      --  return require("luasnip.extras.filetype_functions").from_cursor_pos()
      --  end
      return opts
    end,
    keys = {
      {
        "<leader>msl",
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
