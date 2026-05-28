local SNIPPET_PATH = "~/.config/nvim/lua/plugins/luasnip"
local SNIPPET_TEMPLATE = [[---@diagnostic disable: undefined-global
---@module "luasnip"

-- local ls = require("luasnip")
-- local s = ls.snippet
-- local t = ls.text_node
-- local i = ls.insert_node
-- local c = ls.choice_node
-- local fmta = require("luasnip.extras.fmt").fmta
-- local line_begin = require("luasnip.extras.expand_conditions").line_begin

return {
  -- s({ trig = "trig", snippetType = "autosnippet" }, t("replacement")),
  -- s("fn", fmta("function <>(<>)\n  <>\nend", { i(1, "name"), i(2), i(0) })),
  -- s({ trig = "doc", snippetType = "autosnippet" }, t("TODO"), { condition = line_begin }),
  -- s("choice", c(1, { t("one"), t("two") })),
}]]
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
          local filepath = vim.fn.expand(SNIPPET_PATH .. "/" .. vim.bo.filetype .. ".lua")
          local exists = vim.uv.fs_stat(filepath)
          vim.cmd.edit(vim.fn.fnameescape(filepath))
          if exists or vim.bo.modified then
            return
          end
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          if #lines == 1 and lines[1] == "" then
            vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(SNIPPET_TEMPLATE, "\n", { plain = true }))
          end
        end,
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
