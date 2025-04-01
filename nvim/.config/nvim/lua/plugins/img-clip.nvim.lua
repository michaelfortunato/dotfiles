return {
  "HakonHarnes/img-clip.nvim",
  lazy = false,
  opts = {
    default = {
      verbose = false,
      -- file and directory options
      dir_path = function()
        return LazyVim.root() .. "/assets"
      end, ---@type string | fun(): string
    },
    -- add options here
    -- or leave it empty to use the default settings
    filetypes = {
      typst = {
        template = [[image("$FILE_PATH", width: 80%)]], ---@type string | fun(context: table): string
      },
    },
  },
  keys = {
    -- suggested keymap
  },
}
