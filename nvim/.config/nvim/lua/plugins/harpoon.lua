return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  },
  keys = function()
    --TODO: Don't hardpoon with <leader>H but insteead do <C-1> etc.
    --
    local keys = {
      {
        "<leader>H",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon File",
      },
      {
        "<leader>h",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon Quick Menu",
      },
    }

    for i = 1, 5 do
      table.insert(keys, {
        "<leader>" .. i,
        function()
          require("harpoon"):list():select(i)
        end,
        -- NOTE: Special value tells which-key not to show this guy
        desc = "which_key_ignore",
      })
      table.insert(keys, {
        "<A-" .. i .. ">",
        function()
          local items = require("harpoon"):list()
          if i > items:length() then
            items:replace_at(i)
          else
            local old_item = items[i]
            if old_item ~= nil then
              items:append(old_item)
              items:replace_at(i)
            else
              items:replace_at(i)
            end
          end
          vim.notify("Harpoon: Pinned buffer to slot" .. i, vim.log.levels.INFO)
        end,
        -- NOTE: Special value tells which-key not to show this guy
        desc = "which_key_ignore",
      })
    end
    return keys
  end,
}
