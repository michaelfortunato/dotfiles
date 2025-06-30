# Save this as: ~/.ipython/profile_default/startup/02_fzf_integration.py
# Standalone FZF integration for IPython - completely independent of theming

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


def setup_fzf_integration():
    """Set up FZF integration for IPython history search."""

    # Check if fzf is available
    try:
        import subprocess

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

    # Try different FZF implementations in order of preference
    fzf_implementation = None

    # 1. Try iterfzf (most reliable)
    try:
        import iterfzf

        def fzf_history_search(event):
            """FZF-powered history search using iterfzf."""
            from IPython.core.history import HistoryAccessor

            # Get IPython instance
            ip = get_ipython()
            history_accessor = HistoryAccessor()

            # Get unique history entries (last 2000)
            history_set = set()
            history_entries = []
            for session, line_num, source in history_accessor.get_tail(2000):
                if source.strip() and source not in history_set:
                    history_set.add(source)
                    history_entries.append(source.strip())

            history_entries.reverse()  # Most recent first

            if not history_entries:
                return

            try:
                # Use iterfzf for selection with Escape to dismiss
                selected = iterfzf.iterfzf(
                    history_entries,
                    multi=False,
                    prompt="History> ",
                    preview_window="up:3:wrap",
                    height="40%",
                    bind=["esc:abort"],  # Escape to dismiss!
                )

                if selected:
                    # Insert selected command
                    buffer = event.current_buffer
                    buffer.delete_before_cursor(len(buffer.text))
                    buffer.insert_text(selected)

            except KeyboardInterrupt:
                pass  # User cancelled with Escape or Ctrl+C

        fzf_implementation = "iterfzf"
        mnf_debug("🔍 FZF integration: using iterfzf")

    except ImportError:
        # 2. Try pyfzf
        try:
            import pyfzf

            def fzf_history_search(event):
                """FZF-powered history search using pyfzf."""
                from IPython.core.history import HistoryAccessor

                ip = get_ipython()
                history_accessor = HistoryAccessor()
                fzf = pyfzf.FzfPrompt()

                # Get unique history entries
                history_set = set()
                history_entries = []
                for session, line_num, source in history_accessor.get_tail(2000):
                    if source.strip() and source not in history_set:
                        history_set.add(source)
                        history_entries.append(source.strip())

                history_entries.reverse()

                if not history_entries:
                    return

                try:
                    # Use pyfzf for selection with Escape to dismiss
                    selected = fzf.prompt(
                        history_entries,
                        fzf_options="--height=40% --layout=reverse --border --prompt='History> ' --bind 'esc:abort'",
                    )

                    if selected and len(selected) > 0:
                        # Insert selected command
                        buffer = event.current_buffer
                        buffer.delete_before_cursor(len(buffer.text))
                        buffer.insert_text(selected[0])

                except Exception:
                    pass  # User cancelled with Escape or error

            fzf_implementation = "pyfzf"
            mnf_debug("🔍 FZF integration: using pyfzf")

        except ImportError:
            # 3. Direct subprocess fallback
            def fzf_history_search(event):
                """FZF-powered history search using direct subprocess."""
                from IPython.core.history import HistoryAccessor
                import subprocess
                import tempfile
                import os

                ip = get_ipython()
                history_accessor = HistoryAccessor()

                # Get unique history entries
                history_set = set()
                history_entries = []
                for session, line_num, source in history_accessor.get_tail(2000):
                    if source.strip() and source not in history_set:
                        history_set.add(source)
                        history_entries.append(source.strip())

                history_entries.reverse()

                if not history_entries:
                    return

                try:
                    # Write history to temp file
                    with tempfile.NamedTemporaryFile(mode="w", delete=False) as f:
                        for entry in history_entries:
                            f.write(entry + "\n")
                        temp_file = f.name

                    # Run fzf with Escape to dismiss
                    result = subprocess.run(
                        [
                            "fzf",
                            "--height=40%",
                            "--layout=reverse",
                            "--border",
                            "--prompt=History> ",
                            "--bind=esc:abort",  # Escape to dismiss!
                        ],
                        stdin=open(temp_file),
                        capture_output=True,
                        text=True,
                    )

                    # Clean up
                    os.unlink(temp_file)

                    if result.returncode == 0 and result.stdout.strip():
                        # Insert selected command
                        buffer = event.current_buffer
                        buffer.text = result.stdout.strip()
                        # buffer.delete_before_cursor(1)
                        buffer.cursor_position = len(result.stdout.strip())
                        # buffer.insert_text(result.stdout.strip())
                        # buffer.cursor_position = len(result.stdout.strip())

                except Exception:
                    pass  # User cancelled with Escape or error

            fzf_implementation = "subprocess"
            mnf_debug("🔍 FZF integration: using direct subprocess")

    # Register the key binding
    ip = get_ipython()
    if not (hasattr(ip, "pt_app") and ip.pt_app):
        mnf_error("⚠️  prompt_toolkit not available, FZF hotkey not registered")
        return False

    try:
        from prompt_toolkit.key_binding import KeyBindings
        from prompt_toolkit.keys import Keys

        # Get or create key bindings registry
        if hasattr(ip.pt_app, "key_bindings"):
            registry = ip.pt_app.key_bindings
        elif hasattr(ip, "_key_bindings"):
            registry = ip._key_bindings
        else:
            # Create new registry
            registry = KeyBindings()

        # Add Ctrl+R binding for FZF history search
        @registry.add("c-r")
        def _(event):
            """FZF history search triggered by Ctrl+R."""
            fzf_history_search(event)

        # If we created a new registry, try to integrate it
        if not hasattr(ip.pt_app, "key_bindings") or registry != ip.pt_app.key_bindings:
            # This might require reinitialization, but let's try
            if hasattr(ip, "init_prompt_toolkit_cli"):
                try:
                    ip.init_prompt_toolkit_cli()
                except:
                    pass  # Might fail, but registration might still work

        mnf_debug(f"✅ FZF history search enabled (using {fzf_implementation})")
        mnf_debug("   📋 Ctrl+R: search command history with FZF")
        mnf_debug("   🚪 Escape: dismiss FZF interface")
        return True

    except Exception as e:
        mnf_debug(f"⚠️  Key binding registration failed: {e}")
        mnf_debug("   FZF functions available, but hotkey not registered")
        return False


def show_fzf_help():
    """Show FZF usage help."""
    print("\n🔍 FZF Integration Help:")
    print("   Ctrl+R          - Open FZF history search")
    print("   Escape          - Dismiss/cancel FZF")
    print("   Enter           - Select command")
    print("   Ctrl+C          - Cancel (alternative to Escape)")
    print("   Type to filter  - Fuzzy search history")
    print("   ↑/↓ arrows      - Navigate results")
    print("\n📦 Optional: Install Python FZF packages for better integration:")
    print("   uv add iterfzf  # Recommended")
    print("   # or")
    print("   uv add pyfzf")


# Setup FZF integration
if setup_fzf_integration():
    # Optionally show help (comment out if you don't want this)
    # show_fzf_help()
    pass
else:
    print("❌ FZF integration setup failed")
