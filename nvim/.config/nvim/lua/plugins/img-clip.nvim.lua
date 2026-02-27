-- TODO: Create funciton to set and get vim.b.vars
-- vim.b.mnf_img_clip_path

local function get_img_dir_abs()
  local root = LazyVim.root() or vim.uv.cwd()
  if vim.b.mnf_img_clip_path ~= nil then
    return vim.fs.joinpath(root, vim.b.mnf_img_clip_path)
  end
  return vim.fs.joinpath(root, "assets")
end

local function get_img_dir_rel(root)
  local root = root or LazyVim.root() or vim.uv.cwd()
  local abs_dir = get_img_dir_abs()
  return vim.fs.relpath(root, abs_dir)
end

return {
  -- Thre are issues with this plugin. Ill try to detail them here
  -- 1. The file name is not present in the prompt (bad).
  -- This makes it hard for me to tell what the name will be and the extension
  -- if I want to rename it...
  -- I might fork this
  -- 2. The url regex ccheck is slow. pasing a link is slow ...
  -- 3. It does not detect file types well. For isntance copy image link
  -- to clipboard on zen wnats a jpeg image, but this plugin saves it
  -- as a png, requirng me to to write custom logic to ensure the extension
  -- is changed to jpg. Seems wrong.
  "HakonHarnes/img-clip.nvim",
  lazy = false,
  opts = {
    verbose = false,
    default = {
      -- file and directory options
      dir_path = get_img_dir_abs,
      copy_images = true,
      show_dir_path_in_prompt = true,
      verbose = false,
      prompt_for_file_name = true,
      insert_mode_after_paste = false,
    },
    -- Options that ONLY apply while dragging/dropping (img-clip overrides vim.paste)
    drag_and_drop = {
      verbose = false,
      prompt_for_file_name = true,
      show_dir_path_in_prompt = true,
      insert_mode_after_paste = false,
    },

    download_images = true,
    -- add options here
    -- or leave it empty to use the default settings
    filetypes = {
      typst = {
        template = function(context)
          local url = vim.fs.joinpath(get_img_dir_rel(), "$FILE_NAME")
          return [[image("]] .. "/" .. url .. [[")]]
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
