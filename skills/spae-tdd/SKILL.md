---
name: spae-tdd
description:
  "Use test-first development for behavioral changes. Write a failing
  test, make it pass, then simplify."
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Test-driven development (`SPAE`)

**Goal**: execute exactly one atomic task from `PLAN.md` using strict
Red-Green-Refactor `TDD`.

## When to use

- When `STATE.json` reaches `phase: build`.
- To execute the next task in the plan using test-first development.

## Process

1. **Initialize**: Resolve the `workstream` via the provided name or the
   `.spae/current` symlink. Read `STATE.json` and `PLAN.md` to identify
   and classify the active task (Behavioral, Refactor, or Non-testable).
2. **Execute**:
   - **Red Phase**: Write the minimal failing test for behavioral tasks.
     Confirm it fails for the expected reason.
   - **Green Phase**: Write the minimal code required to pass the test.
   - **Refactor Phase**: Simplify and improve the code while keeping
     tests green.
   - Run the full relevant suite to ensure no regressions and meet
     acceptance criteria.
3. **Finalize**:
   - Mark the task `done` and increment completion metrics in
     `STATE.json`.
   - Advance the cursor to the next task or set `phase: verify` if the
     plan concludes.
   - Output the standardized **Execution Summary** and **Task Execution
     Feedback** (or **Phase Transition Feedback** if the plan
     concludes).

## Verification

- Task classification precedes code creation.
- Red phase produces a failure for the correct reason.
- Green phase passes with least implementation only.
- Refactor phase leaves the suite green with no behavior added.
- Full suite passes with no regressions and acceptance criteria met.
- `STATE.json` remains accurate.

## Rules

- Optimize all operations for agent, token, and context efficiency.
- Execute exactly one atomic task per invocation with minimal edits.
- Never write implementation code before a failing test exists
  (behavioral tasks).
- Prefer behavioral testing over internals; use mocks sparingly.
- **Write Boundaries**: Exercise exclusive authority over source code
  and non-`SPAE` project files.
- **Forbidden Writes**: Never edit `PLAN.md` or `SPEC.md` during this
  phase.
- If a task fails, report the blocker and halt.
- STATUS: SUCCESS on completion.

## Standardized feedback

- Keep feedback prose terse, concise, and precise.
- Optimize prose for token and context efficiency.
- If needed, split findings and summary into terse bullet points.

### Execution summary

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
> _Run `/tdd` (or `/build`) next._
```

### Phase transition feedback (on plan conclusion)

```md
> **SPAE Status** • `workstream-name`
> **Progress**: All [X] tasks completed
> **Phase Complete**: `/tdd`
> **Next Phase**: `/verify`
>
> _Run `/verify` next._
```
<!-- prettier-ignore-end -->
