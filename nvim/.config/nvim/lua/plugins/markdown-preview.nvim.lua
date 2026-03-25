---@type LazySpec
return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      { "<leader>cp", false },
      {
        "<localleader>p",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Toggle Markdown Preview",
        ft = "markdown",
      },
    },
    init = function()
      vim.g.mkdp_auto_start = 1
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_echo_preview_url = 0
      vim.g.mkdp_filetypes = { "markdown" }
    end,
  },
}
