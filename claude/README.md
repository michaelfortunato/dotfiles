Versions both Claude Code CLI (user-scope) and Claude Desktop configs.

Layout:
- `.claude/settings.json` — Claude Code CLI user settings (model, hooks, effortLevel).
- `.claude/skills/vibework` — symlink to the shared Codex/Claude `vibework` skill.
- `.config/claude-desktop/claude_desktop_config.json` — Claude Desktop MCP + preferences.

Not versioned:
- `~/.claude.json` — runtime state (hardcoded path, rewritten constantly).
- `~/.claude/{sessions,projects,history.jsonl,backups,…}` — runtime state.
- `~/Library/Application Support/Claude/{Cache,Cookies,config.json,…}` — Electron state + OAuth tokens.

Fresh install (macOS):
- `cd ~/dotfiles && stow claude`
- `ln -sfn "$HOME/.config/claude-desktop/claude_desktop_config.json" "$HOME/Library/Application Support/Claude/claude_desktop_config.json"`
- Restart Claude Desktop.

If `~/.claude/settings.json` or the Desktop config already exist on the new machine, remove them first — stow won't overwrite regular files.

Resulting links:
- `~/.claude/settings.json` → `~/dotfiles/claude/.claude/settings.json`
- `~/.claude/skills/vibework` → `~/dotfiles/claude/.claude/skills/vibework` → `~/dotfiles/codex/.codex/skills/vibework`
- `~/.config/claude-desktop` → `~/dotfiles/claude/.config/claude-desktop` (stow tree-fold)
- `~/Library/Application Support/Claude/claude_desktop_config.json` → `~/.config/claude-desktop/claude_desktop_config.json`

Claude Code skill use:
- Skills in `~/.claude/skills` are available as slash commands. Invoke this one with `/vibework OUT-255` or ask Claude to use `vibework` for a Linear ticket.
- In an existing Claude session, open `/skills` to confirm it appears. If the session does not pick it up, run `/clear` or start a new Claude Code session.
- Do not start Claude with `--disable-slash-commands` when you want skills available.
