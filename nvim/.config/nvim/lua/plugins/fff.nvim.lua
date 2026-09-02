local fff_modes = {
  { title = "FFF Files", source_id = 1 },
  { title = "FFF Grep · plain", source_id = 2, grep_mode = "plain" },
  { title = "FFF Grep · regex", source_id = 2, grep_mode = "regex" },
  { title = "FFF Grep · fuzzy", source_id = 2, grep_mode = "fuzzy" },
}

local function set_fff_mode(picker, index)
  local mode = fff_modes[index]
  picker.opts._fff_mode = index
  picker.input.filter.source_id = mode.source_id
  if mode.grep_mode then
    picker.opts.grep_mode = { mode.grep_mode }
  end
  picker.title = mode.title
  picker:refresh()
end

local function fff_picker()
  local sources = require("fff-snacks").sources
  local files = vim.deepcopy(sources.find_files)
  local grep = vim.deepcopy(sources.live_grep)
  local initialize = files.on_show

  -- Snacks' multi picker owns the shared window and actions.
  files.on_show = nil
  grep.on_show = nil
  grep.win = nil

  Snacks.picker.pick({
    title = fff_modes[1].title,
    cwd = vim.fn.getcwd(),
    live = true,
    multi = { files, grep },
    formatters = { file = { filename_first = true } },
    actions = {
      cycle_fff_mode = function(picker)
        set_fff_mode(picker, (picker.opts._fff_mode or 1) % #fff_modes + 1)
      end,
    },
    on_show = function(picker)
      if initialize then
        initialize(picker)
      end
      set_fff_mode(picker, 1)
    end,
    win = {
      input = {
        keys = {
          ["<C-h>"] = {
            "cycle_fff_mode",
            mode = { "n", "i" },
            nowait = true,
            desc = "Cycle FFF picker mode",
          },
        },
      },
      list = {
        keys = {
          ["<C-h>"] = {
            "cycle_fff_mode",
            mode = { "n", "i" },
            nowait = true,
            desc = "Cycle FFF picker mode",
          },
        },
      },
    },
  })
end

local function fff_live_grep()
  require("fff-snacks").live_grep({ cwd = vim.fn.getcwd() })
end

local function map_fff_pickers()
  vim.keymap.set("n", "ff", fff_picker, { desc = "FFF Files/Grep (Cwd)" })
  vim.keymap.set("n", "fw", fff_live_grep, { desc = "FFF Live Grep (Cwd)" })
end

return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
  },
  {
    "madmaxieee/fff-snacks.nvim",
    dependencies = {
      "dmtrKovalenko/fff.nvim",
      "michaelfortunato/snacks.nvim",
    },
    opts = {
      live_grep = {
        grep_mode = { "plain", "regex", "fuzzy" },
        win = {
          input = {
            keys = {
              ["<C-h>"] = {
                "cycle_grep_mode",
                mode = { "n", "i" },
                nowait = true,
                desc = "Cycle FFF grep mode",
              },
            },
          },
          list = {
            keys = {
              ["<C-h>"] = {
                "cycle_grep_mode",
                mode = { "n", "i" },
                nowait = true,
                desc = "Cycle FFF grep mode",
              },
            },
          },
        },
      },
    },
    keys = {
      { "ff", fff_picker, desc = "FFF Files/Grep (Cwd)" },
      { "fw", fff_live_grep, desc = "FFF Live Grep (Cwd)" },
    },
    config = function(_, opts)
      require("fff-snacks").setup(opts)
      map_fff_pickers()
      -- config/keymaps.lua remaps ff on VeryLazy; make this trial map win.
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = map_fff_pickers,
      })
    end,
  },
}
