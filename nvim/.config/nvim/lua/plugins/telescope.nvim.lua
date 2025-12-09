return {
  -- Tabs extension remains as-is
  {
    "LukasPietzschmann/telescope-tabs",
    enabled = false,
    config = function()
      require("telescope").load_extension("telescope-tabs")
      require("telescope-tabs").setup({
        -- Your custom config :^)
      })
    end,
    dependencies = { "nvim-telescope/telescope.nvim" },
  },

  -- Global mapping for buffers picker: D in normal mode deletes buffer
  ---@type LazyPluginSpec
  {
    "nvim-telescope/telescope.nvim",
    enabled = false,
    ---@param opts table
    opts = function(_, opts)
      local actions = require("telescope.actions")
      opts = opts or {}
      opts.pickers = opts.pickers or {}
      local existing = opts.pickers.buffers or {}
      local existing_mappings = (existing and existing.mappings) or {}
      local existing_normal = existing_mappings.n or {}

      existing_normal["D"] = actions.delete_buffer

      existing_mappings.n = existing_normal
      existing.mappings = existing_mappings
      opts.pickers.buffers = existing

      opts.defaults.mappings.i = vim.tbl_extend("force", opts.defaults.mappings.i or {}, {
        ["<Esc>"] = actions.close, -- close picker from insert mode
        ["<C-d>"] = actions.delete_buffer, -- close picker from insert mode
      })
      opts.defaults.mappings.n = vim.tbl_extend("force", opts.defaults.mappings.n or {}, {
        ["<Esc>"] = actions.close, -- close picker from normal mode
        ["<C-d>"] = actions.delete_buffer, -- close picker from insert mode
      })
      -- (Note: a minority of users reported terminals left in insert mode
      -- after closing; uncommon, but if you ever see it, we can add a
      -- tiny :stopinsert hook.)
      -- [oai_citation:1‡GitHub](https://github.com/nvim-telescope/telescope.nvim/issues/2785?utm_source=chatgpt.com)

      return opts
    end,
  },
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
