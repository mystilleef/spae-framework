---
name: spae-inspect
description:
  Optimization & Verification for the `SPAE` framework. Performs gap
  analysis on `PLAN.md`.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Inspect (`SPAE`)

**Goal**: fix gaps between `SPEC.md` and `PLAN.md`.

## When to use

- When `STATE.json` reaches `phase: inspect`.
- To refine `PLAN.md` based on codebase context or technical
  constraints.

## Process

1. **Initialize**: Resolve the `workstream` via the provided name or the
   `.spae/current` symlink. Read `SPEC.md` and `PLAN.md`.
2. **Execute**:
   - Perform gap analysis between `SPEC.md`, `PLAN.md`, and the
     codebase.
   - Identify concrete bugs, regressions, or weak verification steps.
   - Refine `PLAN.md` with minimal, high-impact changes.
   - Use `vibe_check` to refine your solutions.
3. **Finalize**:
   - Write the optimized `PLAN.md`.
   - Update `STATE.json` (phase: `build`, cursor: `T-001`, status:
     `todo`).
   - Output the standardized **Execution Summary** and **Phase
     Transition Feedback** (Next Phase: `/build`, `/tdd`, or
     `/execute`).

## Verification

- `PLAN.md` reflects optimizations and aligns with `SPEC.md`.
- `STATE.json` reaches `phase: build`.

## Rules

- Optimize all operations for agent, token, and context efficiency.
- Write inspection findings and `PLAN.md` refinements for maximal
  signal.
- Prevent process inflation; avoid turning this into a heavyweight gate.
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
  - [List of terse summary of revised plan]
```

### Phase transition feedback

```md
> **SPAE Status** • `workstream-name`
> **Phase Complete**: `/inspect`
> **Next Phase**: `/build`, `/tdd`, or `/execute`
>
> _Run `/build`, `/tdd`, or `/execute` next._
```
<!-- prettier-ignore-end -->
