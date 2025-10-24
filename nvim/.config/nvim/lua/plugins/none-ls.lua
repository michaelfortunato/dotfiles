--- In process language server, quite useful
--- Written by codex resume 019a17c8-0188-7850-81ed-46e9650b15a5
return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    -- Make nvim-lspconfig ensures that null-ls code actions go
    -- beneath everything else, which is what I want.
    -- https://github.com/neovim/neovim/issues/22776
    "neovim/nvim-lspconfig",
    "nvim-lua/plenary.nvim",
    {
      "danymat/neogen",
      enabled = true,
      -- Neogen requires explicit call to its setup(), hence the call to opts
      opts = {
        enabled = true,
      },
    },
  },
  config = function()
    local null_ls = require("null-ls")

    local function has_pyrefly_word(value)
      return type(value) == "string" and value:lower():find("pyrefly", 1, true)
    end

    local function is_pyrefly_diagnostic(diagnostic)
      if type(diagnostic) ~= "table" then
        return false
      end
      if has_pyrefly_word(diagnostic.source) then
        return true
      end
      local user_data = diagnostic.user_data
      if type(user_data) == "table" and type(user_data.lsp) == "table" then
        if has_pyrefly_word(user_data.lsp.name) then
          return true
        end
        if user_data.lsp.client and has_pyrefly_word(user_data.lsp.client.name) then
          return true
        end
        if user_data.lsp.client_id then
          local client = vim.lsp.get_client_by_id(user_data.lsp.client_id)
          if client and has_pyrefly_word(client.name) then
            return true
          end
        end
      end
      local client_id = diagnostic.client_id
      if client_id then
        local client = vim.lsp.get_client_by_id(client_id)
        if client and has_pyrefly_word(client.name) then
          return true
        end
      end
      return false
    end

    local function extract_pyrefly_code(diagnostic)
      if type(diagnostic) ~= "table" then
        return nil
      end
      local function pick(value)
        if type(value) == "string" and value ~= "" then
          return value
        end
        return nil
      end

      local code = pick(diagnostic.code)
      if not code and type(diagnostic.code) == "table" then
        code = pick(diagnostic.code.value) or pick(diagnostic.code.code)
      end
      if not code and type(diagnostic.user_data) == "table" and type(diagnostic.user_data.lsp) == "table" then
        local lsp_data = diagnostic.user_data.lsp
        code = pick(lsp_data.code)
          or (type(lsp_data.data) == "table" and (pick(lsp_data.data.code) or pick(lsp_data.data.value)))
      end
      if not code and type(diagnostic.message) == "string" then
        code = diagnostic.message:match("%[(%w[%w_-]*)%]") or diagnostic.message:match("([A-Z]+[%w_-]+)")
      end
      return code
    end

    local function normalize_row(row, is_zero_based)
      if type(row) ~= "number" then
        return nil
      end
      if is_zero_based or row < 1 then
        row = row + 1
      end
      row = math.floor(row)
      if row < 1 then
        return nil
      end
      return row
    end

    local function get_target_row(params)
      local function from_range(range)
        if type(range) ~= "table" then
          return nil
        end
        local start = range.start or range["start"]
        if type(start) ~= "table" then
          return nil
        end
        if type(start.line) == "number" then
          return normalize_row(start.line, true)
        end
        if type(start.row) == "number" then
          return normalize_row(start.row, start.row <= 0)
        end
        if type(start[1]) == "number" then
          return normalize_row(start[1], true)
        end
        return nil
      end

      local row = from_range(params and params.range)
      if not row and params and params.context and params.context.params then
        row = from_range(params.context.params.range)
      end
      if not row and params then
        row = normalize_row(params.row, false) or normalize_row(params.lnum, false) or normalize_row(params.line, false)
      end
      if not row then
        local ok, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
        if ok and type(cursor) == "table" and type(cursor[1]) == "number" then
          row = normalize_row(cursor[1], false)
        end
      end
      return row
    end

    local function insert_pyrefly_ignore(bufnr, row, code)
      if type(bufnr) ~= "number" or type(row) ~= "number" or type(code) ~= "string" then
        return
      end

      local current_line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
      local indent = current_line:match("^%s*") or ""
      local comment_line = indent .. string.format("# pyrefly: ignore[%s]", code)

      local previous_index = row - 2
      if previous_index >= 0 then
        local existing = vim.api.nvim_buf_get_lines(bufnr, previous_index, previous_index + 1, false)[1]
        if existing then
          local prefix, code_list = existing:match("^(%s*#pyrefly: ignore%[)(.*)%]%s*$")
          if prefix then
            local trimmed = vim.trim(code_list or "")
            local codes = {}
            if trimmed ~= "" then
              for entry in trimmed:gmatch("([^,%s]+)") do
                codes[#codes + 1] = entry
              end
            end
            for _, entry in ipairs(codes) do
              if entry == code then
                return
              end
            end
            codes[#codes + 1] = code
            local new_comment = prefix .. table.concat(codes, ", ") .. "]"
            vim.api.nvim_buf_set_lines(bufnr, previous_index, previous_index + 1, false, { new_comment })
            return
          elseif existing:find("#pyrefly: ignore%[.+%]") then
            return
          end
        end
      end

      vim.api.nvim_buf_set_lines(bufnr, row - 1, row - 1, false, { comment_line })
    end

    local function pyrefly_codes_for_line(bufnr, row)
      if type(bufnr) ~= "number" or type(row) ~= "number" then
        return {}
      end
      local diagnostics = vim.diagnostic.get(bufnr, { lnum = row - 1 }) or {}
      local seen = {}
      local codes = {}
      for _, diagnostic in ipairs(diagnostics) do
        if is_pyrefly_diagnostic(diagnostic) then
          local code = extract_pyrefly_code(diagnostic)
          if code and not seen[code] then
            seen[code] = true
            table.insert(codes, code)
          end
        end
      end
      return codes
    end

    null_ls.setup({
      sources = {
        -- NeoGen Code Action
        {
          name = "neogen", -- Custom name instead of "null-ls"
          method = null_ls.methods.CODE_ACTION,
          filetypes = { "lua", "python", "javascript", "typescript", "go", "rust", "java", "c", "cpp" },
          generator = {
            fn = function(params)
              return {
                {
                  title = "Generate Documentation",
                  action = function()
                    require("neogen").generate()
                  end,
                },
              }
            end,
          },
        },
        {
          name = "pyrefly_ignore",
          method = null_ls.methods.CODE_ACTION,
          filetypes = { "python" },
          generator = {
            fn = function(params)
              local row = get_target_row(params)
              if not row then
                return nil
              end

              local codes = pyrefly_codes_for_line(params.bufnr, row)
              if #codes == 0 then
                return nil
              end

              local actions = {}
              for _, code in ipairs(codes) do
                table.insert(actions, {
                  title = string.format("Ignore pyrefly error [%s] on this line", code),
                  action = function()
                    insert_pyrefly_ignore(params.bufnr, row, code)
                  end,
                })
              end

              return actions
            end,
          },
        },
      },
    })
  end,
}
