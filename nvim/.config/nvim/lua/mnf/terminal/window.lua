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

local function native_position(win)
  local ok, position = pcall(vim.api.nvim_win_get_var, win, "mnf_native_position")
  return ok and position or nil
end

local function find_position_win(position)
  local wins = vim.api.nvim_tabpage_list_wins(0)
  for i = #wins, 1, -1 do
    local win = wins[i]
    if native_position(win) == position then
      return win
    end
  end
end

local function equalize_position(position)
  local wins = vim.tbl_filter(function(win)
    return native_position(win) == position
  end, vim.api.nvim_tabpage_list_wins(0))
  if #wins <= 1 then
    return
  end
  local vertical = position == "left" or position == "right"
  local total = 0
  for _, win in ipairs(wins) do
    total = total + (vertical and vim.api.nvim_win_get_height(win) or vim.api.nvim_win_get_width(win))
  end
  local each = math.max(1, math.floor(total / #wins))
  for _, win in ipairs(wins) do
    vim.api.nvim_win_call(win, function()
      vim.cmd(("%sresize %d"):format(vertical and "horizontal " or "vertical ", each))
    end)
  end
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
    local stack_parent = vertical and opts.stack ~= false and find_position_win(position) or nil
    local parent = stack_parent or (opts.win and vim.api.nvim_win_is_valid(opts.win) and opts.win or 0)
    win = vim.api.nvim_win_call(parent, function()
      local config = {
        split = stack_parent and "below"
          or ({
            left = "left",
            right = "right",
            top = "above",
            bottom = "below",
          })[position]
          or "below",
      }
      if stack_parent then
        config.height = size(opts.height, vim.api.nvim_win_get_height(0), 0.5)
      elseif vertical then
        config.width = size(opts.width, vim.api.nvim_win_get_width(0), 0.4)
      else
        config.height = size(opts.height, vim.api.nvim_win_get_height(0), 0.4)
      end
      return vim.api.nvim_open_win(buf, enter, config)
    end)
    if vertical then
      vim.wo[win].winfixwidth = true
    else
      vim.wo[win].winfixheight = true
    end
  end

  vim.w[win].mnf_native_position = position
  apply_wo(win, opts.wo)
  equalize_position(position)
  return win
end

return M
