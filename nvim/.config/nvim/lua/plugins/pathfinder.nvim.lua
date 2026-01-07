--- Better gf and gF
return {
  "HawkinsT/pathfinder.nvim",
  config = function()
    require("pathfinder").setup({ remap_default_keys = false })
    vim.keymap.set("n", "gf", require("pathfinder").gf)
    vim.keymap.set("n", "gF", require("pathfinder").gF)
    -- (optional) vim.keymap.set("n", "gx", require("pathfinder").gx)
  end,
}
