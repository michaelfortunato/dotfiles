# qutebrowser dotfiles

Versions the qutebrowser config, userscripts, Greasemonkey scripts, bookmarks, and quickmarks.

Layout:
- `config.py` - main qutebrowser config and keybindings.
- `userscripts/qute-zotero` - Zotero userscript bound from qutebrowser.
- `userscripts/qute-bitwarden` - Bitwarden userscript bound from qutebrowser.
- `start-zotero-translation-server.sh` - starts the local Zotero translation-server backend.
- `com.michaelfortunato.zotero-translation-server.plist` - launchd job definition for the translation server.
- `bookmarks/urls` and `quickmarks` - curated browser data.

Fresh install:
- `cd ~/dotfiles && stow qutebrowser`
- Restart qutebrowser or run `:config-source`.

Resulting link:
- `~/.qutebrowser` -> `~/dotfiles/qutebrowser/.qutebrowser`

Zotero translation server:

The qutebrowser Zotero command uses two local services:
- Zotero Connector at `http://127.0.0.1:23119/connector/`, provided by the running Zotero app.
- Zotero translation-server at `http://127.0.0.1:1969/web`, started by the launchd job below.

The plist is versioned in this package, but stow only links it into `~/.qutebrowser`.
launchd does not load jobs from there. Install it into `~/Library/LaunchAgents` and bootstrap it:

```sh
mkdir -p "$HOME/Library/LaunchAgents"
cp "$HOME/.qutebrowser/com.michaelfortunato.zotero-translation-server.plist" \
  "$HOME/Library/LaunchAgents/"
launchctl bootout "gui/$(id -u)/com.michaelfortunato.zotero-translation-server" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.michaelfortunato.zotero-translation-server.plist"
launchctl enable "gui/$(id -u)/com.michaelfortunato.zotero-translation-server"
launchctl kickstart -k "gui/$(id -u)/com.michaelfortunato.zotero-translation-server"
```

Inspect the job:

```sh
launchctl print "gui/$(id -u)/com.michaelfortunato.zotero-translation-server"
lsof -nP -iTCP:1969 -sTCP:LISTEN
curl --silent --show-error --max-time 3 \
  -d "https://example.com" \
  -H "Content-Type: text/plain" \
  http://127.0.0.1:1969/web >/dev/null
```

Logs:
- `~/Library/Logs/zotero-translation-server.launchd.log`
- `~/Library/Logs/zotero-translation-server.launchd.err.log`

Update after editing the plist:

```sh
cp "$HOME/.qutebrowser/com.michaelfortunato.zotero-translation-server.plist" \
  "$HOME/Library/LaunchAgents/"
launchctl bootout "gui/$(id -u)/com.michaelfortunato.zotero-translation-server" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.michaelfortunato.zotero-translation-server.plist"
launchctl kickstart -k "gui/$(id -u)/com.michaelfortunato.zotero-translation-server"
```

Unload without uninstalling:

```sh
launchctl bootout "gui/$(id -u)" \
  "$HOME/Library/LaunchAgents/com.michaelfortunato.zotero-translation-server.plist"
```

Uninstall:

This removes the launchd job and the copied LaunchAgent plist. It leaves the stowed qutebrowser files in `~/dotfiles` alone.

```sh
label="com.michaelfortunato.zotero-translation-server"
plist="$HOME/Library/LaunchAgents/${label}.plist"

launchctl bootout "gui/$(id -u)/${label}" 2>/dev/null || true
launchctl disable "gui/$(id -u)/${label}" 2>/dev/null || true
rm -f "$plist"
```

Optional runtime cleanup:

The launchd job starts the backend through Colima/containerd. Removing the LaunchAgent prevents future starts, but an existing container or SSH tunnel may keep port `1969` open until stopped.

```sh
pkill -f "ssh -fN -L 1969:127.0.0.1:1969" 2>/dev/null || true
nerdctl rm -f zotero-translation-server 2>/dev/null || true
rm -f "$HOME/Library/Logs/zotero-translation-server.launchd.log" \
  "$HOME/Library/Logs/zotero-translation-server.launchd.err.log"
```

If Colima was only running for this service, stop it separately with `colima stop`.

The server script starts Colima, ensures a `zotero-translation-server` container exists, and exposes the service on localhost port `1969`.
