-- NOTE: Neovim maps tab by default maybe this does nothign idk
-- pcall(vim.keymap.del({ "i", "s" }, "<Tab>"))
vim.g.mnf_auto_show_comp_menu = false
vim.g.mnf_auto_show_ghost_text = false
return {
  {
    "saghen/blink.cmp",
    -- optional: provides snippets for the snippet source
    -- WARN: I am using latest but the docs say to use
    -- dependencies = { "L3MON4D3/LuaSnip", version = "2.*" },
    dependencies = {
      "L3MON4D3/LuaSnip",
      {
        "micangl/cmp-vimtex",
        dependencies = {
          {
            "saghen/blink.compat",
            version = "*",
            lazy = false,
            opts = {},
          },
        },
      },
      "ribru17/blink-cmp-spell",
      "hrsh7th/cmp-emoji",
    },

    -- use a release tag to download pre-built binaries
    version = "1.*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
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
        -- ["<C-space>"] = { "show", "hide", "show_documentation", "hide_documentation" },
        -- FIXME:
        -- 1. I think Ctrl-space causes buffer to come first, and that overrides
        -- the lsp, I should investigate. see blink-cmp-spell
        -- 2. Some tom foolery with not being able to use the completion right
        -- this helps vs. the other toggles I think??
        ["<C-space>"] = { "show", "hide" },
        ["<C-e>"] = { "hide" },
        ["<C-y>"] = { "select_and_accept" },
        --  NOTE: This is handled in keymaps.lua
        -- ["<C-l>"] = {
        --   function()
        --     local ls = require("luasnip")
        --     if ls.choice_active() then
        --       ls.change_choice(1)
        --       return true
        --     end
        --   end, {
        --
        --   }
        --   "fallback_to_mappings",
        -- },

        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
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
        -- FIXME: Not working
        -- These are only being mapped to insert mode, not normal mode
        ["<C-u>"] = {
          function(cmp)
            -- return true
            return cmp.scroll_documentation_up(8)
          end,
          "fallback",
        },
        ["<C-d>"] = {
          function(cmp)
            -- return true
            return cmp.scroll_documentation_down(8)
          end,
          "fallback",
        },
        -- TODO: jk
        -- ["jk"] = {
        --   function()
        --     local luasnip = require("luasnip")
        --     if luasnip.locally_jumpable(1) then
        --       require("blink.cmp").snippet_forward()
        --       return true
        --     else
        --       return false
        --     end
        --   end,
        --   "fallback",
        -- },
        ["<Tab>"] = {
          function(cmp)
            local pos = vim.fn.getpos(".")
            local line = vim.fn.getline(".")

            -- If at the beginning of the line, you usually just want to insert
            -- a tab
            -- FIXME: this `<space>|asdf` will jump after tab and shoudn't
            if pos[3] == 0 or string.sub(line, 0, pos[3]):match("^%s+$") then
              return false
            end

            local luasnip = require("luasnip")
            if luasnip.locally_jumpable(1) then
              cmp.snippet_forward()
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
        documentation = {
          -- They should make a PR for this
          -- auto_show = function(context, items)
          --   return vim.g.mnf_auto_show_comp_documentation
          -- end,
          auto_show = false,
        },
        -- -- Maybe
        -- accept = { auto_brackets = { enabled = true } },
      },
      snippets = { preset = "luasnip" },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        -- I think Ctrl-space causes buffer to come first, and that overrides
        -- the lsp, I should investigate. see blink-cmp-spell
        default = { "snippets", "lsp", "path", "buffer", "emoji" },

        per_filetype = {
          -- optionally inherit from the `default` sources
          tex = { inherit_defaults = true, "vimtex", "spell" },
          typst = { inherit_defaults = true, "spell" },
          lua = { inherit_defaults = true, "lazydev" },
        },
        --- Custom providers
        providers = {
          buffer = { score_offset = -5, max_items = 10 },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
          -- add vimtex source
          -- ref: https://github.com/micangl/cmp-vimtex/issues/30
          -- ref: https://www.reddit.com/r/neovim/comments/1invqwg/comment/mcgttl5/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
          vimtex = {
            name = "vimtex",
            min_keyword_length = 2,
            module = "blink.compat.source",
            score_offset = 80,
          },
          spell = {
            name = "Spell",
            module = "blink-cmp-spell",
            opts = {
              -- EXAMPLE: Only enable source in `@spell` captures, and disable it
              -- in `@nospell` captures.
              enable_in_context = function()
                local curpos = vim.api.nvim_win_get_cursor(0)
                local captures = vim.treesitter.get_captures_at_pos(0, curpos[1] - 1, curpos[2] - 1)
                local in_spell_capture = false
                for _, cap in ipairs(captures) do
                  if cap.capture == "spell" then
                    in_spell_capture = true
                  elseif cap.capture == "nospell" then
                    return false
                  end
                end
                return in_spell_capture
              end,
            },
          },
          emoji = {
            module = "blink.compat.source",
            name = "emoji",
          },
        },
        --- Function to use when transforming the items before they're returned for all providers
        -- The default will lower the score for snippets to sort them lower in the list
        --  transform_items = function(_, items) return items end,
      },

      -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
      fuzzy = {
        implementation = "prefer_rust_with_warning",
        -- https://cmp.saghen.dev/configuration/fuzzy.html#sorting-priority-and-tie-breaking
        -- sorts = {
        --   -- This might slow things down not sure
        --   function(a, b)
        --     if a.source_id == "spell" and b.source_id == "spell" then
        --       local sort = require("blink.cmp.fuzzy.sort")
        --       return sort.label(a, b)
        --     end
        --   end,
        --   "score", -- Primary sort: by fuzzy matching score
        --   "sort_text", -- Secondary sort: by sortText field if scores are equal
        --   "kind", -- Kind is better than label for pyrefly
        --   "label", -- Tertiary sort: by label if still tied
        -- },
      },

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
        "<leader>ma",
        function()
          -- This is totally fucking stupid but not broken. Fuck this.
          vim.g.mnf_auto_show_comp_menu = not vim.g.mnf_auto_show_comp_menu
          vim.notify("Auto show completion menu " .. (vim.g.mnf_auto_show_comp_menu and "enabled" or "disabled"))
        end,
        desc = "Toggle auto show completion menu. UI Will go crazy if enabled. Off by default. This is a bit of sledge hammer",
      },
      {
        "<leader>mh",
        function()
          -- This is totally fucking stupid but not broken. Fuck this.
          vim.g.mnf_auto_show_ghost_text = not vim.g.mnf_auto_show_ghost_text
          vim.notify("Auto show ghost text " .. (vim.g.mnf_auto_show_ghost_text and "enabled" or "disabled"))
        end,
        desc = "Toggle auto show ghost text. This is kind of nice.",
      },
    },
  },
  {
    {
      --  TODO: Note there is some issue with latex and its
      -- treesitter environment in comment mode that makes
      -- tab out think cursor is right before a closed - deliminter.
      -- Ie % |<Tab>Foo becomes
      --    % Foo|
      "abecodes/tabout.nvim",
      lazy = false,
      enabled = false,
      config = function()
        require("tabout").setup({
          -- This is good as blink cmp will win out over it.
          tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
          backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
          act_as_tab = true, -- shift content if tab out is not possible
          act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
          default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
          default_shift_tab = "<C-d>", -- reverse shift default action,
          enable_backwards = true, -- well ...
          completion = false, -- if the tabkey is used in a completion pum
          tabouts = {
            { open = "'", close = "'" },
            { open = '"', close = '"' },
            { open = "`", close = "`" },
            { open = "(", close = ")" },
            { open = "[", close = "]" },
            { open = "{", close = "}" },
          },
          ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
          exclude = {}, -- tabout will ignore these filetypes
        })
      end,
      dependencies = { -- These are optional
        "nvim-treesitter/nvim-treesitter",
        -- "L3MON4D3/LuaSnip",
      },
    },
  },
}
