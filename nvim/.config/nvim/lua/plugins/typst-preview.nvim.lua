---@type LazySpec
return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  opts = {
    -- HACK: The issue is on firefox non private browser that opening
    -- 127.0.0.1:49810 caused it to be slow for some reason as compared
    -- to firefox private or safari regular. This fixes it though
    -- port = 49811,
    --open_cmd = "open http://localhost:49811",
    open_cmd = "open -a Firefox -u %s --args -P typst-preview --class typst-preview",
    debug = false,
    dependencies_bin = { ["tinymist"] = "tinymist" },
  },
  keys = { {
    "<leader>tp",
    "<Cmd>TypstPreviewToggle<CR>",
    desc = "Toggle preview of Typst document",
  } },
}
