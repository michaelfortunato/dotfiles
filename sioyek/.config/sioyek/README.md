Sioyek on macOS reads directly from `~/.config/sioyek/` (see upstream `main.cpp:220-224`), so a single stow is enough — no `~/Library/Application Support/` double-link needed.

Versioned files:
- `keys_user.config` — user keybinding overrides.
- `prefs_user.config` — user preference overrides.

Fresh install (macOS):
- `cd ~/dotfiles && stow sioyek`
- Restart Sioyek.

State (`shared.db`, `local.db`, `auto.config`, `last_document_path.txt`) lives in `~/Library/Application Support/Sioyek/` and is intentionally not versioned. Any `keys.config` / `prefs.config` symlinks in App Support are vestigial — sioyek merges user overrides from `~/.config/sioyek/keys_user.config` and `prefs_user.config` directly.
