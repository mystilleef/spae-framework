---
name: spae-plan
description:
  Task Decomposition for the `SPAE` framework. Decomposes `SPEC.md` into
  a `DAG` of atomic tasks in `PLAN.md`.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Plan (`SPAE`)

**Goal**: decompose `SPEC.md` into a Directed Acyclic Graph (`DAG`) of
atomic tasks in `PLAN.md`.

## When to use

- When `SPEC.md` exists and requires a new plan.
- When `STATE.json` reaches `phase: plan`.

## Process

1. **Initialize**: Resolve the `workstream` via the provided name or the
   `.spae/current` symlink. Read `SPEC.md`.
2. **Execute**:
   - Decompose `SPEC.md` into a Directed Acyclic Graph (`DAG`) of atomic
     tasks.
   - Order tasks by dependency and risk, ensuring each leaves the system
     in a working state.
   - Define clear acceptance criteria and verification steps for each
     task.

3. **Finalize**:
   - Write `PLAN.md`.
   - Initialize the `tasks` registry and update `phase: inspect` in
     `STATE.json`.
   - Output the standardized **Execution Summary** and **Phase
     Transition Feedback** (Next Phase: `/inspect`).

## Verification

- `PLAN.md` exists with atomic, verifiable tasks.
- `STATE.json` reflects the new tasks and `phase: "inspect"`.

## Rules

- Optimize all operations for agent, token, and context efficiency.
- Write `PLAN.md` for maximal signal with minimal tokens.
- Order tasks by dependency and risk; slice vertically.
- Treat repository source code as read-only.
- **Write Boundaries**: Exercise exclusive authority to edit
  `.spae/current/PLAN.md` and `.spae/current/STATE.json`.
- **Forbidden Writes**: Never edit application code, tests,
  configuration files, docs, `SPEC.md`, or non-`SPAE` project files.
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
  - [List of terse summary of plan]
```

### Phase transition feedback

```md
> **SPAE Status** • `workstream-name`
> **Phase Complete**: `/plan`
> **Next Phase**: `/inspect`
>
> _Run `/inspect` next._
```
<!-- prettier-ignore-end -->
