---@module "snacks"
---@type LazyPluginSpec

---@type LazyPicker
local picker = {
  name = "snacks",
  commands = {
    files = "files",
    live_grep = "grep",
    oldfiles = "recent",
  },

  ---@param source string
  ---@param opts? snacks.picker.Config
  open = function(source, opts)
    return Snacks.picker.pick(source, opts)
  end,
}
if not LazyVim.pick.register(picker) then
  return {}
end

local function picker_cur_part()
  local ft = vim.bo.filetype
  if ft == "snacks_picker_input" then
    return "input"
  end
  if ft == "snacks_picker_list" then
    return "list"
  end
  if ft == "snacks_picker_preview" then
    return "preview"
  end
  return nil
end

local function picker_focus_part(picker, part)
  local node = picker and picker[part]
  local win = node and node.win
  if win and win.focus then
    win:focus()
    return true
  end
  return false
end

-- Capture the user's baseline window options at startup so we can reuse them
-- for picker preview windows instead of Snacks' defaults (which enable numbers).
local preview_wo_defaults = {
  number = vim.wo.number,
  relativenumber = vim.wo.relativenumber,
  signcolumn = vim.wo.signcolumn,
  cursorline = vim.wo.cursorline,
}

-- Keep picker borders consistent (avoids the lighter input border tint).
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "SnacksPickerInputBorder", { link = "SnacksPickerBoxBorder" })
    vim.api.nvim_set_hl(0, "SnacksPickerBorder", { link = "SnacksPickerBoxBorder" })
    vim.api.nvim_set_hl(0, "SnacksPickerPreviewBorder", { link = "SnacksPickerBoxBorder" })
  end,
  desc = "Keep Snacks picker borders color-consistent",
})

-- Also run once on startup to cover the initial colorscheme.
vim.api.nvim_set_hl(0, "SnacksPickerInputBorder", { link = "SnacksPickerBoxBorder" })
vim.api.nvim_set_hl(0, "SnacksPickerBorder", { link = "SnacksPickerBoxBorder" })
vim.api.nvim_set_hl(0, "SnacksPickerPreviewBorder", { link = "SnacksPickerBoxBorder" })

-- typical snacks w
vim.keymap.set({ "n" }, "<Leader>uz", function()
  require("snacks").zen()
end, { desc = "Toggle Zen Mode" })

return {
  {
    "michaelfortunato/snacks.nvim",
    -- I had this because I was paranoid the snacks updates made it slower
    -- but I do not think it actually did so I will remove it after a bit
    -- more usage.
    -- branch = "mnf-snacks-pre-update",
    dev = false,
    ---@type snacks.Config
    opts = {

      dashboard = {
        preset = {
          header = [[mnf.]],
          -- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
          ---@type fun(cmd:string, opts:table)|nil
          pick = nil,
          -- Used by the `keys` section to show keymaps.
          -- Set your custom keymaps here.
          -- When using a function, the `items` argument are the default keymaps.
          ---@type snacks.dashboard.Item[]
          keys = {
            -- Enable once fff gets better?
            -- { icon = " ", key = "f", desc = "Find File", action = ":lua require('fff').find_files()" },
            {
              icon = " ",
              key = "f",
              desc = "Find File",
              -- action = ":Telescope find_files sort_mru=true sort_lastused=true ignore_current_buffer=true",
              action = function()
                Snacks.picker.smart()
              end,
            },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
            },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
      -- For quarto plugins, but also keep here so I can centrally
      -- manage this monoltith plugin and disable it for typst
      -- Also though this is a pretty sick plugin
      image = {
        enabled = true,
        doc = {
          enabled = true,
          max_width = 300,
          max_height = 300,
        },
        math = { enabled = false },
      },
      styles = {
        zen = {
          keys = {
            ["<C-h>"] = "",
            ["<C-j>"] = "",
            ["<C-k>"] = "",
            ["<C-l>"] = "",
          },
        },
      },
      zen = {
        toggles = {
          dim = false, -- no twilight-style dim at all
        },
        show = {
          statusline = false,
          tabline = false,
        },
        win = {
          width = 0.6, -- or a fixed column count (e.g. 120)
          backdrop = {
            transparent = false,
            -- 99 ~= match current buffer bg; you can tweak between 90–99
            blend = 99,
          },
        },
      },
      --
      -- Concepts
      --
      -- TODO: We should figure out away to open bufers in a backgroudn tab
      -- but keep the picker open.
      --
      -- - Finders: sources that produce items. Common ones: files, buffers, recent, git_files, grep, plus LSP pickers.
      -- - Smart: a convenience wrapper over pickers; by default it aggregates multiple finders (buffers, recent, files) and applies a
      --   matcher and transform.
      -- - Filter/matcher/transform:
      --     - matcher: scoring/heuristics (e.g., cwd_bonus, frecency).
      --     - filter: prune items (directory, include/exclude, etc.).
      --     - transform: post-process (e.g., unique_file to dedupe).
      -- image = {},
      picker = {
        -- Navigation assumes the canonical Snacks layout: input + list stacked on the left,
        -- preview on the right. It's a hard-coded pane cycle via filetypes (no geometry check),
        -- so other layouts (e.g., preview above list in grep_buffers) can feel “off”.
        -- TODO: add optional layout-aware direction mapping for non-canonical presets.
        actions = {
          focus_left = function(picker)
            local here = picker_cur_part()
            if here ~= "preview" then
              return
            end
            if picker_focus_part(picker, "list") then
              return
            end
            picker_focus_part(picker, "input")
          end,

          focus_right = function(picker)
            local here = picker_cur_part()
            if here == "preview" then
              return
            end
            if here == "input" or here == "list" then
              picker_focus_part(picker, "preview")
            end
          end,

          focus_up = function(picker)
            local here = picker_cur_part()
            if (here == "list" or here == "preview") and picker_focus_part(picker, "input") then
              return
            end
            picker_focus_part(picker, "list")
          end,

          focus_down = function(picker)
            picker_focus_part(picker, "list")
          end,

          close_or_hide_help = function(picker)
            -- If a Snacks help window is visible, close it; otherwise close the picker.
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == "snacks_win_help" then
                picker:action("hide_help")
                return
              end
            end
            picker:action("close")
          end,
          -- NOTE: Snacks does not expose select action by default
          -- only select_and_next. But it does have the public select()
          -- avilable all good. HOpefully we do not lose this on a breaking
          -- change.
          select_only = function(picker)
            picker.list:select() -- toggle current item, no cursor movement
          end,
        },
        -- These two blocks control the look of tihngs, along with the hol
        -- group
        layout = {
          layout = {
            backdrop = false,
          },
        },
        formatters = {
          selected = {
            show_always = true, -- always render the selection column
            -- unselected = true, -- leave default; keeps hollow radios for unselected rows
          },
        },
        -- This controls the keys
        win = {
          input = {
            keys = {
              ["<C-h>"] = { "focus_left", mode = { "i", "n" }, desc = "Picker focus left" },
              ["<C-j>"] = { "focus_down", mode = { "i", "n" }, desc = "Picker focus down" },
              ["<C-k>"] = { "focus_up", mode = { "i", "n" }, desc = "Picker focus up" },
              ["<C-l>"] = { "focus_right", mode = { "i", "n" }, desc = "Picker focus right" },
              ["<Esc>"] = { "close_or_hide_help", mode = { "n", "i" }, desc = "Close help or picker" },
              ["<c-y>"] = { "confirm", mode = { "i", "n" } },
              ["<c-g>i"] = { "toggle_ignored", mode = { "i", "n" } },
              ["<c-o>"] = { "edit_split", mode = { "i", "n" } },
              ["?"] = { "toggle_help_input", mode = { "i", "n" } },
              ["<c-u>"] = false,
              ["<c-d>"] = false,
              ["<c-a>"] = false,
              ["<del>"] = { "bufdelete", mode = { "n", "i" } },
              ["<c-c>"] = { "yank", mode = { "n", "i" } },
              ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
              ["<D-c>"] = { "yank", mode = { "n", "i" } },
              ["<D-p>"] = { "paste", mode = { "n", "i" } },
              -- Probably won't work given this is Tab
              ["<c-i>"] = { "print_path", mode = { "n", "i" } },
              ["<c-.>"] = { "cd", mode = { "n", "i" } },
              ["<c-;>"] = { "terminal", mode = { "n", "i" } },
              ["<c-space>"] = { "select_only", mode = { "n", "i" } },
              ["<S-enter>"] = { "tab", mode = { "n", "i" } },
              ["<c-enter>"] = { "edit_vsplit", mode = { "n", "i" } },
            },
          },
          list = {
            keys = {
              ["<C-h>"] = { "focus_left", mode = { "i", "n" }, desc = "Picker focus left" },
              ["<C-j>"] = { "focus_down", mode = { "i", "n" }, desc = "Picker focus down" },
              ["<C-k>"] = { "focus_up", mode = { "i", "n" }, desc = "Picker focus up" },
              ["<C-l>"] = { "focus_right", mode = { "i", "n" }, desc = "Picker focus right" },
              ["<Esc>"] = { "close_or_hide_help", mode = { "n", "i" }, desc = "Close help or picker" },
              ["?"] = { "toggle_help_list", mode = { "i", "n" } },
              ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
              ["<c-space>"] = { "select_only", mode = { "n", "i" } },
            },
          },
          preview = {
            keys = {
              ["<C-h>"] = { "focus_left", mode = { "i", "n" }, desc = "Picker focus left" },
              ["<C-j>"] = { "focus_down", mode = { "i", "n" }, desc = "Picker focus down" },
              ["<C-k>"] = { "focus_up", mode = { "i", "n" }, desc = "Picker focus up" },
              ["<C-l>"] = { "focus_right", mode = { "i", "n" }, desc = "Picker focus right" },
              ["<Esc>"] = { "close_or_hide_help", mode = { "n", "i" }, desc = "Close help or picker" },
              ["?"] = { "toggle_help_list", mode = { "i", "n" } },
              ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
            },
            wo = preview_wo_defaults,
          },
        },
        sources = {
          tabs = {
            title = "Tabs",
            prompt = " ",
            preview = "preview",
            format = "file", -- leverage Snacks file formatter for icons/filetype awareness
            finder = function()
              local current = vim.api.nvim_get_current_tabpage()

              return vim.tbl_map(function(tabpage)
                local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
                local win = vim.api.nvim_tabpage_get_win(tabpage)
                local buf = vim.api.nvim_win_get_buf(win)
                local name = vim.api.nvim_buf_get_name(buf)

                local file = name ~= "" and vim.fn.fnamemodify(name, ":p") or nil
                local filename = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
                local parent = name ~= "" and vim.fn.fnamemodify(name, ":h:t") or nil
                local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
                local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
                local win_count = #vim.api.nvim_tabpage_list_wins(tabpage)

                local label = string.format("%s %d", tabpage == current and "" or "", tabnr)
                local comment = win_count > 1 and (win_count .. " wins") or nil

                return {
                  text = filename,
                  file = file,
                  buf = buf,
                  buftype = buftype,
                  filetype = filetype,
                  parent = parent and { text = parent, file = parent, dir = true } or nil,
                  tabpage = tabpage,
                  tabnr = tabnr,
                  search = table.concat({ filename, parent or "", tostring(tabnr), filetype, buftype }, " "),
                  label = label,
                  comment = comment,
                }
              end, vim.api.nvim_list_tabpages())
            end,
            confirm = function(picker, item)
              if item and item.tabpage and vim.api.nvim_tabpage_is_valid(item.tabpage) then
                vim.api.nvim_set_current_tabpage(item.tabpage)
              end
              picker:close()
            end,
            actions = {
              close_tab = function(picker, item)
                if not (item and item.tabnr) then
                  return
                end
                vim.cmd(string.format("%dtabclose", item.tabnr))
                picker:find()
              end,
            },
            win = {
              list = {
                keys = {
                  ["dd"] = "close_tab",
                },
              },
              input = {
                keys = {
                  ["<c-d>"] = { "close_tab", mode = { "n", "i" } },
                },
              },
            },
          },
          buffers = {
            win = {
              input = { keys = {
                ["<c-d>"] = { "bufdelete", mode = { "n", "i" } },
              } },
            },
          },
        },
      },
    },
  -- stylua: ignore
  keys = {
    { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>/", LazyVim.pick("grep"), desc = "Grep (Root Dir)" },
    { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader><space>", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
    -- find
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, desc = "Buffers (all)" },
    { "<leader>ft", function() Snacks.picker.tabs() end, desc = "Tabs" },
    { "<leader>fc", LazyVim.pick.config_files(), desc = "Find Config File" },
    { "<leader>ff", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    { "<leader>fF", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
    { "<leader>fr", LazyVim.pick("oldfiles"), desc = "Recent" },
    { "<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true }}) end, desc = "Recent (cwd)" },
    { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
    -- git
    { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)" },
    { "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, desc = "Git Diff (origin)" },
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
    { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
    { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)" },
    { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
    { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
    { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },
    -- Grep
    -- For <leader>sb and maybe other you should update it where it respects the
    -- line numbers and doesn't autoclose ? Or create a good workflow for it
    { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sg", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
    { "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
    { "<leader>sw", LazyVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
    { "<leader>sW", LazyVim.pick("grep_word", { root = false }), desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { '<leader>s/', function() Snacks.picker.search_history() end, desc = "Search History" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
    { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>su", function() Snacks.picker.undo() end, desc = "Undotree" },
    -- ui
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
  },
    --    -- preset = {
    --    --   header = [[mnf]],
    --    -- },
    -- opts = function(_, opts)
    --  ---@class snacks.dashboard.Config
    --  opts.dashboard = {
    --    -- preset = {
    --    --   header = [[mnf]],
    --    -- },
    --    sections = {
    --      {
    --        section = "terminal",
    --        -- cmd = "kitten icat ~/mnf3.png",
    --        cmd = "kitten icat --use-window-size 1,1,100,100 ~/mnf3.png",
    --      },
    --    },
    --  }
    --  return opts
    --end,
  },
  {
    "folke/todo-comments.nvim",
    optional = true,
    -- stylua: ignore
    keys = {
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Todo" },
      { "<leader>sT", function () Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "Todo/Fix/Fixme" },
    },
  },
}
