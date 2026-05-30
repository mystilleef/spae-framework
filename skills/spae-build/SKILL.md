---
name: spae-build
description:
  Atomic execution for the project framework. Executes exactly one
  atomic task from `PLAN.md`.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Build

## When to use

- `STATE.json` has `phase: build`.
- The work stream needs the next planned task completed.
- The user chose `/build` as the execution mode for the work stream.

## Goal

- Execute exactly one task from `PLAN.md`, mutating source/tests plus
  `STATE.json`, while preserving the framework execution cursor.
- Complete the active task with the smallest useful code change.
- Prove the task acceptance criteria through the task verification
  steps.
- Advance `STATE.json` to the next task or to `phase: verify`.

## Input

Resolve input by one of the following:

- Explicit work stream name supplied by the user.
- `.spae/current` symlink when the user omits a work stream name.

Then read:

- `.spae/<workstream>/STATE.json` for phase, cursor, task registry, and
  metrics.
- `.spae/<workstream>/PLAN.md` for the active task, acceptance criteria,
  and verification steps.
- Relevant project source, tests, docs, and configuration needed for the
  active task.

## Workflow

1. **Resolve Work Stream**: Select the explicit work stream or follow
   `.spae/current`. Confirm `STATE.json` has `phase: build` and an
   active task.
2. **Load Task**: Read only the active task section from `PLAN.md` plus
   minimal surrounding context needed for dependencies.
3. **Plan Slice**: Identify the smallest implementation path that meets
   the active task acceptance criteria.
4. **Implement**: Edit only relevant source, tests, docs, or
   configuration files required by the task.
5. **Test**: Add or adjust tests required for the task, then run every
   verification command listed for the active task. Tests must prove,
   verify, and confirm your solution.
6. **Finalize State**: Mark the active task `done`, increment completion
   metrics, and advance the cursor to the next task. If no next task
   remains, set `phase: verify`.
7. **Report**: Emit the standardized execution summary and framework
   status block.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Execute exactly one atomic task per invocation.
- Prefer existing project patterns over new design.
- Keep edits minimal, local, and acceptance-criteria driven.
- Use test-first when the task changes observable behavior.
- Don't limit yourself to just unit tests; write any category of tests
  necessary to prove, verify, and confirm your solution.
- Run task verification before changing `STATE.json`.
- Halt with a blocker when verification fails.
- When task requirements lack detail, make the most conservative
  assumption, record it in `STATE.json`, and proceed.

## Constraints

- Exercise exclusive authority to edit source code, tests,
  documentation, configuration, and other non-framework project files
  during this phase.
- Never edit `PLAN.md` during `/build`.
- Never edit `SPEC.md` during `/build`.
- Never execute more than one task.
- Never alternate execution mode for the same work stream; respect the
  user's selected `/build` path.
- Never stage or commit `.spae/` artifacts.
- Avoid incidental refactoring, cleanup, formatting, or dependency churn
  outside the active task.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.

## Verification

- Active task acceptance criteria pass.
- All task verification steps pass.
- Relevant project tests pass with no new failures.
- `STATE.json` task registry, metrics, cursor, and phase reflect the
  completed task.
- `PLAN.md` and `SPEC.md` remain unchanged.

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
> _Run `/build` to execute the next task._
```
<!-- prettier-ignore-end -->

### Phase transition feedback

Use this status block instead when the plan concludes.

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `workstream-name`
> **Progress**: All [X] tasks completed
> **Phase Complete**: `/build`
> **Next Phase**: `/verify`
>
> _Run `/verify` next._
```
<!-- prettier-ignore-end -->
