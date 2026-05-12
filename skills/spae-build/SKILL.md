---
name: spae-build
description:
  Atomic Execution for the `SPAE` framework. Executes exactly one atomic
  task from `PLAN.md`.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Build (`SPAE`)

**Goal**: execute exactly one atomic task from `PLAN.md`.

## When to use

- When `STATE.json` reaches `phase: build`.
- To execute the next task in the plan.

## Process

1. **Initialize**: Resolve the `workstream` via the provided name or the
   `.spae/current` symlink. Read `STATE.json` and `PLAN.md` to identify
   the active task.
2. **Execute**:
   - Write the minimal code changes required to meet the task's
     acceptance criteria.
   - Restrict edits to relevant files; avoid incidental refactoring or
     cleanup.
   - Invoke `vibe_check` with `goal` (current task name) and `plan`
     (numbered implementation steps) for high-complexity or
     system-altering tasks.
   - Add required tests and run the verification steps defined in
     `PLAN.md`.
3. **Finalize**:
   - Mark the task `done` and increment completion metrics in
     `STATE.json`.
   - Advance the cursor to the next task or set `phase: verify` if the
     plan concludes.
   - Output the standardized **Execution Summary** and **Task Execution
     Feedback** (or **Phase Transition Feedback** if the plan
     concludes).

## Verification

- Task acceptance criteria met.
- Verification steps pass.
- `STATE.json` updated correctly.

## Rules

- Optimize all operations for agent, token, and context efficiency.
- Execute the active task with maximal signal and minimal edits.
- Execute exactly one atomic task per invocation.
- **Write Boundaries**: Exercise exclusive authority to edit source code
  and non-`SPAE` project files.
- **Forbidden Writes**: Never edit `PLAN.md` or `SPEC.md` during this
  phase.
- If a task fails, report the blocker and halt.
- STATUS: SUCCESS on completion.

### Testing rules

- Adopt a test-first, verify-last approach.
- Write exhaustive unit tests covering edge cases.
- Write acceptance and integration tests where relevant to the task.
- Ensure all test suites pass before finalizing the task.

## Standardized feedback

- Keep feedback prose terse, concise, and precise.
- Optimize prose for token and context efficiency.
- If needed, split findings and summary into terse bullet points.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [List of terse, short, compact, condensed summary of actions taken]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [List of terse summary of key gaps, risks, or architectural notes]
- **Summary**:
  - [List of terse summary of changes]
```

### Task execution feedback

```md
> **SPAE Status** • `workstream-name`
> **Progress**: Task [X] of [Y] ([Z] remaining)
> **Completed**: `T-XXX` - [Task title]
> **Next Task**: `T-YYY` - [Next task title]
>
> _Run `/build` (or `/tdd`) to execute the next task._
```

### Phase transition feedback (on plan conclusion)

```md
> **SPAE Status** • `workstream-name`
> **Progress**: All [X] tasks completed
> **Phase Complete**: `/build`
> **Next Phase**: `/verify`
>
> _Run `/verify` next._
```
<!-- prettier-ignore-end -->
