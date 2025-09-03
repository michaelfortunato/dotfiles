return {
  "LukasPietzschmann/telescope-tabs",
  config = function()
    require("telescope").load_extension("telescope-tabs")
    require("telescope-tabs").setup({
      -- Your custom config :^)
    })
  end,
  dependencies = { "nvim-telescope/telescope.nvim" },
}
-- return {
--   "nvim-telescope/telescope.nvim",
--   dependencies = {
--     "nvim-telescope/telescope-bibtex.nvim",
--   },
--   ---@type telescope
--   opts = {
--     extensions = {
--       load_extension = {
--         "bibtex",
--       },
--       bibtex = {
--         depth = 1,
--         -- Depth for the *.bib file
--         global_files = { os.getenv("MNF_BIB_DIR") },
--         -- Path to global bibliographies (placed outside of the project)
--         search_keys = { "author", "year", "title" },
--         -- Define the search keys to use in the picker
--         citation_format = "{{author}} ({{year}}), {{title}}.",
--         -- Template for the formatted citation
--         citation_trim_firstname = true,
--         -- Only use initials for the authors first name
--         citation_max_auth = 2,
--         -- Max number of authors to write in the formatted citation
--         -- following authors will be replaced by "et al."
--         custom_formats = {
--           { id = "citet", cite_maker = "\\citet{%s}" },
--         },
--         -- Custom format for citation label
--         format = "citet",
--         -- Format to use for citation label.
--         -- Try to match the filetype by default, or use 'plain'
--         context = true,
--         -- Context awareness disabled by default
--         context_fallback = true,
--         -- Fallback to global/directory .bib files if context not found
--         -- This setting has no effect if context = false
--         wrap = false,
--         -- Wrapping in the preview window is disabled by default
--       },
--     },
--   },
-- }
