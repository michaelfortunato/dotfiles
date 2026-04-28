# Agent notes for this repo

This is a GNU Stow-managed dotfiles repo. Each top-level directory is a stow package whose contents mirror `$HOME`. Running `stow <pkg>` from the repo root creates parallel symlinks into `~`.

## Instruction-file terminology

Use these terms precisely:

- **Repo-root AGENTS.md** means this file: `~/dotfiles/AGENTS.md`. It contains instructions for working in the dotfiles repository itself.
- **Codex home AGENTS.md** or **global Codex AGENTS.md** means `~/dotfiles/codex/.codex/AGENTS.md`, which is stowed to `~/.codex/AGENTS.md`. It contains global instructions for Codex across repositories.

When the user asks for a "global AGENTS.md" while working in this repo, edit the Codex home AGENTS.md, not the repo-root AGENTS.md. If the request says "local AGENTS.md", "repo AGENTS.md", or "AGENTS.md here", edit the repo-root AGENTS.md unless the user names another path.

## Conventions

- Only curated files belong in a package. Don't drop runtime state (caches, session logs, databases, tokens) into a stow package.
- Prefer directory structures already rooted under XDG paths (`.config/<app>`) or dot-files at `$HOME` (`.<app>rc`). Stow handles these with a single symlink — nothing extra needed.
- Machine-specific overrides live in the `Melville/` and `Tacitus/` packages, which are stowed per-host. Do not put editor configs (nvim, kitty) in those packages — per-file symlinks break plugin discovery.

## Double-link technique (macOS apps that read only from `~/Library/Application Support/`)

Some macOS apps refuse to read config from XDG locations (e.g. Claude Desktop). The workaround is a two-hop symlink:

```
~/Library/Application Support/<App>/<file>
  → ~/.config/<app>/<file>          (hand-created after stow)
     → ~/dotfiles/<pkg>/.config/<app>/<file>   (created by stow)
```

Stow manages only the second hop. The first hop is created manually with `ln -sfn` and documented in the package's own `README.md` (see `claude/README.md`).

Check before adding the hop: many Qt/Electron apps that *write state* to App Support still read configs from `~/.config/<app>/` directly. Sioyek is one such case — a single stow is enough (see `sioyek/.config/sioyek/README.md`). When in doubt, grep the app's source for `QStandardPaths` / `AppDataLocation` / `.config/<name>`.

Apps that use XDG or dot-files at `$HOME` (nvim, kitty, aerospace, git, qutebrowser, …) get a single stow invocation and nothing else.

## Gitignore allowlist pattern

When a package's source dir must physically contain files you don't want tracked (e.g. bundled system skills), use the allowlist pattern in `codex/.gitignore`:

```
/.codex/**
!/.codex/
!/.codex/config.toml
!/.codex/skills/
!/.codex/skills/*
!/.codex/skills/*/**
/.codex/skills/.system/**
```

Prefer *not* checking runtime state into the package at all — only reach for this pattern when the tool forces coexistence.

## Memory file

`CLAUDE.md` at the repo root is a symlink to `AGENTS.md`. Claude Code reads `CLAUDE.md` by default; keeping a single source of truth in `AGENTS.md` keeps the file discoverable by other agent tooling (Codex, Cursor, etc.).
