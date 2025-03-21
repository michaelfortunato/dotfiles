-- override nvim-cmp
-- turn off autocompletions
-- Make sure to unmap <C-Space> https://github.com/AstroNvim/AstroNvim/issues/601 on macro
vim.g.mnf_enable_autocomplete = false
return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "hrsh7th/cmp-emoji",
    "saadparwaiz1/cmp_luasnip",
    "micangl/cmp-vimtex",
    {
      "liamvdvyver/cmp-bibtex", -- See issue https://github.com/Myriad-Dreamin/tinymist/pull/993 tinymist does not complete bib yet
      config = function(_, opts)
        require("cmp-bibtex").setup({ filetypes = { "typst" }, files = { os.getenv("BIBINPUTS") .. "/Zotero.bib" } })
      end,
    },
  },

  ---@module "cmp"
  ---@param opts cmp.ConfigSchema
  config = function(_, opts)
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
      --- Honestly lets just show them!
      { name = "luasnip", option = { show_autosnippets = false } },
      { name = "nvim_lsp" },
      { name = "buffer" },
      { name = "emoji" },
    }
    opts.experimental.ghost_text = false

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
    -- end
    opts.mapping["<C-y>"] = cmp.mapping(function(fallback)
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
      if luasnip.choice_active() then
        luasnip.change_choice(1)
      else
        fallback()
      end
    end, { "i", "s" })
    opts.mapping["<C-l>"] = cmp.mapping(function(fallback)
      if luasnip.expandable() then
        luasnip.expand()
      else
        fallback()
      end
    end, { "i", "s" })
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
    cmp.setup(opts)
    cmp.setup.filetype("tex", {
      sources = {
        -- { name = "luasnip", option = { show_autosnippets = false } },
        { name = "luasnip", option = { show_autosnippets = false } },
        { name = "vimtex" },
        --  NOTE:  Commenting this out is helpful for performance  { name = "nvim_lsp" },
        -- { name = "buffer" },
        -- { name = "emoji" },
      },
      completion = { autocomplete = false },
    })
    cmp.setup.filetype("typst", {
      sources = {
        --- note we put this first for now I do not know if this will hurt autocomplete
        { name = "luasnip", option = { show_autosnippets = false } },
        { name = "nvim_lsp" },
        { name = "bibtex" }, -- See here: https://github.com/Myriad-Dreamin/tinymist/pull/993
        { name = "buffer" },
        { name = "emoji" },
        --  NOTE:  Commenting this out is helpful for performance  { name = "nvim_lsp" },
        -- { name = "buffer" },
        -- { name = "emoji" },
      },
      completion = { autocomplete = false },
    })
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
