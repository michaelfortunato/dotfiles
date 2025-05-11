---@diagnostic disable: undefined-global
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

local function make_trigger_preceeds_pattern(pattern)
  local condition = function(line_to_cursor, matched_trigger)
    local pos = vim.fn.getpos(".")
    local line = vim.fn.getline(".")
    -- If at the beginning of the line, you usually just want to insert
    local rem_line = string.sub(line, pos[3], #line)
    return (rem_line:match(pattern) ~= nil)
  end
  return cond_obj.make_condition(condition)
end

local ls = require("luasnip")
local trigger_does_not_follow_alpha_char = make_trigger_does_not_follow_char("%a")
local trigger_does_not_preceed_alpha_char = -make_trigger_preceeds_pattern("^%w")

--- TODO: Rename to Math mode
local MATH_NODES = {
  math = true,
  formula = true,
}

--- TODO: Rename to Content mode
local TEXT_NODES = {
  text = true,
  content = true,
  string = true,
}

--- TODO: Rename to Code mode
local CODE_NODES = {
  code = true,
}

local in_textzone = cond_obj.make_condition(function(check_parent)
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
end)

local in_codezone = cond_obj.make_condition(function()
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
end)

local in_mathzone = cond_obj.make_condition(function()
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
end)

local iv = function(i, ...)
  return d(i, get_visual, ...)
end

-- Generating functions for Matrix/Cases - thanks L3MON4D3!
local generate_matrix = function(args, snip)
  local rows = tonumber(snip.captures[2])
  local cols = tonumber(snip.captures[3])
  local nodes = {}
  local ins_indx = 1
  for j = 1, rows do
    table.insert(nodes, r(ins_indx, tostring(j) .. "x1", i(1)))
    ins_indx = ins_indx + 1
    for k = 2, cols do
      table.insert(nodes, t(" , "))
      table.insert(nodes, r(ins_indx, tostring(j) .. "x" .. tostring(k), i(1)))
      ins_indx = ins_indx + 1
    end
    table.insert(nodes, t({ ";", "" }))
  end
  -- fix last node.
  nodes[#nodes] = t(";")
  return sn(nil, nodes)
end

-- update for cases
local generate_cases = function(args, snip)
  local rows = tonumber(snip.captures[1]) or 2 -- default option 2 for cases
  local cols = 2 -- fix to 2 cols
  local nodes = {}
  local ins_indx = 1
  for j = 1, rows do
    table.insert(nodes, r(ins_indx, tostring(j) .. "x1", i(1)))
    ins_indx = ins_indx + 1
    for k = 2, cols do
      table.insert(nodes, t(" & "))
      table.insert(nodes, r(ins_indx, tostring(j) .. "x" .. tostring(k), i(1)))
      ins_indx = ins_indx + 1
    end
    table.insert(nodes, t({ ",", "" }))
  end
  -- fix last node.
  table.remove(nodes, #nodes)
  return sn(nil, nodes)
end

return {
  -- NOTE: Remove auto snippet in the future,
  -- we keep auto until we create another template snippet for this filetype
  --   s(
  --     { trig = "_DOC", snippetType = "autosnippet" },
  --     fmta(
  --       [[
  -- #import "@preview/unequivocal-ams:0.1.2": ams-article, theorem, proof, normal-size
  -- #import "@preview/equate:0.3.0": equate
  -- // #import "@preview/bloated-neurips:0.5.1": botrule, midrule, neurips2024, paragraph, toprule, url, font
  -- #import "@preview/cetz:0.3.3": canvas, draw, tree
  -- #import "@preview/subpar:0.2.1"
  -- #import "@preview/lemmify:0.1.8": *
  -- // #import "@preview/touying:0.6.0": *
  -- // #import themes.simple: *
  -- // #show: simple-theme.with(aspect-ratio: "16-9")
  -- #let remark(body, numbered: true) = figure(
  --   body,
  --   kind: "remark",
  --   supplement: [Theorem],
  --   numbering: if numbered { n =>> counter(heading).display() + [#n] }
  -- )
  -- #let lemma(body, numbered: true) = figure(
  --   body,
  --   kind: "lemma",
  --   supplement: [Theorem],
  --   numbering: if numbered { n =>> counter(heading).display() + [#n] }
  -- )
  -- #let proposition(body, numbered: true) = figure(
  --   body,
  --   kind: "proposition",
  --   supplement: [Theorem],
  --   numbering: if numbered { n =>> counter(heading).display() + [#n] }
  -- )
  -- #show: ams-article.with(
  --   title: [<>],
  --   authors: (
  --     (
  --       name: "<>",
  --       // department: [Department of Mathematics],
  --       // organization: [University of Chicago],
  --       // location: [Chicago, IL 60605],
  --       email: "<>",
  --       url: "<>"
  --     ),
  --   ),
  --   // abstract: lorem(100),
  --   // bibliography: bibliography("main.bib"),
  -- )
  -- // Math equation numbering and referencing.
  -- #set math.equation(numbering: "(1)")
  -- #show ref: it =>> {
  --   let eq = math.equation
  --   let el = it.element
  --   if el != none and el.func() == eq {
  --     let numb = numbering(
  --       "1",
  --       ..counter(eq).at(el.location())
  --     )
  --     let color = rgb(0%, 8%, 45%)  // Originally `mydarkblue`. :D
  --     let content = link(el.location(), text(fill: color, numb))
  --     [(#content)]
  --   } else {
  --     return it
  --   }
  -- }
  --
  -- #show heading: it =>> {
  --   // Create the heading numbering.
  --   let number = if it.numbering != none {
  --     counter(heading).display(it.numbering)
  --     h(7pt, weak: true)
  --   }
  --
  --   // Level 1 headings are centered and smallcaps.
  --   // The other ones are run-in.
  --   // set text(size: normal-size, weight: 400)
  --   set par(first-line-indent: 0em)
  --   set text(size: normal-size, weight: 400)
  --   set align(left)
  --   if it.level == 1 {
  --     v(15pt, weak: true)
  --     counter(figure.where(kind: "theorem")).update(0)
  --   } else {
  --     v(11pt, weak: true)
  --   }
  --   number
  --   strong(it.body)
  --   h(7pt, weak: true)
  -- }
  -- <>]],
  --       {
  --         i(1, "Untitled"),
  --         i(2, "Michael Newman Fortunato"),
  --         i(3, "michael.n.fortunato@gmail.com"),
  --         i(4, "www.mnf.dev"),
  --         i(0),
  --       }
  --     ),
  --     { condition = line_begin } --TODO: Condition should be begining of file!
  --   ),
  s(
    { trig = "DOC", snippetType = "autosnippet" },
    fmta(
      [[
#import "@local/mnf-typst:0.1.0": mnf_ams_article, theorem, definition, remark, lemma, proof, example, subpar, scr
#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/cetz-plot:0.1.1": plot

#show: mnf_ams_article.with(title: <>)
<>]],
      {
        i(1, "Untitled"),
        -- i(2, "main.bib"),
        -- i(3, ""),
        -- i(4, "Placeholder text for the abstract section."),
        -- i(5, "supplemental.bib"),
        i(0),
      }
    ),
    { condition = line_begin } --TODO: Condition should be begining of file!
  ),
  s({ trig = "toc", snippetType = "autosnippet" }, t("#outline()"), { condition = line_begin }),
  s(
    { trig = "#grid", snippetType = "autosnippet" },
    fmta(
      [[
#subpar.grid(
  columns: <>,
  inset: (top: 2em, left: 2em, right: 2em, bottom: 2em),
  gutter: 20pt,
  <>
  caption: [<>]
)<>
]],
      { i(1, "(1fr, 1fr)"), i(2), iv(3), i(0) }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "#figure", snippetType = "autosnippet" },
    fmta(
      [[
#figure(
caption: [<>],
supplement: <>,
<>
)<>
]],
      { i(1), i(2, "[Figure]"), iv(3), i(0) }
    ),
    { condition = line_begin }
  ),
  -- SUBSCRIPT
  -- s(
  --   { trig = "([%w%)%]%}|])ss", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
  --   fmta("<>_(<>)", {
  --     f(function(_, snip)
  --       return snip.captures[1]
  --     end),
  --     d(1, get_visual),
  --   }),
  --   { condition = in_mathzone }
  -- ),
  s(
    {
      trig = "([%w%)%]%}|])jj",
      desc = "Subscript(no ambiguity)",
      wordTrig = false,
      regTrig = true,
      snippetType = "autosnippet",
    },
    fmta("<>_(<>)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = in_mathzone }
  ),
  -- s(
  --   { trig = "([%w%)%]%}|])s([ijknmt])", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
  --   fmta("<>_(<>)<>", {
  --     f(function(_, snip)
  --       return snip.captures[1]
  --     end),
  --     f(function(_, snip)
  --       return snip.captures[2]
  --     end),
  --     i(0),
  --   }),
  --   { condition = in_mathzone }
  -- ),
  s(
    {
      trig = "([%w%)%]%}|])j([ijknmtvd])",
      wordTrig = false,
      desc = "subscript",
      regTrig = true,
      snippetType = "autosnippet",
    },
    fmta("<>_(<>)<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  -- SUBSCRIPT
  -- s(
  --   { trig = "([%w%)%]%}|])s(%d+)", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
  --   fmta("<>_(<>)<>", {
  --     f(function(_, snip)
  --       return snip.captures[1]
  --     end),
  --     f(function(_, snip)
  --       return snip.captures[2]
  --     end),
  --     i(0),
  --   }),
  --   { condition = in_mathzone }
  -- ),
  -- SUBSCRIPT
  s(
    { trig = "([%w%)%]%}|])j(%d+)", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>_(<>)<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    {
      trig = "([%w%)%]%}|])J",
      desc = "Subscript(no ambiguity)",
      wordTrig = false,
      regTrig = true,
      snippetType = "autosnippet",
    },
    fmta("<>_(<>)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = in_mathzone }
  ),
  -- -- SUPERSCRIPT
  -- s(
  --   { trig = "([%w%)%]%}%|])aa", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
  --   fmta("<>^(<>)<>", {
  --     f(function(_, snip)
  --       return snip.captures[1]
  --     end),
  --     d(1, get_visual),
  --     i(0),
  --   }),
  --   { condition = in_mathzone }
  -- ),
  s(
    { trig = "([%w%)%]%}|])kk", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^(<>)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = in_mathzone }
  ),
  -- s(
  --   { trig = "([%w%)%]%}|])a(%d+)", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
  --   fmta("<>^(<>)<>", {
  --     f(function(_, snip)
  --       return snip.captures[1]
  --     end),
  --     f(function(_, snip)
  --       return snip.captures[2]
  --     end),
  --     i(0),
  --   }),
  --   { condition = in_mathzone }
  -- ),
  s(
    { trig = "([%w%)%]%}|])k(%d+)", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^(<>)<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  --- TODO: Conflicts with mat no t then
  -- s(
  --   { trig = "([%w%)%]%}|])a([ijknm])", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
  --   fmta("<>^(<>)<>", {
  --     f(function(_, snip)
  --       return snip.captures[1]
  --     end),
  --     f(function(_, snip)
  --       return snip.captures[2]
  --     end),
  --     i(0),
  --   }),
  --   { condition = in_mathzone }
  -- ),
  s(
    { trig = "([%w%)%]%}|])k([ijknmtvd])", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^(<>)<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([%w%)%]%}|])K", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^(<>)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = in_mathzone }
  ),
  -- INVERSE
  s(
    { trig = "([%w%)%]%}])inv", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta([[<>^(-1)<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  -- DAGGER
  s(
    { trig = "([%w%)%]%}])dagger", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta([[<>^(dagger)<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  --- This kinda works with \infty and \int too!
  --- NOTE: This won't expand on newline but I tried a regTrig and that did not work
  --- its probably because trigger_does_not_follow_alpha_char has a bug on newlines
  -- s(
  --   { trig = "in ", wordTrig = false, snippetType = "autosnippet" },
  --   t("\\in "),
  --   { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  -- ),
  s(
    { trig = "int", wordTrig = false, snippetType = "autosnippet" },
    fmta("integral_(<>)^(<>)<>", {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- https://github.com/michaelfortunato/luasnip-latex-snippets.nvim/blob/main/lua/luasnip-latex-snippets/math_iA.lua
  --- Again, all of these are covered correctly by Typst!
  -- s({ trig = "RR", snippetType = "autosnippet" }, t("\\mathbb{R}"), { condition = in_mathzone }),
  -- s({ trig = "QQ", snippetType = "autosnippet" }, t("\\mathbb{Q}"), { condition = in_mathzone }),
  -- s({ trig = "NN", snippetType = "autosnippet" }, t("\\mathbb{N}"), { condition = in_mathzone }),
  -- s({ trig = "ZZ", snippetType = "autosnippet" }, t("\\mathbb{Z}"), { condition = in_mathzone }),
  -- s({ trig = "SS", snippetType = "autosnippet" }, t("\\mathbb{S}"), { condition = in_mathzone }),
  s({ trig = "cup", snippetType = "autosnippet" }, t("union"), { condition = in_mathzone }),
  s({ trig = "cap", snippetType = "autosnippet" }, t("inter"), { condition = in_mathzone }),
  s({ trig = "notin", snippetType = "autosnippet" }, t("in.not"), { condition = in_mathzone }),
  s({ trig = "nil", snippetType = "autosnippet" }, t("emptyset"), { condition = in_mathzone }),
  s({ trig = "null", snippetType = "autosnippet" }, t("emptyset"), { condition = in_mathzone }),
  s({ trig = "setminus", snippetType = "autosnippet" }, t("backslash"), { condition = in_mathzone }),
  s({ trig = "bigcup", snippetType = "autosnippet" }, t("union.big"), { condition = in_mathzone }),
  s({ trig = "bigcap", snippetType = "autosnippet" }, t("inter.big"), { condition = in_mathzone }),
  s({ trig = "langle", snippetType = "autosnippet" }, t("angle.l"), { condition = in_mathzone }),
  s({ trig = "rangle", snippetType = "autosnippet" }, t("angle.r"), { condition = in_mathzone }),
  -- TODO: can I prioritize lciel and rceil to keep old behavior?
  s({ trig = "lceil", snippetType = "autosnippet" }, t("ceil.l"), { condition = in_mathzone }),
  s({ trig = "rceil", snippetType = "autosnippet" }, t("ceil.r"), { condition = in_mathzone }),
  s({ trig = "floor", snippetType = "autosnippet" }, t("floor.l"), { condition = in_mathzone }),
  s({ trig = "subseteq", snippetType = "autosnippet" }, t("subset.eq"), { condition = in_mathzone }),
  s({ trig = "sseq", snippetType = "autosnippet" }, t("subset.eq"), { condition = in_mathzone }),
  -- s({ trig = ":=", snippetType = "autosnippet" }, t("\\coloneq"), { condition = in_mathzone }),
  -- NOTE: \to is not supprted in typst
  -- NOTE: Everything else is shorthand supported!
  -- s({ trig = "->", snippetType = "autosnippet" }, t("arrow.r"), { condition = in_mathzone }),
  -- s({ trig = "|->", snippetType = "autosnippet" }, t("mapsto"), { condition = in_mathzone }),
  -- s({ trig = "=>", snippetType = "autosnippet" }, t("arrow.r.double"), { condition = in_mathzone }),
  --- Relations
  s({
    trig = "=",
    name = "_insert_equal_sign_as_text_node",
    desc = "Insert a text node in math mode to tab over it. It's nice!",
    hidden = true,
    snippetType = "autosnippet",
  }, t("="), { condition = in_mathzone }),
  --- For now going to make this a snippet
  s({ trig = "implies", snippetType = "autosnippet" }, t("==>"), { condition = in_mathzone }),
  s({ trig = "neq", snippetType = "autosnippet" }, t("!="), { condition = in_mathzone }),
  s({ trig = "leq", snippetType = "autosnippet" }, t("<="), { condition = in_mathzone }),
  s({ trig = "geq", snippetType = "autosnippet" }, t(">="), { condition = in_mathzone }),
  s({ trig = "isomorphism", snippetType = "autosnippet" }, t("tilde.equiv"), { condition = in_mathzone }),
  -- s({ trig = "-->", snippetType = "autosnippet" }, t(" arrow.r.long"), { condition = in_mathzone }),
  -- s({ trig = ">=", snippetType = "autosnippet" }, t("gt.eq"), { condition = in_mathzone }),
  -- s({ trig = "<=", snippetType = "autosnippet" }, t("\\leq"), { condition = in_mathzone }),
  s({ trig = "~~", snippetType = "autosnippet" }, t("tilde.op"), { condition = in_mathzone }),
  s({ trig = "sim", snippetType = "autosnippet" }, t("tilde.op"), { condition = in_mathzone }),
  s({ trig = "to ", snippetType = "autosnippet" }, t("-> "), { condition = in_mathzone }),
  --- TODO: See if I actually use these
  s({ trig = "<|", snippetType = "autosnippet" }, t("lt.tri"), { condition = in_mathzone }),
  s({ trig = "<j", snippetType = "autosnippet" }, t("lt.tri.eq"), { condition = in_mathzone }),
  -- s({ trig = "lt.tri.eq", snippetType = "autosnippet" }, t("lt.tri.eq"), { condition = in_mathzone }),
  -- s({ trig = "lt.tri", snippetType = "autosnippet" }, t("lt.tri "), { condition = in_mathzone }),
  s({ trig = "normalsubgroup", snippetType = "autosnippet" }, t("lt.tri.eq"), { condition = in_mathzone }),
  s({ trig = "normalpsubgroup", snippetType = "autosnippet" }, t("lt.tri"), { condition = in_mathzone }),
  -- Operators
  s({ trig = "||", snippetType = "autosnippet" }, fmta("norm(<>)<>", { i(1), i(0) }), { condition = in_mathzone }),
  --- FIXME: This one is tricky, I think this works though smoothly so long as I put the space back `\mid `
  s({ trig = "| ", snippetType = "autosnippet" }, t("bar.v "), { condition = in_mathzone }),
  -- Interesting...
  s(
    { trig = "|([^%s][^|]*)|", regTrig = true, snippetType = "autosnippet" },
    fmta("abs(<>)<>", { f(function(_, snip)
      return snip.captures[1]
    end), i(0) }),
    { condition = in_mathzone }
  ),
  -- --- Let "@" namespace operators
  s({ trig = "@g", snippetType = "autosnippet" }, t("nabla"), { condition = in_mathzone }),
  s({ trig = "@p", snippetType = "autosnippet" }, t("partial"), { condition = in_mathzone }),
  s({ trig = "@c", snippetType = "autosnippet" }, t("compose"), { condition = in_mathzone }),
  s(
    { trig = "dxdy", snippetType = "autosnippet" },
    fmta([[frac((d <>,d <>)<>]], {
      iv(1),
      i(2),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "ddx", snippetType = "autosnippet" },
    fmta([[\frac{d}{d<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "pxpy", snippetType = "autosnippet" },
    fmta([[\frac{\partial <>}{\partial <>}<>]], {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "ppx", snippetType = "autosnippet" },
    fmta([[\frac{\partial}{\partial <>}<>]], {
      iv(1),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "lr(", wordTrig = false, snippetType = "autosnippet" },
    fmta("lr(( <> ))<>", {
      iv(1),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "lr{", wordTrig = false, snippetType = "autosnippet" },
    fmta("lr({ <> })<>", {
      iv(1),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "lr[", wordTrig = false, snippetType = "autosnippet" },
    fmta("lr([ <> ])<>", {
      iv(1),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  -- TODO: Really hink about if you want these vvv
  s(
    { trig = "(", wordTrig = false, desc = "Autopairs", snippetType = "autosnippet" },
    fmta("(<>)<>", {
      iv(1),
      i(0),
    }),
    { condition = -in_textzone * trigger_does_not_preceed_alpha_char * (in_mathzone + in_codezone) }
  ),
  s(
    { trig = "{", desc = "Autopairs", snippetType = "autosnippet" },
    fmta("{<>}<>", {
      iv(1),
      i(0),
    }),
    { condition = (in_mathzone + in_codezone) * trigger_does_not_preceed_alpha_char }
  ),
  s(
    { trig = "[", wordTrig = false, desc = "Autopairs", snippetType = "autosnippet" },
    fmta("[<>]<>", {
      iv(1),
      i(0),
    }),
    { condition = (in_mathzone + in_codezone) * trigger_does_not_preceed_alpha_char }
  ),
  -- TODO: Really hink about if you want these ^^^
  s(
    { trig = [["]], wordTrig = false, snippetType = "autosnippet" },
    fmta([["<>"<>]], {
      iv(1),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char * (in_mathzone + in_codezone) }
  ),
  s(
    { trig = "`", wordTrig = false, snippetType = "autosnippet" },
    fmta("`<>`<>", {
      i(1),
      i(0),
    }),
    { condition = -in_mathzone }
  ),
  s({ trig = "**", snippetType = "autosnippet" }, {
    t("cdot.op"),
  }, { condition = in_mathzone }),
  -- \times
  s({ trig = "xx", snippetType = "autosnippet" }, {
    t("times"),
  }, { condition = in_mathzone }),
  s({ trig = "by", snippetType = "autosnippet" }, {
    t("times"),
  }, { condition = in_mathzone }),
  -- CDOTS, i.e. \cdots
  -- DOT PRODUCT, i.e. \cdot
  -- s({ trig = "dot", snippetType = "autosnippet" }, {
  --   t("dot.op"),
  -- }, { condition = in_mathzone }),
  s({ trig = "...", snippetType = "autosnippet" }, {
    t("..."),
  }, { condition = in_mathzone }),
  s({ trig = "cdots", snippetType = "autosnippet" }, {
    t("dots.h.c"),
  }, { condition = in_mathzone }),
  s({ trig = " .. ", snippetType = "autosnippet" }, {
    t(" dot.op "),
  }, { condition = in_mathzone }),
  -- \times
  -- s({ trig = "times", snippetType = "autosnippet" }, {
  --   t("\\times"),
  -- }, { condition = in_mathzone }),
  -- CDOTS, i.e. \cdots
  -- LDOTS, i.e. \ldots
  s({ trig = "ldots", snippetType = "autosnippet" }, {
    t("dots.h"),
  }, { condition = in_mathzone }),
  s({ trig = "vdots", snippetType = "autosnippet" }, {
    t("dots.v"),
  }, { condition = in_mathzone }),
  s({ trig = "ddots", snippetType = "autosnippet" }, {
    t("dots.down"),
  }, { condition = in_mathzone }),
  s({ trig = "<>", snippetType = "autosnippet" }, {
    t("< "),
    i(1),
    t(" >"),
    i(0),
  }, { condition = in_mathzone }),
  --- common math commands, notice wordTrig=true
  s(
    { trig = "##c", snippetType = "autosnippet" },
    fmta([[#cite(<>)<>]], {
      d(1, get_visual),
      i(0),
    })
  ),
  s(
    { trig = "##l", snippetType = "autosnippet" },
    fmta([[#label("<>")<>]], {
      d(1, get_visual),
      i(0),
    })
  ),
  s(
    { trig = "lbl", snippetType = "autosnippet" },
    fmta([[#label(<>)<>]], {
      d(1, get_visual),
      i(0),
    })
  ),
  s(
    { trig = "##e", snippetType = "autosnippet" },
    fmta([[@<>]], {
      d(1, get_visual),
    })
  ),
  s(
    { trig = "##r", snippetType = "autosnippet" },
    fmta([[@<>]], {
      d(1, get_visual),
    })
  ),
  s(
    { trig = "bxd", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\boxed{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  -- NOTE: Typst is the same!
  -- s(
  --   { trig = "exists", wordTrig = false, snippetType = "autosnippet" },
  --   t("\\exists"),
  --   { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  -- ),
  -- NOTE: Typst is the same!
  -- s(
  --   { trig = "forall", wordTrig = false, snippetType = "autosnippet" },
  --   t("\\forall"),
  --   { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  -- ),
  --- Accents - Tilde
  s(
    { trig = "tilde", wordTrig = false, snippetType = "autosnippet" },
    fmta([[tilde<>]], {
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- Accents - hat
  s(
    { trig = "hat", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\hat<>]], {
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- BAR
  --   TODO: Which is faster? These two? or the dynamic node one?
  --- Enter display mode quickly
  s(
    { trig = "MM", wordTrig = false, regTrig = false, snippetType = "autosnippet" },
    fmta(
      [[
$
  <>
$<>]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "MM", wordTrig = false, regTrig = false, snippetType = "autosnippet" },
    fmta(
      [[

$
  <>
$<>]],
      {
        d(1, get_visual),
        i(0),
      },
      { trim_empty = false }
    ),
    { condition = -line_begin * trigger_does_not_follow_alpha_char }
  ),
  --  TODO: Which is faster?
  --   s(
  --     { trig = "MM", wordTrig = false, regTrig = false, snippetType = "autosnippet" },
  --     fmta(
  --       [[<>
  --   <>
  -- $<>]],
  --       {
  --         d(1, function()
  --           local line = vim.api.nvim_get_current_line()
  --           if line:sub(1, -(2 + 1)):match("^%s*$") then
  --             return sn(nil, t({ "$" })) -- Just start of math
  --           else
  --             return sn(nil, t({ "", "$" })) -- Newline + start of math
  --           end
  --         end, {}),
  --         d(2, get_visual),
  --         i(0),
  --       }
  --     ),
  --     { condition = trigger_does_not_follow_alpha_char }
  --   ),
  --- Enter inline mathmode quickly
  s(
    { trig = "mm", wordtrig = false, snippetType = "autosnippet" },
    fmta([[$<>$<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "(%a)mb", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta([[upright(bold(<>))<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "mb", wordTrig = false, snippetType = "autosnippet" },
    fmta([[upright(bold(<>))<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "mB", wordTrig = false, snippetType = "autosnippet" },
    fmta([[bb(<>)<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "(%a)mB", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta([[bb(<>)<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "mf", wordTrig = false, snippetType = "autosnippet" },
    fmta([[frak(<>)<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "(%a)mf", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta([[frak(<>)<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  -- FRACTION
  s(
    { trig = "ff", wordTrig = false, snippetType = "autosnippet" },
    fmta("frac(<>,<>)<>", {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  -- SUMMATION
  s(
    { trig = "sum", wordTrig = false, snippetType = "autosnippet" },
    fmta("sum_(<>)^(<>)<>", {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "mc", wordTrig = false, snippetType = "autosnippet" },
    fmta([[cal(<>)<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "mcal", wordTrig = false, snippetType = "autosnippet" },
    fmta([[cal(<>)<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "cal", wordTrig = false, snippetType = "autosnippet" },
    fmta([[cal(<>)<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  -- SECTION
  s(
    { trig = "h1", snippetType = "autosnippet" },
    fmta(
      [[= <> <<sec:<>>>
<>]],
      {
        iv(1),
        l(l._1:gsub("%s", "-"), 1),
        i(0),
      }
    ),
    { condition = in_textzone }
  ),
  -- SUBSECTION
  s(
    { trig = "h2", snippetType = "autosnippet" },
    fmta(
      [[== <>  <<subsec:<>>>
<>]],
      {
        iv(1),
        l(l._1:gsub("%s", "-"), 1),
        i(0),
      }
    ),
    { condition = in_textzone }
  ),
  -- SUBSUBSECTION
  s(
    { trig = "h3", snippetType = "autosnippet" },
    fmta(
      [[=== <>  <<subsubsec:<>>>
<>]],
      {
        iv(1),
        l(l._1:gsub("%s", "-"), 1),
        i(0),
      }
    ),
    { condition = in_textzone }
  ),
  s(
    { trig = "h4", snippetType = "autosnippet" },
    fmta(
      [[par(
  // leading: length,
  // spacing: length,
  // justify: bool,
  // linebreaks: autostr,
  // first-line-indent: lengthdictionary,
  // hanging-indent: length,
  <>) <<paragraph:<>>>
<>]],
      {
        iv(1),
        l(l._1:gsub("%s", "-"), 1),
        i(0),
      }
    ),
    { condition = in_textzone }
  ),
  --   Not supported in typst
  --   s(
  --     { trig = "h5", snippetType = "autosnippet" },
  --     fmta([[\subparagraph{<>}]], {
  --       d(1, get_visual),
  --     }),
  --     { condition = in_textzone }
  --   ),
  --- PART (only applicable to book document class)
  s(
    { trig = "tt", wordTrig = false, snippetType = "autosnippet" },
    fmta([["<>"<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char * in_mathzone }
  ),
  s(
    { trig = "tii", wordTrig = false, snippetType = "autosnippet" },
    fmta([[italic(<>)<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char * in_mathzone }
  ),
  s(
    { trig = "tii", wordTrig = false, snippetType = "autosnippet" },
    fmta([[_<>_<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char * in_textzone }
  ),
  s(
    { trig = "tbb", wordTrig = false, snippetType = "autosnippet" },
    fmta([[bold(<>)<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char * in_mathzone }
  ),
  s(
    { trig = "tbb", wordTrig = false, snippetType = "autosnippet" },
    fmta([[*<>*<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char * in_textzone }
  ),
  --- GREEK BEGIN
  s({ trig = ";a", wordTrig = false, snippetType = "autosnippet" }, {
    t("alpha"),
  }),
  s({ trig = ";b", wordTrig = false, snippetType = "autosnippet" }, {
    t("beta"),
  }),
  s({ trig = ";g", wordTrig = false, snippetType = "autosnippet" }, {
    t("gamma"),
  }),
  s({ trig = ";G", wordTrig = false, snippetType = "autosnippet" }, {
    t("Gamma"),
  }),
  s({ trig = ";d", wordTrig = false, snippetType = "autosnippet" }, {
    t("delta"),
  }),
  s({ trig = ";D", wordTrig = false, snippetType = "autosnippet" }, {
    t("Delta"),
  }),
  s({ trig = ";e", wordTrig = false, snippetType = "autosnippet" }, {
    t("epsilon"),
  }),
  s({ trig = ";ve", wordTrig = false, snippetType = "autosnippet" }, {
    t("varepsilon"),
  }),
  s({ trig = ";z", wordTrig = false, snippetType = "autosnippet" }, {
    t("zeta"),
  }),
  s({ trig = ";h", wordTrig = false, snippetType = "autosnippet" }, {
    t("eta"),
  }),
  s({ trig = ";o", wordTrig = false, snippetType = "autosnippet" }, {
    t("theta"),
  }),
  s({ trig = ";vo", wordTrig = false, snippetType = "autosnippet" }, {
    t("vartheta"),
  }),
  s({ trig = ";O", wordTrig = false, snippetType = "autosnippet" }, {
    t("Theta"),
  }),
  s({ trig = ";k", wordTrig = false, snippetType = "autosnippet" }, {
    t("kappa"),
  }),
  s({ trig = ";l", wordTrig = false, snippetType = "autosnippet" }, {
    t("lambda"),
  }),
  s({ trig = ";L", wordTrig = false, snippetType = "autosnippet" }, {
    t("Lambda"),
  }),
  s({ trig = ";m", wordTrig = false, snippetType = "autosnippet" }, {
    t("mu"),
  }),
  s({ trig = ";n", wordTrig = false, snippetType = "autosnippet" }, {
    t("nu"),
  }),
  s({ trig = ";x", wordTrig = false, snippetType = "autosnippet" }, {
    t("xi"),
  }),
  s({ trig = ";X", wordTrig = false, snippetType = "autosnippet" }, {
    t("Xi"),
  }),
  s({ trig = ";i", wordTrig = false, snippetType = "autosnippet" }, {
    t("pi"),
  }),
  s({ trig = ";I", wordTrig = false, snippetType = "autosnippet" }, {
    t("Pi"),
  }),
  s({ trig = ";r", wordTrig = false, snippetType = "autosnippet" }, {
    t("rho"),
  }),
  s({ trig = ";s", wordTrig = false, snippetType = "autosnippet" }, {
    t("sigma"),
  }),
  s({ trig = ";S", wordTrig = false, snippetType = "autosnippet" }, {
    t("Sigma"),
  }),
  s({ trig = ";t", wordTrig = false, snippetType = "autosnippet" }, {
    t("tau"),
  }),
  s({ trig = ";f", wordTrig = false, snippetType = "autosnippet" }, {
    t("phi"),
  }),
  s({ trig = ";vf", wordTrig = false, snippetType = "autosnippet" }, {
    t("varphi"),
  }),
  s({ trig = ";F", wordTrig = false, snippetType = "autosnippet" }, {
    t("Phi"),
  }),
  s({ trig = ";c", wordTrig = false, snippetType = "autosnippet" }, {
    t("chi"),
  }),
  s({ trig = ";p", wordTrig = false, snippetType = "autosnippet" }, {
    t("psi"),
  }),
  s({ trig = ";P", wordTrig = false, snippetType = "autosnippet" }, {
    t("Psi"),
  }),
  s({ trig = ";w", wordTrig = false, snippetType = "autosnippet" }, {
    t("omega"),
  }),
  s({ trig = ";W", wordTrig = false, snippetType = "autosnippet" }, {
    t("Omega"),
  }),
  --   s(
  --     { trig = "al", snippetType = "autosnippet" },
  --     fmta(
  --       [[
  -- $
  --   <> & <> \
  --   <>
  -- $
  --       ]],
  --       {
  --         i(1),
  --         i(2),
  --         i(0),
  --       }
  --     ),
  --     { condition = line_begin }
  --   ),
  s(
    { trig = "bb", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
        #<>[
<>
]<>
      ]],
      {
        i(1),
        d(2, get_visual),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  --- begin theorem
  s(
    { trig = "bte", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
        #theorem[
<>
]<>
      ]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  --- begin lemma
  s(
    { trig = "ble", snippetType = "autosnippet" },
    fmta(
      [[
        #lemma[
<>
]<>
      ]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  --- begin definition
  s(
    { trig = "bde", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
#definition(name:[<>])[
<>
]<<def:<>>>
<>]],
      {
        i(1),
        iv(2),
        rep(1),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "#[rR][eE][mM][aA][rR][kK]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
#remark(name: [<>])[
<>
]<>
      ]],
      {
        i(1),
        iv(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "#[tT][hH][eE][oO][rR][eE][mM]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
#theorem(name: [<>])[
<>
]<>
      ]],
      {
        i(1),
        iv(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "#[dD][eE][fF][iI][nN][iI][tT][iI][oO][nN]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
#definition(name: [<>])[
<>
]<<def:<>>><>
      ]],
      {
        i(1),
        iv(2),
        l(l._1:gsub("%s", "-"), 1),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "#[eE][xX][aA][mM][pP][lL][eE]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
#example(name: [<>])[
<>
]<>
      ]],
      {
        i(1),
        iv(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "#[pP][rR][oO][oO][fF]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
#proof(name: [<>])[
<>
]<>
      ]],
      {
        i(1),
        iv(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  -- begin PROOF
  s(
    { trig = "bpr", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
        #proof[
<>
]<>
      ]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  -- begin REMARK
  s(
    { trig = "cmd", snippetType = "autosnippet" },
    fmta(
      [[
      % MNF: newcommand, usage \newcommand{hi}[numparams][defaultvalue]{#1 + #2}
      TODO 
      ]],
      {}
    ),
    { condition = line_begin }
  ),
  -- Matrices and Cases
  s(
    {
      trig = "([bBpvV]?)mat(%d+)x(%d+)",
      name = "[bBpvV]matrix",
      desc = "matrices",
      regTrig = true,
      snippetType = "autosnippet",
    },
    fmta(
      [[
mat(delim:<>,
<>
)<>]],
      {
        f(function(_, snip)
          local prefix = snip.captures[1] or ""
          if (prefix == "b") or (prefix == "B") then
            return '"["'
          elseif (prefix == "p") or prefix == "v" or prefix == "V" then
            return '"("'
          else
            return '"["'
          end
        end),
        d(1, generate_matrix),
        i(0),
      }
    ),
    { condition = in_mathzone }
  ),

  s(
    { trig = "(%d?)cases", name = "cases", desc = "cases", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
cases(
<>
)<>]],
      { d(1, generate_cases), i(0) }
    ),
    { condition = in_mathzone }
  ),

  s(
    { trig = "plotf", name = "Plot Function", desc = "Plot a function using Cetz", snippetType = "autosnippet" },
    fmta(
      [[
canvas({
plot.plot(size: (5, 5), {
    plot.add(domain: (<>, <>), { x =>> <> })
})})<>]],
      { i(1, "0"), i(2, "5"), i(3, "calc.pow(x,2)"), i(0) }
    ),
    { condition = -in_mathzone }
  ),

  s(
    {
      trig = "#imagefig",
      name = "Image Function",
      desc = "Adds a figure showing an image",
      snippetType = "autosnippet",
    },
    fmta(
      [[
#figure(
  image(<>),
  caption: [<>]
)]],
      { iv(1), i(2) }
    ),
    { condition = -in_textzone }
  ),
}
