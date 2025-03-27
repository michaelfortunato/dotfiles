---@module "luasnip"
-- local ls = require("luasnip")
-- local s = ls.snippet
-- local sn = ls.snippet_node
-- local t = ls.text_node
-- local i = ls.insert_node
-- local f = ls.function_node
-- local d = ls.dynamic_node
-- local fmt = require("luasnip.extras.fmt").fmt
-- local fmta = require("luasnip.extras.fmt").fmta
-- local rep = require("luasnip.extras").rep
-- Anatomy of a LuaSnip snippet
-- require("luasnip").snippet(
--   snip_params:table,  -- table of snippet parameters
--   nodes:table,        -- table of snippet nodes
--   opts:table|nil      -- *optional* table of additional snippet options
-- )
-- return {
--   s(
--    { trig = "b[eb]", regTrig = true, snippetType = "autosnippet" },
--    fmta(
--      [[
--        \begin{<>}
--            <>
--        \end{<>}
--      ]],
--      {
--        i(1),
--        d(2, get_visual),
--        rep(1),
--      }
--    ),
--    { condition = line_begin }
--  ),
--
-- s({trig = "h1", dscr="Top-level section"},
--   fmta(
--     [[\section{<>}]],
--     { i(1) }
--   ),
--   {condition = line_begin}  -- set condition in the `opts` table
-- ),
--   { trig = "([^%a])l%(", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
--    fmta("<>\\left(<>\\right)", {
--      f(function(_, snip)
--        return snip.captures[1]
--      end),
--      d(1, get_visual),
--    })
--
-- }
---- Some LaTeX-specific conditional expansion functions (requires VimTeX)
--- local tex_utils = {}
--- tex_utils.in_mathzone = function()  -- math context detection
---   return vim.fn['vimtex#syntax#in_mathzone']() == 1
--- end
--- tex_utils.in_text = function()
---   return not tex_utils.in_mathzone()
--- end
--- tex_utils.in_comment = function()  -- comment detection
---   return vim.fn['vimtex#syntax#in_comment']() == 1
--- end
--- tex_utils.in_env = function(name)  -- generic environment detection
---     local is_inside = vim.fn['vimtex#env#is_inside'](name)
---     return (is_inside[1] > 0 and is_inside[2] > 0)
--- end
--- -- A few concrete environments---adapt as needed
--- tex_utils.in_equation = function()  -- equation environment detection
---     return tex_utils.in_env('equation')
--- end
--- tex_utils.in_itemize = function()  -- itemize environment detection
---     return tex_utils.in_env('itemize')
--- end
--- tex_utils.in_tikz = function()  -- TikZ picture environment detection
---     return tex_utils.in_env('tikzpicture')
--- end
--
--- FIXME: Delete this silliness
local PRIORITY = 10000

local get_visual = function(args, parent)
  if #parent.snippet.env.LS_SELECT_RAW > 0 then
    return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
  else -- If LS_SELECT_RAW is empty, return a blank insert node
    return sn(nil, i(1))
  end
end

local line_begin = require("luasnip.extras.expand_conditions").line_begin
-- NOTE: Not in use local line_end = require("luasnip.extras.expand_conditions").line_end
local cond_obj = require("luasnip.extras.conditions")

-----------------------
-- PRESET CONDITIONS --
-----------------------
--- The wordTrig flag will only expand the snippet if
--- the proceeding character is NOT %w or `_`.
--- This is quite useful. The only issue is that the characters
--- on which we negate on hard coded. See here for the actual implementation
--- https://github.com/L3MON4D3/LuaSnip/blob/c9b9a22904c97d0eb69ccb9bab76037838326817/lua/luasnip/nodes/snippet.lua#L827
---
--- As a result, authors willl turn their plain triggers into regexTrig=true
--- triggers and proceed their regex with a negated capture group.
--- The issue is that the capture group on which the pattern matched, although
--- its negated, still expands with the rest of the trigger.
--- So people have worked around that by doing inserting the capture group
--- back into the snippet
--- https://ejmastnak.com/tutorials/vim-latex/luasnip/#after-a
---
--- This is an issue because it can break LuaSnips understanding
--- of parent and child snippets, resulting in broken jump_next() etc.
--- For instance, consider
--- ```text
--- $mbb$
---    ^
--- Cursor is here
--- ```
--- Some latex snippet authors will have their snippet definition
--- for mbb look like s(trig="([^%w])mbb", t("\mathbb{}")
--- The problem is that this consume the leading `$~ character, and even if
--- the snippet re-inserts the `$` back, the parent snippet $$ will be broken.
---
--- I think the character wordTrig=true uses should be customized
--- A condtion seems like the best way to do it
---
--- @param pattern string valid lua pattern
local function make_trigger_does_not_follow_char(pattern)
  local condition = function(line_to_cursor, matched_trigger)
    local line_to_trigger_len = #line_to_cursor - #matched_trigger
    if line_to_trigger_len == 0 then
      return true
    end
    return not string.sub(line_to_cursor, line_to_trigger_len, line_to_trigger_len):match(pattern)
  end
  return cond_obj.make_condition(condition)
end

local ls = require("luasnip")
local trigger_does_not_follow_alpha_num_char = make_trigger_does_not_follow_char("%w")
local trigger_does_not_follow_alpha_char = make_trigger_does_not_follow_char("%a")

local MATH_NODES = {
  math = true,
  formula = true,
}

local TEXT_NODES = {
  text = true,
}

local CODE_NODES = {
  text = true,
  block = true,
}

local function in_textzone(check_parent)
  local node = vim.treesitter.get_node({ ignore_injections = false })
  while node do
    if node:type() == "text" then
      if check_parent then
        -- For \text{}
        local parent = node:parent()
        if parent and MATH_NODES[parent:type()] then
          return false
        end
      end

      return true
    elseif MATH_NODES[node:type()] then
      return false
    end
    node = node:parent()
  end
  return true
end

local STRING_NODES = {
  string_content = true,
  string_literal = true,
  raw_string_literal = true,
}

local COMMENT_NODES = {
  block_comment = true,
  line_comment = true,
}

local in_string = cond_obj.make_condition(function(check_parent)
  local node = vim.treesitter.get_node({ ignore_injections = false })
  local counter = 0
  while node do
    if STRING_NODES[node:type()] then
      return true
    elseif check_parent and counter < 5 then
      counter = counter + 1
      node = node:parent()
    else
      return false
    end
  end
end)

--- in_comment is one shot
local in_comment = cond_obj.make_condition(function(check_parent)
  local node = vim.treesitter.get_node({ ignore_injections = false })
  return node and COMMENT_NODES[node:type()]
end)

local iv = function(i, ...)
  return d(i, get_visual, ...)
end

return {
  s(
    { trig = "(", wordTrig = false, snippetType = "autosnippet" },
    fmta("(<>)<>", {
      iv(1),
      i(0),
    }),
    { condition = -in_string - in_comment }
  ),
  s(
    { trig = "{", wordTrig = false, snippetType = "autosnippet" },
    fmta("{<>}<>", {
      iv(1),
      i(0),
    }),
    { condition = -in_string - in_comment }
  ),
  s(
    { trig = "[", wordTrig = false, snippetType = "autosnippet" },
    fmta("[<>]<>", {
      iv(1),
      i(0),
    }),
    { condition = -in_string - in_comment }
  ),
  s(
    { trig = "/*", wordTrig = false, snippetType = "autosnippet" },
    fmta("/*<>*/<>", {
      iv(1),
      i(0),
    }),
    { condition = -in_string - in_comment }
  ),
  s({ trig = "struct", snippetType = "autosnippet" }, {
    t({ "#[derive(Debug)]", "" }),
    t({ "struct " }),
    i(1),
    t({ " {", "" }),
    i(0),
    t({ "}", "" }),
  }, { condition = line_begin }),
  s(
    { trig = "match", snippetType = "autosnippet" },
    fmta(
      [[
match <> {
  <> =>> <>,
  <> =>> <>,
};<>
]],
      { i(1), i(2), i(3), i(4), i(5), i(0) }
    ),
    { condition = -in_string - in_comment }
  ),
  s(
    { trig = "if", snippetType = "autosnippet" },
    fmta(
      [[
if <> {
  <>
};<>
]],
      { i(1), i(2), i(0) }
    ),
    { condition = -in_string - in_comment }
  ),
  s({ trig = "error", snippetType = "autosnippet" }, {
    fmta([[error!(<>)<>]], { iv(1), i(0) }),
  }, { condition = -in_string - in_comment }),
  s({ trig = "warn", snippetType = "autosnippet" }, {
    fmta([[warn!(<>)<>]], { iv(1), i(0) }),
  }, { condition = -in_string - in_comment }),
  s({ trig = "info", snippetType = "autosnippet" }, {
    fmta([[info!(<>)<>]], { iv(1), i(0) }),
  }, { condition = -in_string - in_comment }),
  s({ trig = "debug", snippetType = "autosnippet" }, {
    fmta([[debug!(<>)<>]], { iv(1), i(0) }),
  }, { condition = -in_string - in_comment }),
  s({ trig = "trace", snippetType = "autosnippet" }, {
    fmta([[error!(<>)<>]], { iv(1), i(0) }),
  }, { condition = -in_string - in_comment }),
}
