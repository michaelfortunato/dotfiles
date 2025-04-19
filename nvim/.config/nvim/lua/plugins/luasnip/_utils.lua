local M = {}

-- Be sure to explicitly define these LuaSnip node abbreviations!
local ls = require("luasnip")
local sn = ls.snippet_node
local i = ls.insert_node

function M.get_visual(args, parent)
  if #parent.snippet.env.LS_SELECT_RAW > 0 then
    return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
  else
    return sn(nil, i(1, ""))
  end
end

function M.char_count_same(c1, c2)
  local line = vim.api.nvim_get_current_line()
  -- '%'-escape chars to force explicit match (gsub accepts patterns).
  -- second return value is number of substitutions.
  local _, ct1 = string.gsub(line, "%" .. c1, "")
  local _, ct2 = string.gsub(line, "%" .. c2, "")
  return ct1 == ct2
end

function M.even_count(c)
  local line = vim.api.nvim_get_current_line()
  local _, ct = string.gsub(line, c, "")
  return ct % 2 == 0
end

function M.neg(fn, ...)
  return not fn(...)
end

function M.part(fn, ...)
  local args = { ... }
  return function()
    return fn(unpack(args))
  end
end

-- This makes creation of pair-type snippets easier.
function M.pair(pair_begin, pair_end, expand_func, ...)
  -- triggerd by opening part of pair, wordTrig=false to trigger anywhere.
  -- ... is used to pass any args following the expand_func to it.
  return s({ trig = pair_begin, wordTrig = false }, {
    t({ pair_begin }),
    i(1),
    t({ pair_end }),
  }, {
    condition = part(expand_func, part(..., pair_begin, pair_end)),
  })
end

return M
