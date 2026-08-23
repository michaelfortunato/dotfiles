---@diagnostic disable: undefined-global
---@module "luasnip"

-- local ls = require("luasnip")
-- local s = ls.snippet
-- local t = ls.text_node
-- local i = ls.insert_node
-- local c = ls.choice_node
-- local fmta = require("luasnip.extras.fmt").fmta
-- local line_begin = require("luasnip.extras.expand_conditions").line_begin

return {
  s({ trig = "tii", snippetType = "autosnippet" }, { t("_"), i(1), t("_"), i(0) }),
  -- s("fn", fmta("function <>(<>)\n  <>\nend", { i(1, "name"), i(2), i(0) })),
  -- s({ trig = "doc", snippetType = "autosnippet" }, t("TODO"), { condition = line_begin }),
  -- s("choice", c(1, { t("one"), t("two") })),
}
