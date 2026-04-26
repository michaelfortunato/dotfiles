-- return {}
local agentic_inline_open_keymaps = {
  {
    "<C-Space>",
    mode = { "x" },
  },
}

local agentic_chat_selection_keymaps = {
  {
    "<C-S-Space>",
    mode = { "x" },
  },
}

local function build_agentic_inline_lazy_keys()
  local keys = {}

  for _, keymap in ipairs(agentic_inline_open_keymaps) do
    keys[#keys + 1] = {
      keymap[1],
      function()
        require("agentic").inline_chat()
      end,
      mode = keymap.mode or { "n" },
      desc = "Open Agentic Inline Chat",
    }
  end

  return keys
end

local function get_visual_selection_text()
  local mode = vim.fn.mode()

  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end

  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local visual_mode = vim.fn.visualmode()
  local lines = vim.fn.getregion(start_pos, end_pos, { type = visual_mode })

  if type(lines) ~= "table" or vim.tbl_isempty(lines) then
    return nil
  end

  return table.concat(lines, "\n")
end

local function open_agentic_chat_with_visual_selection()
  local prompt_text = get_visual_selection_text()

  require("agentic.utils.buf_helpers").feed_ESC_key()

  require("agentic").toggle({
    auto_add_to_context = false,
    focus_prompt = true,
    prompt_text = prompt_text,
  })
end

local function build_agentic_chat_selection_lazy_keys()
  local keys = {}

  for _, keymap in ipairs(agentic_chat_selection_keymaps) do
    keys[#keys + 1] = {
      keymap[1],
      open_agentic_chat_with_visual_selection,
      mode = keymap.mode or { "n" },
      desc = "Open Agentic Chat with Selection",
    }
  end

  return keys
end

local function set_agentic_highlights()
  local set_hl = vim.api.nvim_set_hl

  -- Reuse built-in diff, diagnostic, and UI highlight groups for Agentic's
  -- diff preview, task status, code fences, titles, and spinner states.
  set_hl(0, "AgenticDiffDelete", { link = "DiffDelete" })
  set_hl(0, "AgenticDiffAdd", { link = "DiffAdd" })
  set_hl(0, "AgenticDiffDeleteWord", { link = "DiffDelete" })
  set_hl(0, "AgenticDiffAddWord", { link = "DiffAdd" })

  set_hl(0, "AgenticStatusPending", { link = "DiagnosticWarn" })
  set_hl(0, "AgenticStatusCompleted", { link = "DiagnosticOk" })
  set_hl(0, "AgenticStatusFailed", { link = "DiagnosticError" })
  set_hl(0, "AgenticCodeBlockFence", { link = "Comment" })
  set_hl(0, "AgenticTitle", { link = "FloatTitle" })

  set_hl(0, "AgenticSpinnerGenerating", { link = "Special" })
  set_hl(0, "AgenticSpinnerThinking", { link = "Type" })
  set_hl(0, "AgenticSpinnerSearching", { link = "Constant" })
  set_hl(0, "AgenticSpinnerBusy", { link = "Comment" })
end

local agentic_local_group = vim.api.nvim_create_augroup("AgenticLocalTweaks", { clear = true })

set_agentic_highlights()

vim.api.nvim_create_autocmd("ColorScheme", {
  group = agentic_local_group,
  callback = set_agentic_highlights,
})

vim.api.nvim_create_autocmd("FileType", {
  group = agentic_local_group,
  pattern = "AgenticInput",
  callback = function(ev)
    vim.keymap.set("i", "<Shift-CR>", "<CR>", {
      buffer = ev.buf,
      desc = "Agentic: Insert newline",
    })
    vim.keymap.set("i", ".,", function()
      require("agentic").toggle()
    end, {
      buffer = ev.buf,
      desc = "Agentic: Insert newline",
    })
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = agentic_local_group,
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "AgenticInput" then
      vim.cmd("startinsert!")
    end
  end,
})

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = function()
      return { "AgenticChat" }
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-mini/mini.nvim",
    },
    opts = function(_, opts)
      opts.enabled = true
      opts.file_types = { "AgenticChat" }
      opts.render_modes = true
      opts.anti_conceal = { enabled = false }
      opts.preset = "none"
      opts.heading = vim.tbl_deep_extend("force", opts.heading or {}, {
        enabled = false,
      })
      opts.bullet = vim.tbl_deep_extend("force", opts.bullet or {}, {
        enabled = false,
      })
      opts.checkbox = vim.tbl_deep_extend("force", opts.checkbox or {}, {
        enabled = false,
      })
      return opts
    end,
  },
  {
    "michaelfortunato/agentic.nvim",
    dev = true,
    dependencies = {
      "MeanderingProgrammer/render-markdown.nvim",
    },
    cmd = {
      "AgenticChat",
      "AgenticInline",
    },
    opts = {
      -- Any ACP-compatible provider works. Built-in: "claude-agent-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp" | "copilot-acp" | "auggie-acp" | "mistral-vibe-acp" | "cline-acp" | "goose-acp"
      provider = "codex-acp", -- setting the name here is all you need to get started

      keymaps = {
        prompt = {
          submit = {
            {
              "<CR>",
              mode = { "n", "i" },
            },
            {
              "<C-s>",
              mode = { "n", "v", "i" },
            },
          },
        },

        inline = {
          open = agentic_inline_open_keymaps,
        },

        diff_preview = {
          next_hunk = "]c",
          prev_hunk = "[c",
        },
      },

      windows = {
        width = "40%",
      },

      diff_preview = {
        enabled = true,
        layout = "interwoven",
        center_on_navigate_hunks = true,
      },
    },

    -- these are just suggested keymaps; customize as desired
    keys = function()
      local keys = {
        {
          "<C-/>",
          function()
            require("agentic").add_selection_or_file_to_context()
          end,
          mode = { "v" },
          desc = "Add file or selection to Agentic context",
        },
        {
          "<C-/>",
          function()
            require("agentic").toggle()
          end,
          mode = { "n" },
          desc = "Toggle Agentic Chat",
        },
      }

      vim.list_extend(keys, build_agentic_inline_lazy_keys())
      vim.list_extend(keys, build_agentic_chat_selection_lazy_keys())

      return keys
    end,
  },
}
