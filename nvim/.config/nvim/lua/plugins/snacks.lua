---@diagnostic disable: inject-field
-- TODOs:
--  - [ ] nvim/.config/nvim/lua/plugins/snacks.lua:548: override opts.picker.sources.keymaps.confirm to open item.file/item.pos when
--    present (else vim.notify(...) + no-op).
--  - [ ] Same place: add a secondary key/action (e.g. <C-y>) to “execute keymap” (current behavior) via
--    vim.api.nvim_input(item.item.lhs).

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
      explorer = {
        replace_netrw = true, -- Replace netrw with the snacks explorer
        trash = true, -- Use the system trash when deleting files
      },
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
                ",c",
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
          },
        },
        win = {
          wo = {
            colorcolumn = "",
          },
          -- make it big
          width = 0.86,
          height = 0.86,
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
          -- Note only works here, not on win_by_ft
          footer_keys = { "q", "<cr>", "R", ",c" },
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
            { icon = " ", key = "t", desc = "Open New Terminal", action = ":term" },
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
      ---@type table<string, snacks.win.Config>
      styles = {
        scratch_vsplit = { position = "right", width = 0.45, backdrop = false, fixbuf = false },
        scratch_split = { position = "bottom", height = 0.35, width = 1, backdrop = false, fixbuf = false },
        scratch_float = { position = "float", width = 0.6, height = 0.6, backdrop = 75, fixbuf = false },
        --- TODO: Figure out a way to make sure ever buffer in a floating window, even not the first buffer
        --- gets the q --> quit keymap. That will require adding a BufWinEnter to add q to the buffer
        --- and BufWinLeave to remove it, so that the buffer is not effeced anywhere else.
        big_float = { position = "float", width = 0.86, height = 0.86, fixbuf = false, w = { snacks_main = true } },
        -- NOTE: We need to be careful here
        -- as zenmode will not restore the c-h etc. mappings once left
        -- See the `HACK` below on `on_close`.
        zen = {
          keys = {
            ["<C-h>"] = "",
            ["<C-j>"] = "",
            ["<C-k>"] = "",
            ["<C-l>"] = "",
            ["<leader>ua"] = {
              ---@param self snacks.win
              function(self)
                local statusline = self.meta.statusline
                vim.notify("Zen sline: " .. (statusline or "nil"))
                if statusline == false or statusline == nil then
                  statusline = true
                else
                  statusline = false
                end
                vim.schedule(function()
                  require("snacks").zen()
                  require("snacks").zen({
                    show = { statusline = statusline },
                    win = { meta = { statusline = statusline } },
                  })
                end)
              end,
            },
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
          vim.keymap.set({ "t", "i" }, "<C-l>", function(e)
            local ls = require("luasnip")
            if ls.choice_active() then
              ls.change_choice(1)
              return true
            end
            vim.cmd("stopinsert")
            require("smart-splits").move_cursor_right()
          end, { buffer = win.buf })
          pcall(function()
            vim.keymap.del("n", "<leader>ua", { buffer = win.buf })
          end)
        end,
      },
      ---@type snacks.lazygit.Config
      lazygit = {
        auto_close = true,
        ---@type snacks.win.Config
        win = {
          on_buf = function(self)
            -- NOTE: In the future if you ever need this
            -- its super hacky but will win. Unless of course someone
            -- timers longer or double schedules it!
            -- -- Wrap it in vim.schedule so that
            -- -- even the TermOpen autcmd fails in ../config/autocmds.lua fails
            -- vim.schedule(function()
            --   sc, desc = pcall(function()
            --     vim.keymap.del("t", "<esc>", { buffer = self.buf })
            --   end)
            --   vim.notify("Properly deleted keymap? " .. (desc or ""))
            -- end)
          end,
          keys = {
            term_normal = {
              -- HACK:
              -- make sure snacks doesn't map <Esc> get this in terminal mode
              -- brutal
              -- See the culprit at /Users/michaelfortunato/projects/neovim-plugins/snacks.nvim/lua/snacks/terminal.lua:32-67
              "<Esc>",
              false,
            },
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
        -- doing this gives us a whole lot of beneifts
        -- According to AI,
        -- - current=true -> use the window you launched the picker from
        -- - float=true ->allow floats
        -- - file=false -> let terminals/nofile buffers be replaced too
        -- So float = true is what we want (fcurrent = false, file = true, float = false)
        -- is default.
        main = { current = true, float = true, file = true },
        ---@type snacks.picker.actions
        actions = {
          -- TODO: add optional layout-aware direction mapping for non-canonical presets.
          -- Navigation assumes the canonical Snacks layout: input + list stacked on the left,
          -- preview on the right. It's a hard-coded pane cycle via filetypes (no geometry check),
          -- so other layouts (e.g., preview above list in grep_buffers) can feel “off”.
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

          maybe_close_help = function(picker)
            -- If a Snacks help window is visible, close it; otherwise close the picker.
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == "snacks_win_help" then
                vim.api.nvim_win_close(win, true)
                return
              end
            end
          end,
          close_or_hide_help = function(picker)
            -- If a Snacks help window is visible, close it; otherwise close the picker.
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == "snacks_win_help" then
                vim.api.nvim_win_close(win, true)
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
              end

              Snacks.win.new({ buf = buf, style = "big_float" })

              vim.keymap.set("n", "q", function()
                -- if #vim.fn.win_findbuf(buf) == 1 then
                --   vim.cmd("close")
                -- else
                --   vim.cmd("close")
                -- end
                vim.cmd("close")
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
                -- vim.bo[buf].swapfile = false ??
              end

              vim.cmd("tabnew")
              vim.api.nvim_set_current_buf(buf)

              -- I thought about <Esc> too like this but too senstive.
              vim.keymap.set("n", "q", function()
                -- if #vim.fn.win_findbuf(buf) == 1 then
                --   vim.cmd("tabclose")
                -- end
                vim.cmd("tabclose")
              end, { buffer = buf, nowait = true, silent = true })
            end)
          end,
          toggle_hidden_ignored = function(picker)
            picker.opts.hidden = not picker.opts.hidden
            picker.opts.ignored = not picker.opts.ignored
            picker.list:set_target()
            picker:find()
          end,
          cycle_buffers_filter = function(picker)
            local filter = picker.input and picker.input.filter
            if not filter then
              return
            end

            filter.meta.buf_filter_level = ((filter.meta.buf_filter_level or 1) % 3) + 1
            local level = filter.meta.buf_filter_level

            picker.opts.buf_files = level == 1
            picker.opts.buf_terms = level == 2
            picker.opts.buf_all = level == 3

            picker.opts.nofile = level == 3

            picker.list:set_target()
            picker:find()
          end,
          cycle_diagnostics_severity = function(picker)
            local order = {
              "all",
              vim.diagnostic.severity.ERROR,
              vim.diagnostic.severity.WARN,
              vim.diagnostic.severity.INFO,
              vim.diagnostic.severity.HINT,
            }

            local current = picker.opts.severity or "all"
            local idx = 1
            for i, sev in ipairs(order) do
              if sev == current then
                idx = i
                break
              end
            end

            idx = (idx % #order) + 1
            local next = order[idx]
            if next == "all" then
              ---@diagnostic disable-next-line: inject-field
              picker.opts.severity = nil
            else
              picker.opts.severity = next
            end
            picker.list:set_target()

            local sev = picker.opts.severity
            picker.opts.sev_all = sev == nil
            picker.opts.sev_err = sev == vim.diagnostic.severity.ERROR
            picker.opts.sev_warn = sev == vim.diagnostic.severity.WARN
            picker.opts.sev_info = sev == vim.diagnostic.severity.INFO
            picker.opts.sev_hint = sev == vim.diagnostic.severity.HINT
            -- vim.notify("Picker: Set diagnostic severity level to " .. next)
            picker:find()
          end,
          debug = function(picker, item)
            vim.notify(vim.inspect(item), { timeout = 5000 })
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
              ["<Esc>"] = { "close_or_hide_help", mode = { "n", "i" }, desc = "Close help or picker" },
              ["<C-y>"] = { "confirm", mode = { "i", "n" } },
              ["<C-g><C-i>"] = { "toggle_ignored", mode = { "n", "i" }, desc = "Toggle ignored" },
              ["<C-g><C-h>"] = { "toggle_hidden", mode = { "n", "i" }, desc = "Toggle hidden" },
              ["<C-o>"] = { "edit_split", mode = { "i", "n" } },
              ["?"] = { "toggle_help_input", mode = { "i", "n" } },
              -- TODO: ["<C-u>"] = { "disabled", mode = { "i", "n" } },
              ["<C-u>"] = false,
              ["<C-d>"] = false,
              ["<C-a>"] = false,
              ["<C-g>"] = false, -- no need
              ["<Tab>"] = false,
              ["<Del>"] = { "bufdelete", mode = { "n", "i" } },
              ["<C-c>"] = { "yank", mode = { "n", "i" } },
              ["<C-/>"] = { "cycle_win", mode = { "n", "i" } },
              ["<D-c>"] = { "yank", mode = { "n", "i" } },
              ["<D-p>"] = { "paste", mode = { "n", "i" } },
              -- Probably won't work given this is Tab
              ["<Tab><Enter>"] = { "tabdrop", mode = { "n", "i" }, desc = "Edit in new (or existing) tab" },
              ["<C-t>"] = { "tabe", mode = { "n", "i" }, desc = "Edit in new tab" },
              -- Open file in new tab in background?
              ["<C-S-t>"] = {
                function(picker, item)
                  vim.notify("Open in background tab is TODO", "error")
                  return
                  -- if item._path == nil then
                  --   return
                  -- end
                end,
                mode = { "n", "i" },
                desc = "Edit in new (or existing) tab",
              },
              ["<C-.>"] = { "cd", mode = { "n", "i" } },
              ["<C-;>"] = { "terminal", mode = { "n", "i" } },
              -- TODO: We should have an action like ctrl-enter that opens the file as a hidden buffer!
              -- That way things like <leader>, will work.
              ["<C-space>"] = { "select_only", mode = { "n", "i" } },
              ["<S-enter>"] = { "oneoff_float", mode = { "n", "i" }, desc = "One off edit (float)" },
              ["<C-enter>"] = { "drop", mode = { "n", "i" }, desc = "Focus existing buffer (or open here)" },
              -- ["<C-S-enter>"] = { "...", mode = { "n", "i" }, desc = "..." },
              --- Navigation
              ["<C-h>"] = { "toggle_hidden_ignored", mode = { "n", "i" }, desc = "Toggle hidden+ignored" },
              ["<C-j>"] = { "focus_list", mode = { "i", "n" }, desc = "Picker focus down" },
              ["<C-k>"] = false,
              ["<C-l>"] = { "focus_preview", mode = { "i", "n" }, desc = "Picker focus right" },
              ---- Debug
              ["<C-i>"] = { "debug", mode = { "n", "i" } },
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
              ["yy"] = { "yank", mode = { "n" }, desc = "Copy entry" },
              ["<C-enter>"] = { "drop", mode = { "n", "i" }, desc = "Focus existing buffer (or open here)" },
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
              ["<Esc>"] = false,
              -- -- ["<Esc><Esc>"] = { "close_or_hide_help", mode = { "n", "i" }, desc = "Close help or picker" },
              -- -- ["<Esc>"] = { "<Nop>", mode = { "n" } },
              ["<Esc><Esc>"] = { "close", mode = { "n" }, desc = "Close help or picker" },
              ["?"] = { "toggle_help_list", mode = { "i", "n" } },
              ["<c-/>"] = { "cycle_win", mode = { "n", "i" } },
            },
            wo = {
              number = vim.wo.number,
              relativenumber = vim.wo.relativenumber,
              signcolumn = vim.wo.signcolumn,
              cursorline = vim.wo.cursorline,
              wrap = true, -- Maybe?
              colorcolumn = "",
            },
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
                  -- preview = {
                  --   -- TODO: Make this nuicer
                  --   text = win_count,
                  -- },
                }
              end, vim.api.nvim_list_tabpages())

              -- If you want to put the current tab first etc.
              -- table.sort(items, function(a, b)
              --   if a.is_current ~= b.is_current then
              --     return a.is_current
              --   end
              --   return a.tabnr < b.tabnr
              -- end)

              return items
            end,
            confirm = function(picker, item)
              if item and item.tabpage and vim.api.nvim_tabpage_is_valid(item.tabpage) then
                vim.api.nvim_set_current_tabpage(item.tabpage)
              end
              picker:close()
            end,
            ---@type snacks.picker.actions
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
              move_tab_up = function(picker, item)
                vim.notify(
                  "Not implemented yet, picker is scoped to current tab so difficult without nvim letting us move tabs that are not the current see :tabmove",
                  "error"
                )
                return
                -- if item == nil then
                --   vim.notify("Null item", "warn")
                --   return
                -- end
                -- local current_tabpage = vim.api.nvim_get_current_tabpage()
                -- local tabnr = item.tabnr
                -- if not item.is_current then
                --   vim.api.nvim_set_current_tabpage(item.tabpage)
                -- end
                -- vim.cmd("-tabmove")
                -- vim.api.nvim_set_current_tabpage(current_tabpage)
                -- picker:find()
              end,
              move_tab_down = function(picker, item)
                vim.notify(
                  "Not implemented yet, picker is scoped to current tab so difficult without nvim letting us move tabs that are not the current see :tabmove",
                  "error"
                )
                return
                -- if item == nil then
                --   vim.notify("Null item", "warn")
                --   return
                -- end
                -- local current_tabpage = vim.api.nvim_get_current_tabpage()
                -- local tabnr = item.tabnr
                -- if not item.is_current then
                --   vim.api.nvim_set_current_tabpage(item.tabpage)
                -- end
                -- vim.cmd("+tabmove")
                -- vim.api.nvim_set_current_tabpage(current_tabpage)
                -- picker:find()
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
                  -- Change this to <C-S-j> after debugging
                  ["<C-S-j>"] = { "move_tab_down", mode = { "n", "i" } },
                  -- Change this to <C-S-k> after debugging
                  ["<C-S-j>"] = { "move_tab_up", mode = { "n", "i" } },
                },
              },
            },
          },
          buffers = {
            hidden = true,
            unloaded = true,
            current = true,
            sort_lastused = true,
            toggles = {
              buf_files = { icon = "F" },
              buf_terms = { icon = "T" },
              buf_all = { icon = "A" },
            },
            on_show = function(picker)
              local filter = picker.input.filter
              local level = filter.meta.buf_filter_level
              if level == nil then
                level = picker.opts.nofile and 3 or 1
                filter.meta.buf_filter_level = level
              end

              picker.opts.buf_files = level == 1
              picker.opts.buf_terms = level == 2
              picker.opts.buf_all = level == 3
              picker:update_titles()
            end,
            finder = function(opts, ctx)
              if ctx.filter.meta.buf_filter_level == nil then
                ctx.filter.meta.buf_filter_level = opts.nofile and 3 or 1
              end

              local items = require("snacks.picker.source.buffers").buffers(opts, ctx)
              local visible_tabs_width = 10
              local tab_icon = "󰓩"
              local function add_visible_tabs(item)
                local wins = (item.info and item.info.windows) or {}
                local tabs = {}
                for _, winid in ipairs(wins) do
                  if vim.api.nvim_win_is_valid(winid) then
                    local tabpage = vim.api.nvim_win_get_tabpage(winid)
                    if vim.api.nvim_tabpage_is_valid(tabpage) then
                      tabs[vim.api.nvim_tabpage_get_number(tabpage)] = true
                    end
                  end
                end
                local tabnrs = vim.tbl_keys(tabs)
                table.sort(tabnrs)
                item.mnf_visible_tabs = tabnrs
                if vim.tbl_isempty(tabnrs) then
                  item.mnf_visible_tabs_label = Snacks.picker.util.align("", visible_tabs_width)
                else
                  local label = string.format("%s T:%s", tab_icon, table.concat(tabnrs, ","))
                  item.mnf_visible_tabs_label = Snacks.picker.util.align(label, visible_tabs_width, { truncate = true })
                end
              end
              for _, item in ipairs(items) do
                add_visible_tabs(item)
              end

              local scratch_root = ctx.filter.meta.scratch_root
              if scratch_root == nil then
                scratch_root = vim.fn.stdpath("data") .. "/scratch/"
                ctx.filter.meta.scratch_root = scratch_root
              end

              local scratch, rest = {}, {}
              for _, item in ipairs(items) do
                local name = item.name or item.file or ""
                if type(name) == "string" and name:find(scratch_root, 1, true) == 1 then
                  item.buftype = "scratch"
                  item.text = Snacks.picker.util.text(item, { "buftype", "buf", "name", "filetype" })
                  table.insert(scratch, item)
                else
                  table.insert(rest, item)
                end
              end
              vim.list_extend(rest, scratch)
              return rest
            end,
            format = function(item, picker)
              local function inject_visible_tabs(ret)
                local label = item.mnf_visible_tabs_label or Snacks.picker.util.align("", 10)
                local idx_file = nil
                for i, chunk in ipairs(ret) do
                  if type(chunk) == "table" and (chunk.field == "file" or type(chunk.resolve) == "function") then
                    idx_file = i
                    break
                  end
                end

                if idx_file then
                  table.insert(ret, idx_file, { label, "SnacksPickerComment" })
                  table.insert(ret, idx_file + 1, { " " })
                  return ret
                end

                table.insert(ret, { label, "SnacksPickerComment" })
                table.insert(ret, { " " })
                return ret
              end

              local fmt = require("snacks.picker.format").buffer
              if item.buftype == "scratch" then
                local it = vim.tbl_extend("force", {}, item, { buftype = "" }) -- avoid trailing [scratch]
                local ret = fmt(it, picker)
                table.insert(ret, 1, { "[scratch] ", "SnacksPickerBufType" })
                return inject_visible_tabs(ret)
              end
              return inject_visible_tabs(fmt(item, picker))
            end,
            filter = {
              filter = function(item, filter)
                local level = filter.meta.buf_filter_level or 1
                local bt = item.buftype or ""

                local scratch_root = filter.meta.scratch_root
                if scratch_root == nil then
                  scratch_root = vim.fn.stdpath("data") .. "/scratch/"
                  filter.meta.scratch_root = scratch_root
                end

                local listed = item.buf and vim.bo[item.buf].buflisted
                local name = item.name or item.file or ""
                local is_scratch = type(name) == "string" and name:find(scratch_root, 1, true) == 1
                if level ~= 3 and not (listed or is_scratch) then
                  return false
                end

                if level == 1 then
                  return bt == ""
                end
                if level == 2 then
                  return bt == "" or bt == "terminal"
                end
                return true
              end,
            },
            win = {
              input = {
                keys = {
                  ["<c-d>"] = { "bufdelete", mode = { "n", "i" } },
                  -- NOTE snacks default cr action refocuses the buffer to its oprior slot even if
                  -- its no longer vissible, at least for terminals super fuckign annoying
                  ["<Enter>"] = { "confirm", mode = { "n", "i" }, desc = "Open buffer here" },
                  ["<C-y>"] = { "confirm", mode = { "n", "i" }, desc = "Open buffer here" },
                  ["<C-Enter>"] = { "drop", mode = { "n", "i" }, desc = "Focus existing buffer (or open here)" },
                  ["<C-h>"] = { "cycle_buffers_filter", mode = { "n", "i" }, desc = "Cycle buffers filter" },
                  -- TODO: Get <c-g><c-i> to toggle hidden buffers
                },
              },
              list = {
                keys = {
                  ["<S-enter>"] = { "oneoff_float", mode = { "n", "i" }, desc = "Focus existing buffer (or open here)" },
                  ["<C-h>"] = { "cycle_buffers_filter", mode = { "n", "i" }, desc = "Cycle buffers filter" },
                  ["<C-Enter>"] = { "drop", mode = { "n", "i" }, desc = "Focus existing buffer (or open here)" },
                  ["dd"] = { "bufdelete", mode = { "n", "i" } },
                },
              },
            },
          },
          files = {},
          git_files = {},
          recent = {},
          diagnostics = {
            sev_all = true, -- initial
            toggles = {
              sev_all = { icon = "A" },
              sev_err = { icon = "E" },
              sev_warn = { icon = "W" },
              sev_info = { icon = "I" },
              sev_hint = { icon = "H" },
            },
            on_show = function(picker)
              local sev = picker.opts.severity
              picker.opts.sev_all = sev == nil
              picker.opts.sev_err = sev == vim.diagnostic.severity.ERROR
              picker.opts.sev_warn = sev == vim.diagnostic.severity.WARN
              picker.opts.sev_info = sev == vim.diagnostic.severity.INFO
              picker.opts.sev_hint = sev == vim.diagnostic.severity.HINT
              picker:update_titles()
            end,
            win = {
              input = {
                keys = {
                  ["<C-h>"] = { "cycle_diagnostics_severity", mode = { "n", "i" }, desc = "Cycle diagnostics severity" },
                },
              },
              list = {
                keys = {
                  ["<C-h>"] = { "cycle_diagnostics_severity", mode = { "n", "i" }, desc = "Cycle diagnostics severity" },
                },
              },
            },
          },
          diagnostics_buffer = {
            sev_all = true, -- initial
            toggles = {
              sev_all = { icon = "A" },
              sev_err = { icon = "E" },
              sev_warn = { icon = "W" },
              sev_info = { icon = "I" },
              sev_hint = { icon = "H" },
            },
            on_show = function(picker)
              local sev = picker.opts.severity
              picker.opts.sev_all = sev == nil
              picker.opts.sev_err = sev == vim.diagnostic.severity.ERROR
              picker.opts.sev_warn = sev == vim.diagnostic.severity.WARN
              picker.opts.sev_info = sev == vim.diagnostic.severity.INFO
              picker.opts.sev_hint = sev == vim.diagnostic.severity.HINT
              picker:update_titles()
            end,
            win = {
              input = {
                keys = {
                  ["<C-h>"] = { "cycle_diagnostics_severity", mode = { "n", "i" }, desc = "Cycle diagnostics severity" },
                },
              },
              list = {
                keys = {
                  ["<C-h>"] = { "cycle_diagnostics_severity", mode = { "n", "i" }, desc = "Cycle diagnostics severity" },
                },
              },
            },
          },
          scratch = {
            ---@type snacks.picker.actions
            actions = {
              -- NOTE:  The confirm action for this picker is dfiferent so
              -- override the varioau sactions
              -- ~/projects/neovim-plugins/snacks.nvim/lua/snacks/picker/config/sources.lua
              scratch_open_tab = function(picker, item)
                vim.notify("TODO")
                local selected = picker:selected({ fallback = true })

                item = item or selected[1]
                if not item then
                  return
                end

                local file = item and (item.item or item).file or item._path
                if not file then
                  vim.health.warn("Could not find file")
                  return
                end
                Snacks.scratch.open({ file = file, ft = ft, win = { style = "" } })
                -- TODO: key the buffer local keymaps for python like source the file etc back
                picker:close()
              end,
              scratch_open_split = function(picker, item)
                local selected = picker:selected({ fallback = true })

                item = item or selected[1]
                if not item then
                  return
                end
                local file = item and (item.item or item).file or item._path
                if not file then
                  vim.health.warn("Could not find file")
                  return
                end
                -- TODO: key the buffer local keymaps for python like source the file etc back
                Snacks.scratch.open({ file = file, win = { style = "scratch_split" } })
                picker:close()
              end,
              scratch_open_vsplit = function(picker, item)
                local selected = picker:selected({ fallback = true })

                item = item or selected[1]
                if not item then
                  return
                end
                local file = item and (item.item or item).file or item._path
                if not file then
                  vim.health.warn("Could not find file")
                  return
                end
                -- TODO: key the buffer local keymaps for python like source the file etc back
                Snacks.scratch.open({ file = file, win = { style = "scratch_vsplit" } })
                picker:close()
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
            },
            win = {
              input = {
                keys = {
                  ["<c-n>"] = { "list_down", mode = { "n", "i" } },
                  ["<c-p>"] = { "list_up", mode = { "n", "i" } },
                  ["<c-d>"] = { "scratch_delete_confirm", mode = { "n", "i" } },
                  ["<c-x>"] = { "scratch_delete_confirm", mode = { "n", "i" } },
                  ["<c-g><c-i>"] = { "scratch_toggle_cwd", mode = { "n", "i" } },
                  -- NOTE: For some reason the default tab command
                  -- for snacks treats scratch buffers differently.
                  ["<C-t>"] = { "scratch_open_tab", mode = { "n", "i" } },
                  ["<C-s>"] = { "scratch_open_split", mode = { "n", "i" } },
                  ["<C-v>"] = { "scratch_open_vsplit", mode = { "n", "i" } },
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
              list = {
                keys = {
                  ["<c-y>"] = { "yank", mode = { "n", "i" } },
                },
              },
              preview = {
                wo = { wrap = true, linebreak = true }, -- linebreak is not try to split words
              },
            },
          },
          keymaps = {
            -- keep Snacks’ original knobs (so the picker is runnable)
            global = true,
            plugs = false,
            ["local"] = true,
            modes = { "n", "v", "x", "s", "o", "i", "c", "t" },
            format = "keymap",
            preview = "preview",

            ---@type snacks.picker.actions
            actions = {
              goto_source = function(picker, item)
                picker:norm(function()
                  item = item or picker:selected({ fallback = true })[1]
                  if not item then
                    return
                  end

                  local file = item._path or item.file
                  if not file or file == "" then
                    vim.notify_once(
                      "No source file recorded for this keymap."
                        .. "Rerun neovim with: `nvim -V1`\n"
                        .. "(Note this will have performance degradation)\n"
                        .. "See issue github:neovim#23719 and \n"
                        .. "read `:help :verbose-cmd-V1` for more.",
                      vim.log.levels.WARN,
                      { timeout = 7000 }
                    )
                    return
                  end

                  local pos = item.pos
                  local search = item.search

                  picker:close()
                  vim.schedule(function()
                    vim.cmd("edit " .. vim.fn.fnameescape(file))
                    if type(pos) == "table" and type(pos[1]) == "number" and pos[1] > 0 then
                      vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] or 0 })
                    elseif type(search) == "string" and search ~= "" then
                      pcall(vim.cmd, search)
                    end
                  end)
                end)
              end,

              -- preserve original toggles (so <a-g>/<a-b> still work)
              toggle_global = function(picker)
                picker.opts.global = not picker.opts.global
                picker:find()
              end,
              toggle_buffer = function(picker)
                picker.opts["local"] = not picker.opts["local"]
                picker:find()
              end,
            },

            -- This is AI generated not sure if its necessary
            ---@param opts snacks.picker.keymaps.Config
            finder = function(opts)
              local items = {} ---@type snacks.picker.finder.Item[]
              local maps = {} ---@type vim.api.keyset.get_keymap[]

              for _, mode in ipairs(opts.modes) do
                if opts.global then
                  vim.list_extend(maps, vim.api.nvim_get_keymap(mode))
                end
                if opts["local"] then
                  vim.list_extend(maps, vim.api.nvim_buf_get_keymap(0, mode))
                end
              end

              local done = {} ---@type table<string, boolean>

              -- Cache sid -> script filename
              local sid_cache = {} ---@type table<integer, string|false>
              local function sid_name(sid)
                if type(sid) ~= "number" or sid <= 0 then
                  return nil
                end
                local cached = sid_cache[sid]
                if cached ~= nil then
                  return cached or nil
                end
                local ok, res = pcall(vim.fn.getscriptinfo, { sid = sid })
                local name = ok and res and res[1] and res[1].name or nil
                sid_cache[sid] = name or false
                return name
              end

              for _, km in ipairs(maps) do
                local key = Snacks.picker.util.text(km, { "mode", "lhs", "buffer" })

                local keep = true
                if opts.plugs == false and km.lhs:match("^<Plug>") then
                  keep = false
                end

                if keep and not done[key] then
                  done[key] = true

                  local item = {
                    mode = km.mode,
                    item = km,
                    key = km.lhs,
                    preview = { text = vim.inspect(km), ft = "lua" },
                  }

                  -- 1) Best: Neovim-recorded provenance (sid/lnum)
                  if type(km.sid) == "number" and type(km.lnum) == "number" and km.lnum > 0 then
                    local file = sid_name(km.sid)
                    if file and file ~= "" then
                      if file:sub(1, 1) == "@" then
                        file = file:sub(2)
                      end
                      if file:find("^vim/") then
                        file = file:gsub("^vim/", (vim.env.VIMRUNTIME or "") .. "/lua/vim/")
                      end
                      item.file = file
                      item.pos = { km.lnum, 0 }
                      item.preview = "file"
                    end
                  end

                  -- 2) Fallback: Lua callback debug info
                  if not item.file and km.callback then
                    local info = debug.getinfo(km.callback, "S")
                    item.info = info
                    if info and info.what == "Lua" and type(info.source) == "string" then
                      local source = info.source
                      if source:sub(1, 1) == "@" then
                        source = source:sub(2)
                      end
                      local file = source
                      if file:find("^vim/") then
                        file = file:gsub("^vim/", (vim.env.VIMRUNTIME or "") .. "/lua/vim/")
                      end
                      item.file = file
                      if source:find("^vim/") and (info.linedefined or 0) == 0 then
                        item.search = "/vim\\.keymap\\.set.*['\"]" .. km.lhs
                      else
                        item.pos = { info.linedefined or 1, 0 }
                      end
                      item.preview = "file"
                    end
                  end

                  -- Always present, so your bindings can depend on it
                  item._path = item.file or ""

                  item.text = Snacks.util.normkey(km.lhs)
                    .. " "
                    .. Snacks.picker.util.text(km, { "mode", "lhs", "rhs", "desc" })
                    .. (item.file or "")

                  items[#items + 1] = item
                end
              end
              return items
            end,
            win = {
              input = {
                keys = {
                  ["<c-h>"] = { "toggle_global", mode = { "n", "i" }, desc = "Toggle Global Keymaps" },
                  ["<Enter>"] = { "goto_source", mode = { "n", "i" }, desc = "Go to keymap definition" },
                  ["<C-y>"] = { "goto_source", mode = { "n", "i" }, desc = "Go to keymap definition" },
                },
              },
              list = {
                keys = {
                  ["<C-y>"] = { "goto_source", mode = { "n", "i" }, desc = "Go to keymap definition" },
                  ["<Enter>"] = { "goto_source", mode = { "n", "i" }, desc = "Go to keymap definition" },
                },
              },
            },
          },
          explorer = {
            layout = { preset = "dropdown", preview = false },
            focus = "input",
            jump = { close = true },
            win = {
              input = {
                keys = {
                  ["<C-y>"] = { "confirm", mode = { "n", "i" }, desc = "Confirm & close" },
                  ["<C-h>"] = { "toggle_hidden_ignored", mode = { "n", "i" }, desc = "Toggle hidden+ignored" },
                  ["<C-d>"] = {
                    { "focus_list", "list_scroll_down" },
                    mode = { "n", "i" },
                    desc = "Page down and enter the list",
                  },
                  ["<C-w>"] = { "layout_left", mode = { "n", "i" } },
                },
              },
              list = {
                keys = {
                  ["<C-y>"] = { "confirm", mode = { "n", "i" }, desc = "Confirm & close" },
                  ["<Right>"] = { "confirm", mode = { "n" }, desc = "Confirm" },
                  ["<C-h>"] = { "toggle_hidden_ignored", mode = { "n", "i" }, desc = "Toggle hidden+ignored" },
                  ["<C-l>"] = false,
                  ["<C-w>"] = { "layout_left", mode = { "n", "i" } },
                },
              },
            },
          },
          help = {
            win = {
              preview = {
                wo = {
                  wrap = true,
                },
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
      { "<leader>n", function()
          wins = vim.api.nvim_tabpage_list_wins(0)
          cur_buf = vim.api.nvim_get_current_buf()
          cur_win = vim.api.nvim_get_current_win()
          for _, win in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype == "snacks_notif" then
              if win == cur_win then
                vim.api.nvim_win_close(win, false)
              else
                vim.api.nvim_set_current_win(win)
              end
              return
            end
          end
          Snacks.picker.notifications()
        end, desc = "Notification History"
      },
      { "<leader>e", function() Snacks.picker.explorer() end, desc = "File explorer" },
      { "<leader>E", function() Snacks.picker.explorer( {dirs = {
        vim.fs.dirname(vim.api.nvim_buf_get_name(0)) or vim.fn.getcwd()
      }
      }) end, desc = "File explorer (cwd)" },
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
      { "<leader>sc", function() Snacks.picker.commands() end, desc = "Commands" },
      { "<leader>sC", function() Snacks.picker.command_history() end, desc = "Command History" },
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
