return {
  "HakonHarnes/img-clip.nvim",
  lazy = false,
  opts = {
    default = {
      -- file and directory options
      dir_path = function()
        local root = LazyVim.root() or vim.uv.cwd()
        return root .. "/assets"
      end, ---@type string | fun(): string
      copy_images = true,
    },
    -- Options that ONLY apply while dragging/dropping (img-clip overrides vim.paste)
    drag_and_drop = {
      verbose = false,
      prompt_for_file_name = true,
      insert_mode_after_paste = false,
    },

    download_images = true,
    -- add options here
    -- or leave it empty to use the default settings
    filetypes = {
      typst = {
        template = function(context)
          return [[#image("/assets/$FILE_NAME", width: 80%)]]
        end,
      },
      mdx = {
        download_images = true,
      },
      javascript = {
        template = '<img src="$FILE_PATH" alt="$CURSOR">', ---@type string | fun(context: table): string
      },
      typescript = {
        template = '<img src="$FILE_PATH" alt="$CURSOR">', ---@type string | fun(context: table): string
      },
      javascriptreact = {
        template = '<img src="$FILE_PATH" alt="$CURSOR" />', ---@type string | fun(context: table): string
      },
      typescriptreact = {
        template = '<img src="$FILE_PATH" alt="$CURSOR" />', ---@type string | fun(context: table): string
      },
    },
  },
  keys = {
    -- suggested keymap
  },
}
