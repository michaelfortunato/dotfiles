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
local function sanitize_label(s)
  -- FIXME: caller does not work if you invoke a snippet, not this functions
  -- issue but still should be addressed
  -- I believe this is because we use the first node as the argument
  -- but that id is not stable if we add a snippet while typing the name.
  return s:gsub("%s", "-")
    :gsub("%$", "")
    :gsub(">", "")
    :gsub("<", "")
    :gsub("%?", "")
    :gsub("%(", "")
    :gsub("%)", "")
    :gsub("%^", "")
end
-- Math context detection
local tex = {}
tex.in_mathzone = function()
  return vim.fn["vimtex#syntax#in_mathzone"]() == 1
end
-- TODO: Change tex.in_mathzone to in_mathzone
local in_mathzone = tex.in_mathzone

tex.in_textzone = function()
  return not tex.in_mathzone()
end
--- TS Implementation
tex.in_itemize_ts = function()
  local node = vim.treesitter.get_node({ ignore_injections = false })
  while node do
    if TEXT_NODES[node:type()] then
      return false
    elseif MATH_NODES[node:type()] then
      return true
    end
    node = node:parent()
  end
  return false
end

tex.in_comment = function() -- comment detection
  return vim.fn["vimtex#syntax#in_comment"]() == 1
end
tex.in_env = function(name) -- generic environment detection
  local is_inside = vim.fn["vimtex#env#is_inside"](name)
  return (is_inside[1] > 0 and is_inside[2] > 0)
end
-- A few concrete environments---adapt as needed
tex.in_equation = function() -- equation environment detection
  return tex.in_env("equation")
end
tex.in_itemize_vimtex = function() -- itemize environment detection
  return tex.in_env("itemize")
end
tex.in_tikz = function() -- TikZ picture environment detection
  return tex.in_env("tikzpicture")
end
tex.in_itemize = tex.in_itemize_vimtex

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
      table.insert(nodes, t(" & "))
      table.insert(nodes, r(ins_indx, tostring(j) .. "x" .. tostring(k), i(1)))
      ins_indx = ins_indx + 1
    end
    table.insert(nodes, t({ "\\\\", "" }))
  end
  -- fix last node.
  nodes[#nodes] = t("\\\\")
  return sn(nil, nodes)
end

local generate_vector = function(args, snip)
  snip.captures[2] = snip.captures[1] or 1
  snip.captures[3] = 1
  return generate_matrix(args, snip)
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
    table.insert(nodes, t({ "\\\\", "" }))
  end
  -- fix last node.
  table.remove(nodes, #nodes)
  return sn(nil, nodes)
end

--- Basically an insert node but if the visual clip register
--- is not preseet this will dump that content here instead
--- Note the buffer is cleared after 1 dump so this is good.
local iv = function(i, ...)
  return d(i, get_visual, ...)
end

---@diagnostic disable-next-line: param-type-mismatch
local s = ls.extend_decorator.apply(ls.snippet, { hidden = true })

-- Adds a new undo point
-- See https://github.com/L3MON4D3/LuaSnip/issues/830
local snip_expand = require("luasnip").snip_expand
require("luasnip").snip_expand = function(...)
  vim.o.ul = vim.o.ul
  snip_expand(...)
end

return {
  -- NOTE: Remove auto snippet in the future,
  -- we keep auto until we create another template snippet for this filetype
  s(
    { trig = "DOC", snippetType = "autosnippet" },
    fmta(
      [[
\documentclass[10pt, letterpaper]{article}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                   Packages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\usepackage[utf8]{inputenc} % allow utf-8 input
\usepackage[T1]{fontenc}    % use 8-bit T1 fonts, see https://tex.stackexchange.com/questions/664/why-should-i-use-usepackaget1fontenc
\usepackage{microtype}      % microtypography
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsfonts}
\usepackage{amsthm}
\usepackage{mathtools}
\usepackage{hyperref}       % hyperlinks
\usepackage{url}            % simple URL typesetting
\usepackage{booktabs,multirow,makecell}       % professional-quality tables
\usepackage{siunitx}        % professional-quality number formatting
\usepackage{amsfonts}       % blackboard math symbols
\usepackage{nicefrac}       % compact symbols for 1/2, etc.
\usepackage{xcolor}         % colors
\usepackage{nicematrix} % for matrix/block drawing
\usepackage{float} % for [H] exact placement
\usepackage[capitalize,noabbrev]{cleveref} %  use \cref{} instead of \ref

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Optional Packages
% \usepackage{csquotes}
% \usepackage[textsize=tiny]{todonotes} % usage: \todo[inline]{notehere}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Personal Packages
% \usepackage{tailwindcolors} % my custom tailwindcss colors

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           Theorems/Definitions/etc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newtheorem{theorem}{Theorem}[section]
\newtheorem{lemma}[theorem]{Lemma}
\theoremstyle{definition}
\newtheorem{definition}{Definition}[section]
\theoremstyle{remark}
\newtheorem*{remark}{Remark}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               CLEVERREF Configs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\crefname{algorithm}{Algorithm}{Algorithms}
\Crefname{algorithm}{Algorithm}{Algorithms}
% Sections
\Crefname{section}{Section}{Sections}
% Theorems etc
\crefname{theorem}{Theorem}{Theorems}
\Crefname{theorem}{Theorem}{Theorems}
\crefname{lemma}{Lemma}{Lemmas}
\Crefname{lemma}{Lemma}{Lemmas}
\crefname{remark}{Remark}{Remarks}
\Crefname{remark}{Remark}{Remarks}
%def
\crefname{definition}{Definition}{Definitions}
\Crefname{definition}{Definition}{Definitions}
\crefname{boxeddefinition}{Definition}{Definitions}
\Crefname{boxeddefinition}{Definition}{Definitions}
%fig
\crefname{figure}{Fig.}{Figs.}
\Crefname{figure}{Fig.}{Figs.}
\crefname{table}{Table}{Tables}
\Crefname{table}{Table}{Tables}
% cref formats
\crefformat{equation}{(#2#1#3)}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                               Math Operators
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HELPFUL TIPS
======================================================================
% 	No *  subscript to the side always (inline style)
% 	With *  subscript below in display math (like \lim or \sum)
======================================================================
% Math Operators
\DeclareMathOperator*{\argmax}{arg\,max} % \DeclareMathOperator*{\argmin}{arg\,min}
%% Pair Deleiminter! Lovem 
%%% Absolute values \abs and \norm
\DeclarePairedDelimiter\abs{\lvert}{\rvert}%
\DeclarePairedDelimiter\norm{\lVert}{\rVert}%
%%% Swap the definition of \abs* and \norm*, so that \abs
%%% and \norm resizes the size of the brackets, and the 
%%% starred version does not.
\makeatletter
\let\oldabs\abs
\def\abs{\@ifstar{\oldabs}{\oldabs*}}
\let\oldnorm\norm
\def\norm{\@ifstar{\oldnorm}{\oldnorm*}}
\makeatother
%%% Floor and Ceiling, Because I am not smart enough to be a pure math guy!
\DeclarePairedDelimiter{\ceil}{\lceil}{\rceil}
\DeclarePairedDelimiter{\floor}{\lfloor}{\rfloor}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                  Commands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3 is the number of args, 2 is the default value of arg1
% \newcommand{\plusbinomial}[3][2]{(#2 + #3)^#1}
% Usage: \plusbinomial[4]{x}{y} becomes (x + y)^4
\newcommand{\dxdy}[2]{\frac{d#1}{d#2}}
\newcommand{\ddx}[1]{\frac{d}{d#1}}
\newcommand{\pxpy}[2]{\frac{\partial#1}{\partial#2}}
\newcommand{\ppx}[1]{\frac{\partial}{\partial#1}}
%
% bibliography
% Usage: \cite{keyword}
% See here: https://www.overleaf.com/learn/latex/Bibliography_management_with_biblatex
\usepackage[
backend=biber,
style=alphabetic,
sorting=ynt
]{biblatex}
%\addbibresource{main.bib}
%\addbibresource{Zotero.bib} %Main bib db, see $BIBINPUTS 

\begin{document}
% Title Section
\title{<>}
\author{<>}
\date{\today}
\maketitle
%
<>
% \printbibliography
% \printbibliography[type=book,title={Books only}] 
% \printbibliography[keyword={physics},title={Physics-related only}]
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
  s({ trig = "toc", snippetType = "autosnippet" }, t("\\tableofcontents"), { condition = line_begin }),
  -- SUBSCRIPT
  s(
    {
      trig = "([%w%)%]%}|])jj",
      desc = "Subscript(no ambiguity)",
      wordTrig = false,
      regTrig = true,
      snippetType = "autosnippet",
    },
    fmta("<>_{<>}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = in_mathzone }
  ),
  s(
    {
      trig = "([%w%)%]%}|])j([ijknmtvd])",
      wordTrig = false,
      desc = "subscript",
      regTrig = true,
      snippetType = "autosnippet",
    },
    fmta("<>_{<>}<>", {
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
  s(
    { trig = "([%w%)%]%}|])j(%d+)", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>_{<>}<>", {
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
    fmta("<>_{<>}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([%w%)%]%}|])kk", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^{<>}<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
      i(0),
    }),
    { condition = in_mathzone }
  ),
  s(
    { trig = "([%w%)%]%}|])k(%d+)", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^{<>}<>", {
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
    { trig = "([%w%)%]%}|])k([ijknmtvd])", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^{<>}<>", {
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
    fmta("<>^{<>}", {
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
    fmta([[<>^{-1}<>]], {
      f(function(_, snip)
        return snip.captures[1]
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
  --- NOTE: This won't expand on newline but I tried a regTrig and that did not work
  --- its probably because trigger_does_not_follow_alpha_char has a bug on newlines
  s(
    { trig = "in ", wordTrig = false, snippetType = "autosnippet" },
    t("\\in "),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "int", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\int_{<>}^{<>}<>", {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  --- https://github.com/michaelfortunato/luasnip-latex-snippets.nvim/blob/main/lua/luasnip-latex-snippets/math_iA.lua
  --- Investigate this
  s({ trig = "RR", snippetType = "autosnippet" }, t("\\mathbb{R}"), { condition = tex.in_mathzone }),
  s({ trig = "CC", snippetType = "autosnippet" }, t("\\mathbb{C}"), { condition = tex.in_mathzone }),
  s({ trig = "QQ", snippetType = "autosnippet" }, t("\\mathbb{Q}"), { condition = tex.in_mathzone }),
  s({ trig = "NN", snippetType = "autosnippet" }, t("\\mathbb{N}"), { condition = tex.in_mathzone }),
  s({ trig = "ZZ", snippetType = "autosnippet" }, t("\\mathbb{Z}"), { condition = tex.in_mathzone }),
  s({ trig = "SS", snippetType = "autosnippet" }, t("\\mathbb{S}"), { condition = tex.in_mathzone }),
  s({ trig = "EE", snippetType = "autosnippet" }, t("\\mathbb{E}"), { condition = tex.in_mathzone }),
  s({ trig = "PP", snippetType = "autosnippet" }, t("\\mathbb{P}"), { condition = tex.in_mathzone }),
  --- Relations
  s({ trig = ":=", snippetType = "autosnippet" }, t("\\coloneq"), { condition = tex.in_mathzone }),
  s({ trig = "equiv", snippetType = "autosnippet" }, t("\\equiv"), { condition = tex.in_mathzone }),
  s({ trig = "===", snippetType = "autosnippet" }, t("\\equiv"), { condition = tex.in_mathzone }),
  s({ trig = "neq", snippetType = "autosnippet" }, t("\\neq"), { condition = tex.in_mathzone }),
  s({ trig = "approx", snippetType = "autosnippet" }, t("\\approx"), { condition = tex.in_mathzone }),
  s({
    trig = "=",
    name = "_insert_equal_sign_as_text_node",
    desc = "Insert a text node in math mode to tab over it. It's nice!",
    hidden = true,
    snippetType = "autosnippet",
  }, t("="), { condition = tex.in_mathzone }),
  s({ trig = "->", snippetType = "autosnippet" }, t("\\to"), { condition = tex.in_mathzone }),
  s({ trig = "to", snippetType = "autosnippet" }, t("\\to"), { condition = tex.in_mathzone }),
  s({ trig = ":->", snippetType = "autosnippet" }, t("\\mapsto"), { condition = tex.in_mathzone }),
  s({ trig = "mapsto", snippetType = "autosnippet" }, t("\\mapsto"), { condition = tex.in_mathzone }),
  s({ trig = "=>", snippetType = "autosnippet" }, t("\\implies"), { condition = tex.in_mathzone }),
  --- For now going to make this a snippet
  s({ trig = "implies", snippetType = "autosnippet" }, t("\\implies"), { condition = tex.in_mathzone }),
  s({ trig = "-->", snippetType = "autosnippet" }, t("\\longrightarrow"), { condition = tex.in_mathzone }),
  s({ trig = ">=", snippetType = "autosnippet" }, t("\\geq"), { condition = tex.in_mathzone }),
  s({ trig = "<=", snippetType = "autosnippet" }, t("\\leq"), { condition = tex.in_mathzone }),
  s({ trig = "leq", snippetType = "autosnippet" }, t("\\leq"), { condition = tex.in_mathzone }),
  s({ trig = "geq", snippetType = "autosnippet" }, t("\\geq"), { condition = tex.in_mathzone }),
  s({ trig = "~~", snippetType = "autosnippet" }, t("\\sim"), { condition = tex.in_mathzone }),
  s({ trig = "sim", snippetType = "autosnippet" }, t("\\sim"), { condition = tex.in_mathzone }),
  s({ trig = "cup", snippetType = "autosnippet" }, t("\\cup"), { condition = in_mathzone }),
  s({ trig = "cap", snippetType = "autosnippet" }, t("\\cap"), { condition = in_mathzone }),
  s({ trig = "notin", snippetType = "autosnippet" }, t("\\notin"), { condition = in_mathzone }),
  s({ trig = "nil", snippetType = "autosnippet" }, t("\\emptyset"), { condition = in_mathzone }),
  s({ trig = "null", snippetType = "autosnippet" }, t("\\emptyset"), { condition = in_mathzone }),
  s({ trig = "cong", snippetType = "autosnippet" }, t("\\cong"), { condition = in_mathzone }),
  s({ trig = "iso", snippetType = "autosnippet" }, t("\\cong"), { condition = in_mathzone }),
  s({ trig = "restriction", snippetType = "autosnippet" }, t("\\restriction"), { condition = in_mathzone }),
  s({ trig = "setminus", snippetType = "autosnippet" }, t("\\setminus"), { condition = in_mathzone }),
  s({ trig = "bigcup", snippetType = "autosnippet" }, t("\\bigcup"), { condition = in_mathzone }),
  s({ trig = "bigcap", snippetType = "autosnippet" }, t("\\bigcap"), { condition = in_mathzone }),
  s({ trig = "langle", snippetType = "autosnippet" }, t("\\langle"), { condition = in_mathzone }),
  s({ trig = "complement", snippetType = "autosnippet" }, t("\\complement"), { condition = in_mathzone }),
  s({ trig = "rangle", snippetType = "autosnippet" }, t("\\rangle"), { condition = in_mathzone }),
  s({ trig = "oplus", snippetType = "autosnippet" }, t("\\oplus"), { condition = in_mathzone }),
  s({ trig = "directsum", snippetType = "autosnippet" }, t("\\oplus"), { condition = in_mathzone }),
  s({ trig = "circleplus", snippetType = "autosnippet" }, t("\\oplus"), { condition = in_mathzone }),
  s({ trig = "bigcircleplus", snippetType = "autosnippet" }, t("\\bigoplus"), { condition = in_mathzone }),
  s({ trig = "bigdirectsum", snippetType = "autosnippet" }, t("\\bigoplus"), { condition = in_mathzone }),
  s({ trig = "bigoplus", snippetType = "autosnippet" }, t("\\bigoplus"), { condition = in_mathzone }),
  -- TODO: can I prioritize lciel and rceil to keep old behavior?
  s({ trig = "lceil", snippetType = "autosnippet" }, t("\\lceil"), { condition = in_mathzone }),
  s({ trig = "rceil", snippetType = "autosnippet" }, t("\\rceil"), { condition = in_mathzone }),
  s({ trig = "ceil", snippetType = "autosnippet" }, { t("\\ceil{"), i(1), t("}"), i(0) }, { condition = in_mathzone }),
  s({ trig = "lfloor", snippetType = "autosnippet" }, t("\\lfloor"), { condition = in_mathzone }),
  s({ trig = "rfloor", snippetType = "autosnippet" }, t("\\rfloor"), { condition = in_mathzone }),
  s(
    { trig = "floor", snippetType = "autosnippet" },
    { t("\\floor{"), i(1), t("}"), i(0) },
    { condition = in_mathzone }
  ),
  s({ trig = "compose", snippetType = "autosnippet" }, t("\\circ"), { condition = in_mathzone }),
  s({ trig = "compliment", snippetType = "autosnippet" }, t("\\complement"), { condition = in_mathzone }),
  s({ trig = "subseteq", snippetType = "autosnippet" }, t("\\subseteq"), { condition = in_mathzone }),
  --- TODO: See if I actually use these
  s({ trig = "<|", snippetType = "autosnippet" }, t("\\triangleleft"), { condition = tex.in_mathzone }),
  s({ trig = "<j", snippetType = "autosnippet" }, t("\\trianglelefteq"), { condition = tex.in_mathzone }),
  s({ trig = "normalsubgroup", snippetType = "autosnippet" }, t("\\trianglelefteq"), { condition = tex.in_mathzone }),
  s({ trig = "normalpsubgroup", snippetType = "autosnippet" }, t("\\triangleleft"), { condition = tex.in_mathzone }),
  s({ trig = "quad", snippetType = "autosnippet" }, t("\\quad"), { condition = tex.in_mathzone }),
  s({ trig = "hquad", snippetType = "autosnippet" }, t("\\hquad"), { condition = tex.in_mathzone }),
  s({ trig = "space", snippetType = "autosnippet" }, t("\\enspace"), { condition = in_mathzone }),
  s({ trig = "enspace", snippetType = "autosnippet" }, t("\\enspace"), { condition = in_mathzone }),
  s({ trig = "hspace", snippetType = "autosnippet" }, t("\\,"), { condition = in_mathzone }),
  -- \!
  -- negative thin space
  -- squeeze things together
  -- \,
  -- thin space
  -- \:
  -- medium space
  -- more readable than \,
  -- \;
  -- thick space
  -- best for “visual separation”
  -- \quad
  -- large
  -- separate phrases
  -- \qquad
  -- larger
  -- big structural separation
  -- ---
  -- Operators
  s({ trig = "op", snippetType = "autosnippet" }, fmta("\\mathrm{<>}<>", { i(1), i(0) }), { condition = in_mathzone }),
  s(
    { trig = "||", snippetType = "autosnippet" },
    fmta("\\norm{<>}<>", { i(1), i(0) }),
    { condition = tex.in_mathzone }
  ),
  --- FIXME: This one is tricky, I think this works though smoothly so long as I put the space back `\mid `
  s({ trig = "| ", snippetType = "autosnippet" }, t("\\mid "), { condition = tex.in_mathzone }),
  s(
    { trig = "|([^%s][^|]*)|", regTrig = true, snippetType = "autosnippet" },
    fmta("\\abs{<>}<>", { f(function(_, snip)
      return snip.captures[1]
    end), i(0) }),
    { condition = in_mathzone }
  ),
  -- --- Let "@" namespace operators
  s({ trig = "@g", snippetType = "autosnippet" }, t("\\nabla"), { condition = tex.in_mathzone }),
  s({ trig = "@p", snippetType = "autosnippet" }, t("\\partial"), { condition = tex.in_mathzone }),
  s({ trig = "@c", snippetType = "autosnippet" }, t("\\circ"), { condition = tex.in_mathzone }),
  s(
    { trig = "dxdy", snippetType = "autosnippet" },
    fmta([[\frac{d<>}{d<>}<>]], {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "ddx", snippetType = "autosnippet" },
    fmta([[\frac{d}{d<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "pxpy", snippetType = "autosnippet" },
    fmta([[\frac{\partial <>}{\partial <>}<>]], {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "ppx", snippetType = "autosnippet" },
    fmta([[\frac{\partial}{\partial <>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  --- NOTE: These must have higher prioerity than
  --- the single char snippet versions
  s(
    { trig = "lr(", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\left(<>\\right)<>", {
      iv(1),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "lr{", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\left\\{<>\\right\\}<>", {
      iv(1),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "lr[", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\left[<>\\right]<>", {
      iv(1),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  ---************************************************************
  -- AUTOPAIRS
  ----************************************************************
  -- s(
  --   { trig = "(", wordTrig = false, snippetType = "autosnippet" },
  --   fmta("(<>)<>", {
  --     iv(1),
  --     i(0),
  --   }),
  --   { condition = tex.in_mathzone }
  -- ),
  s(
    { trig = "{", snippetType = "autosnippet", hidden = true },
    fmta("\\{<>\\}<>", {
      iv(1),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "[", wordTrig = false, snippetType = "autosnippet" },
    fmta("[<>]<>", {
      iv(1),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s({ trig = "**", snippetType = "autosnippet" }, {
    t("\\cdot"),
  }, { condition = tex.in_mathzone }),
  -- \times
  s({ trig = "xx", snippetType = "autosnippet" }, {
    t("\\times"),
  }, { condition = tex.in_mathzone }),
  s({ trig = "by", snippetType = "autosnippet" }, {
    t("\\times"),
  }, { condition = tex.in_mathzone }),
  -- CDOTS, i.e. \cdots
  -- DOT PRODUCT, i.e. \cdot
  s({ trig = "...", snippetType = "autosnippet" }, {
    t("..."),
  }, { condition = in_mathzone }),
  s({ trig = "dot", snippetType = "autosnippet" }, {
    t("\\cdot"),
  }, { condition = tex.in_mathzone }),
  -- \times
  s({ trig = "times", snippetType = "autosnippet" }, {
    t("\\times"),
  }, { condition = tex.in_mathzone }),
  -- CDOTS, i.e. \cdots
  s({ trig = "cdots ", snippetType = "autosnippet" }, {
    t("\\cdots "),
  }, { condition = tex.in_mathzone }),
  s({ trig = "cdot ", snippetType = "autosnippet" }, {
    t("\\cdot "),
  }, { condition = tex.in_mathzone }),
  -- LDOTS, i.e. \ldots
  s({ trig = "ldots", snippetType = "autosnippet" }, {
    t("\\ldots"),
  }, { condition = tex.in_mathzone }),
  s({ trig = "vdots", snippetType = "autosnippet" }, {
    t("\\vdots"),
  }, { condition = tex.in_mathzone }),
  s({ trig = "ddots", snippetType = "autosnippet" }, {
    t("\\ddots"),
  }, { condition = tex.in_mathzone }),
  s({ trig = "<>", snippetType = "autosnippet" }, {
    t("\\langle "),
    i(1),
    t(" \\rangle"),
    i(0),
  }, { condition = tex.in_mathzone }),
  s({
    trig = "@",
    snippetType = "autosnippet",
    trigEngine = "plain",
    wordTrig = false, -- allows triggering even when not at word boundary
  }, {
    c(1, {
      { t("\\citep{"), i(1), t("}") },
      { t("\\citet{"), i(1), t("}") },
      { t("\\cref{"), i(1), t("}") },
      { t("\\autoref{"), i(1), t("}") },
    }),
  }),
  s(
    { trig = "bxd", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\boxed{<>}<>]], {
      d(1, get_visual),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "ell", wordTrig = false, snippetType = "autosnippet" },
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
    fmta([[\hat{<>}<>]], {
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "what", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\widehat{<>}<>]], {
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "star", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\star]], {}),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "overline", wordTrig = false, snippetType = "autosnippet" },
    fmta([[<>\overline{<>}<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(1),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "Bar", wordTrig = false, snippetType = "autosnippet" },
    fmta([[<>\overline{<>}<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(1),
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
  s(
    { trig = "MM", wordTrig = false, regTrig = false, snippetType = "autosnippet" },
    c(1, {
      fmta(
        [[
\begin{align}
  <>
\end{align}<>]],
        {
          d(1, get_visual),
          i(0),
        }
      ),
      fmta(
        [[
\begin{align*}
  <>
\end{align*}<>]],
        {
          d(1, get_visual),
          i(0),
        }
      ),
      fmta(
        [[
\[
  <>
\]<>]],
        {
          d(1, get_visual),
          i(0),
        }
      ),
      fmta(
        [[
\begin{equation}
  <>
\end{equation}<>]],
        {
          d(1, get_visual),
          i(0),
        }
      ),
      fmta(
        [[
\begin{aligned}
  <>
\end{aligned}<>]],
        {
          d(1, get_visual),
          i(0),
        }
      ),
    }),
    { condition = line_begin }
  ),
  --   s(
  --     { trig = "MM", wordTrig = false, regTrig = false, snippetType = "autosnippet" },
  --     fmta(
  --       [[
  --
  -- \begin{align}
  --   <>
  -- \end{align}<>]],
  --       {
  --         d(1, get_visual),
  --         i(0),
  --       },
  --       { trim_empty = false }
  --     ),
  --     { condition = -line_begin * trigger_does_not_follow_alpha_char }
  --   ),
  s(
    { trig = "MM", wordTrig = false, regTrig = false, snippetType = "autosnippet" },
    c(1, {
      fmta(
        [[

\begin{align}
  <>
\end{align}<>]],
        {
          d(1, get_visual),
          i(0),
        },
        { trim_empty = false }
      ),
      fmta(
        [[

\begin{align*}
  <>
\end{align*}<>]],
        {
          d(1, get_visual),
          i(0),
        },
        { trim_empty = false }
      ),
      fmta(
        [[

\[
  <>
\]<>]],
        {
          d(1, get_visual),
          i(0),
        },
        { trim_empty = false }
      ),
      fmta(
        [[

\begin{equation}
  <>
\end{equation}<>]],
        {
          d(1, get_visual),
          i(0),
        },
        { trim_empty = false }
      ),
      fmta(
        [[

\begin{aligned}
  <>
\end{aligned}<>]],
        {
          d(1, get_visual),
          i(0),
        },
        { trim_empty = false }
      ),
    }),
    { condition = -line_begin * trigger_does_not_follow_alpha_char }
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
  s(
    { trig = "(%a)mb", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta([[\mathbf{<>}<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
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
  s(
    { trig = "(%a)mB", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta([[\mathbb{<>}<>]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "mf", wordTrig = false, snippetType = "autosnippet" },
    fmta([[\mathfrak{<>}<>]], {
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
  s(
    { trig = "sum", wordTrig = false, snippetType = "autosnippet" },
    fmta("\\sum_{<>}^{<>}<>", {
      d(1, get_visual),
      i(2),
      i(0),
    }),
    { condition = tex.in_mathzone * trigger_does_not_follow_alpha_char }
  ),
  s(
    { trig = "mc", wordTrig = false, snippetType = "autosnippet" },
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
    fmta(
      [[\chapter{<>}
<>]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
    { condition = tex.in_textzone }
  ),
  -- SECTION
  s(
    { trig = "h1", snippetType = "autosnippet" },
    fmta(
      [[\section{<>}
<>]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
    { condition = tex.in_textzone }
  ),
  -- SUBSECTION
  s(
    { trig = "h2", snippetType = "autosnippet" },
    fmta(
      [[\subsection{<>}
<>]],
      {
        d(1, get_visual),
        i(0),
      }
    ),
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
  s(
    { trig = "#[rR][eE][mM][aA][rR][kK]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
\begin{remark}[<>]\label{remark:<>}
<>
\end{remark}<>
      ]],
      {
        i(1),
        l(sanitize_label(l._1), 1),
        iv(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  -- TODO: Alias this with bte
  s(
    { trig = "#[tT][hH][eE][oO][rR][eE][mM]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
\begin{theorem}[<>]\label{theorem:<>}
<>
\end{theorem}<>
      ]],
      {
        i(1),
        l(sanitize_label(l._1), 1),
        iv(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  --TODO: alias this with `bde`
  s(
    { trig = "#[dD][eE][fF][iI][nN][iI][tT][iI][oO][nN]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
\begin{definition}[<>]\label{def:<>}
<>
\end{definition}<>
      ]],
      {
        i(1),
        l(sanitize_label(l._1), 1),
        iv(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "#[eE][xX][aA][mM][pP][lL][eE]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
\begin{example}[<>]\label{example:<>}
<>
\end{example}<>
      ]],
      {
        i(1),
        l(sanitize_label(l._1), 1),
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
\begin{proof}[<>]\label{proof:<>}
<>
\end{proof}<>
      ]],
      {
        i(1),
        l(sanitize_label(l._1), 1),
        iv(2),
        i(0),
      }
    ),
    { condition = line_begin }
  ),
  s(
    { trig = "#begin", regTrig = true, snippetType = "autosnippet" },
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
    { trig = "#[eE][qQ][uU]", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
\begin{equation}[<>]
\begin{aligned}
<>
\end{aligned}
\label{eq:<>}
\end{equation}<>
      ]],
      {
        i(1),
        l(sanitize_label(l._1), 1),
        iv(2),
        i(0),
      }
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
    \begin{<>}<>
    <>
    \end{<>}]],
      {
        f(function(_, snip)
          return ((snip.captures[1] == "") and "b" or snip.captures[1]) .. "matrix"
        end),
        f(function(_, snip)
          -- if snip.captures[4] == "a" then
          --   out = string.rep("c", tonumber(snip.captures[3]) - 1)
          --   return "[" .. out .. "|c]"
          -- end
          return ""
        end),
        d(1, generate_matrix),
        f(function(_, snip)
          return ((snip.captures[1] == "") and "b" or snip.captures[1]) .. "matrix"
        end),
      }
    ),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "(%d?)cases", name = "cases", desc = "cases", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
    \begin{cases}
    <>
    \end{cases}
    ]],
      { d(1, generate_cases) }
    ),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "(%d?)vec", name = "cases", desc = "cases", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
    \begin{pmatrix}
    <>
    \end{pmatrix}
    ]],
      { d(1, generate_vector) }
    ),
    { condition = tex.in_mathzone }
  ),
  s(
    {
      trig = "#itemize",
      name = "itemize environment",
      desc = "Create itemize environment",
      snippetType = "autosnippet",
    },
    fmta(
      [[
    \begin{itemize}
    \item <>
    \end{itemize}<>
    ]],
      { i(1), i(0) }
    )
  ),
  s(
    {
      trig = "#enumerate",
      name = "enumerate environment",
      desc = "Create enumerate environment",
      snippetType = "autosnippet",
    },
    fmta(
      [[
    \begin{enumerate}
    \item <>
    \end{enumerate}<>
    ]],
      { i(1), i(0) }
    )
  ),
  s(
    {
      trig = "#table",
      name = "Booktabs table",
      desc = "Booktabs-compliant table skeleton with SI/column notes",
      snippetType = "autosnippet",
    },
    fmta(
      [[
% Booktabs guidelines:
%   - No vertical rules; use whitespace + \cmidrule for logical groups.
%   - Keep units out of headers (prefer SI-style column formatting).
%   - Align numbers on decimal/comma via siunitx `S` columns when possible.
\begin{table}[<>] % placement: h=here, t=top, b=bottom, p=float page
  \caption{<>}
  \label{tab:<>}
  \centering
  % Column spec cheat sheet:
  %   l / c / r   = left / centered / right text.
  %   S[...]      = siunitx numeric column (aligns on decimal, handles units).
  %   p{len}    = fixed-width paragraph column.
  %   @{}         = suppress default inter-column padding.
  %   >>{\command} = apply formatting to a column (e.g. \raggedright).
  \begin{tabular}{
    l         % column 1: label column, left-aligned text
    r         % column 2: right-aligned numbers (fallback when not using S)
    S[        % column 3: siunitx numeric format example
      table-format = 1.2e2,
      round-mode = figures,
      round-precision = 2
    ]
    c         % column 4: centered text (e.g. success rate or categorical flag)
  }
    \toprule
    % Header rows: keep units/symbols in headers minimal.
    % Use \multicolumn + \cmidrule for grouped headers:
    % \multicolumn{2}{c}{Group} & ... \\
    % \cmidrule(lr){1-2}
    $\abs{\mathcal{D}}$ & $N_{X}$ & {\si{\flop}} & {Success rate} \\
    \midrule
    % Body rows: \num from siunitx to format numbers consistently.
    \num{64}   & \num{20} & \num{5.94e12}   & $6/6$ \\
    \num{3000} & \num{20} & \num{4.48e14}   & $6/6$ \\
    % Add more rows here…
    \bottomrule
  \end{tabular}
  % Optional: table notes (avoid footnotes in body)
  % \begin{tablenotes}[para,flushleft]
  %   \item Notes go here…
  % \end{tablenotes}
\end{table}
<>
]],
      {
        i(1, "t"), -- placement
        i(2, "Caption text"), -- caption
        i(3, "sample"), -- label suffix
        i(0), -- cursor continues here
      }
    )
  ),
  -- s(
  --   { trig = "-", name = "item", desc = "\\item in itemize environment", snippetType = "autosnippet" },
  --   t([[\item]]),
  --   { condition = tex.in_itemize }
  -- ),
}
