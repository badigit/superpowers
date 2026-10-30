---
name: beads-bridge
description: Use when a Superpowers skill (brainstorming, writing-plans, verification-before-completion, finishing-a-development-branch) points here, or whenever the project has a beads workspace (`bd where` succeeds or `.beads/` exists) and you are about to save a spec or plan, claim completion, or integrate a branch. Maps specs, plans and lessons onto beads. Not for projects without beads.
---

# Beads Bridge

Superpowers skills keep their own state in dated files under `docs/superpowers/`.
In a project with a beads workspace the work belongs to a **bead** instead, so
specs, plan tasks and lessons must land there. This skill holds those rules in
one place; the Superpowers skills only point here.

**Detection:** run `bd where` quietly, or check for a `.beads/` directory at the
project root. No beads workspace → this skill does not apply. Behave exactly as
the calling skill says and do not mention beads to the user.

## Identify the bead

Use the id you were dispatched with (BEAD_ID), or the bead or epic already being
discussed. If none exists yet, offer to create one before writing the spec:

```bash
bd create "<feature>" -d "<one-line summary>" [--type epic]
```

Use `--type epic` when the work clearly breaks into several tasks.

## Spec (called from brainstorming)

Save the design document to `.designs/bd-{id}/spec.md` at the project root instead
of `docs/superpowers/specs/`. Commit it as usual. Everything else in brainstorming
(builder check, user approval gate, hand-off to writing-plans) is unchanged.

## Plan (called from writing-plans)

1. Save the plan to `.designs/bd-{id}/plan.md`, next to the spec, instead of
   `docs/superpowers/plans/`.
2. Record the path on the bead so `bd show {id}` shows it:
   `bd update {id} --design ".designs/bd-{id}/plan.md"`
3. Create the plan's tasks as child beads. The parent bead acts as the epic:
   - one child per task:
     `bd create "Task N: <component>" -d "See .designs/bd-{id}/plan.md — Task N" --parent {id}`
   - ordering: a task that waits for another is blocked by it,
     `bd dep add {child-N+1} {child-N}`. Then `bd ready` yields exactly the
     unblocked tasks.

   The plan stays the single source of detail. Child beads are the tracking layer
   that survives context compaction. Keep the checkbox steps in the plan.
4. During execution, implementers mark their child bead `in_progress` and log
   progress with `bd comments add`. The orchestrator closes children as they merge.

## Lesson (called from verification-before-completion and finishing)

Once verification has passed, or before integrating the branch, store the
non-obvious lesson this work produced:

```bash
bd remember "<problem> → <solution>. <why>"
```

Only findings worth looking up later qualify: root cause plus fix plus why, a
gotcha, an undocumented constraint. "Tests pass" is not a memory. One line per
insight. If the work taught nothing non-obvious, or the same insight was already
stored for this work, store nothing.
