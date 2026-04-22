# Codex Dotfiles

This package is the shared Codex home. Stowing it links `~/.codex` to
`~/dotfiles/codex/.codex`.

```sh
cd ~/dotfiles
stow codex
```

Do not commit runtime state, caches, logs, auth files, databases, tokens, or
plugin caches from `.codex/`. The package allowlist in `.gitignore` is meant to
track only shared configuration, rules, and intentional user skills.

## Desired integrations

These four integrations are intentionally enabled in `.codex/config.toml`.

| Integration | Config entry | Setup | Credentials |
| --- | --- | --- | --- |
| GitHub | `[plugins."github@openai-curated"]` and `[mcp_servers.github]` | Keep the curated GitHub plugin enabled. Keep the GitHub MCP server pointed at `https://api.githubcopilot.com/mcp/`. Verify with `codex mcp list` and a GitHub profile lookup from Codex. | Requires `CODEX_GITHUB_PERSONAL_ACCESS_TOKEN` in the environment. Do not store the token in this repo. |
| Computer Use | `[plugins."computer-use@openai-bundled"]` | Keep the bundled Computer Use plugin enabled. The helper is installed under Codex's plugin cache by the app. | No external account credential. macOS may require Accessibility, Screen Recording, or Automation permissions when desktop control is used. |
| Linear | `[plugins."linear@openai-curated"]` and `[mcp_servers.linear]` | Keep the curated Linear plugin enabled. Keep the Linear MCP server pointed at `https://mcp.linear.app/mcp`. Run `codex mcp login linear` if OAuth expires. Verify with `codex mcp list` and a Linear profile lookup from Codex. | Uses Linear OAuth. No token should be committed to this repo. |
| Slack | `[plugins."slack@openai-curated"]` | Keep the official curated Slack plugin enabled. Slack is exposed as a Codex app/plugin connector, not as a raw `[mcp_servers.slack]` block, so it will not appear in `codex mcp list`. Verify by loading Slack tools in Codex and reading the current Slack profile. | Uses the Codex Slack app authorization for the workspace. No token should be committed to this repo. |

The utility MCP servers in this config, such as Context7, fetch, memory, and
sequential thinking, are separate from the desired external app integrations
above.

## Local checks

Useful non-secret checks:

```sh
codex mcp list
test -n "$CODEX_GITHUB_PERSONAL_ACCESS_TOKEN"
```

For Slack, use Codex tool discovery or ask Codex to read the current Slack
profile. The official Slack integration is `slack@openai-curated`, and its
connector metadata lives in Codex's local plugin cache, not in the stowed
configuration.
