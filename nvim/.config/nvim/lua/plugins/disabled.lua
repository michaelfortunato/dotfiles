-- All the disabled lua plugins that came with LazyVim
return {
  -- disable trouble, yuck!
  { "akinsho/bufferline.nvim", enabled = false },
  -- disable auto pairs, yuck!
  {
    "echasnovski/mini.pairs",
    enabled = false,
  },
  {
    --- NOTE: brutal, but necessary
    "echasnovski/mini.ai",
    enabled = false,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
  },
}
