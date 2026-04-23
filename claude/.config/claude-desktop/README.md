Double-link (macOS): Repo manages `~/.config/claude-desktop` (via stow). Claude Desktop reads `~/Library/Application Support/Claude/claude_desktop_config.json`. Link only the config file; leave state (Cache, Cookies, config.json, window-state.json, etc.) in App Support.

Fresh install (macOS):
- `cd ~/dotfiles && stow -S claude-desktop`
- `ln -sfn "$HOME/.config/claude-desktop/claude_desktop_config.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"`

Restart Claude Desktop after linking.
