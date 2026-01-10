return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    default_component_configs = {
      indent = {
        indent_size = 2,
        padding = 0, -- keep columns tight
        with_markers = true,
        expander_collapsed = "",
        expander_expanded = "",
      },
      icon = {
        -- Outlined (previous)
        -- folder_closed = "",
        -- folder_open = "",
        -- folder_empty = "",
        -- Filled (current)
        folder_closed = "",
        folder_open = "",
        folder_empty = "", -- or "󰉖" for hollow empty
        -- Use a uniform, narrow default file icon to avoid overflow
        default = "",
      },
      git_status = {
        symbols = {
          added = "",
          modified = "",
          deleted = "",
          renamed = "",
          untracked = "",
          ignored = "",
          -- This needs to be yellow, but its read right now quite annoying.
          -- unstaged = "",
          -- staged = "",
          conflict = "",
        },
      },
      diagnostics = {
        symbols = { hint = "", info = "", warn = "", error = "" },
      },
    },
    renderers = {
      file = {
        -- add a sliver of padding so icons/names aren't cramped
        { "icon", padding = 1 },
        { "name", zindex = 10 },
        { "diagnostics", zindex = 20, align = "right" },
        { "git_status", zindex = 30, align = "right" },
      },
      directory = {
        { "indent" },
        { "icon", padding = 1 },
        { "current_filter" },
        { "name" },
        { "diagnostics", align = "right" },
        { "git_status", align = "right" },
      },
    },
    window = { width = 32 },
  },
  ---@type LazyKeysSpec[]
  keys = {
    { "<leader>e", false },
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
