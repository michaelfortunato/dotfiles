# Save this as: ~/.ipython/profile_default/startup/catppuccin_theme.py
# Proper IPython 9+ theme implementation using the new Theme system

from IPython import get_ipython


def setup_catppuccin_theme():
    """Set up Catppuccin Mocha theme using IPython 9+ Theme system."""

    try:
        import catppuccin
        from catppuccin import PALETTE
        from IPython.utils.PyColorize import Theme, theme_table
        from pygments.token import Token
        from pygments import __version__ as pygments_version

        print(f"🔍 Using Pygments version: {pygments_version}")

        # Catppuccin Mocha color palette
        mocha = PALETTE.mocha.colors

        # Create a comprehensive Catppuccin theme using IPython's Theme class
        # The Theme constructor signature: __init__(self, name, base, extra_style, *, symbols={})

        # Define Catppuccin colors in IPython's format (this becomes extra_style)
        catppuccin_extra_style = {
            # Basic Python syntax
            Token.Keyword: mocha.mauve.hex,  # def, class, import, etc.
            Token.Keyword.Constant: mocha.mauve.hex,  # True, False, None
            Token.Keyword.Declaration: mocha.mauve.hex,  # def, class
            Token.Keyword.Namespace: mocha.peach.hex,  # import, from
            Token.Keyword.Pseudo: mocha.pink.hex,  # self, super
            Token.Keyword.Reserved: mocha.mauve.hex,  # reserved keywords
            Token.Keyword.Type: mocha.yellow.hex,  # int, str, etc.
            # Names and identifiers
            Token.Name: mocha.text.hex,  # variable names
            Token.Name.Attribute: mocha.blue.hex,  # object.attribute
            Token.Name.Builtin: mocha.red.hex,  # len, print, range
            Token.Name.Builtin.Pseudo: mocha.red.hex,  # __name__, __file__
            Token.Name.Class: mocha.yellow.hex,  # class names
            Token.Name.Constant: mocha.peach.hex,  # CONSTANTS
            Token.Name.Decorator: mocha.pink.hex,  # @decorator
            Token.Name.Entity: mocha.blue.hex,  # entities
            Token.Name.Exception: f"bold {mocha.red.hex}",  # Exception classes
            Token.Name.Function: mocha.blue.hex,  # function names
            Token.Name.Function.Magic: mocha.blue.hex,  # __init__, __str__
            Token.Name.Label: mocha.blue.hex,  # labels
            Token.Name.Namespace: mocha.yellow.hex,  # module names
            Token.Name.Other: mocha.text.hex,  # other names
            Token.Name.Property: mocha.blue.hex,  # properties
            Token.Name.Tag: mocha.pink.hex,  # HTML/XML tags
            Token.Name.Variable: mocha.text.hex,  # variables
            Token.Name.Variable.Class: mocha.text.hex,  # class variables
            Token.Name.Variable.Global: mocha.text.hex,  # global variables
            Token.Name.Variable.Instance: mocha.text.hex,  # instance variables
            Token.Name.Variable.Magic: mocha.pink.hex,  # __dict__, etc.
            # Literals and strings
            Token.Literal: mocha.text.hex,
            Token.String: mocha.green.hex,  # "string"
            Token.String.Affix: mocha.green.hex,  # r, f, b prefixes
            Token.String.Backtick: mocha.green.hex,  # `backtick`
            Token.String.Char: mocha.green.hex,  # 'c'
            Token.String.Delimiter: mocha.green.hex,  # string delimiters
            Token.String.Doc: f"italic {mocha.green.hex}",  # """docstring"""
            Token.String.Double: mocha.green.hex,  # "double quoted"
            Token.String.Escape: mocha.pink.hex,  # \n, \t, etc.
            Token.String.Heredoc: mocha.green.hex,  # heredoc strings
            Token.String.Interpol: mocha.pink.hex,  # f"{interpolation}"
            Token.String.Other: mocha.green.hex,  # other string types
            Token.String.Regex: mocha.green.hex,  # regex strings
            Token.String.Single: mocha.green.hex,  # 'single quoted'
            Token.String.Symbol: mocha.green.hex,  # symbols
            # Numbers
            Token.Number: mocha.peach.hex,  # 123
            Token.Number.Bin: mocha.peach.hex,  # 0b101
            Token.Number.Float: mocha.peach.hex,  # 1.23
            Token.Number.Hex: mocha.peach.hex,  # 0xff
            Token.Number.Integer: mocha.peach.hex,  # 123
            Token.Number.Integer.Long: mocha.peach.hex,  # 123L
            Token.Number.Oct: mocha.peach.hex,  # 0o777
            # Comments
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
            # Additional IPython tokens (from PyColorize.py)
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

        # Create the theme using the correct signature: name, base, extra_style, symbols
        catppuccin_theme = Theme(
            name="catppuccin-mocha",
            base=None,  # No base pygments style, we define everything
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
            # Set the theme
            ip.config.InteractiveShell.colors = "catppuccin-mocha"
            ip.config.TerminalInteractiveShell.true_color = True

            # Force refresh of syntax highlighting
            if hasattr(ip, "init_syntax_highlighting"):
                ip.init_syntax_highlighting()

            # Refresh the style if method exists
            if hasattr(ip, "refresh_style"):
                ip.refresh_style()

            print("🎨 Catppuccin Mocha theme registered and applied successfully!")
            print("   Theme available as: catppuccin-mocha")
            print("   You can also use: %colors catppuccin-mocha")

        return True

    except ImportError:
        print("❌ Catppuccin not found. Install with:")
        print("   uv add catppuccin")
        return False
    except Exception as e:
        print(f"❌ Error setting up Catppuccin theme: {e}")
        import traceback

        traceback.print_exc()
        return False


# Set up the theme
setup_catppuccin_theme()
