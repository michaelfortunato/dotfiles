# Save this file as: ~/.ipython/profile_default/startup/01_completion_binding.py
# Enhanced completion binding with auto-selection of first option

from IPython import get_ipython
from prompt_toolkit.keys import Keys
from prompt_toolkit.filters import HasFocus, Condition
from prompt_toolkit.enums import DEFAULT_BUFFER
from prompt_toolkit.application.current import get_app

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


def setup_enhanced_completion():
    """Set up enhanced completion with auto-selection and better bindings."""
    ip = get_ipython()
    if not ip or not hasattr(ip, "pt_app") or not ip.pt_app:
        return

    # Configure IPython for better completion behavior
    try:
        # Enable greedy completion (auto-selects when there's one option)
        ip.config.IPCompleter.greedy = True

        # Configure completion display
        ip.config.TerminalInteractiveShell.display_completions = "multicolumn"

        # Ensure Jedi is enabled for better completions
        ip.config.IPCompleter.use_jedi = True

        # Configure auto-suggestions
        ip.config.TerminalInteractiveShell.autosuggestions_provider = (
            "NavigableAutoSuggestFromHistory"
        )

        mnf_debug("✅ Enhanced completion configuration applied")

    except Exception as e:
        mnf_error(f"⚠️ Completion configuration failed: {e}")

    kb = ip.pt_app.key_bindings

    # Enhanced completion filters
    def completion_menu_is_active():
        try:
            app = get_app()
            return bool(app.current_buffer.complete_state)
        except:
            return False

    def autosuggestion_is_available():
        try:
            app = get_app()
            buffer = app.current_buffer
            return bool(buffer.suggestion)
        except:
            return False

    # Ctrl+Y for accepting completions/suggestions
    @kb.add(
        "c-y", filter=HasFocus(DEFAULT_BUFFER) & Condition(completion_menu_is_active)
    )
    def accept_completion_menu(event):
        """Accept the currently selected completion from the menu."""
        buffer = event.current_buffer
        if buffer.complete_state:
            current_completion = buffer.complete_state.current_completion
            if current_completion:
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

    # Enhanced Tab behavior for auto-selecting first completion
    @kb.add("tab", filter=HasFocus(DEFAULT_BUFFER))
    def smart_tab_completion(event):
        """Smart Tab: auto-select first completion or show menu with first selected."""
        buffer = event.current_buffer

        # If there's already a completion menu, navigate it
        if buffer.complete_state:
            buffer.complete_next()
            return

        # Start completion
        buffer.start_completion(select_first=True)

        # If only one completion, accept it immediately
        if buffer.complete_state:
            completions = buffer.complete_state.completions
            if len(completions) == 1:
                buffer.apply_completion(completions[0])

    # Ctrl+Space for explicit completion (like VSCode)
    @kb.add("c-space", filter=HasFocus(DEFAULT_BUFFER))
    def trigger_completion(event):
        """Trigger completion menu explicitly."""
        buffer = event.current_buffer

        if buffer.complete_state:
            buffer.complete_next()
        else:
            buffer.start_completion(select_first=True)

    # Shift+Tab for reverse completion navigation
    @kb.add(
        "s-tab", filter=HasFocus(DEFAULT_BUFFER) & Condition(completion_menu_is_active)
    )
    def reverse_completion(event):
        """Navigate completions in reverse."""
        buffer = event.current_buffer
        if buffer.complete_state:
            buffer.complete_previous()

    mnf_debug("✅ Enhanced completion bindings loaded")
    mnf_debug("   Tab: Smart completion with auto-select first option")
    mnf_debug("   Ctrl+Y: Accept completion/suggestion")
    mnf_debug("   Ctrl+Space: Explicit completion trigger")
    mnf_debug("   Shift+Tab: Reverse completion navigation")


# Set up enhanced completion
try:
    setup_enhanced_completion()
except Exception as e:
    mnf_error(f"Enhanced completion setup failed: {e}")

# Fallback configuration through IPython config
try:
    ip = get_ipython()
    if ip:
        # Additional config-based setup
        ip.config.TerminalInteractiveShell.shortcuts = [
            {
                "new_keys": ["c-y"],
                "command": "IPython:auto_suggest.accept_or_jump_to_end",
                "create": True,
            },
        ]
        mnf_debug("✅ Fallback completion bindings configured")
except Exception as e:
    mnf_debug(f"Fallback completion binding failed: {e}")
