---@type LazySpec
return {
  "michaelfortunato/typst-preview.nvim",
  dev = true,
  ft = "typst",
  opts = {
    -- HACK: The issue is on firefox non private browser that opening
    -- 127.0.0.1:49810 caused it to be slow for some reason as compared
    -- to firefox private or safari regular. This fixes it though
    -- port = 49811,
    --open_cmd = "open http://localhost:49811",
    port = 41798,
    host = "127.0.0.1",
    -- open_cmd = "open -g -a 'Typst Preview' '%s'",
    open_cmd = [[bash -lc '
URL="$1"
SW="PS"

if command -v aerospace >/dev/null 2>&1; then
  CW="$(aerospace list-workspaces --focused --format "%%{workspace}" 2>/dev/null | head -n1 || true)"
  WID="$(aerospace list-windows --workspace "$SW" --format "%%{window-id}|%%{window-title}" | rg -m1 "\\|Typst Preview$" || true)"

  if [ -n "${CW:-}" ] && [ -n "${WID:-}" ] >/dev/null 2>&1; then
    aerospace move-node-to-workspace --window-id "$WID" "$CW" >/dev/null 2>&1 || true
    exit 0
  fi
fi

open -a "Typst Preview" "$URL"
' _ '%s']],
    debug = true,
    dependencies_bin = { ["tinymist"] = "tinymist" },
  },
  keys = {
    {
      "<localleader>p",
      "<Cmd>TypstPreview<CR>",
      desc = "Start preview of Typst document",
      ft = "typst", -- NOTE: Added file type so `,` remains localleader
    },
  },
}
