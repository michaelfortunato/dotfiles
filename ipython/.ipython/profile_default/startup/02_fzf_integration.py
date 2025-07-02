# Save this as: ~/.ipython/profile_default/startup/02_fzf_integration.py
# Improved FZF integration for IPython with multi-line support and CLI-only implementation

from IPython import get_ipython
import subprocess
import tempfile
import os


ip = get_ipython()
logger = ip.log if ip else None


def mnf_log(msg, level):
    if logger:
        getattr(logger, level)(msg)
    else:
        print(msg)


def mnf_debug(msg):
    return mnf_log(msg, "debug")


def mnf_error(msg):
    return mnf_log(msg, "error")


def setup_fzf_integration():
    """Set up FZF integration for IPython history search with multi-line support."""

    # Check if fzf is available
    try:
        subprocess.run(["fzf", "--version"], capture_output=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        mnf_error("⚠️  fzf not found. Install with:")
        mnf_error("   # macOS: brew install fzf")
        mnf_error("   # Ubuntu/Debian: sudo apt install fzf")
        mnf_error("   # Arch: sudo pacman -S fzf")
        mnf_error(
            "   # Or: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install"
        )
        return False

    def fzf_history_search(event):
        """FZF-powered history search with multi-line command support."""
        from IPython.core.history import HistoryAccessor

        ip = get_ipython()
        history_accessor = HistoryAccessor()

        # Get history entries with multi-line support
        history_entries = []
        seen_commands = set()

        # Get more history entries (last 3000) for better search
        for session, line_num, source in history_accessor.get_tail(3000):
            if source.strip():
                # Clean up the source - remove leading/trailing whitespace but preserve internal structure
                cleaned_source = source.strip()

                # Skip duplicates (case-sensitive to preserve intentional variations)
                if cleaned_source not in seen_commands:
                    seen_commands.add(cleaned_source)
                    # For display in FZF, replace newlines with ␤ symbol for visibility
                    display_command = cleaned_source.replace("\n", " ␤ ")
                    # Store both display version and original for later use
                    history_entries.append((display_command, cleaned_source))

        # Reverse to show most recent first
        history_entries.reverse()

        if not history_entries:
            return

        try:
            # Write display versions to temp file for FZF
            with tempfile.NamedTemporaryFile(
                mode="w", delete=False, encoding="utf-8"
            ) as f:
                for display_cmd, _ in history_entries:
                    f.write(display_cmd + "\n")
                temp_file = f.name

            # Run fzf with enhanced options
            result = subprocess.run(
                [
                    "fzf",
                    "--height=50%",  # Taller for better multi-line viewing
                    "--layout=reverse",
                    "--border=rounded",  # Rounded border for better aesthetics
                    "--prompt=History ❯ ",  # Nice prompt
                    "--bind=esc:abort",  # Escape to dismiss
                    "--bind=ctrl-c:abort",  # Ctrl+C to dismiss
                    "--preview-window=up:3:wrap",  # Preview window for long commands
                    "--preview=echo {q}",  # Show search query in preview
                    "--ansi",  # Support ANSI colors if available
                    "--tabstop=4",  # Better tab handling
                    "--info=inline",  # Compact info display
                ],
                stdin=open(temp_file, encoding="utf-8"),
                capture_output=True,
                text=True,
                encoding="utf-8",
            )

            # Clean up temp file
            os.unlink(temp_file)

            if result.returncode == 0 and result.stdout.strip():
                selected_display = result.stdout.strip()

                # Find the original command corresponding to the selected display version
                original_command = None
                for display_cmd, orig_cmd in history_entries:
                    if display_cmd == selected_display:
                        original_command = orig_cmd
                        break

                if original_command:
                    # Clear current buffer and insert the selected command
                    buffer = event.current_buffer
                    buffer.text = original_command
                    buffer.cursor_position = len(original_command)

        except Exception as e:
            mnf_debug(f"FZF search error: {e}")

    # Register the key binding
    ip = get_ipython()
    if not (hasattr(ip, "pt_app") and ip.pt_app):
        mnf_error("⚠️  prompt_toolkit not available, FZF hotkey not registered")
        return False

    try:
        from prompt_toolkit.key_binding import KeyBindings

        # Get or create key bindings registry
        if hasattr(ip.pt_app, "key_bindings"):
            registry = ip.pt_app.key_bindings
        else:
            registry = KeyBindings()

        # Add Ctrl+R binding for FZF history search
        @registry.add("c-r")
        def _(event):
            """FZF history search triggered by Ctrl+R."""
            fzf_history_search(event)

        mnf_debug("✅ Enhanced FZF history search enabled")
        mnf_debug("   📋 Ctrl+R: search command history (multi-line supported)")
        mnf_debug("   🚪 Escape/Ctrl+C: dismiss FZF interface")
        mnf_debug("   ␤ symbol indicates line breaks in multi-line commands")
        return True

    except Exception as e:
        mnf_error(f"⚠️  Key binding registration failed: {e}")
        return False


def setup_completion_auto_select():
    """Configure completion to auto-select first option."""
    try:
        ip = get_ipython()
        if ip:
            # Configure IPython to automatically select the first completion
            ip.config.IPCompleter.greedy = True
            ip.config.TerminalInteractiveShell.display_completions = "multicolumn"

            # This makes Tab immediately select the first completion if there's only one
            # or shows the menu with the first item selected if there are multiple
            if hasattr(ip, "Completer"):
                completer = ip.Completer
                if hasattr(completer, "use_jedi"):
                    completer.use_jedi = True

            mnf_debug("✅ Auto-select first completion enabled")
            mnf_debug("   Tab will auto-select first option")
            return True
    except Exception as e:
        mnf_error(f"⚠️  Completion auto-select setup failed: {e}")
        return False


# Setup both FZF integration and completion improvements
if setup_fzf_integration():
    setup_completion_auto_select()
else:
    mnf_error("❌ FZF integration setup failed")
