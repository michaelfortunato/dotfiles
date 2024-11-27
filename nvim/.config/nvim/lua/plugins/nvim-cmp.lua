-- override nvim-cmp
-- turn off autocompletions
-- Make sure to unmap <C-Space> https://github.com/AstroNvim/AstroNvim/issues/601 on mac
return {
  "hrsh7th/nvim-cmp",
  dependencies = { "hrsh7th/cmp-emoji", "saadparwaiz1/cmp_luasnip", "gitaarik/nvim-cmp-toggle" },
  opts = function(_, opts)
    opts.snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    }

    opts.completion.autocomplete = false
    table.insert(opts.sources, { name = "emoji" })
    table.insert(opts.sources, { name = "luasnip" })

    local luasnip = require("luasnip")
    local cmp = require("cmp")
    -- Consider doing something fun here
    -- opts.mapping["<CR>"] = cmp.mapping(function(fallback)
    --   --
    --   -- if cmp.visible() then
    --   --     if luasnip.expandable() then
    --   --         luasnip.expand()
    --   --     else
    --   --         cmp.confirm({
    --   --             select = true,
    --   --         })
    --   --     end
    --   -- else
    --   fallback()
    -- end)

    opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
      -- if cmp.visible() then
      --  Comment out if you want autoexpand
      -- if luasnip.expandable() then
      --   luasnip.expand()
      -- else
      --   cmp.confirm({
      --     select = true,
      --   })
      -- end
      -- cmp.select_next_item()
      -- else
      if luasnip.locally_jumpable(1) then
        luasnip.jump(1)
      else
        fallback()
      end
    end, { "i", "s" })

    opts.mapping["<S-Tab>"] = cmp.mapping(function(fallback)
      -- if cmp.visible() then
      -- cmp.select_prev_item()
      if luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { "i", "s" })
    return opts
  end,
  keys = {
    { "<leader>ua", "<cmd>NvimCmpToggle<cr>", desc = "Toggle autocomplete" },
  },
}
