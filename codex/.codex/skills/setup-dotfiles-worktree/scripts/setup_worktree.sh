#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup_worktree.sh [--submodules=none|light|all] [--help]

Prepare this dotfiles repo for agent work in a git worktree.

Options:
  --submodules=none   Do not update submodules; only report their status. Default.
  --submodules=light  Initialize shallow root submodules except known-heavy ones.
  --submodules=all    Initialize every submodule recursively, including heavy ones.
  --help              Show this help.
USAGE
}

log() {
  printf '[setup-dotfiles-worktree] %s\n' "$*"
}

warn() {
  printf '[setup-dotfiles-worktree] WARN: %s\n' "$*" >&2
}

die() {
  printf '[setup-dotfiles-worktree] ERROR: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

is_heavy_submodule() {
  case "$1" in
    _fonts/nerd-fonts)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

submodule_mode="none"

while (($#)); do
  case "$1" in
    --submodules=none)
      submodule_mode="none"
      ;;
    --submodules=light)
      submodule_mode="light"
      ;;
    --submodules=all)
      submodule_mode="all"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
  shift
done

have git || die "git is required"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "run from inside the dotfiles git repository"
cd "$repo_root"

[[ -f AGENTS.md ]] || die "AGENTS.md not found; this does not look like the dotfiles repo root"
[[ -d codex/.codex/skills ]] || die "codex/.codex/skills not found; this does not look like the expected dotfiles repo"

log "repo: $repo_root"

git_dir="$(git rev-parse --path-format=absolute --git-dir)"
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
branch="$(git branch --show-current || true)"

if [[ "$git_dir" == "$common_dir" ]]; then
  warn "this appears to be the primary checkout, not a linked worktree"
else
  log "linked worktree git dir: $git_dir"
fi

if [[ -n "$branch" ]]; then
  log "branch: $branch"
else
  warn "detached HEAD; create a mergeable branch before substantive edits"
fi

if [[ -n "$(git status --short)" ]]; then
  warn "worktree already has local changes; inspect them before editing"
fi

for cmd in rg stow; do
  if have "$cmd"; then
    log "found optional tool: $cmd"
  else
    warn "optional tool not found: $cmd"
  fi
done

if [[ ! -f .gitmodules ]]; then
  log "no .gitmodules file found"
  exit 0
fi

submodules=()
while IFS= read -r path; do
  [[ -n "$path" ]] && submodules+=("$path")
done < <(git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{print $2}' || true)

if [[ "${#submodules[@]}" -eq 0 ]]; then
  log "no submodules configured"
  exit 0
fi

case "$submodule_mode" in
  none)
    log "submodule mode: none"
    git submodule status --recursive || warn "could not read submodule status"
    ;;
  light|all)
    paths=()
    skipped=()
    for path in "${submodules[@]}"; do
      if [[ "$submodule_mode" == "light" ]] && is_heavy_submodule "$path"; then
        skipped+=("$path")
        continue
      fi
      paths+=("$path")
    done

    if [[ "${#skipped[@]}" -gt 0 ]]; then
      log "skipping known-heavy submodule(s) in light mode: ${skipped[*]}"
    fi

    if [[ "${#paths[@]}" -eq 0 ]]; then
      log "no submodules selected for update"
      exit 0
    fi

    log "initializing ${#paths[@]} submodule(s)"
    if [[ "$submodule_mode" == "light" ]]; then
      git submodule update --init --depth=1 -- "${paths[@]}"
    else
      git submodule update --init --recursive --depth=1 -- "${paths[@]}"
    fi
    ;;
esac

log "setup check complete"
