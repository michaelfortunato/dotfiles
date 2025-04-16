vim.g.mnf_auto_show_comp_menu = false
vim.g.mnf_auto_show_ghost_text = false
return {
  "saghen/blink.cmp",
  -- optional: provides snippets for the snippet source
  dependencies = { "L3MON4D3/LuaSnip", version = "v2.*" },

  -- use a release tag to download pre-built binaries
  version = "1.*",
  -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    enabled = function()
      return true
    end,

    -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
    -- 'super-tab' for mappings similar to vscode (tab to accept)
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- All presets have the following mappings:
    -- C-space: Open menu or open docs if already open
    -- C-n/C-p or Up/Down: Select next/previous item
    -- C-e: Hide menu
    -- C-k: Toggle signature help (if signature.enabled = true)
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    -- If the command/function returns false or nil, the next command/function will be run.
    keymap = {
      preset = "default",
      ["<C-space>"] = { "show", "hide", "show_documentation", "hide_documentation" },
      ["<C-e>"] = { "hide" },
      ["<C-y>"] = { "select_and_accept" },

      ["<Up>"] = { "select_prev", "fallback" },
      ["<Down>"] = { "select_next", "fallback" },
      -- ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
      -- ["<C-n>"] = { "select_next", "fallback_to_mappings" },

      ["<C-p>"] = {
        function()
          local cmp = require("blink.cmp")
          if not cmp.is_visible() then
            return false
          end
          vim.schedule(function()
            require("blink.cmp.completion.list").select_prev({ auto_insert = false })
          end)
          return true
        end,
        "fallback_to_mappings",
      },
      ["<C-n>"] = {
        --- Basically jsut like cmp.slect_next() but also works if ghost text is showing and the menu is hidden
        function()
          local cmp = require("blink.cmp")
          if not cmp.is_visible() then
            return false
          end
          vim.schedule(function()
            require("blink.cmp.completion.list").select_next({ auto_insert = false })
          end)
          return true
        end,
        "fallback_to_mappings",
      },

      ["<C-b>"] = { "scroll_documentation_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "fallback" },

      -- TODO: Until snippet_forward and snippet_backward is understood by me, do not use it.
      ["<Tab>"] = {
        function()
          local luasnip = require("luasnip")
          if luasnip.locally_jumpable(1) then
            require("blink.cmp").snippet_forward()
            return true
          else
            return false
          end
        end,
        "fallback",
      },
      -- ["<Tab>"] = { "snippet_forward", "fallback" },
      ["<S-Tab>"] = {
        function()
          local luasnip = require("luasnip")
          if luasnip.locally_jumpable(-1) then
            require("blink.cmp").snippet_backward()
            return true
          else
            return false
          end
        end,
        "fallback",
      },
      -- ["<S-Tab>"] = { "snippet_backward","fallback" },

      ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
    },
    --- This stops annoying popups from happneing on signature
    signature = { enabled = false },

    appearance = {
      -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
      -- Adjusts spacing to ensure icons are aligned
      nerd_font_variant = "mono",
    },

    -- (Default) Only show the documentation popup when manually triggered
    completion = {
      --- TODO: Can enabled be by file type?
      ghost_text = {
        enabled = function()
          return vim.g.mnf_auto_show_ghost_text
        end,
        show_with_menu = false,
      },
      --- TODO: Can autoshow be by filie type
      --- TODO: Do not show ghost text for buffer completion. Remove buffer
      --- completion as a source.
      menu = {
        auto_show = function(context, items)
          return vim.g.mnf_auto_show_comp_menu
        end,
      },
      documentation = { auto_show = false },
    },
    snippets = { preset = "luasnip" },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { "snippets", "lsp", "path", "buffer" },
      --- Function to use when transforming the items before they're returned for all providers
      -- The default will lower the score for snippets to sort them lower in the list
      --  transform_items = function(_, items) return items end,
    },

    -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
    -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
    -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
    --
    -- See the fuzzy documentation for more information
    fuzzy = { implementation = "prefer_rust_with_warning" },

    cmdline = {
      completion = {
        -- Displays a preview of the selected item on the current line
        ghost_text = { enabled = false },
      },
    },
  },
  opts_extend = { "sources.default" },
  keys = {
    {
      "<leader>uaa",
      function()
        -- This is totally fucking stupid but not broken. Fuck this.
        vim.g.mnf_auto_show_comp_menu = not vim.g.mnf_auto_show_comp_menu
        vim.notify("Auto show completion menu " .. (vim.g.mnf_auto_show_comp_menu and "enabled" or "disabled"))
      end,
      desc = "Toggle auto show completion menu. UI Will go crazy if enabled. Off by default. This is a bit of sledge hammer",
    },
    {
      "<leader>uag",
      function()
        -- This is totally fucking stupid but not broken. Fuck this.
        vim.g.mnf_auto_show_ghost_text = not vim.g.mnf_auto_show_ghost_text
        vim.notify("Auto show ghost text " .. (vim.g.mnf_auto_show_ghost_text and "enabled" or "disabled"))
      end,
      desc = "Toggle auto show ghost text. This is kind of nice.",
    },
  },
}
-- override nvim-cmp
-- turn off autocompletions
-- Make sure to unmap <C-Space> https://github.com/AstroNvim/AstroNvim/issues/601 on macro
-- vim.g.mnf_enable_autocomplete = false
-- return {
--   "hrsh7th/nvim-cmp",
--   dependencies = {
--     "hrsh7th/cmp-emoji",
--     "saadparwaiz1/cmp_luasnip",
--     "micangl/cmp-vimtex",
--     {
--       "liamvdvyver/cmp-bibtex", -- See issue https://github.com/Myriad-Dreamin/tinymist/pull/993 tinymist does not complete bib yet
--       config = function(_, opts)
--         require("cmp-bibtex").setup({ filetypes = { "typst" }, files = { os.getenv("BIBINPUTS") .. "/Zotero.bib" } })
--       end,
--     },
--   },
--
--   ---@module "cmp"
--   ---@param opts cmp.ConfigSchema
--   config = function(_, opts)
--     opts.snippet = {
--       expand = function(args)
--         require("luasnip").lsp_expand(args.body)
--       end,
--     }
--     --- NOTE: Setting opts.completion.autcomplete = false
--     --- stops the  annoying table from showing, BUT still lets luasnip
--     --- automatically insert snippets, which is exactly what I wanted! Yay.
--     opts.completion.autocomplete = false
--     -- NOTE: Disabling `{ name = 'nvim_lsp' }`, is desired in latex documents
--     -- I can do `opts.sources = {}`, but that removes lsp for all file types
--     -- Order detrmines priority as well so do it in autocommand for tex buffer
--     opts.sources = {
--       --- NOTE: It's not always the worst idea to show autosnippets.
--       --- TODO: Come up with a way of showing autosnippets in completion window via toggle.
--       --- Honestly lets just show them!
--       { name = "luasnip", option = { show_autosnippets = false } },
--       { name = "nvim_lsp" },
--       { name = "buffer" },
--       { name = "emoji" },
--     }
--     opts.experimental.ghost_text = false
--
--     local luasnip = require("luasnip")
--     local cmp = require("cmp")
--     -- Consider doing something fun here
--     -- opts.mapping["<CR>"] = cmp.mapping(function(fallback)
--     --   --
--     --   -- if cmp.visible() then
--     --   --     if luasnip.expandable() then
--     --   --         luasnip.expand()
--     --   --     else
--     --   --         cmp.confirm({
--     --   --             select = true,
--     --   --         })
--     --   --     end
--     --   -- else
--     --   fallback()
--     -- end
--     opts.mapping["<C-y>"] = cmp.mapping(function(fallback)
--       -- if cmp.visible() then
--       --  Comment out if you want autoexpand
--       -- if luasnip.expandable() then
--       --   luasnip.expand()
--       -- else
--       --   cmp.confirm({
--       --     select = true,
--       --   })
--       -- end
--       -- cmp.select_next_item()
--       -- else
--       -- WARN: Maybe use luasnip.jumpable(1) ??
--       if luasnip.choice_active() then
--         luasnip.change_choice(1)
--       else
--         fallback()
--       end
--     end, { "i", "s" })
--     opts.mapping["<C-l>"] = cmp.mapping(function(fallback)
--       if luasnip.expandable() then
--         luasnip.expand()
--       else
--         fallback()
--       end
--     end, { "i", "s" })
--     opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
--       -- if cmp.visible() then
--       --  Comment out if you want autoexpand
--       -- if luasnip.expandable() then
--       --   luasnip.expand()
--       -- else
--       --   cmp.confirm({
--       --     select = true,
--       --   })
--       -- end
--       -- cmp.select_next_item()
--       -- else
--       -- WARN: Maybe use luasnip.jumpable(1) ??
--       if luasnip.locally_jumpable(1) then
--         luasnip.jump(1)
--       else
--         fallback()
--       end
--     end, { "i", "s" })
--
--     opts.mapping["<S-Tab>"] = cmp.mapping(function(fallback)
--       -- if cmp.visible() then
--       -- cmp.select_prev_item()
--       if luasnip.locally_jumpable(-1) then
--         luasnip.jump(-1)
--       else
--         fallback()
--       end
--     end, { "i", "s" })
--     cmp.setup(opts)
--     cmp.setup.filetype("tex", {
--       sources = {
--         -- { name = "luasnip", option = { show_autosnippets = false } },
--         { name = "luasnip", option = { show_autosnippets = false } },
--         { name = "vimtex" },
--         --  NOTE:  Commenting this out is helpful for performance  { name = "nvim_lsp" },
--         -- { name = "buffer" },
--         -- { name = "emoji" },
--       },
--       completion = { autocomplete = false },
--     })
--     cmp.setup.filetype("typst", {
--       sources = {
--         --- note we put this first for now I do not know if this will hurt autocomplete
--         { name = "luasnip", option = { show_autosnippets = false } },
--         { name = "nvim_lsp" },
--         { name = "bibtex" }, -- See here: https://github.com/Myriad-Dreamin/tinymist/pull/993
--         { name = "buffer" },
--         { name = "emoji" },
--         --  NOTE:  Commenting this out is helpful for performance  { name = "nvim_lsp" },
--         -- { name = "buffer" },
--         -- { name = "emoji" },
--       },
--       completion = { autocomplete = false },
--     })
--   end,
--   keys = {
--     {
--       "<leader>ua",
--       function()
--         -- This is totally fucking stupid but not broken. Fuck this.
--         vim.g.mnf_enable_autocomplete = not vim.g.mnf_enable_autocomplete
--         local cmp = require("cmp")
--         cmp.setup({
--           completion = { autocomplete = vim.g.mnf_enable_autocomplete and { cmp.TriggerEvent.TextChanged } },
--         })
--         vim.notify("Auto completion " .. (vim.g.mnf_enable_autocomplete and "enabled" or "disabled"))
--       end,
--       desc = "Toggle autocomplete. UI Will go crazy if enabled. Off by default. This is a bit of sledge hammer",
--     },
--   },
-- }
