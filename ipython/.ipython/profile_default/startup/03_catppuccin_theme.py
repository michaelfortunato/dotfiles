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
    """Set up Catppuccin Mocha theme with Neovim-style completion menu and exact syntax highlighting."""
    try:
        import catppuccin
        from catppuccin import PALETTE
        from IPython.utils.PyColorize import Theme, theme_table
        from pygments.token import Token
        from prompt_toolkit.styles import Style
        from prompt_toolkit.formatted_text import HTML

        # Catppuccin Mocha color palette
        mocha = PALETTE.mocha.colors

        # Enhanced token mapping to match Neovim's syntax highlighting more closely
        catppuccin_extra_style = {
            # Text and whitespace
            Token.Text: mocha.text.hex,
            Token.Whitespace: mocha.base.hex,
            # Keywords (purple/mauve like Neovim)
            Token.Keyword: mocha.mauve.hex,  # def, class, import, etc.
            Token.Keyword.Constant: mocha.mauve.hex,  # True, False, None
            Token.Keyword.Declaration: mocha.mauve.hex,  # def, class
            Token.Keyword.Namespace: mocha.mauve.hex,  # import, from (Neovim uses same color)
            Token.Keyword.Pseudo: mocha.pink.hex,  # self, super
            Token.Keyword.Reserved: mocha.mauve.hex,  # reserved keywords
            Token.Keyword.Type: mocha.yellow.hex,  # int, str, etc.
            # Names and identifiers (refined for Neovim matching)
            Token.Name: mocha.text.hex,  # variable names
            Token.Name.Attribute: mocha.teal.hex,  # object.attribute (teal in Neovim)
            Token.Name.Builtin: mocha.peach.hex,  # len, print, range (orange in Neovim)
            Token.Name.Builtin.Pseudo: mocha.peach.hex,  # __name__, __file__
            Token.Name.Class: mocha.yellow.hex,  # class names (yellow in Neovim)
            Token.Name.Constant: mocha.peach.hex,  # CONSTANTS
            Token.Name.Decorator: mocha.blue.hex,  # @decorator (blue in Neovim)
            Token.Name.Entity: mocha.blue.hex,  # entities
            Token.Name.Exception: f"bold {mocha.red.hex}",  # Exception classes
            Token.Name.Function: mocha.blue.hex,  # function names (blue in Neovim)
            Token.Name.Function.Magic: mocha.blue.hex,  # __init__, __str__
            Token.Name.Label: mocha.blue.hex,  # labels
            Token.Name.Namespace: mocha.peach.hex,  # module names
            Token.Name.Other: mocha.text.hex,  # other names
            Token.Name.Property: mocha.teal.hex,  # properties
            Token.Name.Tag: mocha.pink.hex,  # HTML/XML tags
            Token.Name.Variable: mocha.text.hex,  # variables
            Token.Name.Variable.Class: mocha.text.hex,  # class variables
            Token.Name.Variable.Global: mocha.text.hex,  # global variables
            Token.Name.Variable.Instance: mocha.text.hex,  # instance variables
            Token.Name.Variable.Magic: mocha.pink.hex,  # __dict__, etc.
            # Literals
            Token.Literal: mocha.text.hex,
            # Strings (green like Neovim)
            Token.String: mocha.green.hex,  # "string"
            Token.String.Affix: mocha.green.hex,  # r, f, b prefixes
            Token.String.Backtick: mocha.green.hex,  # `backtick`
            Token.String.Char: mocha.green.hex,  # 'c'
            Token.String.Delimiter: mocha.green.hex,  # string delimiters
            Token.String.Doc: f"italic {mocha.green.hex}",  # """docstring"""
            Token.String.Double: mocha.green.hex,  # "double quoted"
            Token.String.Escape: mocha.pink.hex,  # \n, \t, etc. (pink in Neovim)
            Token.String.Heredoc: mocha.green.hex,  # heredoc strings
            Token.String.Interpol: mocha.pink.hex,  # f"{interpolation}"
            Token.String.Other: mocha.green.hex,  # other string types
            Token.String.Regex: mocha.green.hex,  # regex strings
            Token.String.Single: mocha.green.hex,  # 'single quoted'
            Token.String.Symbol: mocha.green.hex,  # symbols
            # Numbers (peach/orange like Neovim)
            Token.Number: mocha.peach.hex,  # 123
            Token.Number.Bin: mocha.peach.hex,  # 0b101
            Token.Number.Float: mocha.peach.hex,  # 1.23
            Token.Number.Hex: mocha.peach.hex,  # 0xff
            Token.Number.Integer: mocha.peach.hex,  # 123
            Token.Number.Integer.Long: mocha.peach.hex,  # 123L
            Token.Number.Oct: mocha.peach.hex,  # 0o777
            # Comments (overlay0/gray like Neovim)
            Token.Comment: f"italic {mocha.overlay0.hex}",  # # comment
            Token.Comment.Hashbang: f"italic {mocha.overlay0.hex}",  # #!/usr/bin/env
            Token.Comment.Multiline: f"italic {mocha.overlay0.hex}",  # /* multiline */
            Token.Comment.Preproc: f"italic {mocha.overlay0.hex}",  # preprocessor
            Token.Comment.PreprocFile: f"italic {mocha.overlay0.hex}",  # included files
            Token.Comment.Single: f"italic {mocha.overlay0.hex}",  # // single line
            Token.Comment.Special: f"italic bold {mocha.overlay0.hex}",  # special comments
            # Operators and punctuation
            Token.Operator: mocha.sky.hex,  # +, -, *, /
            Token.Operator.Word: mocha.mauve.hex,  # and, or, not, in
            Token.Punctuation: mocha.overlay2.hex,  # (), [], {}, ;
            # Generic tokens
            Token.Generic: mocha.text.hex,
            Token.Generic.Deleted: mocha.red.hex,  # deleted lines
            Token.Generic.Emph: f"italic {mocha.text.hex}",  # emphasized
            Token.Generic.Error: f"bold {mocha.red.hex}",  # error text
            Token.Generic.Heading: f"bold {mocha.blue.hex}",  # headings
            Token.Generic.Inserted: mocha.green.hex,  # inserted lines
            Token.Generic.Output: mocha.text.hex,  # program output
            Token.Generic.Prompt: f"bold {mocha.lavender.hex}",  # prompts
            Token.Generic.Strong: f"bold {mocha.text.hex}",  # strong text
            Token.Generic.Subheading: f"bold {mocha.blue.hex}",  # subheadings
            Token.Generic.Traceback: mocha.red.hex,  # tracebacks
            # Error tokens
            Token.Error: f"bold {mocha.red.hex}",  # error tokens
            # IPython specific prompt tokens
            Token.Prompt: f"bold {mocha.lavender.hex}",  # In [1]:
            Token.PromptNum: f"bold {mocha.blue.hex}",  # [1]
            Token.OutPrompt: f"bold {mocha.pink.hex}",  # Out[1]:
            Token.OutPromptNum: f"bold {mocha.pink.hex}",  # [1]
            # Additional IPython tokens
            Token.Normal: mocha.text.hex,
            Token.NormalEm: f"bold {mocha.text.hex}",
            Token.Line: mocha.overlay1.hex,
            Token.TB.Name: mocha.blue.hex,
            Token.TB.NameEm: f"bold {mocha.blue.hex}",
            Token.Breakpoint: "",
            Token.Breakpoint.Enabled: mocha.green.hex,
            Token.Breakpoint.Disabled: mocha.overlay0.hex,
            Token.Prompt.Continuation: mocha.overlay1.hex,
        }

        # Create the theme using IPython's Theme class
        catppuccin_theme = Theme(
            name="catppuccin-mocha",
            base=None,  # No base pygments style
            extra_style=catppuccin_extra_style,
            symbols={
                "arrow_body": "─",  # Unicode line drawing
                "arrow_head": "▶",  # Unicode triangle
                "top_line": "─",  # Unicode line drawing
            },
        )

        # Register the theme in IPython's theme table
        theme_table["catppuccin-mocha"] = catppuccin_theme

        # Apply the theme
        ip = get_ipython()
        if ip:
            # Set the theme in config
            ip.config.InteractiveShell.colors = "catppuccin-mocha"
            ip.config.TerminalInteractiveShell.true_color = True

            # Create a custom prompt_toolkit style for the completion menu (Neovim-style)
            completion_style = Style.from_dict(
                {
                    # Completion menu styling (dark background, light text like Neovim)
                    "completion-menu": f"bg:{mocha.surface0.hex} {mocha.text.hex}",
                    "completion-menu.completion": f"bg:{mocha.surface0.hex} {mocha.text.hex}",
                    "completion-menu.completion.current": f"bg:{mocha.blue.hex} {mocha.base.hex} bold",  # Blue highlight like Neovim
                    # Enhanced type information styling - more distinct from main completion
                    "completion-menu.meta": f"bg:{mocha.mantle.hex} {mocha.yellow.hex} italic",  # Darker background, yellow text for type info
                    "completion-menu.meta.current": f"bg:{mocha.peach.hex} {mocha.base.hex} bold",  # Orange highlight when selected
                    "completion-menu.multi-column-meta": f"bg:{mocha.mantle.hex} {mocha.yellow.hex} italic",  # Consistent with meta
                    "completion-menu.progress-bar": f"bg:{mocha.overlay0.hex}",
                    "completion-menu.progress-button": f"bg:{mocha.blue.hex}",
                    # Scrollbar
                    "scrollbar": f"{mocha.overlay0.hex}",
                    "scrollbar.background": f"bg:{mocha.surface0.hex}",
                    "scrollbar.button": f"bg:{mocha.blue.hex}",
                    "scrollbar.arrow": f"{mocha.text.hex}",
                    # Menu borders
                    "menu-border": f"{mocha.overlay0.hex}",
                    "menu-border.shadow": f"{mocha.crust.hex}",
                    # Additional styling for better Neovim feel
                    "bottom-toolbar": f"bg:{mocha.mantle.hex} {mocha.text.hex}",
                    "search": f"bg:{mocha.yellow.hex} {mocha.base.hex}",
                    "search.current": f"bg:{mocha.peach.hex} {mocha.base.hex}",
                    "system": f"{mocha.red.hex}",
                    "arg-toolbar": f"bg:{mocha.surface0.hex} {mocha.text.hex}",
                    "search-toolbar": f"bg:{mocha.surface0.hex} {mocha.text.hex}",
                    "validation-toolbar": f"bg:{mocha.red.hex} {mocha.base.hex}",
                }
            )

            # Try to apply the custom style to the shell
            try:
                # Set the custom completion style
                if hasattr(ip, "_make_style_from_name_or_cls"):
                    # This is a bit of a hack to inject our completion menu styling
                    original_make_style = ip._make_style_from_name_or_cls

                    def enhanced_make_style(name_or_cls):
                        base_style = original_make_style(name_or_cls)
                        # Merge our completion style with the base style
                        try:
                            from prompt_toolkit.styles import merge_styles

                            return merge_styles([base_style, completion_style])
                        except ImportError:
                            # Fallback if merge_styles isn't available
                            return base_style

                    ip._make_style_from_name_or_cls = enhanced_make_style

                # Force apply the theme using the magic command
                # ip.magic("colors catppuccin-mocha")
                mnf_debug(
                    "🎨 Enhanced Catppuccin Mocha theme with Neovim-style completion applied!"
                )
                mnf_debug("   ✨ Improved syntax highlighting to match Neovim")
                mnf_debug(
                    "   🔍 Styled completion menu with dark background and blue selection"
                )

            except Exception as e:
                mnf_error(f"⚠️  Theme applied but completion styling failed: {e}")
                # Fallback: just apply the basic theme
                # ip.magic("colors catppuccin-mocha")
                mnf_error("🎨 Catppuccin Mocha theme applied (basic version)")

            mnf_debug("   Theme available as: catppuccin-mocha")
            mnf_debug("   You can also use: %colors catppuccin-mocha")

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
