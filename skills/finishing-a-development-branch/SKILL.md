---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to integrate the work - by default merges the branch into the base branch and pushes autonomously (no menu); presents structured options only for the listed exceptions (user asked for review, experimental work, semantic conflict, detached HEAD)
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Integrate autonomously (default) → Clean up. Menu only for exceptions.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 1b: Capture the Insight (beads projects only)

Run `bd where` quietly (or check for a `.beads/` directory at the project
root). No beads workspace → skip straight to Step 2 and do not mention beads.

Otherwise, before integrating the branch, store what this work taught you so
it survives the session:

```bash
bd remember "<problem> → <solution>. <context why>"
```

One line, specific enough to be found later. "pg pool exhaustion under load →
max=20 + idle_timeout=30s; default max=10 gave 503s at >50 rps" is a memory;
"fixed the bug" is not. If the work taught nothing non-obvious, or
verification-before-completion already stored this insight for the same work,
skip — do not duplicate.

### Step 2: Detect Environment

**Determine workspace state before presenting options:**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |

### Step 3: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 4: Choose Integration Path

**Default — integrate autonomously, do NOT ask.** Per
`~/.claude/rules/git-integration.md`, a finished green branch goes in without
a menu: execute Option 1 (merge into <base-branch> + push), then clean up
(Step 6). If the base branch is checked out elsewhere or the repo's convention
requires a PR — push the branch, `gh pr create`, then immediately
`gh pr merge <N> --merge --delete-branch` yourself. Do not wait for review.

**Present the menu ONLY when one of these holds:**

- The user explicitly asked for a PR with review, or said "не мержи" /
  "покажи сначала" / "keep the branch".
- The work is experimental / exploratory (same exclusions as proactive
  commits in CLAUDE.md).
- A non-trivial semantic conflict with someone else's uncommitted WIP.
- Detached HEAD (externally managed workspace) — reduced menu below.

**Menu for those exceptional cases (normal repo / named-branch worktree):**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Detached HEAD — present exactly these 3 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)
3. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Get main repo root for CWD safety
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>

# Publish the merged result
git push origin <base-branch>

# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
```

If `<base-branch>` is checked out in another worktree (checkout fails):
from the feature worktree, a fast-forward integration works without touching
that checkout — `git fetch . HEAD:<base-branch> && git push origin <base-branch>`.
If fast-forward is impossible, fall back to push + `gh pr create` +
`gh pr merge --merge --delete-branch` (self-merge, no review wait).

Then: Cleanup worktree (Step 6), then delete branch:

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>
```

**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then: Cleanup worktree (Step 6), then force-delete branch:
```bash
git branch -D <feature-branch>
```

### Step 6: Cleanup Workspace

**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If worktree path is under `.worktrees/` or `worktrees/`:** Superpowers created this worktree — we own cleanup.

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clean up any stale registrations
```

**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Asking when the default applies**
- **Problem:** "Merge or PR?" menus stall autonomous work the user already authorized
- **Fix:** Integrate autonomously (Option 1 + push); menu only for the Step 4 exceptions
- If a menu IS warranted, present exactly 4 structured options (or 3 for detached HEAD) — never an open-ended "What should I do next?"

**Cleaning up worktree for Option 2**
- **Problem:** Remove worktree user needs for PR iteration
- **Fix:** Only cleanup for Options 1 and 4

**Deleting branch before removing worktree**
- **Problem:** `git branch -d` fails because worktree still references the branch
- **Fix:** Merge first, remove worktree, then delete branch

**Running git worktree remove from inside the worktree**
- **Problem:** Command fails silently when CWD is inside the worktree being removed
- **Fix:** Always `cd` to main repo root before `git worktree remove`

**Cleaning up harness-owned worktrees**
- **Problem:** Removing a worktree the harness created causes phantom state
- **Fix:** Only clean up worktrees under `.worktrees/` or `worktrees/`

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Ask "merge or PR?" when the autonomous default applies
- Leave a PR you created waiting for review the user never asked for
- Delete work without confirmation
- Force-push without explicit request
- Remove a worktree before confirming merge success
- Clean up worktrees you didn't create (provenance check)
- Run `git worktree remove` from inside the worktree

**Always:**
- Verify tests before integrating (or before offering options)
- Detect environment before acting
- Integrate autonomously by default; menu only for the Step 4 exceptions
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only
- `cd` to main repo root before worktree removal
- Run `git worktree prune` after removal
