---
name: spae-tdd
description:
  "Use test-first development for behavioral changes. Write a failing
  test, make it pass, then simplify."
user-invocable: true
---

# Test-driven development

## When to use

- `STATE.json` has `phase: build`.
- The active task changes observable behavior and benefits from
  failing-test-first proof.
- The user chose `/tdd` as the execution mode for the work stream.

## Goal

- Execute exactly one atomic task from `.spae/current/PLAN.md`, proving
  behavior through Red-Green-Refactor, mutating source/tests plus
  `.spae/current/STATE.json`, and preserving the framework execution
  cursor.
- Complete the active task with minimal production code satisfying
  exhaustive tests, serving its `Intent` and the plan `## Goal`, and
  leaving seams for downstream tasks.
- Meet the acceptance criteria through exhaustive failing tests before
  any implementation.
- Advance `.spae/current/STATE.json` to the next task or to
  `phase: verify`.

## Input

Read:

- `.spae/current/STATE.json` for phase, cursor, task registry, and
  metrics.
- `.spae/current/PLAN.md` for the plan `## Goal`, the active task, its
  `Intent`, acceptance criteria, and verification steps; they carry all
  the goal context `/tdd` needs.
- Relevant project source, tests, docs, and configuration needed for the
  active task.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Workflow

1. **Load Task**: Confirm `.spae/current/STATE.json` has `phase: build`,
   the `/tdd` path remains selected, and an active task exists. Read the
   plan `## Goal` and the active task section (including its `Intent`)
   from `.spae/current/PLAN.md`. Read dependent and forward task titles
   plus acceptance to map seams, not to build them.
2. **Mark In Progress**: Set `cursor.task_status` and
   `tasks[active_task_id]` to `"in_progress"` in
   `.spae/current/STATE.json`.
3. **Classify Task**: Label the task `behavioral`, `refactor`, or
   `non-testable` before editing.
4. **Red**: For behavioral tasks, write exhaustive failing tests:
   expected behavior, failure modes, and edge cases. Run them and
   confirm each fails for the expected reason.
5. **Green**: Write the minimal implementation needed to pass the new
   test and active-task verification.
6. **Refactor**: Simplify code while keeping the new test and relevant
   suite green. Avoid behavior expansion.
7. **Handle Non-Behavioral Tasks**: For refactor tasks, prove a green
   baseline first, refactor in micro-steps, and keep tests green. For
   non-testable tasks, run the strongest available static or manual
   verification from the task.
8. **Test**: Run every verification command listed for the active task
   plus relevant regression tests.
9. **Finalize State**: Mark the active task `done` in
   `.spae/current/STATE.json`, increment completion metrics, and
   advance the cursor to the next task. If no next task remains, set
   `phase: verify`.
10. **Report**: Emit the standardized execution summary and framework
    status block.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Execute exactly one atomic task per invocation.
- Prefer existing project patterns over new design.
- Keep production code minimal, local, and test-driven; never reduce
  test scope.
- Look ahead, don't act ahead: read forward tasks to avoid foreclosing
  them; never build beyond the active task. Name any forward task you
  designed around in the result.
- Never write implementation code before failing tests exist.
- Write every category of test the task demands: unit, integration,
  end-to-end, or otherwise. Cover expected behavior, failure modes, and
  edge cases exhaustively.
- Prefer observable behavior tests over implementation-detail tests.
- Use mocks sparingly and only at stable boundaries.
- When the task legitimately changes a contract, update the tests it
  invalidates to the new contract; never weaken, skip, or delete a test
  to force green.
- Run task verification before changing `.spae/current/STATE.json`.
- On an unexpected red result, diagnose and adjust the test, not the
  cursor.
- Drive the green phase until the new test and task verification pass;
  treat red as ordinary build work. Halt with a blocker only when green
  can't pass within task scope: infeasible criterion, plan/spec defect,
  or broken external dependency; never to escape fixing your own code,
  never by gaming a test or editing the plan.
- Halt with a blocker when the task as written logically contradicts the
  plan `## Goal`, the task `Intent`, or a downstream task, an undeniable
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
- Edit `.spae/current/STATE.json` only for execution-cursor updates.
- Never edit `.spae/current/PLAN.md` during `/tdd`.
- Never edit `.spae/current/SPEC.md` during `/tdd`.
- Never execute more than one task.
- Never alternate execution mode for the same work stream; respect the
  user's selected `/tdd` path.
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

- Task classification precedes code creation.
- Behavioral tasks show a red test that fails for the expected reason.
- Green phase passes with the least implementation needed.
- Refactor phase keeps the new test and relevant suite green.
- Active task acceptance criteria pass.
- All task verification steps pass.
- Relevant project tests pass with no new failures.
- Task tests cover expected behavior, failure modes, and edge cases
  exhaustively; no thin-coverage shortcuts.
- Implementation advances the task `Intent` and plan `## Goal`; no
  forward-task work performed.
- `.spae/current/STATE.json` task registry, metrics, cursor, and phase
  reflect the completed task.
- `.spae/current/PLAN.md` and `.spae/current/SPEC.md` remain unchanged.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Strictly follow the result template below.
- Emit task execution feedback after completing a task.
- Prefer lists, and sub-lists, over long paragraphs and sentences.
- Emit phase transition feedback when the plan concludes.

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
  - [List of key gaps, risks, blockers, or notable observations]
- **Summary**:
  - [List of summary of changes]

> **`SPAE` Status** • `workstream-name`
> **Progress**: Task [X] of [Y] ([Z] remaining)
> **Completed**: `T-XXX` - [Task title]
> **Next Task**: `T-YYY` - [Next task title]
>
> _Run `/tdd` to execute the next task._
```
<!-- prettier-ignore-end -->

### Phase transition feedback

Use this status block instead when the plan concludes.

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `workstream-name`
> **Progress**: All [X] tasks completed
> **Phase Complete**: `/tdd`
> **Next Phase**: `/verify`
>
> _Run `/verify` next._
```
<!-- prettier-ignore-end -->
