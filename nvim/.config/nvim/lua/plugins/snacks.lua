-- TODOs:
--  - [ ] nvim/.config/nvim/lua/plugins/snacks.lua:548: override opts.picker.sources.keymaps.confirm to open item.file/item.pos when
--    present (else vim.notify(...) + no-op).
--  - [ ] Same place: add a secondary key/action (e.g. <C-y>) to “execute keymap” (current behavior) via
--    vim.api.nvim_input(item.item.lhs).
--  - [ ] nvim/.config/nvim/lua/plugins/snacks.lua:627: add a buffers-picker filter/state so terminal buffers (buftype == "terminal")
--    can be hidden by default and shown on demand.
--  - [ ] Bind sources.buffers.win.input.keys["<C-g><C-t>"] → actions.toggle_terminal (flip flag + picker:find()), and pick additional
--    <C-g><C-…> toggles for other kinds (nofile, help, quickfix, unlisted, modified-only, etc.).

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
vim.keymap.set({ "n" }, "<Leader>ux", function()
  local dim = require("snacks.dim")
  if dim.enabled then
    dim.disable()
  else
    dim.enable()
  end
end, { desc = "Toggle Dim Mode" })

vim.t.scratch = "python"
vim.keymap.set("n", "''", function()
  local snacks = require("snacks")
  if vim.t.scratch ~= nil then
    snacks.scratch.open({ ft = vim.t.scratch })
  end
end, { desc = "Python scratch buffer" })

-- Main scratch operations
vim.keymap.set("n", "'g", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.select()
end, { desc = "List scratch buffers" })

-- Filetype-specific shortcuts
vim.keymap.set("n", "'py", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "python" })
end, { desc = "Python scratch buffer" })

vim.keymap.set("n", "'js", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "javascript" })
end, { desc = "JavaScript scratch buffer" })

vim.keymap.set("n", "'lua", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "lua" })
end, { desc = "Lua scratch buffer" })

vim.keymap.set("n", "'ty", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "typst" })
end, { desc = "Typst scratch buffer" })

vim.keymap.set("n", "'tex", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "tex" })
end, { desc = "TeX scratch buffer" })

vim.keymap.set("n", "'md", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "markdown" })
end, { desc = "Markdown scratch buffer" })

vim.keymap.set("n", "'sql", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "sql" })
end, { desc = "SQL scratch buffer" })

vim.keymap.set("n", "'sh", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "sh" })
end, { desc = "Shell scratch buffer" })

vim.keymap.set("n", "'rust", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "rust" })
end, { desc = "Rust scratch buffer" })

vim.keymap.set("n", "'rs", function()
  local snacks_local = require("snacks")
  snacks_local.scratch.open({ ft = "rust" })
end, { desc = "Rust scratch buffer" })

return {
  {
    "michaelfortunato/snacks.nvim",
    dev = true,
    ---@type snacks.Config
    opts = {
      scratch = {
        -- Per-filetype scratch actions (kept in your config; no Snacks patches).
        -- This mirrors Folke's lua scratch `<cr>` runner, but routes python to `mnf.scratch.python`.
        win_by_ft = {
          python = {
            keys = {
              ["run"] = {
                "<cr>",
                function(self)
                  require("mnf.scratch.python").run({ buf = self.buf })
                end,
                desc = "Run selection (ghost output)",
                mode = { "n", "x" },
              },
              ["clear"] = {
                "C",
                function(self)
                  require("mnf.scratch.python").clear({ buf = self.buf })
                end,
                desc = "Clear output",
              },
              ["reset"] = {
                "R",
                function(self)
                  require("mnf.scratch.python").reset({ buf = self.buf })
                end,
                desc = "Reset Python session",
              },
            },
            footer_keys = { "<cr>", "R" },
          },
        },
        win = {
          wo = {
            colorcolumn = "",
          },
          on_close = function(win)
            assert(win and win.buf, "We need this to be not none here")
            local buf = win.buf
            local ft = vim.bo[buf].filetype
            vim.t.scratch = ft
          end,
          on_win = function(win)
            vim.t.scratch = nil
          end,
          -- if you want none
          -- footer_keys = false,
          footer_keys = { "q" },
          keys = {
            -- ["''"] = {
            --   ---@param arg snacks.win
            --   "close",
            --   mode = "n",
            --   desc = "Close scratch window",
            -- },
            ["'f"] = function(win)
              assert(win and win.opts and win.opts.position, "scratch_cycle_layout: missing win/position")
              assert(win.buf and vim.api.nvim_buf_is_valid(win.buf), "scratch_cycle_layout: invalid buffer")
              local snacks = require("snacks")

              -- FIXME: This is registering styles a tone of times
              snacks.config.style("scratch_float", { position = "float", width = 0.6, height = 0.6, backdrop = 75 })
              snacks.config.style("scratch_split", { position = "bottom", height = 0.35, width = 1, backdrop = false })
              snacks.config.style("scratch_vsplit", { position = "right", width = 0.45, backdrop = false })

              local next_style = ({
                float = "scratch_split",
                bottom = "scratch_vsplit",
                top = "scratch_vsplit",
                right = "scratch_float",
                left = "scratch_float",
              })[win.opts.position] or "scratch_float"

              local buf = win.buf
              local file = vim.api.nvim_buf_get_name(buf)
              local ft = vim.bo[buf].filetype

              if win.close then
                win:close()
              end
              Snacks.scratch.open({ file = file, ft = ft, win = { style = next_style } })
            end,

            ["''"] = function(win) -- value is fun(self: snacks.win)
              win:close()
            end,
            -- ["''"] = function(win) -- value is fun(self: snacks.win)
            --   win:action(actions)()
            -- end,
          },
        },
      },

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
              action = LazyVim.pick("files"),
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
        enabled = false,
        doc = {
          enabled = true,
          max_width = 300,
          max_height = 300,
        },
        math = { enabled = false },
      },
      styles = {
        -- NOTE: We need to be careful here
        -- as zenmode will not restore the c-h etc. mappings once left
        -- See the `HACK` below on `on_close`.
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
        ---@param win snacks.win
        -- HACK: See below for why this is important window navigation given
        -- i disable the relativent buttons in zen mode
        -- as zenmode will not restore the c-h etc. mappings once left
        on_close = function(win)
          vim.keymap.set({ "n", "v" }, "<C-h>", function()
            require("smart-splits").move_cursor_left()
          end, { buffer = win.buf })
          vim.keymap.set({ "n", "v" }, "<C-j>", function()
            require("smart-splits").move_cursor_down()
          end, { buffer = win.buf })
          vim.keymap.set({ "n", "v" }, "<C-k>", function()
            require("smart-splits").move_cursor_up()
          end)
          vim.keymap.set({ "n", "v" }, "<C-l>", function(e)
            require("smart-splits").move_cursor_right()
          end, { buffer = win.buf })
          --- The splits in insert mode
          vim.keymap.set({ "i", "t" }, "<C-h>", function()
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_left()
          end, { buffer = win.buf })
          vim.keymap.set({ "t", "i" }, "<C-j>", function()
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_down()
          end, { buffer = win.buf })
          vim.keymap.set({ "t", "i" }, "<C-k>", function()
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_up()
          end)
          vim.kemap.set({ "t", "i" }, "<C-l>", function(e)
            local ls = require("luasnip")
            if ls.choice_active() then
              ls.change_choice(1)
              return true
            end
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_right()
          end, { buffer = win.buf })
        end,
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
            --- Note that this will not when the buffer
            --- is reused since the buffer type is no longer preview
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
              picker:focus("preview")
              -- picker_focus_part(picker, "preview")
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

          hide_help = function(picker)
            -- picker:help
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

          scratch_delete_confirm = function(picker, item)
            local selected = picker:selected({ fallback = true })
            item = item or selected[1]
            if not item then
              return
            end
            local meta = item.item or item
            local file = meta.file
            if not file then
              return
            end
            local name = meta.name or vim.fn.fnamemodify(file, ":t")
            local choice = vim.fn.confirm("Delete scratch '" .. name .. "'?", "&Yes\n&No", 2)
            if choice ~= 1 then
              return
            end
            os.remove(file)
            os.remove(file .. ".meta")
            picker:refresh()
          end,

          scratch_toggle_cwd = function(picker)
            scratch_filter_cwd = not scratch_filter_cwd
            picker:refresh()
          end,

          ---@diagnostic disable-next-line: redefined-local
          oneoff_float = function(picker, item)
            item = item or picker:selected({ fallback = true })[1]
            -- use item._path for things like snacks config picker
            local file = item and item._path or (item.item or item).file
            if not file or file == "" then
              return
            end

            picker:close()
            vim.schedule(function()
              local filep = vim.fn.fnamemodify(file, ":p")
              local existed = vim.fn.bufexists(filep) == 1
              local buf = vim.fn.bufadd(filep)
              vim.fn.bufload(buf)

              if not existed then
                vim.bo[buf].buflisted = false
                vim.bo[buf].bufhidden = "wipe"
                vim.bo[buf].swapfile = false
              end

              Snacks.win.new({ buf = buf, position = "float", width = 0.86, height = 0.86 })

              vim.keymap.set("n", "q", function()
                if #vim.fn.win_findbuf(buf) == 1 then
                  vim.cmd("bwipeout!")
                else
                  vim.cmd("close")
                end
              end, { buffer = buf, nowait = true, silent = true })
              vim.keymap.set("n", "<Esc>", function()
                if #vim.fn.win_findbuf(buf) == 1 then
                  vim.cmd("bwipeout!")
                else
                  vim.cmd("close")
                end
              end, { buffer = buf, nowait = true, silent = true })
            end)
          end,

          ---@diagnostic disable-next-line: redefined-local
          oneoff_tab = function(picker, item)
            -- use item._path for things like snacks config picker
            item = item or picker:selected({ fallback = true })[1]
            local file = item and item._path or (item.item or item).file
            if not file or file == "" then
              return
            end

            picker:close()
            vim.schedule(function()
              local filep = vim.fn.fnamemodify(file, ":p")
              local existed = vim.fn.bufexists(filep) == 1
              local buf = vim.fn.bufadd(filep)
              vim.fn.bufload(buf)

              if not existed then
                vim.bo[buf].buflisted = false
                vim.bo[buf].bufhidden = "wipe"
                vim.bo[buf].swapfile = false
              end

              vim.cmd("tabnew")
              vim.api.nvim_set_current_buf(buf)

              vim.keymap.set("n", "q", function()
                if #vim.fn.win_findbuf(buf) == 1 then
                  vim.cmd("bwipeout!")
                end
                vim.cmd("tabclose")
              end, { buffer = buf, nowait = true, silent = true })
            end)
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
              -- ["<C-h>"] = { "focus_left", mode = { "i", "n" }, desc = "Picker focus left" },
              -- ["<C-j>"] = { "focus_down", mode = { "i", "n" }, desc = "Picker focus down" },
              -- ["<C-k>"] = { "focus_up", mode = { "i", "n" }, desc = "Picker focus up" },
              -- ["<C-l>"] = { "focus_right", mode = { "i", "n" }, desc = "Picker focus right" },
              ["<Esc>"] = { "close", mode = { "n", "i" }, desc = "Close help or picker" },
              ["<c-y>"] = { "confirm", mode = { "i", "n" } },
              ["<c-g><c-i>"] = { "toggle_ignored", mode = { "i", "n" } },
              ["<c-g><c-i>"] = { "toggle_hidden", mode = { "i", "n" } },
              ["<c-o>"] = { "edit_split", mode = { "i", "n" } },
              ["?"] = { "toggle_help_input", mode = { "i", "n" } },
              ["<c-u>"] = false,
              ["<c-d>"] = false,
              ["<c-a>"] = false,
              ["<c-g>"] = false, -- no need
              ["<del>"] = { "bufdelete", mode = { "n", "i" } },
              ["<c-c>"] = { "yank", mode = { "n", "i" } },
              ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
              ["<D-c>"] = { "yank", mode = { "n", "i" } },
              ["<D-p>"] = { "paste", mode = { "n", "i" } },
              -- Probably won't work given this is Tab
              ["<c-i>"] = { "print_path", mode = { "n", "i" } },
              ["<C-t>"] = { "tab", mode = { "n", "i" } },
              ["<c-.>"] = { "cd", mode = { "n", "i" } },
              ["<c-;>"] = { "terminal", mode = { "n", "i" } },
              -- TODO: We should have an action like ctrl-enter that opens the file as a hidden buffer!
              -- That way things like <leader>, will work.
              ["<C-space>"] = { "select_only", mode = { "n", "i" } },
              -- Maybe do one of these
              ["<S-enter>"] = { "oneoff_float", mode = { "n", "i" }, desc = "One off edit (tab)" },
              -- ["<C-enter>"] = { "edit_vsplit", mode = { "n", "i" } },
              ["<C-h>"] = false,
              ["<C-j>"] = { "focus_list", mode = { "i", "n" }, desc = "Picker focus down" },
              ["<C-k>"] = false,
              ["<C-l>"] = { "focus_preview", mode = { "i", "n" }, desc = "Picker focus right" },
            },
          },
          list = {
            keys = {
              -- ["<C-h>"] = { "focus_left", mode = { "i", "n" }, desc = "Picker focus left" },
              -- ["<C-j>"] = { "focus_down", mode = { "i", "n" }, desc = "Picker focus down" },
              -- ["<C-k>"] = { "focus_up", mode = { "i", "n" }, desc = "Picker focus up" },
              -- ["<C-l>"] = { "focus_right", mode = { "i", "n" }, desc = "Picker focus right" },
              ["<Esc>"] = { "close_or_hide_help", mode = { "n", "i" }, desc = "Close help or picker" },
              ["?"] = { "toggle_help_list", mode = { "i", "n" } },
              ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
              ["<c-space>"] = { "select_only", mode = { "n", "i" } },
              ["<C-h>"] = false,
              ["<C-j>"] = { "focus_input", mode = { "i", "n" }, desc = "Picker focus down" },
              ["<C-k>"] = { "focus_input", mode = { "i", "n" }, desc = "Picker focus up" },
              ["<C-l>"] = { "focus_preview", mode = { "i", "n" }, desc = "Picker focus right" },
            },
          },
          preview = {
            -- on_close = function(win)
            --   -- vim.keymap.del({ "i", "n" }, "<C-h>", { buffer = win.buf })
            --   -- vim.keymap.del({ "i", "n" }, "<C-l>", { buffer = win.buf })
            --   -- vim.keymap.del({ "i", "n" }, "<C-j>", { buffer = win.buf })
            --   -- vim.keymap.del({ "i", "n" }, "<C-k>", { buffer = win.buf })
            --
            --   vim.keymap.set({ "n", "v" }, "<C-h>", "<C-w><C-h>", { buffer = win.buf })
            --   vim.keymap.set({ "n", "v" }, "<C-j>", "<C-w><C-j>", { buffer = win.buf })
            --   vim.keymap.set({ "n", "v" }, "<C-k>", "<C-w><C-k>", { buffer = win.buf })
            --   vim.keymap.set({ "n", "v" }, "<C-l>", "<C-w><c-l>", { buffer = win.buf })
            --   --- The splits in insert mode
            --   vim.keymap.set({ "i", "t" }, "<C-h>", function()
            --     vim.cmd("stopinsert")
            --     return "<C-w><C-h>"
            --     -- require("smart-splits").move_cursor_left()
            --   end, { buffer = win.buf })
            --   vim.keymap.set({ "t", "i" }, "<C-j>", function()
            --     vim.cmd("stopinsert")
            --     return "<C-w><C-j>"
            --     -- require("smart-splits").move_cursor_down()
            --   end, { buffer = win.buf })
            --   vim.keymap.set({ "t", "i" }, "<C-k>", function()
            --     vim.cmd("stopinsert")
            --     return "<C-w><C-k>"
            --     -- require("smart-splits").move_cursor_up()
            --   end)
            --   vim.kemap.set({ "t", "i" }, "<C-l>", function(e)
            --     local ls = require("luasnip")
            --     if ls.choice_active() then
            --       ls.change_choice(1)
            --       return true
            --     end
            --     vim.cmd("stopinsert")
            --     return "<C-w><C-l>"
            --   end, { buffer = win.buf })
            --   vim.keymap.del({ "i", "n" }, "<Esc>", { buffer = win.buf })
            -- end,
            keys = {
              -- WARN: Note rn there is a nto so great bug that
              -- where all of these keymaps will be added to buffer local maps
              --
              ["<C-h>"] = { "focus_list", mode = { "i", "n" }, desc = "Picker focus left" },
              ["<C-j>"] = { "focus_list", mode = { "i", "n" }, desc = "Picker focus down" },
              ["<C-k>"] = { "focus_input", mode = { "i", "n" }, desc = "Picker focus up" },
              ["<C-l>"] = false,
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
            preview = "file",
            format = "file", -- leverage Snacks file formatter for icons/filetype awareness
            finder = function()
              local current = vim.api.nvim_get_current_tabpage()

              local items = vim.tbl_map(function(tabpage)
                local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
                local win = vim.api.nvim_tabpage_get_win(tabpage)
                local buf = vim.api.nvim_win_get_buf(win)
                local name = vim.api.nvim_buf_get_name(buf)
                local is_current = tabpage == current

                local file = name ~= "" and vim.fn.fnamemodify(name, ":p") or nil
                local filename = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
                local parent = name ~= "" and vim.fn.fnamemodify(name, ":h:t") or nil
                local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
                local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
                local win_count = #vim.api.nvim_tabpage_list_wins(tabpage)

                local label = string.format("%s %d", is_current and "" or "", tabnr)
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
                  is_current = is_current,
                  search = table.concat({ filename, parent or "", tostring(tabnr), filetype, buftype }, " "),
                  label = label,
                  comment = comment,
                }
              end, vim.api.nvim_list_tabpages())

              table.sort(items, function(a, b)
                if a.is_current ~= b.is_current then
                  return a.is_current
                end
                return a.tabnr < b.tabnr
              end)

              return items
            end,
            confirm = function(picker, item)
              if item and item.tabpage and vim.api.nvim_tabpage_is_valid(item.tabpage) then
                vim.api.nvim_set_current_tabpage(item.tabpage)
              end
              picker:close()
            end,
            actions = {
              -- TODO: Get it so that the highlighted entry
              -- doesn't move arund after the fact
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
              input = {
                keys = {
                  ["<c-d>"] = { "bufdelete", mode = { "n", "i" } },
                  -- TODO: Get <c-g><c-i> to toggle hidden buffers
                },
              },
            },
          },
          scratch = {
            win = {
              input = {
                keys = {
                  ["<c-n>"] = { "list_down", mode = { "n", "i" } },
                  ["<c-p>"] = { "list_up", mode = { "n", "i" } },
                  ["<c-d>"] = { "scratch_delete_confirm", mode = { "n", "i" } },
                  ["<c-x>"] = { "scratch_delete_confirm", mode = { "n", "i" } },
                  ["<c-g><c-i>"] = { "scratch_toggle_cwd", mode = { "n", "i" } },
                },
              },
            },
          },
          notifications = {
            win = {
              input = {
                keys = {
                  ["<c-y>"] = { "yank", mode = { "n", "i" } },
                },
              },
              preview = {
                wo = { wrap = true, linebreak = true }, -- linebreak is not try to split words
              },
            },
          },
        },
      },
    },
    -- This almost worked.
    -- config = function(_, opts)
    --   local Snacks = require("snacks")
    --
    --   -- When the preview window reuses a real buffer (not the scratch preview
    --   -- buffer), re-apply the picker window keymaps to that buffer so
    --   -- <C-h/j/k/l> and other picker bindings still work inside preview.
    --   local preview = require("snacks.picker.core.preview")
    --   local orig_set_buf = preview.set_buf
    --   function preview:set_buf(buf)
    --     orig_set_buf(self, buf)
    --     if self.win and self.win.buf == buf then
    --       self.win:map() -- rebind picker window maps onto the reused buffer
    --     end
    --   end
    --
    --   Snacks.setup(opts)
    -- end,
    -- stylua: ignore
    keys = {
      --- Modified true does not give us what we want, which is modifed
      --- since before we opened it.
      -- { "ff", function() Snacks.picker.buffers({ modified = true }) end, desc = "List Modified Buffers" },
      { "ff", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
      -- Get this to list terminal buffers last
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
