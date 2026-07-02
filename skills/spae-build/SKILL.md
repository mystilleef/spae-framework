---
name: spae-build
description:
  Atomic execution for the project framework. Executes exactly one
  atomic task from `PLAN.md`.
user-invocable: true
---

# Build

## When to use

- `STATE.json` has `phase: build`.
- The work stream needs the next planned task completed.
- The user chose `/build` as the execution mode for the work stream.

## Goal

- Execute exactly one task from `PLAN.md`, mutating source/tests plus
  `STATE.json`, while preserving the framework execution cursor.
- Complete the active task with minimal production code that satisfies
  exhaustive tests, serves its `Intent` and the plan `## Goal`, and
  leaves seams for downstream tasks.
- Meet the task acceptance criteria through exhaustive tests and task
  verification steps.
- Advance `.spae/current/STATE.json` to the next task or to
  `phase: verify`.

## Input

Read:

- `.spae/current/STATE.json` for phase, cursor, task registry, and
  metrics.
- `.spae/current/PLAN.md` for the plan `## Goal`, the active task, its
  `Intent`, acceptance criteria, and verification steps; they carry all
  the goal context build needs.
- Relevant project source, tests, docs, and configuration needed for the
  active task.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Shell commands

See `references/shell-command-guide.md` for command safety, timeouts,
redirects, and non-interactive environment directives.

## Workflow

1. **GATE**—Confirm `.spae/current/STATE.json` has `phase: build` and an
   active task. Read the plan `## Goal` and active task section —
   including its `Intent` — from `.spae/current/PLAN.md`. Read dependent
   and forward task titles plus acceptance criteria to map seams, not
   build them. Verify every task ID in the active task's `Dependencies`
   field carries `task_status: done` in `STATE.json`; halt with a
   blocker for any incomplete dependency.
2. **ORIENT**—State the goal in one sentence: execute the active task
   and advance the cursor. Name what won't change: `PLAN.md`, `SPEC.md`,
   and forward-task seams. **Cursor exception**: set
   `cursor.task_status` and `tasks[active_task_id]` to `"in_progress"`
   in `.spae/current/STATE.json`.
3. **PLAN**—Declare the full implementation path that satisfies every
   acceptance criterion, advances the task `Intent` and plan `## Goal`,
   and leaves seams for forward tasks. Read
   `references/testing-guide.md` and
   `references/shell-command-guide.md`. Map the test surface per
   criterion: expected behaviors, failure modes, and edge cases. Choose
   among valid implementations by goal fit, not local convenience. Run
   `vibe-check` only when the slice carries ambiguity, complexity, risk,
   or irreversibility; skip trivial, reversible, single-step work; when
   unsure, run it. Don't surface its exchange to the user.
4. **ACT**—Iterate over every acceptance criterion:
   - Write a failing test: expected behavior, failure modes, and edge
     cases.
   - Write minimal code to pass it.
   - Drive green; repeat `test→implement` until the criterion passes.

   Stop when all criteria have exhaustive passing test coverage. Never
   write production code before its test exists. Edit only source,
   tests, docs, or configuration files required by the task.

5. **VERIFY**—Loop over every acceptance criterion and verification
   command listed for the active task:
   - Audit every new test file against CI Parity rules in
     `references/testing-guide.md`; fix any violation before proceeding.
   - For each unmet criterion or failing command: return to `ACT`,
     execute, then re-enter `VERIFY`.
   - Exit only when all criteria pass and all commands succeed.
   - Halt only for out-of-scope blockers: infeasible acceptance
     criterion, plan/spec defect, or broken external dependency.
6. **PERSIST**—Mark the active task `done` in
   `.spae/current/STATE.json`, increment completion metrics, and advance
   the cursor to the next task. If no next task remains, set
   `phase: verify`.
7. **REPORT**—Emit the result following the result directives and using
   the result template.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Execute exactly one atomic task per invocation.
- Prefer existing project patterns over new design.
- Keep production code minimal, local, and test-driven; never reduce
  test scope.
- Look ahead, don't act ahead: read forward tasks to avoid foreclosing
  them; never build beyond the active task. Name any forward task you
  designed around in the result.
- Tests drive every task; write them first, exhaustively, before any
  production code. Implementation serves tests, never the reverse.
- Write every category of test the task demands: unit, integration,
  end-to-end, or otherwise. Cover expected behavior, failure modes, and
  edge cases exhaustively.
- When the task legitimately changes a contract, update the tests it
  invalidates to the new contract; never weaken, skip, or delete a test
  to force green.
- Run task verification before changing `.spae/current/STATE.json`.
- Drive verification green; treat red as ordinary build work. Halt with
  a blocker only when verification can't pass within task scope:
  infeasible acceptance criterion, plan/spec defect, or broken external
  dependency; never to escape fixing your own code, never by gaming a
  test or editing the plan.
- Halt with a blocker when the task as written logically contradicts the
  plan `## Goal`, the task `Intent`, or a downstream task—an undeniable
  conflict, not a subjective doubt. Record it in
  `.spae/current/STATE.json`. Leave ambiguous interpretation to
  `/verify`; never ship a locally correct, globally wrong
  implementation.
- When task requirements lack detail, choose the assumption most
  consistent with the task `Intent` and plan `## Goal`, record it in
  `.spae/current/STATE.json`, and proceed.

## Constraints

- Exercise exclusive authority to edit source code, tests,
  documentation, configuration, and other non-framework project files
  during this phase.
- Never edit `.spae/current/PLAN.md` during `/build`.
- Never edit `.spae/current/SPEC.md` during `/build`.
- Never execute more than one task.
- Never alternate execution mode for the same `workstream`; respect the
  user's selected `/build` path.
- Never stage or commit `.spae/` artifacts.
- Avoid incidental refactoring, cleanup, formatting, or dependency churn
  outside the active task.
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

- Active task acceptance criteria pass.
- All task verification steps pass.
- Relevant project tests pass with no new failures.
- Task tests cover expected behavior, failure modes, and edge cases
  exhaustively; no thin-coverage shortcuts.
- All new tests pass CI Parity audit in `references/testing-guide.md`.
- Implementation advances the task `Intent` and plan `## Goal`; no
  forward-task work performed.
- `.spae/current/STATE.json` task registry, metrics, cursor, and phase
  reflect the completed task, and the relevant tasks marked as `done`.
- `.spae/current/PLAN.md` and `.spae/current/SPEC.md` remain unchanged.

## Result directives

- Optimize result for agent, token, and context efficiency: terse,
  concise, precise.
- Split actions, findings, and summaries into terse bullet points.
- Emit task execution feedback after completing a task.
- Use lists and sub-lists over paragraphs and long sentences.
- Emit phase transition feedback when the plan concludes.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of affected files]
- **Tests**:
  - [Terse list of tests written — behaviors, failure modes, and edge cases covered]
- **Findings**:
  - [Terse list of notable findings]
- **Summary**:
  - [Terse list of summary of changes]

> **`SPAE` Status** • `[workstream-name]`
> **Progress**: Task [X] of [Y] ([Z] remaining)
> **Completed**: `T-XXX` - [Task title]
> **Next Task**: `T-YYY` - [Next task title]
>
> _Run `/build` to execute the next task._
```
<!-- prettier-ignore-end -->

### Phase transition feedback

Use this status block instead when the plan concludes.

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Progress**: All [X] tasks completed
> **Phase Complete**: `/build`
> **Next Phase**: `/verify`
>
> _Run `/verify` next._
```
<!-- prettier-ignore-end -->
