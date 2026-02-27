# Save this as: ~/.ipython/profile_default/startup/catppuccin_theme.py
# Enhanced Catppuccin theme for IPython with Neovim-style completion menu and syntax highlighting

from IPython import get_ipython


ip = get_ipython()
logger = ip.log if ip else None


def mnf_log(msg, level):
    if logger:
        getattr(logger, level)(msg)
    # Fallback to print if no logger (shouldn't happen in IPython)
    else:
        print(msg)


def mnf_debug(msg):
    return mnf_log(msg, "debug")


def mnf_error(msg):
    return mnf_log(msg, "error")


def setup_catppuccin_neovim_theme():
    """Set up Catppuccin Latte/Mocha themes with Neovim-style completion menu and syntax highlighting."""
    try:
        import os
        from catppuccin import PALETTE
        from IPython.utils.PyColorize import Theme, theme_table
        from pygments.token import Token
        from prompt_toolkit.styles import Style

        def theme_name(flavor: str) -> str:
            return f"catppuccin-{flavor}"

        palettes = {
            "latte": PALETTE.latte.colors,
            "mocha": PALETTE.mocha.colors,
        }

        def make_token_style(colors, *, flavor: str):
            # Catppuccin Latte is a light theme; slightly darken comments to keep them readable
            comment = colors.overlay1 if flavor == "latte" else colors.overlay0
            tb_highlight = f"bg:{colors.red.hex} {colors.base.hex} bold"
            tb_bg = f"bg:{colors.surface1.hex}"
            return (
                {
                    # Text and whitespace
                    Token.Text: colors.text.hex,
                    Token.Whitespace: colors.base.hex,
                    # Keywords (purple/mauve like Neovim)
                    Token.Keyword: colors.mauve.hex,  # def, class, import, etc.
                    Token.Keyword.Constant: colors.mauve.hex,  # True, False, None
                    Token.Keyword.Declaration: colors.mauve.hex,  # def, class
                    Token.Keyword.Namespace: colors.mauve.hex,  # import, from
                    Token.Keyword.Pseudo: colors.pink.hex,  # self, super
                    Token.Keyword.Reserved: colors.mauve.hex,  # reserved keywords
                    Token.Keyword.Type: colors.yellow.hex,  # int, str, etc.
                    # Names and identifiers (refined for Neovim matching)
                    Token.Name: colors.text.hex,  # variable names
                    Token.Name.Attribute: colors.teal.hex,  # object.attribute
                    Token.Name.Builtin: colors.peach.hex,  # len, print, range
                    Token.Name.Builtin.Pseudo: colors.peach.hex,  # __name__, __file__
                    Token.Name.Class: colors.yellow.hex,  # class names
                    Token.Name.Constant: colors.peach.hex,  # CONSTANTS
                    Token.Name.Decorator: colors.blue.hex,  # @decorator
                    Token.Name.Entity: colors.blue.hex,  # entities
                    Token.Name.Exception: f"bold {colors.red.hex}",  # Exception classes
                    Token.Name.Function: colors.blue.hex,  # function names
                    Token.Name.Function.Magic: colors.blue.hex,  # __init__, __str__
                    Token.Name.Label: colors.blue.hex,  # labels
                    Token.Name.Namespace: colors.peach.hex,  # module names
                    Token.Name.Other: colors.text.hex,  # other names
                    Token.Name.Property: colors.teal.hex,  # properties
                    Token.Name.Tag: colors.pink.hex,  # HTML/XML tags
                    Token.Name.Variable: colors.text.hex,  # variables
                    Token.Name.Variable.Class: colors.text.hex,  # class variables
                    Token.Name.Variable.Global: colors.text.hex,  # global variables
                    Token.Name.Variable.Instance: colors.text.hex,  # instance variables
                    Token.Name.Variable.Magic: colors.pink.hex,  # __dict__, etc.
                    # Literals
                    Token.Literal: colors.text.hex,
                    # Strings (green like Neovim)
                    Token.String: colors.green.hex,  # "string"
                    Token.String.Affix: colors.green.hex,  # r, f, b prefixes
                    Token.String.Backtick: colors.green.hex,  # `backtick`
                    Token.String.Char: colors.green.hex,  # 'c'
                    Token.String.Delimiter: colors.green.hex,  # string delimiters
                    Token.String.Doc: f"italic {colors.green.hex}",  # """docstring"""
                    Token.String.Double: colors.green.hex,  # "double quoted"
                    Token.String.Escape: colors.pink.hex,  # \n, \t, etc.
                    Token.String.Heredoc: colors.green.hex,  # heredoc strings
                    Token.String.Interpol: colors.pink.hex,  # f"{interpolation}"
                    Token.String.Other: colors.green.hex,  # other string types
                    Token.String.Regex: colors.green.hex,  # regex strings
                    Token.String.Single: colors.green.hex,  # 'single quoted'
                    Token.String.Symbol: colors.green.hex,  # symbols
                    # Numbers (peach/orange like Neovim)
                    Token.Number: colors.peach.hex,  # 123
                    Token.Number.Bin: colors.peach.hex,  # 0b101
                    Token.Number.Float: colors.peach.hex,  # 1.23
                    Token.Number.Hex: colors.peach.hex,  # 0xff
                    Token.Number.Integer: colors.peach.hex,  # 123
                    Token.Number.Integer.Long: colors.peach.hex,  # 123L
                    Token.Number.Oct: colors.peach.hex,  # 0o777
                    # Comments (overlay/gray like Neovim)
                    Token.Comment: f"italic {comment.hex}",  # # comment
                    Token.Comment.Hashbang: f"italic {comment.hex}",  # #!/usr/bin/env
                    Token.Comment.Multiline: f"italic {comment.hex}",  # /* multiline */
                    Token.Comment.Preproc: f"italic {comment.hex}",  # preprocessor
                    Token.Comment.PreprocFile: f"italic {comment.hex}",  # included files
                    Token.Comment.Single: f"italic {comment.hex}",  # // single line
                    Token.Comment.Special: f"italic bold {comment.hex}",  # special comments
                    # Operators and punctuation
                    Token.Operator: colors.sky.hex,  # +, -, *, /
                    Token.Operator.Word: colors.mauve.hex,  # and, or, not, in
                    Token.Punctuation: colors.overlay2.hex,  # (), [], {}, ;
                    # Generic tokens
                    Token.Generic: colors.text.hex,
                    Token.Generic.Deleted: colors.red.hex,  # deleted lines
                    Token.Generic.Emph: f"italic {colors.text.hex}",  # emphasized
                    Token.Generic.Error: f"{tb_bg} {colors.red.hex} bold",  # error text
                    Token.Generic.Heading: f"bold {colors.blue.hex}",  # headings
                    Token.Generic.Inserted: colors.green.hex,  # inserted lines
                    Token.Generic.Output: colors.text.hex,  # program output
                    Token.Generic.Prompt: f"bold {colors.lavender.hex}",  # prompts
                    Token.Generic.Strong: f"bold {colors.text.hex}",  # strong text
                    Token.Generic.Subheading: f"bold {colors.blue.hex}",  # subheadings
                    Token.Generic.Traceback: f"{tb_bg} {colors.text.hex}",  # tracebacks
                    Token.Traceback: f"{tb_bg} {colors.text.hex}",
                    # Error tokens
                    Token.Error: f"{tb_bg} {colors.red.hex} bold",
                    # IPython specific prompt tokens
                    Token.Prompt: f"bold {colors.lavender.hex}",  # In [1]:
                    Token.PromptNum: f"bold {colors.blue.hex}",  # [1]
                    Token.OutPrompt: f"bold {colors.pink.hex}",  # Out[1]:
                    Token.OutPromptNum: f"bold {colors.pink.hex}",  # [1]
                    # Additional IPython tokens
                    Token.Normal: colors.text.hex,
                    Token.NormalEm: f"bold {colors.text.hex}",
                    Token.Line: colors.overlay1.hex,
                    Token.TB.Name: f"{tb_bg} {colors.blue.hex}",
                    Token.TB.NameEm: f"bold {tb_bg} {colors.blue.hex}",
                    Token.Breakpoint: "",
                    Token.Breakpoint.Enabled: colors.green.hex,
                    Token.Breakpoint.Disabled: colors.overlay0.hex,
                    Token.Prompt.Continuation: colors.overlay1.hex,
                },
                tb_highlight,
            )

        def make_completion_style(colors):
            return Style.from_dict(
                {
                    # Completion menu styling (Neovim-style)
                    "completion-menu": f"bg:{colors.surface0.hex} {colors.text.hex}",
                    "completion-menu.completion": f"bg:{colors.surface0.hex} {colors.text.hex}",
                    "completion-menu.completion.current": f"bg:{colors.blue.hex} {colors.base.hex} bold",
                    # Type information / meta (more distinct than main completion)
                    "completion-menu.meta": f"bg:{colors.mantle.hex} {colors.yellow.hex} italic",
                    "completion-menu.meta.current": f"bg:{colors.peach.hex} {colors.base.hex} bold",
                    "completion-menu.multi-column-meta": f"bg:{colors.mantle.hex} {colors.yellow.hex} italic",
                    "completion-menu.progress-bar": f"bg:{colors.overlay0.hex}",
                    "completion-menu.progress-button": f"bg:{colors.blue.hex}",
                    # Scrollbar
                    "scrollbar": f"{colors.overlay0.hex}",
                    "scrollbar.background": f"bg:{colors.surface0.hex}",
                    "scrollbar.button": f"bg:{colors.blue.hex}",
                    "scrollbar.arrow": f"{colors.text.hex}",
                    # Menu borders
                    "menu-border": f"{colors.overlay0.hex}",
                    "menu-border.shadow": f"{colors.crust.hex}",
                    # Additional styling
                    "bottom-toolbar": f"bg:{colors.mantle.hex} {colors.text.hex}",
                    "search": f"bg:{colors.yellow.hex} {colors.base.hex}",
                    "search.current": f"bg:{colors.peach.hex} {colors.base.hex}",
                    "system": f"{colors.red.hex}",
                    "arg-toolbar": f"bg:{colors.surface0.hex} {colors.text.hex}",
                    "search-toolbar": f"bg:{colors.surface0.hex} {colors.text.hex}",
                    "validation-toolbar": f"bg:{colors.red.hex} {colors.base.hex}",
                    # Traceback styling to keep highlighted frames readable
                    "pygments.generic.traceback": f"bg:{colors.surface1.hex} {colors.text.hex}",
                    "pygments.traceback": f"bg:{colors.surface1.hex} {colors.text.hex}",
                    "pygments.generic.error": f"bg:{colors.surface1.hex} {colors.red.hex} bold",
                    "pygments.error": f"bg:{colors.surface1.hex} {colors.red.hex} bold",
                    "pygments.tb.name": f"bg:{colors.surface1.hex} {colors.blue.hex}",
                    "pygments.tb.nameem": f"bold bg:{colors.surface1.hex} {colors.blue.hex}",
                }
            )

        completion_styles = {}
        tb_highlights = {}

        # Create and register each theme in IPython's theme table
        for flavor, colors in palettes.items():
            extra_style, tb_highlight = make_token_style(colors, flavor=flavor)
            name = theme_name(flavor)
            theme_table[name] = Theme(
                name=name,
                base=None,  # No base pygments style
                extra_style=extra_style,
                symbols={
                    "arrow_body": "─",
                    "arrow_head": "▶",
                    "top_line": "─",
                },
            )
            completion_styles[name] = make_completion_style(colors)
            tb_highlights[name] = tb_highlight

        # Apply the selected theme
        ip = get_ipython()
        if ip:
            flavor = os.environ.get("IPYTHON_CATPPUCCIN_FLAVOR", "latte").lower()
            if flavor not in palettes:
                flavor = "latte"
            selected = theme_name(flavor)

            ip.config.InteractiveShell.colors = selected
            ip.config.TerminalInteractiveShell.true_color = True

            def apply_tb_highlight(theme: str) -> None:
                highlight = tb_highlights.get(theme)
                if not highlight:
                    return
                try:
                    from IPython.core import ultratb

                    ultratb.VerboseTB.tb_highlight = highlight
                    ultratb.FormattedTB.tb_highlight = highlight
                    ultratb.AutoFormattedTB.tb_highlight = highlight
                    if hasattr(ip, "InteractiveTB"):
                        ip.InteractiveTB.tb_highlight = highlight
                except Exception as e:
                    mnf_error(f"⚠️  Failed to adjust traceback highlight: {e}")

            apply_tb_highlight(selected)

            # Try to apply the custom style to the shell
            try:
                if hasattr(ip, "_make_style_from_name_or_cls"):
                    # Inject completion menu styling, keyed off the active color scheme
                    original_make_style = ip._make_style_from_name_or_cls

                    def enhanced_make_style(name_or_cls):
                        base_style = original_make_style(name_or_cls)

                        scheme = None
                        if isinstance(name_or_cls, str):
                            scheme = name_or_cls
                        elif hasattr(name_or_cls, "name"):
                            scheme = name_or_cls.name

                        if scheme in tb_highlights:
                            apply_tb_highlight(scheme)

                        completion_style = completion_styles.get(scheme) or completion_styles.get(
                            selected
                        )
                        if not completion_style:
                            return base_style

                        try:
                            from prompt_toolkit.styles import merge_styles

                            return merge_styles([base_style, completion_style])
                        except ImportError:
                            return base_style

                    ip._make_style_from_name_or_cls = enhanced_make_style

                mnf_debug(
                    f"🎨 Enhanced Catppuccin {flavor.title()} theme with Neovim-style completion applied!"
                )
                mnf_debug("   ✨ Improved syntax highlighting to match Neovim")
                mnf_debug("   🔍 Styled completion menu with Catppuccin selection colors")
            except Exception as e:
                mnf_error(f"⚠️  Theme applied but completion styling failed: {e}")
                mnf_error(f"🎨 Catppuccin {flavor.title()} theme applied (basic version)")

            mnf_debug("   Themes available as: catppuccin-latte, catppuccin-mocha")
            mnf_debug("   Switch with: %colors catppuccin-latte (or catppuccin-mocha)")

        return True

    except ImportError as e:
        mnf_error(f"❌ Missing dependency: {e}")
        mnf_error("   Install with: uv add catppuccin")
        return False
    except Exception as e:
        mnf_error(f"❌ Error setting up enhanced Catppuccin theme: {e}")
        import traceback

        traceback.print_exc()
        return False


# Set up the enhanced theme
setup_catppuccin_neovim_theme()
