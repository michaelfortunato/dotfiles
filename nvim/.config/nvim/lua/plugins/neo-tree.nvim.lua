return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = {
    {
      "<leader>E",
      function()
        local bufpath = vim.api.nvim_buf_get_name(0)
        if bufpath == "" then
          vim.notify("No file in current buffer", vim.log.levels.WARN)
          return
        end
        local dir = vim.fs.dirname(bufpath)
        require("neo-tree.command").execute({
          toggle = true,
          dir = dir,
          reveal_file = bufpath,
        })
      end,
      desc = "Explorer NeoTree (Buf cwd)",
    },
  },
}
