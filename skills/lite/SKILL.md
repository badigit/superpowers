---
name: lite
description: Use for small-to-medium implementation work and fixes — inline TDD in the current session, no separate spec/plan documents and no subagents. This is the DEFAULT for routine changes. Triggers include "lite", "лайтом", "superpowers lite". Escalate to the full brainstorming → writing-plans → subagent-driven chain only for multi-subsystem features, high-risk changes, or when the user explicitly asks to "use superpowers".
---

# Superpowers Lite

A lightweight, single-session development flow for the everyday case: a focused
change in a codebase you already understand, where the full
brainstorming → spec → plan → subagent-driven apparatus would cost more than the
work itself.

This skill is the fast path. It keeps the parts of Superpowers that pay for
themselves on small work — TDD, a real review pass, frequent commits — and drops
the parts that only pay off on large multi-task features: separate design/plan
documents, fresh-subagent-per-task dispatch, and multi-stage review loops.

## When to use this (and when NOT)

Use **lite** when:
- The change touches a few files in a codebase whose patterns you already know.
- The goal is clear enough to state in one or two sentences.
- One person (you, in this session) can hold the whole change in context.

Escalate to the **full chain** (`superpowers-dim:brainstorming` → `writing-plans` →
`subagent-driven-development`) when ANY of these is true:
- The request spans multiple independent subsystems.
- The design is genuinely unclear and needs collaborative exploration first.
- The change is high-risk (auth, payments, data migration, concurrency, public API).
- The user explicitly says "use superpowers" / "давай через superpowers" / asks
  for a design doc or implementation plan.

If you start in lite and discover mid-flight that the task is actually one
of the escalation cases above — **stop and say so**. Offer to switch to the full
chain rather than forcing a large change through the light path.

## The Flow

1. **Scope inline (no document).** State, in 1–2 sentences in the chat, what you
   are building and the one or two key decisions. Get a quick nod if anything is
   ambiguous. Do NOT write a `design.md` or `plan.md` — the chat message IS the
   spec.

2. **Work test-first.** Follow `superpowers-dim:test-driven-development`: write the
   failing test, watch it fail, write the minimal code, watch it pass. Keep each
   red→green cycle small.

3. **Commit frequently.** One logical change per commit. Don't batch unrelated
   edits.

4. **One self-review pass.** Before declaring done, re-read your own diff with
   fresh eyes against the checklist below. Fix what you find inline — no separate
   reviewer subagent for routine work. (For anything you'd call risky, dispatch
   one reviewer via `superpowers-dim:requesting-code-review` instead of self-review.)

5. **Verify, then claim.** Follow `superpowers-dim:verification-before-completion`:
   run the actual tests/build and confirm the output before saying it works.
   Evidence before assertions.

6. **Report.** In a beads project, when the work runs under a bead, close out
   with bead bookkeeping and the checklist-style report below (see "Completion
   Report — beads projects only"). Otherwise report normally.

## Self-Review Checklist

- **Spec match:** does the diff do what step 1 said — no more (YAGNI), no less?
- **Tests:** does every new behavior have a test that would fail without the code?
- **Reuse:** did you duplicate something that already exists in the codebase?
- **Boundaries:** is each touched file still focused, or did one grow unwieldy?
- **Leftovers:** debug prints, commented-out code, TODOs you actually resolved?

## Completion Report (beads projects only)

**Detection:** `bd where` succeeds (or `.beads/` exists at the project root)
AND the work runs under a bead id — one from the dispatch prompt (BEAD_ID) or
a bead created for this work. Otherwise skip this section: report as usual and
do not mention beads.

Before the final message:

- `bd update {BEAD_ID} --status in_progress` — if not already; never leave it
  `open`. Leave it `in_progress`: the orchestrator closes it after the merge.
- `bd comments add {BEAD_ID} "Completed: <summary>"`

Final message format — completion-validation hooks in beads projects check for
exactly these elements, so keep it under 25 lines / 1200 chars:

```
BEAD {BEAD_ID} COMPLETE
Branch: bd-{BEAD_ID}        (or Worktree: .worktrees/bd-{BEAD_ID})
Checklist:
- [x] <requirement 1 from the bead description>
- [x] <requirement 2>
Files: <names only>
Tests: pass
Summary: <1 sentence>
```

Re-read `bd show {BEAD_ID}` first and derive the checklist from the bead's
description and acceptance criteria. Every item must be checked `[x]` — an
unchecked `[ ]` item means the work is not complete: finish it or update the
bead, don't ship the report.

## What this deliberately drops (vs. the full chain)

| Full chain | lite |
|---|---|
| `design.md` spec + user approval gate | 1–2 sentence inline scope |
| `plan.md` with bite-sized task breakdown | none — you hold the plan in context |
| fresh subagent per task | you implement directly in this session |
| implementer + task-reviewer + fix + re-review loop | one self-review pass |
| final whole-branch review subagent | optional `requesting-code-review` if risky |

The cost saved is mostly **context rebuilds** — the full chain re-establishes
context on every subagent dispatch. lite pays that once.

## Red Flags

- "This is actually three features" → stop, escalate to brainstorming.
- "I'm not sure what the user wants" → ask, or escalate to brainstorming. Don't
  guess your way through implementation.
- "I'll skip the test, it's trivial" → no. TDD is the part lite keeps.
- "It probably works" → run it. verification-before-completion is not optional.
