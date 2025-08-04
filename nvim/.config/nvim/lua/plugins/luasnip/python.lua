---@diagnostic disable: undefined-global
---@module "luasnip"
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
--- FIXME: mnf_s is bullshit, and it fucking sucks!
--- local mnf_s = ls.extend_decorator.apply(s, { wordTrig = false, condition = trigger_does_not_follow_alpha_num_char })

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

local STRING_NODES = {
  string = true,
  string_content = true,
  string_start = true,
  string_end = true,
}

local COMMENT_NODES = {
  comment = true,
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

local function in_codezone()
  local node = vim.treesitter.get_node({ ignore_injections = false })
  while node do
    if CODE_NODES[node:type()] then
      return true
    elseif TEXT_NODES[node:type()] or MATH_NODES[node:type()] then
      return false
    end
    node = node:parent()
  end
  return false
end

local function in_mathzone()
  local node = vim.treesitter.get_node({ ignore_injections = false })
  while node do
    if MATH_NODES[node:type()] then
      return true
    elseif TEXT_NODES[node:type()] or CODE_NODES[node:type()] then
      return false
    end
    node = node:parent()
  end
  return false
end

local iv = function(i, ...)
  return d(i, get_visual, ...)
end

-- dynamic node generator
local generate_matchcase_dynamic = function(args, snip)
  if not snip.num_cases then
    snip.num_cases = tonumber(snip.captures[1]) or 1
  end
  local nodes = {}
  local ins_idx = 1
  for j = 1, snip.num_cases do
    vim.list_extend(
      nodes,
      fmta(
        [[
        case <>:
            <>
        ]],
        { r(ins_idx, "var" .. j, i(1)), r(ins_idx + 1, "next" .. j, i(0)) }
      )
    )
    table.insert(nodes, t({ "", "" }))
    ins_idx = ins_idx + 2
  end
  table.remove(nodes, #nodes) -- removes the extra line break
  return isn(nil, nodes, "\t")
end

return {
  -- idc if stylua doesn't like my code looking like this it's neat to me
  s(
    "trig",
    c(1, {
      t("Ugh boring, a text node"),
      i(nil, "At least I can edit something now..."),
      f(function(args)
        return "Still only counts as text!!"
      end, {}),
    })
  ),
  --   s(
  --     { trig = "if ", snippetType = "autosnippet" },
  --     fmta(
  --       [[
  -- if <>:
  --   <>
  -- <>]],
  --       { i(1), i(2), i(0) }
  --     ),
  --     { condition = -in_string - in_comment }
  --   ),
  -- s(
  --   { trig = "(", wordTrig = false, snippetType = "autosnippet" },
  --   fmta("(<>)<>", {
  --     iv(1),
  --     i(0),
  --   }),
  --   { condition = -in_string - in_comment }
  -- ),
  -- s(
  --   { trig = "{", snippetType = "autosnippet" },
  --   fmta("{<>}<>", {
  --     iv(1),
  --     i(0),
  --   }),
  --   { condition = -in_string - in_comment }
  -- ),
  -- s(
  --   { trig = "[", wordTrig = false, snippetType = "autosnippet" },
  --   fmta("[<>]<>", {
  --     iv(1),
  --     i(0),
  --   }),
  --   { condition = -in_string - in_comment }
  -- ),
  -- s(
  --   { trig = '"', wordTrig = false, snippetType = "autosnippet" },
  --   fmta('"<>"<>', {
  --     iv(1),
  --     i(0),
  --   }),
  --   { condition = -in_string - in_comment }
  -- ),
}
