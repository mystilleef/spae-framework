---
name: spae-execute
description:
  Comprehensive Execution for the `SPAE` framework. Executes all tasks
  from `PLAN.md` sequentially in one invocation.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
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
- Execute all remaining `PLAN.md` tasks sequentially.
- Keep each task minimal, verified, and aligned with acceptance
  criteria.
- Leave the `workstream` ready for `/verify`.

## Input

Resolve input from:

- Optional `workstream` name argument.
- `.spae/current` symlink when the user omits a `workstream` name.
- `.spae/<workstream>/STATE.json` for phase, cursor, task registry, and
  metrics.
- `.spae/<workstream>/PLAN.md` for remaining tasks, acceptance criteria,
  and verification steps.
- Relevant source, tests, configuration, and documentation.

## Workflow

1. **Resolve**: Locate the `workstream`. Read `STATE.json` and
   `PLAN.md`. Confirm `phase: build`.
2. **Select**: Identify all `todo` or `in_progress` tasks in plan order.
   Skip tasks already marked `done`.
3. **Execute**: For each remaining task, build the smallest useful slice
   that satisfies acceptance criteria. Add tests when needed.
4. **Advance**: After each successful task, mark it `done`, update the
   cursor, task registry, blockers, and metrics in `STATE.json`.
5. **Finalize**: After the final task passes verification, set
   `phase: verify` in `STATE.json` and emit the required result.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Execute tasks sequentially in one invocation.
- Apply minimal, relevant edits only.
- Follow existing codebase patterns over speculative design.
- Preserve the selected execution mode for the `workstream`; don't mix
  `/build`, `/tdd`, and `/execute`.
- Report SUCCESS only after every remaining task passes verification.

## Constraints

- **Authorized writes**: Source code, tests, configuration, docs, other
  non-`SPAE` project files, and `STATE.json`.
- **Forbidden writes**: Never edit `PLAN.md`, `SPEC.md`, or `.spae/`
  artifacts other than `STATE.json` during execution.
- **Blockers**: On failure, update `STATE.json` with the blocker, leave
  remaining tasks `todo`, report the issue, and halt.
- **Version control**: Never stage or commit `.spae/` artifacts.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.

## Verification

- Every completed task meets its acceptance criteria.
- Every task verification step passes.
- Added or existing tests cover changed behavior when applicable.
- `STATE.json` accurately records completed tasks, metrics, cursor,
  blockers, and `phase: verify` after full completion.

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
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [Key gaps, risks, blockers, or notable observations]
- **Summary**:
  - [Summary of implementation changes]

> **SPAE Execute Status** • `[workstream-name]`
> **Result**: [Complete | Blocked | Failed]
> **Progress**: All [X] tasks completed
> **Completed**: [`T-001` through `T-XXX`]
> **Next Phase**: `/verify`
> **Impact**: [Terse implementation impact]
>
> _Run `/verify` to validate the implementation against the specification._
```
<!-- prettier-ignore-end -->
