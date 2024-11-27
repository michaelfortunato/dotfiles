-- override nvim-cmp
-- turn off autocompletions
-- Make sure to unmap <C-Space> https://github.com/AstroNvim/AstroNvim/issues/601 on mac
return {
  "hrsh7th/nvim-cmp",
  dependencies = { "hrsh7th/cmp-emoji", "gitaarik/nvim-cmp-toggle" },
  opts = function(_, opts)
    opts.completion.autocomplete = false
    table.insert(opts.sources, { name = "emoji" })
    return opts
  end,
  keys = { { "<leader>ua", "<cmd>NvimCmpToggle<cr>", desc = "Toggle autocomplete" } },
}
