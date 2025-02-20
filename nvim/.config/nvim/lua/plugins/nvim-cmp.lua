-- override nvim-cmp
-- turn off autocompletions
-- Make sure to unmap <C-Space> https://github.com/AstroNvim/AstroNvim/issues/601 on macro
vim.g.mnf_enable_autocomplete = false
return {
  "hrsh7th/nvim-cmp",
  dependencies = { "hrsh7th/cmp-emoji", "saadparwaiz1/cmp_luasnip" },
  ---@module "cmp"
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    opts.snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    }
    --- NOTE: Setting opts.completion.autcomplete = false
    --- stops the  annoying table from showing, BUT still lets luasnip
    --- automatically insert snippets, which is exactly what I wanted! Yay.
    opts.completion.autocomplete = false
    -- NOTE: Disabling `{ name = 'nvim_lsp' }`, is desired in latex documents
    -- I can do `opts.sources = {}`, but that removes lsp for all file types
    -- Order detrmines priority as well so do it in autocommand for tex buffer
    opts.sources = {
      --- NOTE: It's not always the worst idea to show autosnippets.
      --- TODO: Come up with a way of showing autosnippets in completion window via toggle.
      { name = "luasnip", option = { show_autosnippets = false } },
      { name = "nvim_lsp" },
      { name = "buffer" },
      { name = "emoji" },
    }

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
      -- WARN: Maybe use luasnip.jumpable(1) ??
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
    {
      "<leader>ua",
      function()
        -- This is totally fucking stupid but not broken. Fuck this.
        vim.g.mnf_enable_autocomplete = not vim.g.mnf_enable_autocomplete
        local cmp = require("cmp")
        cmp.setup({
          completion = { autocomplete = vim.g.mnf_enable_autocomplete and { cmp.TriggerEvent.TextChanged } },
        })
        vim.notify("Auto completion " .. (vim.g.mnf_enable_autocomplete and "enabled" or "disabled"))
      end,
      desc = "Toggle autocomplete. UI Will go crazy if enabled. Off by default. This is a bit of sledge hammer",
    },
  },
}
