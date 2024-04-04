-- override nvim-cmp
-- turn off autocompletions
-- Make sure to unmap <C-Space> https://github.com/AstroNvim/AstroNvim/issues/601 on mac
return {
  "hrsh7th/nvim-cmp",
  dependencies = { "hrsh7th/cmp-emoji" },
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    opts.completion.autocomplete = false
    table.insert(opts.sources, { name = "emoji" })
    return opts
  end,
}
