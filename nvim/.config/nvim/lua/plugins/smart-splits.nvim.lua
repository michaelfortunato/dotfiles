return {
  "michaelfortunato/smart-splits.nvim",
  dev = {
    ---@type string | fun(plugin: LazyPlugin): string directory where you store your local plugin projects
    path = "~/projects/neovim-plugins/",
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = {}, -- For example {"folke"}
    fallback = true, -- Fallback to git when local plugin doesn't exist
  },
  build = "./kitty/install-kittens.bash",
  lazy = false,
}
