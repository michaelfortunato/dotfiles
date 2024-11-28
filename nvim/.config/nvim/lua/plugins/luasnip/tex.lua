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
-- s({trig = "h1", dscr="Top-level section"},
--   fmta(
--     [[\section{<>}]],
--     { i(1) }
--   ),
--   {condition = line_begin}  -- set condition in the `opts` table
-- ),
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
tex.in_text = function()
  return not tex.in_mathzone()
end

return {
  --- mdoc
  s(
    { trig = "mdoc", snippetType = "autosnippet" },
    fmta(
      [[
\documentclass[10pt, letterpaper]{article}
\usepackage{amsmath}
\usepackage{amssym}
\usepackage{amsthm}
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
    { condition = line_begin }
  ),
  s(
    { trig = "([^%a])toc", priority = PRIORITY, wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    t("\\tableofcontents"),
    { condition = line_begin }
  ),
  -- LEFT/RIGHT PARENTHESES
  s(
    { trig = "([^%a])l%(", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\left(<>\\right)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
  ),
  -- LEFT/RIGHT SQUARE BRACES
  s(
    { trig = "([^%a])l%[", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\left[<>\\right]", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
  ),
  -- LEFT/RIGHT CURLY BRACES
  s(
    { trig = "([^%a])l%{", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\left\\{<>\\right\\}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
  ),
  -- BIG PARENTHESES
  s(
    { trig = "([^%a])b%(", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\big(<>\\big)", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
  ),
  -- BIG SQUARE BRACES
  s(
    { trig = "([^%a])b%[", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\big[<>\\big]", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
  ),
  -- BIG CURLY BRACES
  s(
    { trig = "([^%a])b%{", regTrig = true, wordTrig = false, snippetType = "autosnippet" },
    fmta("<>\\big\\{<>\\big\\}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
  ),
  -- ESCAPED CURLY BRACES
  s(
    { trig = "([^%a])\\%{", regTrig = true, wordTrig = false, snippetType = "autosnippet", priority = 2000 },
    fmta("<>\\{<>\\}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    })
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
  s({ trig = "cdo", snippetType = "autosnippet" }, {
    t("\\cdots"),
  }, { condition = tex.in_mathzone }),
  -- LDOTS, i.e. \ldots
  s({ trig = "ldo", snippetType = "autosnippet" }, {
    t("\\ldots"),
  }, { condition = tex.in_mathzone }),
  --- Enter display mode quickly
  s(
    { trig = "([^%a]?)MM", priority = PRIORITY, wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta("<>\\[<>\\]", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_text }
  ),
  --- Enter inline mathmode quickly
  s(
    { trig = "([^%a]?)mm", priority = PRIORITY, wordTrig = false, regTrig = true, snippetType = "autosnippet" },
    fmta([[<>$<>$]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_text }
  ),
  -- Define vectors and matrices quickly
  s(
    { trig = "([^%a])mb", wordTrig = false, regTrig = true, priority = PRIORITY, snippetType = "autosnippet" },
    fmta([[<>\mathbf{<>}]], {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  s(
    { trig = "([^%a])mB", regTrig = true, wordTrig = false, priority = PRIORITY, snippetType = "autosnippet" },
    fmta("<>\\mathbb{<>}", {
      f(function(_, snip)
        return snip.captures[1]
      end),
      d(1, get_visual),
    }),
    { condition = tex.in_mathzone }
  ),
  --- PART (only applicable to book document class)
  s(
    { trig = "h-1", snippetType = "autosnippet" },
    fmta([[\part{<>}]], {
      d(1, get_visual),
    })
  ),
  --- CHAPTER (only applicable to book document class)
  s(
    { trig = "h0", snippetType = "autosnippet" },
    fmta([[\chapter{<>}]], {
      d(1, get_visual),
    })
  ),
  -- SECTION
  s(
    { trig = "h1", snippetType = "autosnippet" },
    fmta([[\section{<>}]], {
      d(1, get_visual),
    })
  ),
  -- SUBSECTION
  s(
    { trig = "h2", snippetType = "autosnippet" },
    fmta([[\subsection{<>}]], {
      d(1, get_visual),
    })
  ),
  -- SUBSUBSECTION
  s(
    { trig = "h3", snippetType = "autosnippet" },
    fmta([[\subsubsection{<>}]], {
      d(1, get_visual),
    })
  ),
  s(
    { trig = "h4", snippetType = "autosnippet" },
    fmta([[\paragraph{<>}]], {
      d(1, get_visual),
    })
  ),
  s(
    { trig = "h5", snippetType = "autosnippet" },
    fmta([[\subparagraph{<>}]], {
      d(1, get_visual),
    })
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
    { trig = "bb", snippetType = "autosnippet" },
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
    { trig = "bte", snippetType = "autosnippet" },
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
    { trig = "bde", snippetType = "autosnippet" },
    fmta(
      [[
        \begin{definitio}
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
    { trig = "bpro", snippetType = "autosnippet" },
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
}
