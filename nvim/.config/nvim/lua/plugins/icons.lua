--[[
Icon stack cheat sheet (what makes an icon render)
- Terminal font in Kitty/Ghostty: set to JetBrainsMono Nerd Font (or NL). That single font file contains both code text glyphs and the added symbol glyphs.
- Nerd Font “patching”: Nerd Fonts take a base font (JetBrains Mono) and inject icon glyphs from sets like Font Awesome/Codicons into the Unicode Private Use Area (PUA), mainly U+E000–F8FF. That’s why the font is called “patched”.
- Glyph vs symbol: a glyph is just the shape in the font; “symbols” are those extra PUA glyphs. If the font doesn’t have a glyph for a codepoint, the OS falls back to another font. Using a Nerd Font avoids fallback gaps.
- PUA specifics: The Unicode PUA blocks (BMP: U+E000–F8FF; Supplementary: U+F0000–FFFFD) are intentionally “unassigned” by Unicode. Nerd Fonts put icons there, so they never clash with real letters. A “code text” glyph (like the letter ‘A’ at U+0041) and a “symbol” glyph (like a folder icon at U+F07C) are both just glyphs mapped to different codepoints; one is standardized, the other lives in PUA.
- Why patching matters: Unpatched JetBrains Mono has only code-text glyphs. When Neovim asks to render U+F07C, the unpatched font has no glyph, so the OS either shows tofu (□) or substitutes another font (width/height may differ). A patched Nerd Font guarantees that PUA codepoints draw with the same metrics as your base font, keeping columns aligned.
- Provider layer (mini.icons): chooses which codepoint to emit for a given file/extension and what highlight to use. It doesn’t draw; it picks codepoints.
- Compatibility: mock_nvim_web_devicons() lets plugins that ask for nvim-web-devicons get mini.icons’ mappings instead.
- Current setup:
  * Font: JetBrainsMono Nerd Font loaded by Kitty/Ghostty (fonts typically live in ~/Library/Fonts or /Library/Fonts on macOS).
  * Provider: mini.icons with narrow defaults plus a specific README markdown icon.
  * Neo-tree spacing: indent 2, icon padding 1, single-width defaults to keep columns aligned.
- Tweaks you can do:
  * Change defaults here (default.file / default.directory) for global look.
  * Add per-file overrides in file = { ["NAME"] = { glyph = "...", hl = "..." } }.
  * Set style = "ascii" to ignore Nerd Font glyphs entirely (always single-width ASCII).
]]
return {
  "echasnovski/mini.icons",
  version = false,
  lazy = true,
  enabled = true,
  config = function()
    require("mini.icons").setup({
      style = "glyph", -- switch to "ascii" if you want guaranteed single-width fallbacks
      -- Provide explicit defaults to avoid mixed-width fallbacks
      default = {
        file = { glyph = "", hl = "MiniIconsGrey" },
        directory = { glyph = "", hl = "MiniIconsBlue" },
      },
      -- Per-file tweaks (keep compact markdown icon)
      file = {
        ["README.md"] = { glyph = "", hl = "MiniIconsGrey" },
      },
    })
    -- Make mini.icons act as nvim-web-devicons for plugin compatibility
    require("mini.icons").mock_nvim_web_devicons()
  end,
}
