--- See LazyVim/plugins/editor.lua
return {
  {
    "MagicDuck/grug-far.nvim",
    keys = {
      {
        "<leader>sr",
        function()
          local bufname = vim.api.nvim_buf_get_name(0)
          local filename = vim.fn.fnamemodify(bufname, ":t")
          local fallback = vim.bo.buftype == "" and vim.fn.expand("%:e")
          require("grug-far").open({
            transient = true,
            prefills = {
              filesFilter = filename ~= "" and filename or (fallback ~= "" and "*." .. fallback or nil),
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace (current file)",
      },
    },
  },
}
