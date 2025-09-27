-- For quick fixes and such
--
return {
  ---@type LazyPluginSpec
  {
    ---@module "trouble"
    "folke/trouble.nvim",
    ---@type trouble.Config
    opts = {
      focus = false,
      win = { type = "split", position = "bottom", size = 18 },
    },

    keys = {
      { "<leader>aa", "<Cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (Buffer)" },
      { "<leader>aA", "<Cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Workspace)" },
      {
        "<C-S-[>",
        function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Previous Trouble/Quickfix Item",
      },
      {
        "<C-S-]>",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Next Trouble/Quickfix Item",
      },
    },
  },
}
