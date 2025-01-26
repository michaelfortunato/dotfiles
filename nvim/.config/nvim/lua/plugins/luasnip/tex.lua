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
local mnf_s = ls.extend_decorator.apply(s, { wordTrig = false, condition = trigger_does_not_follow_alpha_num_char })

-- Math context detection
local tex = {}
tex.in_mathzone = function()
  return vim.fn["vimtex#syntax#in_mathzone"]() == 1
end
tex.in_textzone = function()
  return not tex.in_mathzone()
end

return {
  -- NOTE: Remove auto snippet in the future,
  -- we keep auto until we create another template snippet for this filetype
  s(
    { trig = "DOC", snippetType = "autosnippet" },
    fmta(
      [[
\documentclass[10pt, letterpaper]{article}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsfonts}
\usepackage{amsthm}
\usepackage{mathtools}
\usepackage{hyperref}
% Optional Packages
% \usepackage{csquotes}
%
\newtheorem{theorem}{Theorem}[section]
\newtheorem{lemma}[theorem]{Lemma}
\theoremstyle{definition}
\newtheorem{definition}{Definition}[section]
\theoremstyle{remark}
\newtheorem*{remark}{Remark}
% Math Operators
\DeclareMathOperator*{\argmax}{arg\,max}
% \DeclareMathOperator*{\argmin}{arg\,min}
%
% Commands
% 3 is the number of args, 2 is the default value of arg1
%\newcommand{\plusbinomial}[3][2]{(#2 + #3)^#1}
\begin{document}
% MNF Default Math Latex Document
\title{<>}
\author{<>}
% FIXME: \institute{} is broken
\maketitle
  <>
\end{document}
      ]],
      {
        i(1, "Untitled"),
        i(2, "Michael Newman Fortunato"),
        i(0),
      }
    ),
    { condition = line_begin } --TODO: Condition should be begining of file!
  ),
  s(
    { trig = "toc", priority = PRIORITY, snippetType = "autosnippet" },
    t("\\tableofcontents"),
    { condition = line_begin }
  ),
  -- SUBSCRIPT
  s(
    { trig = "([%w%)%]%}|])ss", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>_{<>}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  -- INVERSE
  s(
    { trig = "([%w%)%]%}])inv", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta([[<>^{-1}<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  -- SUPERSCRIPT
  s(
    { trig = "([%w%)%]%}%|])SS", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^{<>}<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  -- TRANSPOSE
  s(
    { trig = "([%w%)%]%}])ST", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta([[<>^{T}<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  -- SUBSCRIPT
  s(
    { trig = "([%w%)%]%}|])s(%d+)", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>_{<>}<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  -- SUPERSCRIPT
  s(
    { trig = "([%w%)%]%}|])S(%d+)", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^{<>}<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "([%w%)%]%}|])s([ijknmt])", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>_{<>}<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      f(function(_, snip)
        return snip.captures[2]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  -- DAGGER
  s(
    { trig = "([%w%)%]%}])dagger", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta([[<>^{\dagger}<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  --- This kinda works with \infty and \int too!
  s(
    { trig = "in", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    t("\\in"),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- https://github.com/michaelfortunato/luasnip-latex-snippets.nvim/blob/main/lua/luasnip-latex-snippets/math_iA.lua
  --- Investigate this
  s(
    { trig = "bmat", snippetType = "autosnippet" },
    fmta(
      [[
  \begin{bmatrix} <> \end{bmatrix}<>]],
      {
        i(1),
        i(0),
      }
    ),
    { condition = tex.in_mathzone }
  ),
  s({ trig = "RR", snippetType = "autosnippet" }, t("\\mathbb{R}"), { condition = tex.in_mathzone }),
  s({ trig = "QQ", snippetType = "autosnippet" }, t("\\mathbb{Q}"), { condition = tex.in_mathzone }),
  s({ trig = "NN", snippetType = "autosnippet" }, t("\\mathbb{N}"), { condition = tex.in_mathzone }),
  s({ trig = "ZZ", snippetType = "autosnippet" }, t("\\mathbb{Z}"), { condition = tex.in_mathzone }),
  s({ trig = "UU", snippetType = "autosnippet" }, t("\\cup"), { condition = tex.in_mathzone }),
  s({ trig = "II", snippetType = "autosnippet" }, t("\\cap"), { condition = tex.in_mathzone }),
  s({ trig = ":=", snippetType = "autosnippet" }, t("\\coloneqq"), { condition = tex.in_mathzone }),
  s({ trig = "->", snippetType = "autosnippet" }, t("\\to"), { condition = tex.in_mathzone }),
  s({ trig = ":->", snippetType = "autosnippet" }, t("\\mapsto"), { condition = tex.in_mathzone }),
  s({ trig = "=>", snippetType = "autosnippet" }, t("\\implies"), { condition = tex.in_mathzone }),
  --- For now going to make this a snippet
  s({ trig = "implies", snippetType = "autosnippet" }, t("\\implies"), { condition = tex.in_mathzone }),
  s({ trig = "-->", snippetType = "autosnippet" }, t("\\longrightarrow"), { condition = tex.in_mathzone }),
  s({ trig = ">=", snippetType = "autosnippet" }, t("\\geq"), { condition = tex.in_mathzone }),
  s({ trig = "<=", snippetType = "autosnippet" }, t("\\leq"), { condition = tex.in_mathzone }),
  -- --- Let ".." namespace commonly used but not yet semantic prefix
  s({ trig = "..g", snippetType = "autosnippet" }, t("\\nabla"), { condition = tex.in_mathzone }),
  s({ trig = "..p", snippetType = "autosnippet" }, t("\\partial"), { condition = tex.in_mathzone }),
  s(
    { trig = "(", wordTrig = false, snippetType = "autosnippet" },
    fmta("(<>)<>", {
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  mnf_s(
    { trig = "{", snippetType = "autosnippet" },
    fmta("\\{<>\\}<>", {
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "{", wordTrig = false, snippetType = "autosnippet" },
    fmta("{<>}<>", {
      i(1),
      i(0),
    })
  ),
  -- e(SCAPED) PARENTHESES v2 {{
  s(
    { trig = "((", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\left( <> \\right)<>", {
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),

  -- e(SCAPED) BRACKETS v2 {{
  s(
    { trig = "[[", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\left[ <> \\right]<>", {
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),

  -- e(SCAPED) CURLY BRACES v2 {{
  s(
    { trig = "{{", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\left\\{ <> \\right\\}<>", {
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),

  -- BIG PARENTHESES
  s(
    { trig = "([^%a])b[%(%)]", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\big(<>\\big)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  -- BIG SQUARE BRACES
  s(
    { trig = "([^%a])b[%[%]]", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\big[<>\\big]", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  -- BIG CURLY BRACES
  s(
    { trig = "([^%a])b[%{%}]", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\big\\{<>\\big\\}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  -- ESCAPED CURLY BRACES
  s(
    { trig = "([^%a])\\%{", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\{<>\\}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  -- DOT PRODUCT, i.e. \cdot
  s({ trig = "dot", snippetType = "autosnippet" }, {
    t("\\cdot "),
  }, { condition = tex.in_mathzone }),
  -- \times
  s({ trig = "xx", snippetType = "autosnippet" }, {
    t("\\times "),
  }, { condition = tex.in_mathzone }),
  -- CDOTS, i.e. \cdots
  s({ trig = "cdots", snippetType = "autosnippet" }, {
    t("\\cdots"),
  }, { condition = tex.in_mathzone }),
  -- LDOTS, i.e. \ldots
  s({ trig = "ldo", snippetType = "autosnippet" }, {
    t("\\ldots"),
  }, { condition = tex.in_mathzone }),
  --- common math commands
  s(
    { trig = "lbl", snippetType = "autosnippet" },
    fmta([[\label{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "erf", snippetType = "autosnippet" },
    fmta([[\eqref{eq:<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "bxd", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\boxed{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "lll", wordTrig = false, snippetType = "autosnippet" },
    t("\\ell"),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "exists", wordTrig = false, snippetType = "autosnippet" },
    t("\\exists"),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "forall", wordTrig = false, snippetType = "autosnippet" },
    t("\\forall"),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- Accents - Tilde
  s(
    { trig = "tilde", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\tilde<>]], {
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- Accents - hat
  s(
    { trig = "hat", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\hat<>]], {
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- BAR
  s(
    { trig = "bar", wordTrig = false, snippetType = "autosnippet" },
    fmta([[<>\bar{<>}<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- Enter display mode quickly
  s(
    { trig = "MM", wordTrig = false, priority = PRIORITY, regTrig = false, snippetType = "autosnippet" },
    fmta(
      [[
\[
  <>
\]<>
    ]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  --- Enter inline mathmode quickly
  s(
    { trig = "mm", wordtrig = false, snippetType = "autosnippet" },
    fmta([[$<>$<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char }
  ),
  -- Define vectors and matrices quickly
  -- TODO: this does not get put inside a $$ snippet so tab jumping does not work?
  -- OK, I think I know why, the capture group on the negated
  -- %a class takes in $, which messes up the rnage
  -- wordTrig=true only expands if the charcter before the cursor is NOT  pattern is [%w_] not sure why they want _
  -- a word https://github.com/L3MON4D3/LuaSnip/blob/c9b9a22904c97d0eb69ccb9bab76037838326817/lua/luasnip/nodes/snippet.lua#L827
  -- s(
  --   { trig = "([^%a])mb", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
  --   fmta([[<>\mathbf{<>}]], {
  --     f(function(_, snip)
  --       return snip.captures[1]
  --     end),
  --     d(1, get_visual),
  --   }),
  --   { condition = tex.in_mathzone }
  -- ),
  s(
    { trig = "mb", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\mathbf{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "mB", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\mathbb{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  -- FRACTION
  s(
    { trig = "ff", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\frac{<>}{<>}<>", {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  -- SUMMATION
  mnf_s(
    { trig = "su", snippetType = "autosnippet" },
    fmta("\\sum_{<>}^{<>}<>", {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "mcal", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\mathcal{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "mathcal", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\mathcal{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "case", snippetType = "autosnippet" },
    fmta(
      [[
\left\{\begin{array}{lr}
  <>
\end{array}\right\}<>
      ]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  --- PART (only applicable to book document class)
  s(
    { trig = "h-1", snippetType = "autosnippet" },
    fmta([[\part{<>}]], {
      d(1, get_visual),
    }),
    { condition = tex.in_textzone }
  ),
  --- CHAPTER (only applicable to book document class)
  s(
    { trig = "h0", snippetType = "autosnippet" },
    fmta([[\chapter{<>}]], {
      d(1, get_visual),
    }),
    { condition = tex.in_textzone }
  ),
  -- SECTION
  s(
    { trig = "h1", snippetType = "autosnippet" },
    fmta([[\section{<>}]], {
      d(1, get_visual),
    }),
    { condition = tex.in_textzone }
  ),
  -- SUBSECTION
  s(
    { trig = "h2", snippetType = "autosnippet" },
    fmta([[\subsection{<>}]], {
      d(1, get_visual),
    }),
    { condition = tex.in_textzone }
  ),
  -- SUBSUBSECTION
  s(
    { trig = "h3", snippetType = "autosnippet" },
    fmta([[\subsubsection{<>}]], {
      d(1, get_visual),
    }),
    { condition = tex.in_textzone }
  ),
  s(
    { trig = "h4", snippetType = "autosnippet" },
    fmta([[\paragraph{<>}]], {
      d(1, get_visual),
    }),
    { condition = tex.in_textzone }
  ),
  s(
    { trig = "h5", snippetType = "autosnippet" },
    fmta([[\subparagraph{<>}]], {
      d(1, get_visual),
    }),
    { condition = tex.in_textzone }
  ),
  --- PART (only applicable to book document class)
  s(
    { trig = "tt", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\text{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "tii", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\textit{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "tbb", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\textbf{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = trigger_does_not_follow_alpha_char }
  ),
  --- GREEK BEGIN
  s({ trig = ";a", snippetType = "autosnippet" }, {
    t("\\alpha"),
  }),
  s({ trig = ";b", snippetType = "autosnippet" }, {
    t("\\beta"),
  }),
  s({ trig = ";g", snippetType = "autosnippet" }, {
    t("\\gamma"),
  }),
  s({ trig = ";G", snippetType = "autosnippet" }, {
    t("\\Gamma"),
  }),
  s({ trig = ";d", snippetType = "autosnippet" }, {
    t("\\delta"),
  }),
  s({ trig = ";D", snippetType = "autosnippet" }, {
    t("\\Delta"),
  }),
  s({ trig = ";e", snippetType = "autosnippet" }, {
    t("\\epsilon"),
  }),
  s({ trig = ";ve", snippetType = "autosnippet" }, {
    t("\\varepsilon"),
  }),
  s({ trig = ";z", snippetType = "autosnippet" }, {
    t("\\zeta"),
  }),
  s({ trig = ";h", snippetType = "autosnippet" }, {
    t("\\eta"),
  }),
  s({ trig = ";o", snippetType = "autosnippet" }, {
    t("\\theta"),
  }),
  s({ trig = ";vo", snippetType = "autosnippet" }, {
    t("\\vartheta"),
  }),
  s({ trig = ";O", snippetType = "autosnippet" }, {
    t("\\Theta"),
  }),
  s({ trig = ";k", snippetType = "autosnippet" }, {
    t("\\kappa"),
  }),
  s({ trig = ";l", snippetType = "autosnippet" }, {
    t("\\lambda"),
  }),
  s({ trig = ";L", snippetType = "autosnippet" }, {
    t("\\Lambda"),
  }),
  s({ trig = ";m", snippetType = "autosnippet" }, {
    t("\\mu"),
  }),
  s({ trig = ";n", snippetType = "autosnippet" }, {
    t("\\nu"),
  }),
  s({ trig = ";x", snippetType = "autosnippet" }, {
    t("\\xi"),
  }),
  s({ trig = ";X", snippetType = "autosnippet" }, {
    t("\\Xi"),
  }),
  s({ trig = ";i", snippetType = "autosnippet" }, {
    t("\\pi"),
  }),
  s({ trig = ";I", snippetType = "autosnippet" }, {
    t("\\Pi"),
  }),
  s({ trig = ";r", snippetType = "autosnippet" }, {
    t("\\rho"),
  }),
  s({ trig = ";s", snippetType = "autosnippet" }, {
    t("\\sigma"),
  }),
  s({ trig = ";S", snippetType = "autosnippet" }, {
    t("\\Sigma"),
  }),
  s({ trig = ";t", snippetType = "autosnippet" }, {
    t("\\tau"),
  }),
  s({ trig = ";f", snippetType = "autosnippet" }, {
    t("\\phi"),
  }),
  s({ trig = ";vf", snippetType = "autosnippet" }, {
    t("\\varphi"),
  }),
  s({ trig = ";F", snippetType = "autosnippet" }, {
    t("\\Phi"),
  }),
  s({ trig = ";c", snippetType = "autosnippet" }, {
    t("\\chi"),
  }),
  s({ trig = ";p", snippetType = "autosnippet" }, {
    t("\\psi"),
  }),
  s({ trig = ";P", snippetType = "autosnippet" }, {
    t("\\Psi"),
  }),
  s({ trig = ";w", snippetType = "autosnippet" }, {
    t("\\omega"),
  }),
  s({ trig = ";W", snippetType = "autosnippet" }, {
    t("\\Omega"),
  }),
  --- GREEK END
  s(
    { trig = "eq", snippetType = "autosnippet" },
    fmta(
      [[
        \begin{equation}
            <>
        \end{equation}
      ]],
      {
        i(1),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "al", snippetType = "autosnippet" },
    fmta(
      [[
        \begin{align}
            <>
        \end{align}
      ]],
      {
        i(1),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "bb", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
        \begin{<>}
            <>
        \end{<>}
      ]],
      {
        i(1),
        d(2, get_visual),
        rep(1),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "beg", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
        \begin{<>}
            <>
        \end{<>}
      ]],
      {
        i(1),
        d(2, get_visual),
        rep(1),
      }
    ),
    { condition = line_begin }
  ),
  --- begin theorem
  s(
    { trig = "bte", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
        \begin{theorem}
            <>
        \end{theorm}
      ]],
      {
        d(1, get_visual),
      }
    ),
    { condition = line_begin }
  ),
  --- begin lemma
  s(
    { trig = "ble", snippetType = "autosnippet" },
    fmta(
      [[
        \begin{lemma}
            <>
        \end{lemma}
      ]],
      {
        d(1, get_visual),
      }
    ),
    { condition = line_begin }
  ),
  --- begin definition
  s(
    { trig = "bde", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
        \begin{definition}
            <>
        \end{definition}
      ]],
      {
        d(1, get_visual),
      }
    ),
    { condition = line_begin }
  ),
  -- begin PROOF
  s(
    { trig = "bpr", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
        \begin{proof}
            <>
        \end{proof}
      ]],
      {
        d(1, get_visual),
      }
    ),
    { condition = line_begin }
  ),
  -- begin REMARK
  s(
    { trig = "bre", snippetType = "autosnippet" },
    fmta(
      [[
        \begin{remark}
            <>
        \end{remark}
      ]],
      {
        d(1, get_visual),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "cmd", snippetType = "autosnippet" },
    fmta(
      [[
      % MNF: newcommand, usage \newcommand{hi}[numparams][defaultvalue]{#1 + #2}
      \newcommand{<>}{<>}
      ]],
      {
        i(1),
        i(2),
      }
    ),
    { condition = line_begin }
  ),
}
