---@type LazySpec
return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  opts = {
    -- HACK: The issue is on firefox non private browser that opening
    -- 127.0.0.1:49810 caused it to be slow for some reason as compared
    -- to firefox private or safari regular. This fixes it though
    port = 49810,
    open_cmd = "open http://localhost:49810",
    debug = false,
    dependencies_bin = { ["tinymist"] = "tinymist" },
  },
  keys = { {
    "<leader>tp",
    "<Cmd>TypstPreviewToggle<CR>",
    desc = "Toggle preview of Typst document",
  } },
}
