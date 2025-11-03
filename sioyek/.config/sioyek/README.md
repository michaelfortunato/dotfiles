Double-link (macOS): Repo manages `~/.config/sioyek` (via stow). macOS reads `~/Library/Application Support/sioyek`. Link only config files; leave state files in App Support.

Fresh install (macOS):
- `cd ~/dotfiles && stow -S sioyek`
- ln -sfn "$HOME/.config/sioyek/keys.config" "$HOME/Library/Application Support/sioyek/keys.config"
- ln -sfn "$HOME/.config/sioyek/prefs_user.config" "$HOME/Library/Application Support/sioyek/prefs_user.config"

ln flags (brief):
- -s: symbolic link
- -f: replace destination if it exists
- -n: don’t dereference DEST if it’s a symlink to a dir
