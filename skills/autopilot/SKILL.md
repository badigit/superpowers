---
name: autopilot
description: Autonomous full-cycle development — run the entire brainstorming → writing-plans → subagent-driven-development → finishing chain end-to-end WITHOUT pausing at human approval gates. Use ONLY when the user explicitly opts in with phrases like "autopilot", "yolo", "автономно", "не спрашивай — сделай сам", "прогони весь цикл сам". Replaces every optional human checkpoint with a self-review and proceeds; halts ONLY for a genuine blocker, outcome-changing ambiguity, or before merging to the default branch / deploying.
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
сделай сам", "прогони весь цикл сам". Without that phrase, use `superpowers-lite`
(default) or the gated `superpowers:brainstorming` chain. If you are unsure
whether the user opted into autonomy, you are NOT in autopilot — fall back to
the gated path.

## Halt conditions — the ONLY reasons to stop and ask

Stop and surface to the user when, and only when:

1. **Genuine blocker** you cannot resolve — missing dependency, a verification
   that fails and you can't fix, contradictory requirements.
2. **Outcome-changing ambiguity** — a decision where picking wrong would build
   the wrong thing, and neither the spec nor the codebase settles it. Autonomy
   is not permission to guess about what the user actually wants.
3. **Default-branch merge or deploy.** You MAY commit, push a feature branch,
   and open a PR autonomously. You may NOT merge to main/master or deploy —
   stop there and hand it back.

Everything else proceeds without a check-in.

## The Autonomous Cycle

1. **Isolate.** Use `superpowers:using-git-worktrees` for an isolated branch/
   worktree. Never run autopilot on main/master directly.
2. **Design (self-approved).** Run `superpowers:brainstorming` to produce the
   spec, but self-approve each section instead of waiting. Still write the spec
   doc and run the spec self-review. An outcome-changing clarifying question is
   a halt condition (#2); otherwise pick the sensible default, record it in one
   line, move on.
3. **Plan (self-approved).** Run `superpowers:writing-plans`. Auto-select
   subagent-driven execution (the recommended path) without asking. Run the plan
   self-review.
4. **Build.** Run `superpowers:subagent-driven-development` end to end — it is
   already continuous (no between-task check-ins). Honor its review loops fully;
   autonomy removes the human gates, NOT the quality gates.
5. **Finish.** Run `superpowers:finishing-a-development-branch`, but instead of
   presenting merge/PR/cleanup options, auto-pick: confirm tests pass, push the
   branch, open a PR, then STOP. Report the PR. Do not merge to the default
   branch, do not deploy.

## Report at the end

When the cycle completes (or halts), give one compact report: what was built,
the spec and plan file paths, the branch/PR link, test results, and any
decisions you self-approved that the user might want to revisit.
`superpowers:verification-before-completion` still applies — evidence before
claims.

## Red Flags

- "Should I proceed?" mid-cycle — defeats the mode. Proceed.
- Guessing what the user wants when it is genuinely unclear — that is a halt
  (#2), not a guess. Autonomy ≠ recklessness.
- Merging to main or deploying because "it all passed" — never. Stop at the PR.
- Skipping a sub-skill's review loop to go faster — never. The quality gates
  stay; only the human approval gates are auto-passed.
- Running on main/master without a worktree/branch — never.
