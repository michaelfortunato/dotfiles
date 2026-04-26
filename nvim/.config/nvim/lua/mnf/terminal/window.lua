local M = {}

local function size(value, total, fallback)
  value = type(value) == "number" and value or fallback
  if value > 0 and value < 1 then
    return math.max(1, math.floor(total * value))
  end
  return math.max(1, math.floor(value))
end

local function apply_wo(win, wo)
  for name, value in pairs(wo or {}) do
    pcall(function()
      vim.wo[win][name] = value
    end)
  end
end

local function collect_row_leaves(node, leaves)
  if node[1] == "leaf" then
    leaves[#leaves + 1] = node[2]
    return true
  end
  if node[1] ~= "row" then
    return false
  end
  for _, child in ipairs(node[2]) do
    if not collect_row_leaves(child, leaves) then
      return false
    end
  end
  return true
end

local function row_leaves()
  local leaves = {}
  if not collect_row_leaves(vim.fn.winlayout(), leaves) then
    return nil
  end
  return leaves
end

local function count_position(wins, position)
  local count = 0
  for _, win in ipairs(wins) do
    local ok, win_position = pcall(vim.api.nvim_win_get_var, win, "mnf_native_position")
    if ok and win_position == position then
      count = count + 1
    end
  end
  return count
end

function M.equalize(position)
  if position ~= "left" and position ~= "right" then
    return
  end

  local wins = row_leaves()
  if not wins or #wins < 3 then
    return
  end
  if count_position(wins, position) < 2 then
    return
  end

  local total = 0
  for _, win in ipairs(wins) do
    total = total + vim.api.nvim_win_get_width(win)
  end
  local each = math.max(1, math.floor(total / #wins))
  for _, win in ipairs(wins) do
    vim.api.nvim_win_call(win, function()
      vim.cmd(("vertical resize %d"):format(each))
    end)
  end
end

function M.mark(win, position)
  vim.w[win].mnf_native_position = position
  M.equalize(position)
end

function M.open(buf, opts)
  opts = opts or {}
  local position = opts.position or "float"
  local enter = opts.enter ~= false
  local win

  if position == "float" then
    local width = size(opts.width, vim.o.columns, 0.9)
    local height = size(opts.height, vim.o.lines, 0.9)
    win = vim.api.nvim_open_win(buf, enter, {
      relative = opts.relative or "editor",
      width = width,
      height = height,
      row = opts.row or math.floor((vim.o.lines - height) / 2),
      col = opts.col or math.floor((vim.o.columns - width) / 2),
      style = opts.style == "minimal" and "minimal" or nil,
      border = opts.border,
      title = opts.title,
      title_pos = opts.title_pos,
      noautocmd = opts.noautocmd,
      zindex = opts.zindex,
    })
  elseif position == "current" then
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  else
    local vertical = position == "left" or position == "right"
    local parent = opts.win and vim.api.nvim_win_is_valid(opts.win) and opts.win or 0
    win = vim.api.nvim_win_call(parent, function()
      local config = {
        split = ({
          left = "left",
          right = "right",
          top = "above",
          bottom = "below",
        })[position] or "below",
      }
      if vertical then
        config.width = size(opts.width, vim.api.nvim_win_get_width(0), 0.45)
      else
        config.height = size(opts.height, vim.api.nvim_win_get_height(0), 0.4)
      end
      return vim.api.nvim_open_win(buf, enter, config)
    end)
    if enter then
      vim.api.nvim_set_current_win(win)
    end
    if vertical then
      vim.wo[win].winfixwidth = true
    else
      vim.wo[win].winfixheight = true
    end
  end

  M.mark(win, position)
  apply_wo(win, opts.wo)
  return win
end

return M
