# Budget Rules (fork addition)

Part of superpowers:subagent-driven-development.

Apply these three rules only when your human partner asked to spend less
("economically", "in batches", "cheaper", "экономно", "батчами", "подешевле") and no task
in the plan is high-risk. They trade review coverage for cost; do not spend that currency
where a missed defect is expensive.

On a budget run these rules override the conflicting defaults in SKILL.md (the
"every round ends with a scoped re-review" rationalization row and the re-review
step in references/fix-loop.md) for non-high-risk tasks only.

**High-risk stays strict.** Auth, payments, data migration, concurrency, public API, or
anything your human partner called risky: one implementer and one reviewer per task, a
scoped re-review after every fix round, TDD throughout. None of the rules below applies.

## 1. Triage the tasks before the first dispatch

Read the plan once and sort every task. Show the triage as one short table so your human
partner can move a task between buckets, then execute without asking again.

| Bucket | Test | Who does it |
|---|---|---|
| **Transcription** | the plan already contains the code; the work is typing it and running the tests | you, inline. A subagent would pay a full context rebuild to type text you already hold |
| **Related** | ordinary implementation that shares context with its neighbours: same module, same schema, same file set | one implementer for 2-4 tasks. Batch by cohesion, not only by sameness of shape |
| **Solo-risk** | touches a schema, a public interface, secrets, real data, or the network; or later tasks depend on getting it exactly right | its own implementer and its own reviewer |

Two unrelated tasks in one dispatch cost the same as two dispatches and lose the fresh
context. Batch only when task N+1 reuses what the implementer learned in task N.

## 2. Re-review only on Critical

After a fix round, run the scoped re-review only when the review reported a Critical issue.
Important and Minor fixes are checked by the controller against the diff. This overrides the
"every round ends with a scoped re-review" default for budget runs only. The final
whole-branch review is unchanged and always runs.

## 3. Risk-based TDD

Mechanical tasks (renames, moving code, config values, copying a pattern across files) get no
new test; the existing suite must stay green. Tasks that add or change behavior keep
test-first. When unsure which it is, it is behavior.
