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
- Complete the active task with the smallest useful behavioral change.
- Prove the acceptance criteria with a failing test before
  implementation whenever the task changes behavior.
- Advance `.spae/current/STATE.json` to the next task or to
  `phase: verify`.

## Input

Read:

- `.spae/current/STATE.json` for phase, cursor, task registry, and
  metrics.
- `.spae/current/PLAN.md` for the active task, acceptance criteria, and
  verification steps.
- Relevant project source, tests, docs, and configuration needed for the
  active task.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Workflow

1. **Load Task**: Confirm `.spae/current/STATE.json` has `phase: build`,
   the `/tdd` path remains selected, and an active task exists. Read
   only the active task section from `.spae/current/PLAN.md` plus
   minimal surrounding context needed for dependencies.
2. **Mark In Progress**: Set `cursor.task_status` and
   `tasks[active_task_id]` to `"in_progress"` in
   `.spae/current/STATE.json`.
3. **Classify Task**: Label the task `behavioral`, `refactor`, or
   `non-testable` before editing.
4. **Red**: For behavioral tasks, write the smallest failing test that
   proves the required behavior. Run it and confirm failure for the
   expected reason.
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
- Keep edits minimal, local, and acceptance-criteria driven.
- Never write implementation code before a failing test exists for a
  behavioral task.
- Prefer observable behavior tests over implementation-detail tests.
- Use mocks sparingly and only at stable boundaries.
- Run task verification before changing `.spae/current/STATE.json`.
- Halt with a blocker when the red phase produces an unexpected result
  or green doesn't pass.
- When task requirements lack detail, make the most conservative
  assumption, record it in `.spae/current/STATE.json`, and proceed.

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

## Verification

- Task classification precedes code creation.
- Behavioral tasks show a red test that fails for the expected reason.
- Green phase passes with the least implementation needed.
- Refactor phase keeps the new test and relevant suite green.
- Active task acceptance criteria pass.
- All task verification steps pass.
- Relevant project tests pass with no new failures.
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
