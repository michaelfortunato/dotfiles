-- All the disabled lua plugins that came with LazyVim
return {
  -- disable trouble, yuck!
  { "akinsho/bufferline.nvim", enabled = false },
  -- disable auto pairs, yuck!
  {
    "echasnovski/mini.pairs",
    enabled = false,
    -- NOTE:All of this lua noise is because ...
    --  I JUST WANT {<CR>} TO WORK NICELY.
    -- config = function(_, opts)
    --   require("mini.pairs").setup(opts)
    --   local map_cr = function(lhs, rhs)
    --     vim.keymap.set("i", lhs, rhs, { expr = true, replace_keycodes = false })
    --   end
    --   map_cr("<CR>", "v:lua.MiniPairs.cr()")
    -- end,
    -- opts = {
    --   mappings = {
    --     ["("] = false,
    --     ["["] = false,
    --     ["{"] = false,
    --
    --     [")"] = false,
    --     ["]"] = false,
    --     ["}"] = false,
    --
    --     ['"'] = false,
    --     ["'"] = false,
    --     ["`"] = false,
    --   },
    -- },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- I want Markdown rendering in the browser only.
    -- This plugin does in-editor chrome.
    enabled = false,
  },
  { "akinsho/bufferline.nvim", enabled = false },
  { "hrsh7th/nvim-cmp", enabled = false },
  -- Swapped for shortcuts/no-neck-pain.nvim
  { "folke/zen-mode.nvim", enabled = false },
}
