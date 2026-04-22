---
name: vibework
description: Implement Linear tickets end-to-end from an issue key such as OUT-255. Use when Codex should fetch a Linear issue, mark it In Progress, create an isolated git worktree and ticket-named feature branch, implement and test the change, create verified signed commits that reference the precise Linear issue URL, push the branch to the company repository, open a GitHub pull request through MCP tooling, and tag the relevant reviewer or subsystem owner.
---

# Vibework

## Overview

Drive one Linear ticket from issue key to pull request while keeping the user's primary checkout clean. Use Linear MCP for issue state and metadata, and GitHub MCP for repository metadata, reviewer discovery, and PR creation.

## Workflow

1. Resolve the Linear ticket from the user's issue key, for example `OUT-255`.
2. Move the ticket to `In Progress` before implementation starts.
3. Create or enter an isolated git worktree on a branch named from the ticket.
4. Review the implementation strategy before editing when the change is not trivial.
5. Implement, test, create signed commits with the exact Linear URL, push a feature branch to the company repository, and open a GitHub PR with the right reviewer tagged for approval.

## Ticket Intake

Use the Linear MCP server. If Linear tools are not loaded, search for them with `tool_search`. If no Linear MCP access is available after tool discovery, stop before implementation and report that the required issue lookup/status update cannot be completed unless the user explicitly permits proceeding without Linear changes.

Fetch the issue by key and capture:

- Issue key, title, description, acceptance criteria, comments, labels, project, assignee, and parent/related issues.
- The exact issue URL returned by Linear. Do not reconstruct or guess this URL.
- Any repository, branch, or implementation hints in the issue body or comments.

Move the issue to the workflow state named `In Progress`, matching case-insensitively. If multiple states match or the team uses a different active-work state, ask one concise question before changing the issue. If the issue is already in progress or later, leave it as-is and say so.

## Worktree And Branch

Work from a separate worktree unless the user explicitly says to use the current checkout. Preserve unrelated dirty state.

Derive names deterministically:

- Branch: `codex/<issue-key-lowercase>-<title-slug>`.
- Worktree directory: `<repo>/.codex/worktrees/<issue-key-lowercase>-<title-slug>`.
- Slug: lowercase the Linear title, replace non-alphanumeric runs with `-`, collapse repeats, trim edges, and keep the full branch under about 80 characters.

Example: `OUT-255` with title `Add webhook retry telemetry` becomes branch `codex/out-255-add-webhook-retry-telemetry`.

Before adding the worktree, inspect `git status --short`, `git branch --show-current`, `git worktree list`, and `git remote -v`. Use the canonical company repository remote for the base and push target, preferring `origin` when it points at the company repository. Fetch the default branch from that remote, then create the worktree from the fetched default branch unless the Linear ticket or user names another base.

Prefer:

```bash
git fetch origin
git worktree add -b codex/out-255-title-slug .codex/worktrees/out-255-title-slug origin/main
```

If the branch or worktree already exists, inspect it and continue there when it clearly corresponds to the same ticket. Do not delete an existing worktree without explicit user approval.

## Strategy Review

After reading the issue and relevant code, provide a brief strategy review before substantive edits when the implementation is not trivial. Keep it short:

- Intended approach.
- Likely files or modules.
- Main risk or ambiguity.
- Validation plan.

For trivial fixes, state the direct change and proceed.

## Implementation

Follow the repo's local agent instructions first, including any `AGENTS.md` files in scope. Read the existing code before editing, keep changes scoped to the ticket, and add focused tests when behavior changes.

During the work:

- Keep the user updated on meaningful findings and blockers.
- Do not include generated runtime state, credentials, local databases, caches, or editor session files.
- Run the narrowest useful validation first, then broader tests when the blast radius justifies them.
- If the ticket is underspecified, inspect Linear comments and linked issues before asking the user.

## Commit, Push, And PR

Commit only the ticket-related files. Commits must be signed. The commit message must include the exact Linear URL captured from MCP.

Before committing, inspect signing configuration:

```bash
git config --show-origin --get commit.gpgsign
git config --show-origin --get user.signingkey
```

Do not pass `--no-gpg-sign`, `-c commit.gpgsign=false`, or any environment/config override that disables signing. Prefer an explicit signed commit even when repo config already enables signing:

Use this shape:

```bash
git commit -S -m "OUT-255: concise imperative summary" \
  -m "Linear: https://linear.app/<workspace>/issue/OUT-255/<exact-slug-from-linear>" \
  -m "Test: <commands run or \"not run: reason\">"
```

If signing fails because GPG, SSH signing, keychain, or pinentry is unavailable, stop before pushing and report the blocker. Do not create unsigned fallback commits.

After committing and before pushing, verify every ticket commit since the base branch has a signature. Replace `<base-branch>` with the branch used to create the worktree, such as `origin/main`:

```bash
git log --format='%h %G? %an <%ae> %s' <base-branch>..HEAD
git log --show-signature --oneline <base-branch>..HEAD
```

All new commits must show a signed state such as `G` or `U`; investigate any other value. Treat `N` in `%G?` as a blocker because it means no signature. If a new local commit is unsigned and the branch has not been pushed, rewrite it before pushing, for example:

```bash
git commit --amend --no-edit -S
```

For multiple local commits, use a rebase exec from the base branch:

```bash
git rebase --exec 'git commit --amend --no-edit -S' <base-branch>
```

If unsigned commits were already pushed, ask the user before rewriting and force-pushing.

The commit message shape is:

```text
OUT-255: concise imperative summary

Linear: https://linear.app/<workspace>/issue/OUT-255/<exact-slug-from-linear>

Test: <commands run or "not run: reason">
```

Use a same-repository branch workflow for PRs. Do not create or use forks for company repositories.

Before pushing, use GitHub MCP and local `git remote -v` output to identify the company repository remote and default/base branch. Prefer `origin` when it points at the company repository. If the checkout points at a personal fork or the company remote is ambiguous, stop before pushing and ask how to normalize the remotes.

Push the feature branch to the company repository remote:

```bash
git push <company-remote> HEAD:codex/out-255-title-slug
```

Then use GitHub MCP to open a pull request in the same repository, with the repository default branch as the base and the pushed feature branch as the head. If GitHub tools are not loaded, search for them with `tool_search`. Use `gh` only as a fallback after MCP is unavailable or insufficient, and say that fallback was used.

Before opening the PR, choose a reviewer or mention target:

- Prefer the person or team that effectively owns the touched subsystem, using CODEOWNERS, maintainers files, package ownership docs, Linear project ownership, or recent reviewer history for the same files.
- If subsystem ownership is unclear, tag Daniel in the PR when his GitHub handle is unambiguous from repo history, GitHub MCP user search, existing review history, or team membership.
- Do not invent `@daniel` or any other handle. If the correct Daniel cannot be resolved, say that the reviewer mention was skipped because the handle was ambiguous.

When GitHub MCP supports it, request review/approval from the chosen user or team. Also include a short `cc @handle` line in the PR body when a user or team handle was verified.

PR title:

```text
OUT-255: concise summary
```

PR body must include:

- Linear issue: exact Linear URL.
- Summary of the implementation.
- Test plan with actual commands and results.
- Commit signatures: include the signature verification command and whether every new commit was signed.
- Strategy notes when the implementation was not trivial.
- Reviewer/owner: requested reviewer or `cc @handle`, or a brief note that no unambiguous owner was found.
- Any remaining risks, follow-ups, or explicitly skipped tests.

Open a draft PR unless the user asks for a ready PR or the repository convention clearly says otherwise. After opening the PR, add the PR URL back to Linear as a comment when Linear MCP supports comments. Move the Linear issue to a review state only if the team's workflow state is unambiguous, such as `In Review`; otherwise leave it `In Progress`.

## Final Response

End with the branch name, PR URL, Linear URL, validation performed, and any unresolved risks. Keep the summary concise.
