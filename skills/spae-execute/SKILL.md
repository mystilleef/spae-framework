---
name: spae-execute
description:
  Comprehensive Execution for the `SPAE` framework. Executes all tasks
  from `PLAN.md` sequentially in one invocation.
user-invocable: false
---

# Execute (`SPAE`)

## When to use

- `STATE.json` has `phase: build`.
- The `workstream` needs all remaining `PLAN.md` tasks completed in one
  invocation.
- The plan has low risk, routine scope, or clear acceptance criteria.

## Goal

- Complete every remaining task, verify each slice, and advance durable
  `workstream` state without relying on conversational memory.
- Execute all remaining `.spae/current/PLAN.md` tasks sequentially.
- Keep each task's production code minimal, its tests exhaustive, and
  its implementation aligned with its `Intent`, the plan `## Goal`, and
  acceptance criteria.
- Leave the `workstream` ready for `/verify`.

## Input

Read:

- `.spae/current/STATE.json` for phase, cursor, task registry, and
  metrics.
- `.spae/current/PLAN.md` for the plan `## Goal`, the remaining tasks,
  their `Intent`, acceptance criteria, and verification steps—these
  carry all the goal context execute needs.
- Relevant source, tests, configuration, and documentation.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Workflow

Repeat `ACT → VERIFY → PERSIST` for each task in plan order.

1. **GATE**—Read `STATE.json`; confirm `phase: build`; reset any
   `in_progress` task to `todo` (prior interrupted run); identify all
   **todo** tasks in plan order. Halt on phase mismatch.
2. **ORIENT**—Read the plan `## Goal` and all remaining tasks (including
   each `Intent`, acceptance criteria, and verification steps) from
   `PLAN.md`.
3. **PLAN**—Confirm the plan advances the `## Goal`, not merely literal acceptance criteria.
4. **ACT** (per task)—Verify all task `Dependencies` carry `done` in
   `STATE.json`; halt with a blocker on any incomplete dependency. Set
   `cursor.task_status` and `tasks[task_id]` to `"in_progress"` in
   `STATE.json`. Read `references/testing-guide.md`. Iterate over every
   acceptance criterion:
   - Write a failing test: expected behavior, failure modes, and edge
     cases.
   - Write minimal code to pass it.
   - Drive green; repeat `test→implement` until the criterion passes.

   Stop when all criteria have exhaustive passing test coverage. Keep
   later tasks' seams open. Never merge, reorder, or skip ahead.

5. **VERIFY** (per task)—Loop over every verification step for the
   active task:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when all steps pass.
   - Halt only for out-of-scope blockers: infeasible criterion,
     plan/spec defect, or broken external dependency; never by gaming a
     test or editing the plan. Record the blocker in `STATE.json`, leave
     remaining tasks `todo`, and halt.
6. **PERSIST** (per task)—Mark the task `done`; update cursor, task
   registry, blockers, and metrics in `STATE.json`.
7. **REPORT**—Set `phase: verify` in `STATE.json`; emit result using the
   Result template.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Execute tasks sequentially in one invocation.
- Keep production code minimal, local, and test-driven; never reduce
  test scope.
- Tests drive every task; write them first, exhaustively, before any
  production code. Implementation serves tests—never the reverse.
- Write every category of test the task demands—unit, integration,
  end-to-end, or otherwise. Cover expected behavior, failure modes, and
  edge cases exhaustively.
- When the task legitimately changes a contract, update the tests it
  invalidates to the new contract; never weaken, skip, or delete a test
  to force green.
- Aim each task at its `Intent` and the plan `## Goal`; choose among
  valid implementations by goal fit, not local convenience.
- Halt when a task as written logically contradicts the plan `## Goal`,
  its `Intent`, or another task—an undeniable conflict, not a subjective
  doubt; record the blocker, leave remaining tasks `todo`, and stop.
  Leave ambiguous interpretation to `/verify`.
- Follow existing codebase patterns over speculative design.
- Preserve the selected execution mode for the `workstream`; don't mix
  `/build`, `/tdd`, and `/execute`.
- Report SUCCESS only after every remaining task passes verification.

## Constraints

- **Authorized writes**: Source code, tests, configuration, docs, other
  non-`SPAE` project files, and `.spae/current/STATE.json`.
- **Forbidden writes**: Never edit `.spae/current/PLAN.md`,
  `.spae/current/SPEC.md`, or `.spae/` artifacts other than
  `.spae/current/STATE.json` during execution.
- **Blockers**: Drive each task's verification green before advancing;
  treat red as ordinary work. Block only when verification can't pass
  within task scope—never to escape fixing your own code, never by
  gaming a test or editing the plan. On a blocker, record it in
  `.spae/current/STATE.json`, leave remaining tasks `todo`, report, and
  halt.
- **Version control**: Never stage or commit `.spae/` artifacts.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.
- Never introduce fields to `STATE.json` outside the schema reference.
- No hacks, workarounds, or shortcuts.
- Forbid laziness; fix issues properly, correctly, and idiomatically.
- Never edit build or tool configuration files as a workaround; build
  and tool configuration changes only apply when the active task's
  acceptance criteria explicitly require them.
- Never suppress or disable compiler or linter diagnostics; for example,
  `@ts-ignore`, `eslint-disable`, `@SuppressWarnings`, `# type: ignore`.
- Never weaken type contracts to silence errors; for example, `as any`,
  `!` non-null assertions, or broadening union types.

## Verification

- Every completed task meets its acceptance criteria.
- Every task verification step passes.
- Task tests cover expected behavior, failure modes, and edge cases
  exhaustively; no thin-coverage shortcuts.
- Each completed task advances its `Intent` and the plan `## Goal`.
- `.spae/current/STATE.json` accurately records completed tasks,
  metrics, cursor, blockers, and `phase: verify` after full completion.
- `.spae/current/PLAN.md` and `.spae/current/SPEC.md` remain unchanged.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Prefer lists, and sub-lists, over long paragraphs and sentences.
- Strictly follow the result template below.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Tests**:
  - [Terse list of tests written — behaviors, failure modes, and edge cases covered]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [Key gaps, risks, blockers, or notable observations]
- **Summary**:
  - [Summary of implementation changes]

> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Complete | Blocked | Failed]
> **Phase Complete**: `/execute`
> **Progress**: All [X] tasks completed
> **Completed**: [`T-001` through `T-XXX`]
> **Next Phase**: `/verify`
> **Impact**: [Terse impact statement]
>
> _Run `/verify` to validate the implementation against the specification._
```
<!-- prettier-ignore-end -->
