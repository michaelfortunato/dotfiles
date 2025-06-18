---@type LazySpec
return {
  {
    ---@module "nvim-treesitter/nvim-treesitter"
    "nvim-treesitter/nvim-treesitter",
    opts = {
      indent = {
        enable = true,
      },
      textobjects = {
        move = {
          goto_next_start = {
            ["]b"] = "@block.outer",
            ["]f"] = "@function.outer",
            ["]c"] = "@class.outer",
            ["]a"] = "@parameter.inner",
          },
          goto_next_end = {
            ["]B"] = "@block.outer",
            ["]F"] = "@function.outer",
            ["]C"] = "@class.outer",
            ["]A"] = "@parameter.inner",
          },
          goto_previous_start = {
            ["[b"] = "@block.outer",
            ["[f"] = "@function.outer",
            ["[c"] = "@class.outer",
            ["[a"] = "@parameter.inner",
          },
          goto_previous_end = {
            ["[B"] = "@block.outer",
            ["[F"] = "@function.outer",
            ["[C"] = "@class.outer",
            ["[A"] = "@parameter.inner",
          },
          --     --
          --     -- n  K           *@<Lua 877: ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/lsp/keymaps.lua:22>
          --     --                  Hover
          --     -- n  [H          *@<Lua 1324: ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua:288>
          --     --                  First Hunk
          --     -- n  [h          *@<Lua 1293: ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua:280>
          --     --                  Prev Hunk
          --     -- n  [F          *@<Lua 1179: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto previous end @function.outer
          --     -- n  [C          *@<Lua 920: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto previous end @class.outer
          --     -- n  [A          *@<Lua 1193: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto previous end @parameter.inner
          --     -- n  [c          *@<Lua 1190: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto previous start @class.outer
          --     -- n  [f          *@<Lua 1187: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto previous start @function.outer
          --     -- n  [a          *@<Lua 1183: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto previous start @parameter.inner
          --     -- n  [[          *@<Lua 89: ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/lsp/keymaps.lua:33>
          --     --                  Prev Reference
          --     -- n  ]H          *@<Lua 1294: ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua:287>
          --     --                  Last Hunk
          --     -- n  ]h          *@<Lua 1295: ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua:273>
          --     --                  Next Hunk
          --     -- n  ]A          *@<Lua 1180: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto next end @parameter.inner
          --     -- n  ]F          *@<Lua 1032: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto next end @function.outer
          --     -- n  ]C          *@<Lua 944: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto next end @class.outer
          --     -- n  ]c          *@<Lua 940: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto next start @class.outer
          --     -- n  ]f          *@<Lua 937: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto next start @function.outer
          --     -- n  ]a          *@<Lua 1169: ~/.local/share/nvim/lazy/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/attach.lua:44>
          --     --                  Goto next start @parameter.inner
          --     -- n  ]]          *@<Lua 90: ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/lsp/keymaps.lua:31>
          --     --                  Next Reference
        },
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-n>",
          node_incremental = "<C-n>",
          scope_incremental = false,
          node_decremental = "<C-p>",
        },
      },
    },
  },
  {
    --- FIXME: It doesnt seem like this plugin does anything lol
    --- maybe it comes on when I do ]ga
    --- do I need this plugin? What about next and previous?
    "echasnovski/mini.ai",
    -- event = "VeryLazy",
    lazy = false,
    opts = function()
      local ai = require("mini.ai")
      --     -- NOTE: Very important swap. ; -> [ and ' ->]
      --     -- On second though This is a bad idea
      --     -- map({ "n", "v", "s", "o" }, ";", "[", { remap = true, desc = "For backwards textobject navigation" })
      --     -- map({ "n", "v", "s", "o" }, ";;", "[[", { desc = "For backwards textobject navigation" })
      --     -- map({ "n", "v", "s", "o" }, "g;", "g[", { desc = "For forwards textobject navigation" })
      --     -- map({ "n", "v", "s", "o" }, "'", "]", { desc = "For forwards textobject navigation" })
      --     -- map({ "n", "v", "s", "o" }, "''", "]]", { desc = "For forwards textobject navigation" })
      --     -- map({ "n", "v", "s", "o" }, "g'", "g]", { desc = "For forwards textobject navigation" })
      return {
        n_lines = 500,
        -- Move cursor to corresponding edge of `a` textobject
        mappings = {
          -- Main textobject prefixes
          around = "a",
          inside = "i",

          -- Next/last textobjects
          around_next = "an",
          inside_next = "in",
          around_last = "al",
          inside_last = "il",

          -- Move cursor to corresponding edge of `a` textobject
          goto_left = "[",
          goto_right = "]",
        },
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ -- code block
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
          d = { "%f[%d]%d+" }, -- digits
          e = { -- Word with case
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          i = LazyVim.mini.ai_indent, -- indent
          g = LazyVim.mini.ai_buffer, -- buffer
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
        },
      }
    end,
    config = function(_, opts)
      require("mini.ai").setup(opts)
      LazyVim.on_load("which-key.nvim", function()
        vim.schedule(function()
          LazyVim.mini.ai_whichkey(opts)
        end)
      end)
    end,
  },
}
-- I am confused
-- SO
-- 1. I think af = function.outer
-- 2. [<textobject> is move to prev textobject
-- 3. ]<textobject> is move to next textobject
-- BUT, for some reason ]af is not a default mapping, why?
-- This mini.ai seems to have the same idea as me
-- It goes one step further, defining f as <noun> function
-- and a<around> and i <inner> specify the object's two children
-- {
--  "echasnovski/mini.ai",
--  event = "VeryLazy",
--  opts = function()
--    local ai = require("mini.ai")
--    return {
--      n_lines = 500,
--      custom_textobjects = {
--        o = ai.gen_spec.treesitter({ -- code block
--          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
--          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
--        }),
--        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
--        c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
--        t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
--        d = { "%f[%d]%d+" }, -- digits
--        e = { -- Word with case
--          { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
--          "^().*()$",
--        },
--        i = LazyVim.mini.ai_indent, -- indent
--        g = LazyVim.mini.ai_buffer, -- buffer
--        u = ai.gen_spec.function_call(), -- u for "Usage"
--        U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
--      },
--    }
--  end,
--  config = function(_, opts)
--    require("mini.ai").setup(opts)
--    LazyVim.on_load("which-key.nvim", function()
--      vim.schedule(function()
--        LazyVim.mini.ai_whichkey(opts)
--      end)
--    end)
--  end,
-- {
--  "nvim-treesitter/nvim-treesitter-textobjects",
--  event = "VeryLazy",
--  enabled = true,
--  config = function()
--    -- If treesitter is already loaded, we need to run config again for textobjects
--    if LazyVim.is_loaded("nvim-treesitter") then
--      local opts = LazyVim.opts("nvim-treesitter")
--      require("nvim-treesitter.configs").setup({ textobjects = opts.textobjects })
--    end
--
--    -- When in diff mode, we want to use the default
--    -- vim text objects c & C instead of the treesitter ones.
--    local move = require("nvim-treesitter.textobjects.move") ---@type table<string,fun(...)>
--    local configs = require("nvim-treesitter.configs")
--    for name, fn in pairs(move) do
--      if name:find("goto") == 1 then
--        move[name] = function(q, ...)
--          if vim.wo.diff then
--            local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
--            for key, query in pairs(config or {}) do
--              if q == query and key:find("[%]%[][cC]") then
--                vim.cmd("normal! " .. key)
--                return
--              end
--            end
--          end
--          return fn(q, ...)
--        end
--      end
--    end
--  end,
--}
-- {
--   "nvim-treesitter/nvim-treesitter",
--   version = false, -- last release is way too old and doesn't work on Windows
--   build = ":TSUpdate",
--   event = { "LazyFile", "VeryLazy" },
--   lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
--   init = function(plugin)
--     -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
--     -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
--     -- no longer trigger the **nvim-treesitter** module to be loaded in time.
--     -- Luckily, the only things that those plugins need are the custom queries, which we make available
--     -- during startup.
--     require("lazy.core.loader").add_to_rtp(plugin)
--     require("nvim-treesitter.query_predicates")
--   end,
--   cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
--   keys = {
--     { "<c-space>", desc = "Increment Selection" },
--     { "<bs>", desc = "Decrement Selection", mode = "x" },
--   },
--   opts_extend = { "ensure_installed" },
--   ---@type TSConfig
--   ---@diagnostic disable-next-line: missing-fields
--   opts = {
--     highlight = { enable = true },
--     indent = { enable = true },
--     ensure_installed = {
--       "bash",
--       "c",
--       "diff",
--       "html",
--       "javascript",
--       "jsdoc",
--       "json",
--       "jsonc",
--       "lua",
--       "luadoc",
--       "luap",
--       "markdown",
--       "markdown_inline",
--       "printf",
--       "python",
--       "query",
--       "regex",
--       "toml",
--       "tsx",
--       "typescript",
--       "vim",
--       "vimdoc",
--       "xml",
--       "yaml",
--     },
--     incremental_selection = {
--       enable = true,
--       keymaps = {
--         init_selection = "<C-space>",
--         node_incremental = "<C-space>",
--         scope_incremental = false,
--         node_decremental = "<bs>",
--       },
--     },
--     textobjects = {
--       move = {
--         enable = true,
--         goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
--         goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
--         goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
--         goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
--       },
--     },
--   },
--   ---@param opts TSConfig
--   config = function(_, opts)
--     if type(opts.ensure_installed) == "table" then
--       opts.ensure_installed = LazyVim.dedup(opts.ensure_installed)
--     end
--     require("nvim-treesitter.configs").setup(opts)
--   end,
-- }
