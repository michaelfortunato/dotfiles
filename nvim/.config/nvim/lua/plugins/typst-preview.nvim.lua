---@type LazySpec
return {
  "michaelfortunato/typst-preview.nvim",
  dev = true,
  ft = "typst",
  opts = {
    -- HACK: The issue is on firefox non private browser that opening
    -- 127.0.0.1:49810 caused it to be slow for some reason as compared
    -- to firefox private or safari regular. This fixes it though
    -- port = 49811,
    --open_cmd = "open http://localhost:49811",
    port = 41798,
    host = "127.0.0.1",
    open_cmd = "open -g -a 'Typst Preview' '%s'",
    debug = true,
    dependencies_bin = { ["tinymist"] = "tinymist" },
  },
  keys = {
    {
      "<leader>tp",
      "<Cmd>TypstPreviewToggle<CR>",
      desc = "Toggle preview of Typst document",
    },
    {
      "<localleader>p",
      "<Cmd>TypstPreview<CR>",
      desc = "Start preview of Typst document",
      ft = "typst", -- NOTE: Added file type so `,` remains localleader
    },
  },
}
