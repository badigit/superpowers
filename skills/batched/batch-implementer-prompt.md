# Batch Implementer Prompt Template

A **delta** over
[../subagent-driven-development/implementer-prompt.md](../subagent-driven-development/implementer-prompt.md).
Start from that template — it carries the questions-first rule, the code
organization rules, the escalation contract, and the self-review checklist,
and it stays in sync with upstream. Apply the changes below.

Keep the implementer's agent id: fixes go back to **this** agent via
`SendMessage`, not to a fresh fixer.

## Changes to the strict template

**1. Header — several tasks, not one**

```
    You are implementing Tasks N–M: [batch name]

    ## Task Descriptions

    Read your task briefs in order — they are your requirements, and the
    exact values in them are to be used verbatim:
    - Task N: [BRIEF_FILE_N]
    - Task N+1: [BRIEF_FILE_N+1]
    ...

    These tasks were batched because they share context: [one line on what
    they have in common — same module, same schema, same file set]. Do them
    in order; each builds on the last.
```

**2. Add — one commit per task**

```
    ## Commits

    Commit each task separately, with the task number in the subject
    (e.g. "feat(schema): add address table [Task 3]"). Do not squash the
    batch into one commit: the reviewer needs to attribute findings to
    tasks, and a rollback must be able to drop one task.
```

**3. Replace the TDD instruction with the risk-based rule**

```
    ## Testing Discipline

    Full TDD — write the failing test, watch it fail, then the minimal code
    — for: business logic, data transformation, parsing, migrations, error
    and edge-case handling.

    For mechanical work (schemas, config, wiring, static files): validation
    (schema check, lint) plus at least one smoke or integration test
    covering the batch as a whole.

    If a task you were told is mechanical turns out to contain a branch, a
    conversion, or an error path, treat it as logic: write the test first
    and say so in your report.
```

**4. Replace the report format**

```
    ## Report Format

    Write your full report to [REPORT_FILE], with a section per task:
    - Task N: what you implemented, files changed, tests and their results,
      TDD evidence (RED/GREEN commands and relevant output) where full TDD
      applied, self-review findings
    - ...one such section per task in the batch

    Then report back with ONLY (under 20 lines — detail lives in the report
    file):
    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
    - One line per task: task number, short SHA, one-line test summary
    - Which tasks got full TDD and which rode on batch smoke tests
    - Your concerns, if any
    - The report file path

    A partial batch is reportable: if tasks N and N+1 are done and N+2 is
    blocked, report DONE for what landed and BLOCKED with specifics for the
    rest. Never abandon finished work because a later task stalled.
```

**5. Add — stay available**

```
    ## After Review

    You will likely receive review findings as a follow-up message in this
    same session. Do not treat your report as the end: keep your
    understanding of the code available. When findings arrive, fix them,
    re-run the tests covering the amended code, and append the results to
    your report file.
```

## Placeholders

- `[MODEL]` — REQUIRED: per the SKILL.md model ladder. Cheap tier only when
  the plan text already contains the code for every task in the batch.
- `[BRIEF_FILE_*]` — REQUIRED: one per task, from
  `../subagent-driven-development/scripts/task-brief PLAN_FILE N`
- `[REPORT_FILE]` — REQUIRED: one report file for the whole batch
  (`…/batch-N-report.md`)
