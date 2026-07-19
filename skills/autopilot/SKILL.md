---
name: autopilot
description: Autonomous full-cycle development — run the entire brainstorming → writing-plans → subagent-driven-development → finishing chain end-to-end WITHOUT pausing at human approval gates. Use ONLY when the user explicitly opts in with phrases like "autopilot", "yolo", "автономно", "не спрашивай — сделай сам", "прогони весь цикл сам". ALSO use mid-chain — when a spec/design was just approved collaboratively and the user says to continue autonomously ("дальше сам", "дальше на автопилоте", "исполнение автономно") — enter at writing-plans and run to the end. Replaces every optional human checkpoint with a self-review and proceeds; halts ONLY for a genuine blocker, outcome-changing ambiguity, or before deploying.
---

# Autopilot (Autonomous Superpowers)

Maximum-trust mode. The user has explicitly delegated the whole development
cycle. Run it end to end and report when done — do not stop for approval at
gates that exist only for a human-in-the-loop.

<TRUST-CONTRACT>
The user opted into autonomy. Treat every "present to the user and wait for
approval" instruction in the skills invoked below as a SELF-REVIEW gate instead:
check the same criteria yourself, record the decision in one line, and proceed.
Do NOT emit "Should I continue?" / "Does this look right?" / progress check-ins.
They asked you to run it — run it.
</TRUST-CONTRACT>

## When this applies

Only on explicit opt-in: "autopilot", "yolo", "автономно", "не спрашивай —
сделай сам", "прогони весь цикл сам". Without that phrase, use `lite`
(default) or the gated `superpowers-dim:brainstorming` chain. If you are unsure
whether the user opted into autonomy, you are NOT in autopilot — fall back to
the gated path.

## Entry points

**Full cycle (from scratch).** The user hands over the whole task. Start at
step 1 below; the design too is self-approved.

**Mid-chain handoff (the common case).** The user participated in
brainstorming — the design/spec was discussed and approved collaboratively —
and then says "дальше сам" / "дальше на автопилоте" / "исполнение автономно".
Skip step 2: the approved spec IS the contract. Do not re-litigate or expand
it; treat every decision recorded in it as user-approved. Enter at step 3
(Plan) and run to the end. If, while planning or building, you discover the
spec is materially wrong or incomplete — that is halt condition #2, not a
license to redesign silently.

## Loop-readiness (running under ralph-loop or repeated re-invocation)

Autopilot is safe to re-enter: the chain's state lives on disk, not in
conversation memory. On every (re)entry, before doing anything else, resume
from durable state instead of restarting:

1. Spec exists in `docs/superpowers/specs/` (beads projects:
   `.designs/bd-<id>/spec.md`)? → design is done, don't redo it.
2. Plan exists in `docs/superpowers/plans/` (beads projects:
   `.designs/bd-<id>/plan.md`)? → planning is done, don't redo it.
3. Progress ledger (`.superpowers/sdd/progress.md`) lists completed tasks? →
   trust it and `git log`; resume at the first task not marked complete. Never
   re-dispatch a completed task.
4. All tasks complete? → proceed to finishing (merge + push), then report and
   stop.

This makes autopilot idempotent: a loop that re-invokes it converges on the
integrated branch instead of duplicating work.

## Halt conditions — the ONLY reasons to stop and ask

Stop and surface to the user when, and only when:

1. **Genuine blocker** you cannot resolve — missing dependency, a verification
   that fails and you can't fix, contradictory requirements.
2. **Outcome-changing ambiguity** — a decision where picking wrong would build
   the wrong thing, and neither the spec nor the codebase settles it. Autonomy
   is not permission to guess about what the user actually wants. This
   includes newly discovered forks: mid-build you uncover a design-affecting
   choice, alternative approaches, or a fact that invalidates a spec
   assumption.

   **How to ask when this fires:** present the fork as ONE concrete question —
   what you discovered, 2-3 options with trade-offs, and your recommendation.
   Batch related discoveries into a single interrupt instead of a stream of
   questions. After the answer, record the decision in the spec/plan and
   resume fully autonomously — a halt is a data request, not a mode change
   back to gated confirmations.
3. **Deploy.** You MAY commit, push, and integrate the finished branch into
   main/master autonomously (per `~/.claude/rules/git-integration.md`: merge +
   push, or a self-merged PR). You may NOT deploy to any live environment —
   stop there and hand it back.

Everything else proceeds without a check-in.

## The Autonomous Cycle

1. **Isolate.** Use `superpowers-dim:using-git-worktrees` for an isolated branch/
   worktree. Never run autopilot on main/master directly.
2. **Design (self-approved).** Run `superpowers-dim:brainstorming` to produce the
   spec, but self-approve each section instead of waiting. Still write the spec
   doc and run the spec self-review. An outcome-changing clarifying question is
   a halt condition (#2); otherwise pick the sensible default, record it in one
   line, move on.
3. **Plan (self-approved).** Run `superpowers-dim:writing-plans`. Auto-select
   subagent-driven execution (the recommended path) without asking. Run the plan
   self-review.
4. **Build.** Run `superpowers-dim:subagent-driven-development` end to end — it is
   already continuous (no between-task check-ins). Honor its review loops fully;
   autonomy removes the human gates, NOT the quality gates.
5. **Finish.** Run `superpowers-dim:finishing-a-development-branch` — its
   autonomous default: confirm tests pass, merge into the base branch, push
   (or push + self-merged PR when the base is busy or repo convention wants a
   PR), clean up the branch. Report what was merged. Do NOT deploy.

## Report at the end

When the cycle completes (or halts), give one compact report: what was built,
the spec and plan file paths, the merged branch (and PR link if one was
used), test results, and any
decisions you self-approved that the user might want to revisit.
`superpowers-dim:verification-before-completion` still applies — evidence before
claims.

## Red Flags

- "Should I proceed?" mid-cycle — defeats the mode. Proceed.
- Guessing what the user wants when it is genuinely unclear — that is a halt
  (#2), not a guess. Autonomy ≠ recklessness.
- Deploying because "it all passed" — never. Merging to main after green
  verification is the default (git-integration rule); deploy is the hard stop.
- Skipping a sub-skill's review loop to go faster — never. The quality gates
  stay; only the human approval gates are auto-passed.
- Running on main/master without a worktree/branch — never.
