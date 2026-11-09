---
name: spae-build
description:
  Atomic Execution for the `SPAE` framework. Executes exactly one atomic
  task from `PLAN.md`.
user-invocable: true
---

# Build (`SPAE`)

## When to use

- `STATE.json` reads `phase: build`: implement the active `PLAN.md`
  task.

## Goal

- Implement exactly the active `PLAN.md` task, test-first, so it meets
  every `Acceptance` criterion, serves its `Intent` and the plan
  `## Goal`, and leaves seams for forward tasks.
- Advance the `workstream` to `phase: check`.

## Input

Read only what the active task requires:

- `.spae/current/STATE.json`; `references/STATE.md` holds field
  reference, directives, and snapshots.
- `.spae/current/PLAN.md`; it carries all goal context.
- Repository source, tests, docs, and configuration the active task
  touches.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Cleanup

See `references/cleanup-guide.md` for the self-introduced-artifact
checklist and diff-only audit scope.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json`; self-heal missing metadata:
     `version` (`"1.0"`), `workstream` (target directory name), `status`
     (`"active"`); `PERSIST` writes the healed fields.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - `PLAN.md` stays unmodified; forward tasks stay unbuilt.
   - Read the plan `## Goal` and the active task in full; read the
     `Acceptance` of its `Dependencies` tasks as the contracts it may
     rely on, and of forward tasks as seams to keep open.
   - Capture the pre-task baseline per `references/cleanup-guide.md`.
   - Mark in progress—the sole write before `PERSIST`; reruns repeat it
     safely: set `STATE.json` `tasks[active_task_id]` to
     `"in_progress"`.
3. **PLAN**—Declare the implementation path:
   - Read `references/testing-guide.md` and
     `references/shell-command-guide.md`.
   - Map the test surface per `Acceptance` criterion: expected
     behaviors, failure modes, and edge cases.
   - Choose among valid implementations by fit to the task `Intent`, the
     plan `## Goal`, and forward seams, not local convenience.
   - Halt on any **Halt conditions** entry.
4. **ACT**—Per `Acceptance` criterion, repeat `test→implement` until it
   passes:
   - Write a failing test: expected behavior, failure modes, and edge
     cases.
   - Write the minimal code that passes it.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for the active task:
   - Audit task edits against the pre-task baseline using the
     Self-cleanup checklist in `references/cleanup-guide.md`; remove
     every self-introduced artifact before proceeding.
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - Write `STATE.json` per `references/STATE.md` exit snapshot.
   - Re-read `STATE.json`; on a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit result following result directives and using result
   template:
   - `Result`: `Implemented, pending check` after `PERSIST`, else
     `Failed`.
   - List under `Findings`: each assumption made and each forward task
     designed around.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- Never write production code before its test exists; write every test
  category the task demands—unit, integration, end-to-end.
- Treat a failing test or check as ordinary build work; drive it green.
- When the task legitimately changes a contract, update the tests it
  invalidates to the new contract.
- Execute `Verification` steps as planned per
  `references/verification-guide.md`; never discover, install, or
  calibrate tooling ad hoc.
- Resolve underspecified requirements with the assumption most
  consistent with the task `Intent` and the plan `## Goal`, then
  proceed; never ship a locally correct, globally wrong implementation.

## Constraints

- **Write scope**: edit only the source, tests, docs, and configuration
  the active task requires, plus `.spae/current/STATE.json`; forbid all
  other writes. Byproducts of a command run for evidence, such as a
  formatter's rewrites, never count as this phase's writes; never run a
  command for its write effect outside this scope. Never delete
  pre-existing uncommitted files.
- **Phase boundary**: execute exactly one task; hand off work to
  `/check`; never mark a task `"done"` or move the cursor.
- **Version control and release**: never execute git mutations (staging,
  commits, branches, tags, pushes) or release operations. Never stage or
  commit `.spae/`.
- **Autonomy**: never ask users for input or clarification
  mid-execution; halts and failures stop autonomously. Never perform or
  request human execution, an attended or interactive terminal, or human
  presence.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt with no further `STATE.json` write; report
  `Failed` with a diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `build`.
  - `PLAN.md` missing, `cursor.active_task_id` missing, or the active
    task absent from `PLAN.md`.
  - `tasks[active_task_id]` reads `"done"`.
  - A `Dependencies` task not `"done"` in `tasks`.
  - The task can't pass within its scope: an infeasible `Acceptance`
    criterion, a broken external dependency, an unrunnable planned
    `Verification` step, a step requiring human presence, or the task as
    written contradicting the plan `## Goal`, its `Intent`, or a forward
    task—an undeniable conflict, not a subjective doubt.
- **Scope control**: no incidental refactoring, cleanup, formatting, or
  dependency churn outside the active task.
- **Integrity**: fix issues properly and idiomatically; no hacks,
  workarounds, or shortcuts:
  - Never suppress compiler or linter diagnostics—for example,
    `@ts-ignore`, `eslint-disable`, `@SuppressWarnings`,
    `# type: ignore`.
  - Never weaken type contracts to silence errors—for example, `as any`,
    `!` non-null assertions, or broadened union types.
  - Never edit build or tool configuration as a workaround; change it
    only when an `Acceptance` criterion requires it.
  - Never weaken, skip, delete, or game a test to force a pass.

## Verification

- Every `Acceptance` criterion passes.
- Every task `Verification` step passes.
- Relevant project tests pass with no new failures.
- Task tests cover expected behavior, failure modes, and edge cases
  exhaustively; no thin-coverage shortcuts.
- Every added or updated test passes the CI parity rules in
  `references/testing-guide.md`.
- No self-introduced artifact remains per `references/cleanup-guide.md`.
- Implementation advances the task `Intent` and the plan `## Goal`; no
  forward-task work performed.
- The task diff breaks no **Integrity** rule.
- `STATE.json` specifies `phase: "check"`,
  `tasks[active_task_id]: "in_progress"`, and the entry cursor.
- This phase wrote no file outside **Write scope**.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`; a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, abort, or halt—with the
  result template as the final message; never end on progress narration.
- Set `Result` to exactly one template literal, verbatim; report an
  abort or halt lacking its own literal as `Failed`, with the reason
  under `Findings`.
- Emit result template as live markdown—never in a code fence.
- Output nothing outside template.
- Source every `SPAE Status` value from confirmed re-read, never from
  working memory of intent.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of affected files]
- **Tests**:
  - [Terse list of tests written—behaviors, failure modes, and edge cases covered]
- **Findings**:
  - [Terse list of notable findings]
- **Summary**:
  - [Terse list of summary of changes]

> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Implemented, pending check | Failed]
> **Active Task**: `T-XXX` - [Task title]
>
> _Run `/check` to verify the completed task._  _(unless failed)_
```
<!-- prettier-ignore-end -->
