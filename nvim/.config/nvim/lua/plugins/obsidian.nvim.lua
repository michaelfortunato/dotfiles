--- Disable
if true then
  return {}
end

return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  ---@param opts obsidian
  opts = function(_, opts)
    opts.workspaces = {
      {
        name = "personal",
        path = "~/notes",
      },
    }
    opts.daily_notes = {
      -- Optional, if you keep daily notes in a separate directory.
      -- Does not sync with .obsidian/daily-notes.json for some reason
      folder = "dailies",
    }
    -- Register <leader>o> as the Obsidian keygroup with which-key
  end,
  -- Taken, shamelessly, and happily, from
  -- https://github.com/epwalsh/dotfiles/blob/main/neovim/lua/plugins/notes.lua#L72
  -- Thanks Pete!
  init = function()
    local wk = require("which-key")
    wk.add({
      { "<leader>o", group = "Obsidian" }, -- group
    })
  end,
  keys = {
    -- { "<leader>o", group = "Obsidian" }, -- group
    -- { "<leader>od", "<cmd>ObsidianDailies -10 0<cr>", desc = "Obsidian Daily notes" },
    { "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Open Today's Note" },
    { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note" },
    { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Open Note In Obsidian App" },
    { "<leader>ot", "<cmd>ObsidianTemplate<cr>", desc = "Obsidian Template" },
    { "<leader>om", "<cmd>ObsidianTags<cr>", desc = "Obsidian Tags" },
    { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian Search" },
    { "<leader>op", "<cmd>ObsidianPasteImg<cr>", desc = "Obsidian Paste image" },
    { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian Quick switch" },
    { "<leader>ol", "<cmd>ObsidianLinks<cr>", desc = "Obsidian Links" },
    { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian Backlinks" },
    -- { "<leader>ob","<cmd>luafile lua/backlinks.lua<cr>", desc = "Obsidian Backlinks" },
    { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Obsidian Rename" },
    { "<leader>oc", "<cmd>ObsidianTOC<cr>", desc = "Obsidian Contents (TOC)" },
  },
}
