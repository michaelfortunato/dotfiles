-- override nvim-cmp
-- turn off autocompletions
-- Make sure to unmap <C-Space> https://github.com/AstroNvim/AstroNvim/issues/601 on mac
return {
  "hrsh7th/nvim-cmp",
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    opts.completion.autocomplete = false
    return opts
  end,
}
