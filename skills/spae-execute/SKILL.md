---
name: spae-execute
description:
  Comprehensive Execution for the `SPAE` framework. Executes all tasks
  from `PLAN.md` sequentially in a single invocation.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Execute (`SPAE`)

**Goal**: execute all tasks from `PLAN.md` sequentially.

## When to use

- When `STATE.json` reaches `phase: build`.
- To execute all remaining tasks in the plan for low-risk or routine
  `workstreams`.

## Process

1. **Initialize**: Resolve the `workstream` via the provided name or the
   `.spae/current` symlink. Read `STATE.json` and `PLAN.md` to identify
   the remaining tasks.
2. **Execute**:
   - Process all tasks in the plan sequentially.
   - Write the minimal code changes required for each task's acceptance
     criteria.
   - Restrict edits to relevant files; avoid incidental refactoring.
   - Add required tests and run the verification steps for each task.
3. **Finalize**:
   - Mark all completed tasks `done` and update metrics in `STATE.json`.
   - Set `phase: verify` upon completing the plan.
   - Output the standardized **Execution Summary** and **Comprehensive
     Execution Feedback**.

## Verification

- All task acceptance criteria met.
- All verification steps pass.
- `STATE.json` updated correctly, showing all tasks as `done`.

## Rules

- Optimize all operations for agent, token, and context efficiency.
- Execute tasks with maximal signal and minimal edits.
- Execute all tasks sequentially in a single invocation.
- **Write Boundaries**: Exercise exclusive authority to edit source code
  and non-`SPAE` project files.
- **Forbidden Writes**: Never edit `PLAN.md` or `SPEC.md` during this
  phase.
- If any task fails, report the blocker, halt execution, and leave
  remaining tasks as `todo`.
- STATUS: SUCCESS on completion.

## Standardized feedback

- Keep feedback prose terse, concise, and precise.
- Optimize prose for token and context efficiency.
- If needed, split findings and summary into terse bullet points.

### Execution summary

<!-- prettier-ignore-start -->
```md
### Execution summary

- **Actions**:
  - [List of terse, short, compact, condensed summary of actions taken]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [List of terse summary of key gaps, risks, or architectural notes]
- **Summary**:
  - [List of terse summary of changes]
```

### Comprehensive execution feedback

```md
> **SPAE Status** • `workstream-name`
> **Progress**: All [X] tasks completed
> **Completed**: `T-001` through `T-XXX`
> **Next Phase**: `/verify`
>
> _Run `/verify` next._
```
<!-- prettier-ignore-end -->
