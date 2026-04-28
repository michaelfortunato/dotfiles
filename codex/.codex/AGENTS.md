# Global agent instructions

These are the default working rules for agents on Michael Fortunato's machine and repositories. Prefer the instructions nearest the code you are editing when they are more specific, but keep these defaults unless the user says otherwise.

## Working style

- Inspect the real files, config, command output, docs, logs, or runtime behavior before making claims. If a fact is cheap to verify, verify it.
- Keep changes scoped to the request. Follow the existing project patterns before inventing a new abstraction, layout, or toolchain.
- Preserve user work. Always check `git status --short` before editing, read any file that is already modified before touching it, and never revert unrelated changes unless the user explicitly asks.
- If the user asks you to do something, do it end to end when feasible: implement, validate, and report the result. Do not stop at instructions unless the user asked for a plan or explanation only.
- If the user says "do not stop until it is", continue iterating until the requested behavior is actually verified.
- Prefer `rg` / `rg --files` for search. Treat `rg` exit code 1 as "no matches" when that is the expected result.
- Keep fixes small and proportional. If a patch is growing beyond the bug or request, pause and explain the tradeoff before expanding scope.

## Tooling defaults

- Python projects always use `uv`.
  - Use `uv sync` to create or refresh environments.
  - Use `uv run python ...` for scripts, smoke checks, and tests.
  - Use `uv add` / `uv remove` for dependency changes.
  - Use `uv tool install` / `uvx` for isolated CLI tools when appropriate.
  - Do not use global `pip`, ad hoc virtualenvs, Poetry, or Conda unless the repository already owns that workflow or the user asks for it.
- If a metabuild/task runner is needed, use `just`. Prefer an existing `justfile` over new wrapper scripts.
- Rust projects use the existing Cargo workspace. Keep domain types independent of optional runtime/compiler internals, make abstractions justify themselves, and prefer concrete flow-oriented code until duplication or complexity earns a shared layer.
- JavaScript/TypeScript projects should follow the repository's lockfile and package manager. Do not introduce a new package manager for convenience.
- Shell and Zsh startup changes should be measured or traced in a fresh shell when behavior matters. Keep startup paths fast; avoid adding startup subprocesses unless there is a clear reason.

## Repository shape

- Conventions matter. Repositories should look modern, legible, and familiar to someone joining the project.
- Prefer a `src/` layout for application/library code when the ecosystem supports it. Use conventional top-level homes such as `tests/`, `docs/`, `examples/`, `scripts/`, and `tools/` when they are useful.
- Prefer `docs/` over `doc/` for project documentation unless the language ecosystem or existing repo convention strongly points elsewhere.
- Add or maintain a `.codex/` directory for curated project-specific agent context: local config, plans, memories, setup notes, and reusable workflow guidance. Do not put Codex runtime state, logs, caches, auth, or session databases there.
- Every serious repo should explain how to set it up from scratch. Keep setup instructions current and split by OS when the commands differ, especially for macOS and Linux.
- Dev tooling is part of the product surface. Prefer checked-in formatter, linter, test, typecheck, task-runner, and editor integration defaults over undocumented personal setup.
- If an existing repo is messy, improve layout incrementally and preserve working behavior. Do not churn structure just to satisfy a template.

## Editor workflow

- Michael's Neovim setup is highly customized and important to the development workflow. Treat editor integration as first-class when it helps a repo be pleasant to work in.
- Use repo-local `.lazy.lua` for project-specific Neovim behavior such as keymaps, dev jobs, commands, or filetype helpers. It is acceptable to commit `.lazy.lua` when it captures real project workflow rather than private machine state.
- If a request is about repo-local editor behavior, inspect and patch `.lazy.lua` before changing global dotfiles.
- Keep `.lazy.lua` small, explicit, and project-owned. Do not hide broad tooling behavior in global config when the behavior belongs to one repository.

## Git and review workflow

- Use same-repository feature branches by default; do not fork unless the user requests it.
- Commits for user work should be signed with `git commit -S` when committing is requested, and signature verification failures are blockers.
- Before pushing, check what commits will be published, especially in dotfiles or shared repos.
- For branch review, compare against the merge base with three-dot semantics such as `git diff main...HEAD`.
- When the user asks for a review, lead with findings ordered by severity and include file/line references. If there are no findings, say so and mention residual test risk.
- Use isolated worktrees when the user asks for them or when a risky/broad change should not disturb the main checkout.

## Validation

- Run the smallest meaningful validation first, then broaden when the change touches shared behavior, public contracts, or user-facing workflows.
- Prefer repository-native commands: `uv run ...`, `cargo test`, `just ...`, `npm run ...`, or the existing Makefile/task entrypoint.
- For UI changes, verify in the browser or with screenshots when practical.
- For config changes, validate with the tool that consumes the config rather than only checking syntax.
- Report exactly what was validated and what was not.
