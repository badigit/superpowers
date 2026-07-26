# Batch Reviewer Prompt Template

A **delta** over
[../subagent-driven-development/task-reviewer-prompt.md](../subagent-driven-development/task-reviewer-prompt.md).
Start from that template — it carries the do-not-trust-the-report rule, the
do-not-re-run-tests rule, the read-only constraint, the severity
calibration, and the evidence requirement, and it stays in sync with
upstream. Apply the changes below.

## Changes to the strict template

**1. Header — a batch, still judged per task**

```
    You are reviewing one batch of tasks: for each task, whether it matches
    its requirements, and whether it is well-built. This is a batch-scoped
    gate, not a merge review — a broad whole-branch review happens
    separately after all batches are complete.

    ## What Was Requested

    Read the task briefs:
    - Task N: [BRIEF_FILE_N]
    - Task N+1: [BRIEF_FILE_N+1]
    ...

    Global constraints from the spec/design that bind these tasks:
    [GLOBAL_CONSTRAINTS]
```

**2. Add — attribute every finding to a task**

```
    The diff spans several tasks, one commit (or more) per task, with the
    task number in each commit subject. Attribute every finding to the task
    that introduced it. A finding you cannot attribute is still a finding —
    report it under "Cross-task".
```

**3. Add — the coverage rule this mode depends on**

```
    ## Test Coverage Is Part of the Spec Here

    This batch was executed under risk-based TDD: full TDD for logic, data
    transformation, parsing, migrations, and error paths; validation plus a
    batch-level smoke test for mechanical work (schemas, config, wiring).

    The implementer's report states which task got which. Check that
    classification against the diff. A task that contains a branch, a
    conversion, or an error path but was tested as "mechanical" is a
    finding — Important, not Minor. This is the gate that keeps the mode
    honest; do not soften it.
```

**4. Replace the output format**

```
    ## Output Format

    ### Per Task

    For each task in the batch, in order:

    #### Task N
    - **Spec:** ✅ compliant | ❌ [what's missing/extra/misunderstood, with
      file:line] | ⚠️ cannot verify from diff: [what the controller must check]
    - **Quality:** Approved | Needs fixes
    - **TDD classification:** correct | miscategorised: [which task, why]
    - Findings: Critical / Important / Minor, each with file:line, what's
      wrong, why it matters, how to fix

    ### Cross-task
    Findings that span tasks or that you could not attribute to one.

    ### Strengths
    [Specific — accurate praise makes the rest credible.]

    ### Assessment
    **Batch quality:** Approved | Needs fixes
    **Reasoning:** [1-2 sentences]
```

A single verdict for the whole batch is not acceptable output. If the
reviewer returns one, re-dispatch asking for the per-task pairs — that
collapse is exactly how a missed requirement survives batching.

## Placeholders

- `[MODEL]` — REQUIRED: standard tier by default. A cheap reviewer misses
  what it was hired to find.
- `[BRIEF_FILE_*]` — REQUIRED: one per task in the batch
- `[GLOBAL_CONSTRAINTS]` — binding requirements copied verbatim from the
  plan's Global Constraints or the spec
- `[REPORT_FILE]` — REQUIRED: the batch report the implementer wrote
- `[BASE_SHA]` — the commit recorded **before the batch was dispatched**,
  never `HEAD~1`
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — REQUIRED: path printed by
  `../subagent-driven-development/scripts/review-package BASE HEAD`
