---
name: setup-dotfiles-worktree
description: Prepare Michael Fortunato's GNU Stow dotfiles repository for agent work in a git worktree. Use when Codex is starting work in this dotfiles repo, especially from a linked worktree under .codex/worktrees, .claude/worktrees, or another temporary agent checkout, and needs repo-specific setup, safety checks, submodule guidance, or validation commands before making mergeable changes.
---

# Setup Dotfiles Worktree

## Overview

Use this skill at the start of work in this dotfiles repository when the checkout is a git worktree intended to be merged back later. Keep setup local to the worktree, avoid changing the user's live home-directory symlinks, and leave unrelated dirty state alone.

## Quick Start

From anywhere inside the repo, run the setup helper:

```bash
"$(git rev-parse --show-toplevel)/codex/.codex/skills/setup-dotfiles-worktree/scripts/setup_worktree.sh"
```

If the task touches zsh plugins, templates, personal scripts, or other submodule-backed content, initialize only the lightweight root submodules:

```bash
"$(git rev-parse --show-toplevel)/codex/.codex/skills/setup-dotfiles-worktree/scripts/setup_worktree.sh" --submodules=light
```

Default setup never clones submodules. Use `--submodules=all` only when the task explicitly needs `_fonts/nerd-fonts` or another known-heavy asset submodule. Light mode intentionally skips known-heavy submodules and avoids recursive submodule cloning.

## Worktree Rules

- Treat each top-level directory as a GNU Stow package whose contents mirror `$HOME`.
- Do not run real `stow <pkg>` from an agent worktree unless the user explicitly asks to change the live machine configuration.
- Use `stow -n -v -t "$HOME" <pkg>` for dry-run validation when package layout matters.
- Do not run `install.sh` as routine setup. It is a machine setup script and writes git hooks for the user's checkout.
- Do not edit `_MANIFESTS/**` unless the task is specifically about package manifests. The pre-push hook can regenerate these from the user's machine state.
- Do not add runtime state, caches, tokens, databases, logs, or generated local app state to a stow package.
- Preserve unrelated dirty files in the worktree. Read before editing any file that is already modified.

## Repo Checks

After setup, inspect the local state:

```bash
git status --short
git worktree list
```

If the checkout is detached, create or switch to a mergeable branch before substantive edits unless the user has directed otherwise. Prefer the repo's agent branch conventions when available, such as `codex/<short-task-name>`.

## Validation

Choose validation based on the files touched:

- For stow package layout: `stow -n -v -t "$HOME" <pkg>`
- For Codex skills in `codex/.codex/skills/<skill>`: run the system `skill-creator` validator if available:

```bash
python3 codex/.codex/skills/.system/skill-creator/scripts/quick_validate.py codex/.codex/skills/<skill>
```

The `.system` skills directory is ignored in git, so the validator may exist on the user's machine but not in a clean remote checkout. If it is missing, validate the `SKILL.md` frontmatter manually: only `name` and `description` should appear in YAML frontmatter, and the folder name should match `name`.

## Before Finishing

- Re-run `git status --short` and summarize only the files intentionally changed.
- If submodules were initialized only for setup, do not commit incidental submodule pointer changes unless the task required them.
- If package manifests or generated lockfiles changed, explain which command changed them and why they belong in the merge.
- Leave final instructions in terms of repo files and commands, not personal machine state.
