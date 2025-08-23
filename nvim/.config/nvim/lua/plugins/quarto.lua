return {
  {
    "quarto-dev/quarto-nvim",
    dependencies = { "jmbuhr/otter.nvim", "nvim-treesitter/nvim-treesitter", "benlubas/molten-nvim"
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
          ft_runners = {}, -- filetype to runner, ie. `{ python = "molten" }`.
          -- Takes precedence over `default_method`
          never_run = { "yaml" }, -- filetypes which are never sent to a code runner
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

      -- Set up buffer-local keymaps for quarto files
      local function setup_quarto_keymaps()
        -- Only set these keymaps for quarto/qmd files
        if vim.bo.filetype == "quarto" or vim.bo.filetype == "qmd" then
          local opts = { buffer = true, silent = true }
          local runner = require("quarto.runner")

          -- Quarto/Molten integration keymaps
          vim.keymap.set("n", "<S-Enter>", function()
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
          end, vim.tbl_extend("force", opts, { desc = "run cell" }))
          -- TODO: Below
          vim.keymap.set("n", "<S-J>", function()
            expand_fence("python")
          end, vim.tbl_extend("force", opts, { desc = "run cell" }))

          vim.keymap.set("n", "<Leader-j>", function()
            expand_fence("python")
          end, vim.tbl_extend("force", opts, { desc = "run cell" }))
          -- TODO: Below
          vim.keymap.set(
            "v",
            "<S-Enter>",
            runner.run_range,
            vim.tbl_extend("force", opts, { desc = "evaluate visual selection" })
          )

          -- Additional useful keymaps for Quarto files
          -- vim.keymap.set("n", "<leader>qr", function()
          -- 	runner.run_all()
          -- end, vim.tbl_extend("force", opts, { desc = "run all cells" }))
          -- vim.keymap.set("n", "<leader>qa", function()
          -- 	runner.run_above()
          -- end, vim.tbl_extend("force", opts, { desc = "run cells above" }))
        end
      end

      -- Set up autocommand to apply keymaps to quarto buffers
      vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = { "quarto", "qmd" }, -- Only for actual quarto files, not general markdown
        callback = function(ev)
          setup_quarto_keymaps()
          vim.opt_local.conceallevel = 0
        end,
      })
    end,
  },
  {
    "benlubas/molten-nvim",
    version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
    dependencies = {
      {
        "3rd/image.nvim",
        build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
        config = function(_, opts)
          local eops = {
            processor = "magick_cli",
            backend = "kitty", -- Kitty will provide the best experience, but you need a compatible terminal
            integrations = {}, -- do whatever you want with image.nvim's integrations
            max_width = 100, -- tweak to preference
            max_height = 12, -- ^
            max_height_window_percentage = math.huge, -- this is necessary for a good experience
            max_width_window_percentage = math.huge,
            window_overlap_clear_enabled = true,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
          }
        end,
      },
    },
    build = ":UpdateRemotePlugins",
    init = function()
      -- these are examples, not defaults. Please see the readme
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
    end,
  },
}
