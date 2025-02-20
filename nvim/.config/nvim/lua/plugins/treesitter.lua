---@type LazySpec
return {
  {
    ---@module "nvim-treesitter/nvim-treesitter"
    "nvim-treesitter/nvim-treesitter",
    opts = {
      textobjects = {
        move = {
          -- enable = true,
          -- goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
          -- goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
          -- goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
          -- goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
        },
      },
    },
  },
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
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
