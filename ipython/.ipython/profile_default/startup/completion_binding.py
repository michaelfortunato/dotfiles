# Save this file as: ~/.ipython/profile_default/startup/completion_binding.py
# This will be automatically loaded when IPython starts

from IPython import get_ipython
from prompt_toolkit.keys import Keys
from prompt_toolkit.filters import HasFocus, Condition
from prompt_toolkit.enums import DEFAULT_BUFFER
from prompt_toolkit.application.current import get_app


def setup_completion_shortcut():
    """Set up Ctrl-Y to accept completion menu selections and autosuggestions."""
    ip = get_ipython()
    if not ip or not hasattr(ip, "pt_app") or not ip.pt_app:
        return

    kb = ip.pt_app.key_bindings

    # Define a filter to check if completion menu is active
    def completion_menu_is_active():
        try:
            app = get_app()
            return bool(app.current_buffer.complete_state)
        except:
            return False

    # Define a filter to check if autosuggestion is available
    def autosuggestion_is_available():
        try:
            app = get_app()
            buffer = app.current_buffer
            return bool(buffer.suggestion)
        except:
            return False

    @kb.add(
        "c-y", filter=HasFocus(DEFAULT_BUFFER) & Condition(completion_menu_is_active)
    )
    def accept_completion_menu(event):
        """Accept the currently selected completion from the menu."""
        buffer = event.current_buffer
        if buffer.complete_state:
            # Get the current completion
            current_completion = buffer.complete_state.current_completion
            if current_completion:
                # Accept the completion
                buffer.apply_completion(current_completion)

    @kb.add(
        "c-y",
        filter=HasFocus(DEFAULT_BUFFER)
        & Condition(autosuggestion_is_available)
        & ~Condition(completion_menu_is_active),
    )
    def accept_autosuggestion(event):
        """Accept autosuggestion when no completion menu is active."""
        buffer = event.current_buffer
        if buffer.suggestion:
            buffer.insert_text(buffer.suggestion.text)

    # Fallback: if neither completion menu nor autosuggestion is active,
    # behave like the default Ctrl-Y (yank/paste)
    @kb.add(
        "c-y",
        filter=HasFocus(DEFAULT_BUFFER)
        & ~Condition(completion_menu_is_active)
        & ~Condition(autosuggestion_is_available),
    )
    def default_yank(event):
        """Default yank behavior when no completions are available."""
        # This preserves the original Ctrl-Y functionality
        event.current_buffer.paste_clipboard_data(event.app.clipboard.get_data())


# Alternative simpler version if the above doesn't work
def setup_simple_completion_shortcut():
    """Simpler version that tries to handle both cases in one binding."""
    ip = get_ipython()
    if not ip or not hasattr(ip, "pt_app") or not ip.pt_app:
        return

    kb = ip.pt_app.key_bindings

    @kb.add("c-y", filter=HasFocus(DEFAULT_BUFFER))
    def smart_accept(event):
        """Smart accept: tries completion menu first, then autosuggestion, then default yank."""
        buffer = event.current_buffer

        # Try completion menu first
        if buffer.complete_state:
            current_completion = buffer.complete_state.current_completion
            if current_completion:
                buffer.apply_completion(current_completion)
                return

        # Try autosuggestion
        if buffer.suggestion:
            buffer.insert_text(buffer.suggestion.text)
            return

        # Fallback to default yank behavior
        try:
            event.current_buffer.paste_clipboard_data(event.app.clipboard.get_data())
        except:
            pass


# Add Ctrl-Space for completion (like VSCode)
def setup_ctrl_space_completion():
    """Set up Ctrl-Space to trigger completion like VSCode."""
    ip = get_ipython()
    if not ip or not hasattr(ip, "pt_app") or not ip.pt_app:
        return

    kb = ip.pt_app.key_bindings

    @kb.add("c-space", filter=HasFocus(DEFAULT_BUFFER))
    def trigger_completion(event):
        """Trigger completion menu like Tab but with Ctrl-Space."""
        buffer = event.current_buffer

        # If there's already a completion state, cycle through completions
        if buffer.complete_state:
            # Move to next completion
            buffer.complete_next()
        else:
            # Start completion
            buffer.start_completion(select_first=True)


# Try the advanced version first, fall back to simple if it fails
try:
    setup_completion_shortcut()
    print("Advanced Ctrl-Y completion binding loaded successfully")
except Exception as e:
    print(f"Advanced binding failed ({e}), trying simple version...")
    try:
        setup_simple_completion_shortcut()
        print("Simple Ctrl-Y completion binding loaded successfully")
    except Exception as e2:
        print(f"Both completion bindings failed: {e2}")


# Set up ctrl-space binding
try:
    setup_ctrl_space_completion()
    print("Ctrl-Space completion binding loaded successfully")
except Exception as e:
    print(f"Ctrl-Space completion binding failed: {e}")


# Optional: Also set up the config-based autosuggestion binding as backup
try:
    ip = get_ipython()
    if ip:
        # This adds the autosuggestion binding through the config system
        ip.config.TerminalInteractiveShell.shortcuts = [
            {
                "new_keys": ["c-y"],
                "command": "IPython:auto_suggest.accept_or_jump_to_end",
                "create": True,
            },
        ]
except Exception as e:
    print(f"Config-based autosuggestion binding failed: {e}")
