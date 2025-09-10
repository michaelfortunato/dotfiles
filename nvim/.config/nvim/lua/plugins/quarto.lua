return {
  {
    "quarto-dev/quarto-nvim",
    dependencies = {
      "jmbuhr/otter.nvim",
      "nvim-treesitter/nvim-treesitter",
      { "benlubas/molten-nvim", commit = "4e1c999" },
    },
    ft = { "quarto", "markdown", "qmd" }, -- Load for these filetypes
    config = function()
      require("quarto").setup({
        debug = false,
        closePreviewOnExit = true,
        lspFeatures = {
          enabled = true,
          chunks = "curly",
          languages = { "r", "python", "julia", "bash", "html" },
          diagnostics = {
            enabled = true,
            triggers = { "BufWritePost" },
          },
          completion = {
            enabled = true,
          },
        },
        codeRunner = {
          enabled = true,
          default_method = "molten", -- Use molten as the code runner
          ft_runners = { typst = nil }, -- filetype to runner, ie. `{ python = "molten" }`.
          -- Takes precedence over `default_method`
          never_run = { "yaml", "typst" }, -- filetypes which are never sent to a code runner
        },
      })

      -- Requires Neovim 0.10+ (built-in snippet engine)

      -- Recognize common markdown/quarto fence node kinds
      local FENCE_KINDS = {
        fenced_code_block = true,
        indented_code_block = true,
      }

      local function fence_ancestor()
        -- Use ignore_injections=true so we walk the *host* tree (markdown/quarto),
        -- even if the cursor is inside an injected python/r chunk.
        local node = vim.treesitter.get_node({ ignore_injections = true })
        while node do
          if FENCE_KINDS[node:type()] then
            return node
          end
          node = node:parent()
        end
        return nil
      end

      local function move_after_fence(node)
        -- start_row, start_col, end_row (EXCLUSIVE), end_col
        local _, _, erow, _ = node:range()
        local buf = 0
        local total = vim.api.nvim_buf_line_count(buf)

        -- Because end_row is EXCLUSIVE, the first line *after* the node is erow.
        local target = erow

        if target >= total then
          -- Fence ends at EOF: append a blank line, then place the cursor.
          vim.api.nvim_buf_set_lines(buf, total, total, false, { "" })
          total = total + 1
        end

        -- Extra safety against any parser oddities.
        if target >= total then
          target = total - 1
        end
        if target < 0 then
          target = 0
        end

        -- win_set_cursor is 1-based.
        vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
      end

      -- local function move_after_fence(node)
      -- 	-- node:range() is 0-based; end row points at the closing fence line.
      -- 	local _, _, erow, _ = node:range()
      -- 	local buf = 0
      -- 	local total = vim.api.nvim_buf_line_count(buf)
      --
      -- 	-- We want the line *after* the fence.
      -- 	local target = erow + 1
      -- 	if target >= total then
      -- 		-- We're at EOF; append a new blank line and update total.
      -- 		vim.api.nvim_buf_set_lines(buf, total, total, false, { "" })
      -- 		total = total + 1
      -- 	end
      -- 	-- Cursor is 1-based in win_set_cursor.
      -- 	vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
      -- end

      local function ensure_blank_line_below_cursor()
        local buf = 0
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        local total = vim.api.nvim_buf_line_count(buf)

        -- Work on the next line (create it if missing).
        local next_row = math.min(row + 1, total)
        if next_row >= total then
          vim.api.nvim_buf_set_lines(buf, total, total, false, { "" })
        else
          local next_line = vim.api.nvim_buf_get_lines(buf, next_row, next_row + 1, false)[1] or ""
          if next_line ~= "" then
            vim.api.nvim_buf_set_lines(buf, next_row, next_row, false, { "" })
          end
        end
        vim.api.nvim_win_set_cursor(0, { next_row + 1, 0 })
      end

      local function expand_fence(lang)
        -- Defensive: some folks pass nil/empty accidentally.
        lang = tostring(lang or "text")

        local node = fence_ancestor()
        if node then
          move_after_fence(node)
        else
          ensure_blank_line_below_cursor()
        end

        -- VSCode-style snippet: $1 first tabstop, $0 final cursor
        -- Quarto prefers ```{python} style braces; keep your original format string.
        local ok, err = pcall(function()
          vim.snippet.expand(("```{%s}\n$1\n```\n$0"):format(lang))
        end)
        if not ok then
          vim.notify("Snippet expand failed: " .. tostring(err), vim.log.levels.WARN)
        end
      end

      -- ftplugin/quarto.lua

      -- Only treat <Esc> specially while cursor is inside a fenced code block?

      local function in_fenced_cell()
        local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = true })
        if not ok or not node then
          return false
        end
        while node do
          local t = node:type()
          if t == "fenced_code_block" or t == "indented_code_block" then
            return true
          end
          node = node:parent()
        end
        return false
      end

      -- Is a molten output window currently attached (visible in any window)?
      local function is_molten_output_window_attached()
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          local b = vim.api.nvim_win_get_buf(w)
          if vim.bo[b].filetype == "molten_output" then
            return true
          end
        end
        return false
      end

      -- Set up buffer-local keymaps for quarto files
      local function setup_quarto_keymaps()
        -- Only set these keymaps for quarto/qmd files
        if vim.bo.filetype == "quarto" or vim.bo.filetype == "qmd" then
          local opts = { buffer = true, silent = true }
          local runner = require("quarto.runner")

          -- Treesitter helpers and cell utilities are defined below; keymaps that depend on
          -- them are placed after their definitions to avoid forward references.

          -- Quarto/Molten integration keymaps
          vim.keymap.set({ "v", "n" }, "<S-Enter>", function()
            runner.run_cell()
          end, vim.tbl_extend("force", opts, { desc = "run cell" }))
          -- vim.keymap.set(
          -- 	"n",
          -- 	"<esc><esc>",
          -- 	":MoltenHideOutput<CR>",
          -- 	vim.tbl_extend("force", opts, { desc = "hide molten output" })
          -- )
          -- TODO: Above
          vim.keymap.set("n", "<S-K>", function()
            expand_fence("python")
            vim.notify("TODO: Above")
          end, vim.tbl_extend("force", opts, { desc = "run cell" }))
          -- TODO: Below
          vim.keymap.set("n", "<S-J>", function()
            expand_fence("python")
          end, vim.tbl_extend("force", opts, { desc = "run cell" }))
          vim.keymap.set("n", "<Esc>", function()
            if not in_fenced_cell() or not is_molten_output_window_attached() then
              return "<Esc>"
            end
            -- FIXME: This command is broken if I am outside the buffer
            -- report to molten or find workour. Basically I have to enter
            -- the output window to close it from there now.
            -- HACK: Molten has a crazy bug where MoltenEnterOutput
            -- _closes_ the window if called _without_ :noautocmd
            -- and MoltenHideOutput is a noop. this is on 4e1cc9
            return "<CMD>MoltenEnterOutput<CR>"
          end, {
            buffer = true,
            expr = true,
            noremap = true, -- ensures returned <Esc> is *not* remapped; default behavior runs
            silent = true,
            desc = "Molten: hide output if visible; else normal <Esc>",
          })
          pcall(vim.keymap.del, "n", "]c", { buffer = 0 })
          pcall(vim.keymap.del, "n", "[c", { buffer = 0 })
          vim.keymap.set("n", "]c", function()
            local move = require("nvim-treesitter.textobjects.move")
            move.goto_next("@fenced_code_block")
          end, { buffer = true, desc = "Next code cell (content start)" })
          vim.keymap.set("n", "[c", function()
            local move = require("nvim-treesitter.textobjects.move")
            move.goto_previous("@fenced_code_block")
          end, { buffer = true, desc = "Next code cell (content start)" })

          vim.keymap.set("n", "<S-Up>", function()
            print("UHHHH")
            local move = require("nvim-treesitter.textobjects.move")
            move.goto_previous("@fenced_code_block")
          end, { buffer = true, desc = "Previous code cell (content start)" })

          -- From the Molten docs doubling enter will enter the the output
          -- which is what we want, requires this variable to be set though.
          -- | `g:molten_enter_output_behavior`
          -- | ("open_then_enter") | "open_and_enter" | "no_open" |
          -- The behavior of MoltenEnterOutput is used later after helpers are defined.

          -- Additional useful keymaps for Quarto files
          -- vim.keymap.set("n", "<leader>qr", function()
          -- 	runner.run_all()
          -- end, vim.tbl_extend("force", opts, { desc = "run all cells" }))
          -- vim.keymap.set("n", "<leader>qa", function()
          -- 	runner.run_above()
          --
          -- end, vim.tbl_extend("force", opts, { desc = "run cells above" }))
          -- Make the "quarto" filetype use the markdown parser (no-op if already done)
          pcall(vim.treesitter.language.register, "markdown", "quarto")

          -- Query the host (markdown) tree for code blocks
          local CELL_QUERY = vim.treesitter.query.parse(
            "markdown",
            [[
  (fenced_code_block) @cell
  (indented_code_block) @cell
]]
          )

          -- Utilities ---------------------------------------------------------------

          local function get_parser(bufnr)
            bufnr = bufnr or 0
            local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "markdown")
            if not ok then
              ok, parser = pcall(vim.treesitter.get_parser, bufnr)
            end
            return ok and parser or nil
          end

          local function get_node_text(node, bufnr)
            return vim.treesitter.get_node_text(node, bufnr or 0)
          end

          -- Extract content range and language/meta for fenced blocks
          local function fenced_content_rows(node, bufnr)
            local cs, ce
            local info
            for i = 0, node:child_count() - 1 do
              local ch = node:child(i)
              local t = ch:type()
              if t == "code_fence_content" then
                local srow, _, erow, _ = ch:range() -- erow exclusive
                cs, ce = srow, erow
              elseif t == "info_string" then
                info = get_node_text(ch, bufnr)
              end
            end
            -- Parse language token from info string: accepts "{python}" or "python opts"
            local lang
            if info then
              info = info:gsub("^%s+", ""):gsub("%s+$", "")
              local inside = info:match("^%{(.-)%}") or info:match("^%{(.-)$")
              local head = inside or info
              lang = head:match("^([%w_%.%-]+)") -- conservative first token
            end
            return cs, ce, lang, info
          end

          -- Build a list of all cells with computed IDs and metadata
          local function collect_cells(bufnr)
            bufnr = bufnr or 0
            local parser = get_parser(bufnr)
            if not parser then
              return {}
            end
            local tree = parser:parse()[1]
            if not tree then
              return {}
            end
            local root = tree:root()

            local cells = {}
            for _, node in CELL_QUERY:iter_captures(root, bufnr, 0, -1) do
              local srow, _, erow, _ = node:range() -- erow exclusive
              local kind = node:type()
              local cs, ce, lang, info

              if kind == "fenced_code_block" then
                cs, ce, lang, info = fenced_content_rows(node, bufnr)
                -- empty fences: content is effectively between the fences if present
                if not cs or not ce or ce <= cs then
                  cs = math.min(srow + 1, erow - 1)
                  ce = cs
                end
              else
                -- indented code block: content is whole node
                cs, ce = srow, erow
              end

              cells[#cells + 1] = {
                node = node,
                bufnr = bufnr,
                kind = kind,
                srow = srow,
                erow = erow,
                cs = cs,
                ce = ce, -- content [cs, ce)
                lang = lang,
                info = info,
              }
            end

            table.sort(cells, function(a, b)
              return a.srow < b.srow
            end)
            -- Assign 1..N IDs in buffer order
            for i, c in ipairs(cells) do
              c.id = i
            end
            return cells
          end

          local function idx_next(cells, cur_row)
            for i, c in ipairs(cells) do
              if c.srow > cur_row then
                return i
              end
            end
          end

          local function idx_prev(cells, cur_row)
            -- 1) If cursor is INSIDE cell j, jump to j-1
            for j = 1, #cells do
              local c = cells[j]
              if c.srow <= cur_row and cur_row < c.erow then
                return (j > 1) and (j - 1) or nil
              end
            end
            -- 2) Cursor is BETWEEN cells: pick the last start < cur_row
            local last
            for i, c in ipairs(cells) do
              if c.srow < cur_row then
                last = i
              else
                break
              end
            end
            return last
          end

          -- Choose target row: "middle" (default), "inside" (first content line), or "start" (fence)
          local function target_row_for_cell(cell, where)
            where = where or "middle"
            if where == "start" then
              return cell.srow
            end
            -- For both fenced & indented, we have content bounds [cs, ce)
            local cs, ce = cell.cs, cell.ce
            if not cs or not ce then
              return cell.srow
            end
            if where == "inside" then
              return cs
            end
            if where == "end" then
              return ce - 1
            end
            -- middle of content region; ce is exclusive, so last content row is ce-1
            local last = math.max(cs, ce - 1)
            return math.floor((cs + last) / 2)
          end

          local function goto_cell(cell, where)
            if not cell then
              return
            end
            local row = math.max(0, target_row_for_cell(cell, where))
            vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
          end

          -- Echo quick info like: Cell [3/10] python (12 lines)
          local function echo_cell_info(cell, total)
            if not cell then
              return
            end
            local lines = math.max(0, (cell.ce or cell.erow) - (cell.cs or cell.srow))
            local lang = cell.lang or "?"
            vim.notify(
              string.format(
                "Cell [%d/%d] %s • %d line%s",
                cell.id,
                total or cell.id,
                lang,
                lines,
                lines == 1 and "" or "s"
              ),
              vim.log.levels.INFO,
              { title = "Quarto cells" }
            )
          end

          -- Public jump (wraps around by default)
          local function jump_cell(direction, opts)
            opts = opts or {}
            local where = opts.where or "middle"
            local wrap = opts.wrap ~= false

            local row = vim.api.nvim_win_get_cursor(0)[1] - 1
            local cells = collect_cells(0)
            if #cells == 0 then
              vim.notify("No code fences found", vim.log.levels.INFO, { title = "Quarto cells" })
              return
            end

            local idx = (direction == "next") and idx_next(cells, row) or idx_prev(cells, row)
            if not idx and wrap then
              idx = (direction == "next") and 1 or #cells
            end
            if not idx then
              vim.notify("No " .. direction .. " cell", vim.log.levels.INFO, { title = "Quarto cells" })
              return
            end
            local cell = cells[idx]
            goto_cell(cell, where)
            -- For debugging
            -- echo_cell_info(cell, #cells)
          end

          -- Mappings (buffer-local) -------------------------------------------------

          -- Prefer landing at the MIDDLE of content
          vim.keymap.set("n", "[c", function()
            jump_cell("prev", { where = "middle", wrap = true })
          end, { buffer = true, desc = "Previous code cell (middle of content)" })
          vim.keymap.set("n", "[[", function()
            jump_cell("prev", { where = "end", wrap = true })
          end, { buffer = true, desc = "Previous code cell (middle of content)" })

          vim.keymap.set("n", "]c", function()
            jump_cell("next", { where = "middle", wrap = true })
          end, { buffer = true, desc = "Next code cell (middle of content)" })
          vim.keymap.set("n", "]]", function()
            jump_cell("next", { where = "end", wrap = true })
          end, { buffer = true, desc = "Next code cell (middle of content)" })

          -- -- (Optional) Variants that land on first content line or fence line:
          -- vim.keymap.set("n", "]C", function()
          --   jump_cell("next", { where = "inside", wrap = true })
          -- end, { buffer = true, desc = "Next code cell (first content line)" })
          --
          -- vim.keymap.set("n", "[C", function()
          --   jump_cell("prev", { where = "inside", wrap = true })
          -- end, { buffer = true, desc = "Previous code cell (first content line)" })

          -- (Optional) Show the current cell's id/lang/size without moving
          vim.keymap.set("n", "g?c", function()
            local row = vim.api.nvim_win_get_cursor(0)[1] - 1
            local cells = collect_cells(0)
            for i = #cells, 1, -1 do
              if cells[i].srow <= row and row < cells[i].erow then
                echo_cell_info(cells[i], #cells)
                return
              end
            end
            vim.notify("Cursor is not in a code cell", vim.log.levels.INFO, { title = "Quarto cells" })
          end, { buffer = true, desc = "Current cell info" }) --

          -- Locate molten output window in current tabpage
          local function current_tab_molten_win()
            local curtab = vim.api.nvim_get_current_tabpage()
            for _, w in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_get_tabpage(w) == curtab then
                local b = vim.api.nvim_win_get_buf(w)
                if vim.bo[b].filetype == "molten_output" then
                  return w
                end
              end
            end
          end

          -- Compute the screen row of the bottom of a window (approximate)
          local function molten_output_bottom_on_screen(winid)
            if not winid then
              return nil
            end
            local pos = vim.fn.win_screenpos(winid)
            local top = type(pos) == "table" and pos[1] or nil
            if not top or top <= 0 then
              return nil
            end
            local h = vim.fn.winheight(winid)
            return top + math.max(0, h - 1)
          end

          -- Enter behavior: smart-scroll around Molten output
          vim.keymap.set("n", "<Enter>", function()
            if not in_fenced_cell() then
              return "<Enter>"
            end
            -- Helper: find current cell and its bottom line (0/1-based)
            local function current_cell_and_bottom()
              local row0 = vim.api.nvim_win_get_cursor(0)[1] - 1
              local cells = collect_cells(0)
              local cell
              for i = #cells, 1, -1 do
                local c = cells[i]
                if c.srow <= row0 and row0 < c.erow then
                  cell = c
                  break
                end
              end
              if not cell then
                return nil
              end
              local bottom0 = (cell.ce and (cell.ce - 1)) or (cell.erow - 1)
              if bottom0 < cell.srow then
                bottom0 = cell.srow
              end
              return cell, bottom0, bottom0 + 1
            end

            local output_visible = is_molten_output_window_attached()
            if vim.bo.filetype == "molten_output" then
              print("HOUSTON WE HAVE A PROBLEM, WHY ARE WE IN THE OUTPUT??")
            end

            if not output_visible then
              -- Case A: Output not visible; move to cell bottom ONLY if it's not in view, then open.
              local _, _, bottom1 = current_cell_and_bottom()
              if bottom1 then
                local top1 = vim.fn.line("w0")
                local bot1 = vim.fn.line("w$")
                local in_view = (top1 <= bottom1) and (bottom1 <= bot1)
                if not in_view then
                  return string.format("<Cmd>%d<CR><Cmd>noautocmd MoltenEnterOutput<CR>", bottom1)
                end
              end
              return "<Cmd>noautocmd MoltenEnterOutput<CR>"
            else
              return "<Cmd>noautocmd MoltenEnterOutput<CR>"
            end
          end, {
            buffer = true,
            expr = true,
            silent = true,
            desc = "Molten: open/enter output with viewport smart-scroll",
          })
          local scheduled = false

          -- Trigger on insert changes (after a character is inserted).
          -- Only act if we're in a fenced cell and an output window is visible.
          vim.api.nvim_create_autocmd({ "InsertEnter" }, {
            buffer = 0,
            callback = function()
              -- Only hide if we're actually in a code cell and an output window is visible.
              if scheduled or not in_fenced_cell() or not is_molten_output_window_attached() then
                return
              end
              -- Call immediately; no scheduling.
              vim.schedule(function()
                vim.cmd("MoltenEnterOutput")
                scheduled = false
              end)
              scheduled = true
            end,
          })
        end
      end

      -- Set up autocommand to apply keymaps to quarto buffers
      vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = { "quarto", "qmd" }, -- Only for actual quarto files, not general markdown
        callback = function()
          setup_quarto_keymaps()
          vim.opt_local.conceallevel = 0
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "molten_output",
        callback = function()
          vim.keymap.set("n", "q", "<cmd>MoltenHideOutput<cr>", { buffer = true })
          vim.keymap.set("n", "<Esc>", "<cmd>MoltenHideOutput<cr>", { buffer = true })
          vim.keymap.set("n", "<Enter>", "<cmd>MoltenHideOutput<cr>", { buffer = true, silent = true })
          -- or whatever key/command you prefer
        end,
      })
    end,
  },
  {
    "benlubas/molten-nvim",
    --version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
    dependencies = {
      {
        "folke/snacks.nvim",
      },
      --   {
      --     "3rd/image.nvim",
      --     build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
      --     config = function(_, opts)
      --       local eops = {
      --         processor = "magick_cli",
      --         backend = "kitty", -- Kitty will provide the best experience, but you need a compatible terminal
      --         integrations = {}, -- do whatever you want with image.nvim's integrations
      --         max_width = 100, -- tweak to preference
      --         max_height = 12, -- ^
      --         max_height_window_percentage = math.huge, -- this is necessary for a good experience
      --         max_width_window_percentage = math.huge,
      --         window_overlap_clear_enabled = true,
      --         window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
      --       }
      --     end,
      --   },
      -- },
    },
    build = ":UpdateRemotePlugins",
    init = function()
      -- these are examples, not defaults. Please see the readme
      vim.g.molten_image_provider = "snacks.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
      -- See our comment in quarto plugin spec
      vim.g.molten_enter_output_behavior = "open_then_enter"
      --- See if this helps with the focusing ???
      vim.g.molten_output_virt_lines = true
      -- vim.g.molten_output_win_zindex = 1 -- I want lsp to cover it
      -- vim.g.molten_tick_rate = 500 -- be careful with this
      -- shows the number of extra lines in the buffer  if any
      -- vim.g.molten_output_show_more = true
    end,
  },
}
