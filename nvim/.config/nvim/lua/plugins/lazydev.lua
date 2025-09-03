return {
  "folke/lazydev.nvim",
  ft = "lua", -- only load on lua files
  opts = {
    library = {
      -- Library paths can be absolute
      -- Or relative, which means they will be resolved from the plugin dir.
      "lazy.nvim",
      -- It can also be a table with trigger words / mods
      -- Only load luvit types when the `vim.uv` word is found
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      -- always load the LazyVim library
      "LazyVim",
      -- Only load the lazyvim library when the `LazyVim` global is found
      { path = "LazyVim", words = { "LazyVim" } },
      -- Load the xmake types when opening file named `xmake.lua`
      -- Needs `LelouchHe/xmake-luals-addon` to be installed
      { path = "xmake-luals-addon/library", files = { "xmake.lua" } },
    },
    -- always enable unless `vim.g.lazydev_enabled = false`
    -- This is the default
    enabled = function(root_dir)
      return vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled
    end,
    -- -- disable when a .luarc.json file is found
    -- enabled = function(root_dir)
    --   return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
    -- end,
    -- enabled = function(root_dir)
    --   return vim.uv.fs_stat(root_dir .. "/.lazy.lua")
    -- end,
  },
}
