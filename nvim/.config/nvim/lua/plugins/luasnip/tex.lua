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
--
--
local PRIORITY = 10000

local get_visual = function(args, parent)
  if #parent.snippet.env.LS_SELECT_RAW > 0 then
    return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
  else -- If LS_SELECT_RAW is empty, return a blank insert node
    return sn(nil, i(1))
  end
end

local line_begin = require("luasnip.extras.expand_conditions").line_begin

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
    { trig = "DOC", regTrig = true, snippetType = "autosnippet" },
    fmta(
      [[
\documentclass[10pt, letterpaper]{article}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsthm}
\usepackage{mathtools}
%
\newtheorem{theorem}{Theorem}[section]
\newtheorem{lemma}[theorem]{Lemma}
\theoremstyle{definition}
\newtheorem{definition}{Definition}[section]
\theoremstyle{remark}
\newtheorem*{remark}{Remark}
%
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
    { trig = "([^%a])toc", priority = PRIORITY, wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    t("\\tableofcontents"),
    { condition = line_begin }
  ),
  -- SUBSCRIPT
  s(
    { trig = "([%w%)%]%}])ss", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
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
    fmta("<>^{-1}<>", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      i(0),
    }),
    { condition = tex.in_mathzone }
  ),
  -- SUPERSCRIPT
  s(
    { trig = "([%w%)%]%}])SS", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>^{<>}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  -- --- Let ".." namespace commonly used operators for me
  s({ trig = "..g", snippetType = "autosnippet" }, t("\\nabla"), { condition = tex.in_mathzone }),
  s({ trig = "..p", snippetType = "autosnippet" }, t("\\partial"), { condition = tex.in_mathzone }),
  -- ESCAPED PARENTHESES (notice that e( or e) works, lest I hit the wrong one!)
  -- Note, that we specify the priority high so that e) works quickly.
  s(
    { trig = "([^%a])e[%(%)]", regTrig = true, PRIORITY = 1000, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\left(<>\\right)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  -- e(SCAPED) BRACES
  s(
    { trig = "([^%a])e[%[%]]", regTrig = true, PRIORITY = 1000, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\left[<>\\right]", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  -- e(SCAPED) CURLY BRACES
  s(
    { trig = "([^%a])e[%{%}]", regTrig = true, PRIORITY = 1000, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\left\\{<>\\right\\}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
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
  s({ trig = "x.", snippetType = "autosnippet" }, {
    t("\\cdot "),
  }, { condition = tex.in_mathzone }),
  -- \times
  s({ trig = "xx", snippetType = "autosnippet" }, {
    t("\\times "),
  }, { condition = tex.in_mathzone }),
  -- CDOTS, i.e. \cdots
  s({ trig = "c.", snippetType = "autosnippet" }, {
    t("\\cdots"),
  }, { condition = tex.in_mathzone }),
  -- LDOTS, i.e. \ldots
  s({ trig = "l.", snippetType = "autosnippet" }, {
    t("\\ldots"),
  }, { condition = tex.in_mathzone }),
  --- Enter display mode quickly
  s(
    { trig = "([^%a]?)MM", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>\\[<>\\]", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
  ),
  --- Enter inline mathmode quickly
  s(
    { trig = "([^%a]?)mm", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta([[<>$<>$]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
  ),
  -- Define vectors and matrices quickly
  s(
    { trig = "([^%a])mb", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta([[<>\mathbf{<>}]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
    -- { condition = tex.in_mathzone }
  ),
  s(
    { trig = "([^%a])mB", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta([[<>\mathbb{<>}]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
    -- { condition = tex.in_mathzone }
  ),
  -- FRACTION
  s(
    { trig = "([^%a])ff", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>\\frac{<>}{<>}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
      i(2),
    }),
    { condition = tex.in_mathzone }
  ),
  -- SUMMATION
  s(
    { trig = "([^%a])su", wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>\\sum_{<>}^{<>}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
      i(2),
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
        \begin{align*}
            <>
        \end{align*}
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
    )
  ),
  s(
    { trig = "b[eb]", regTrig = true, snippetType = "autosnippet" },
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
    { trig = "(the)|(bte)", regTrig = true, snippetType = "autosnippet" },
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
    { trig = "(def)|(bde)", regTrig = true, snippetType = "autosnippet" },
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
    { trig = "(pro)|(bpr)", regTrig = true, snippetType = "autosnippet" },
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
    { trig = "(rem)|(bre)", snippetType = "autosnippet" },
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
    { trig = "nc", snippetType = "autosnippet" },
    fmta([[\newcommand{<>}{<>}]], {
      i(1),
      i(2),
    }),
    { condition = line_begin }
  ),
}
