local get_visual = function(args, parent)
  if #parent.snippet.env.LS_SELECT_RAW > 0 then
    return sn(nil, i(1, parent.snippet.env.LS_SELECT_RAW))
  else -- If LS_SELECT_RAW is empty, return a blank insert node
    return sn(nil, i(1))
  end
end

local line_begin = require("luasnip.extras.expand_conditions").line_begin
return {
  s(
    { trig = "rdoc", snippetType = "autosnippet" },
    fmta(
      [[
    # This Makefile is to run commands. While justfiles are better purposed
    # It is unlikely Make will go away and it works well enough for my needs.
    .PHONY: <> <> <> clean
    <>:
    \#techo 'TODO'
    <>:
    \t#echo 'TODO'
    <>:
    \t#echo 'TODO'
    clean:
    \t#echo 'TODO'
   ]],
      {
        rep(1),
        rep(2),
        rep(3),
        i(1, "command1"),
        i(2, "command2"),
        i(3, "command3"),
      }
    ),
    { condition = line_begin }
  ),
}

-- return {
--   s(
--     { trig = "tdoc", snippetType = "autosnippet" },
--     fmta([[foo<>]], i(1))
--
--     -- { condition = line_begin } --TODO: Condition should be begining of file!
--   ),
--   s(
--     { trig = "doc", snippetType = "autosnippet" },
--     fmta(
--       [[
--       CC=gcc
--       CFLAGS=""
--       DBGFLAGS := -g
--       COBJFLAGS := $(CFLAGS) -c
--       # path macros
--       BIN_DIR := bin
--       OBJ_DIR := obj
--       SRC_DIR := src
--       all:
--         <>
--       build <>:
--         <>
--       install <>:
--         <>
--       clean:
--         <>
--      ]],
--       {
--         i(1),
--         i(2),
--         i(3),
--         i(4),
--         i(5),
--         i(6),
--       }
--     )
--     -- { condition = line_begin } --TODO: Condition should be begining of file!
--   ),
--   -- Make is not a runner, but it is lol. Use make as a runner here.
--   s(
--     { trig = "rdoc", snippetType = "autosnippet" },
--     fmta(
--       [[
--       # This Makefile is to run commands. While justfiles are better purposed
--       # It is unlikely Make will go away and it works well enough for my needs.
--       .PHONY: <> <> <>
--       <>:
--         # echo 'TODO'
--       <>:
--         # echo 'TODO'
--       <>:
--         # echo 'TODO'
--       clean:
--         # echo 'TODO'
--      ]],
--       {
--         rep(1),
--         rep(2),
--         rep(3),
--         i(1, "command1"),
--         i(2, "command2"),
--         i(3, "command3"),
--       }
--     ),
--     { condition = line_begin }
--   ),
--   -- s(
--   --   { trig = "all", snippetType = "autosnippet" },
--   --   fmta(
--   --     [[
--   --     all:
--   --       <>
--   --    ]],
--   --     {
--   --       i(1),
--   --     }
--   --   ),
--   --   { condition = line_begin }
--   -- ),
-- }
