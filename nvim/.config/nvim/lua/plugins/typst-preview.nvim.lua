return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  opts = {
    -- debug = true,
    dependencies_bin = {
      ["tinymist"] = vim.fn.stdpath("data") .. "/mason/bin/tinymist",
      -- My fork
      -- ["tinymist"] = "/Users/michaelfortunato/projects/tinymist/target/debug/tinymist",
    },
  }, -- lazy.nvim will implicitly calls `setup {}`
  keys = { {
    "<leader>tp",
    "<Cmd>TypstPreviewToggle<CR>",
    desc = "Toggle preview of Typst document",
  } },
}
