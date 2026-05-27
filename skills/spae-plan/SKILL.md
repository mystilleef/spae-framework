---
name: spae-plan
description:
  Task Decomposition for the `SPAE` framework. Decomposes `SPEC.md` into
  a `DAG` of atomic tasks in `PLAN.md`.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Plan (`SPAE`)

## When to use

- `SPEC.md` exists and needs an execution plan.
- `STATE.json` reports `phase: plan`.
- A revision cycle returns control to planning.

## Role

`SPAE` planning agent. Convert normalized requirements into a concise,
acyclic, atomic task graph while preserving strict phase and write
boundaries.

## Goal

Produce `.spae/[workstream]/PLAN.md`, initialize task tracking in
`STATE.json`, and advance the workstream to `phase: inspect`.

## Input

Use only relevant context from:

- User-provided `workstream` argument.
- `.spae/current` symlink when no argument exists.
- `.spae/[workstream]/SPEC.md`.
- `.spae/[workstream]/STATE.json`.
- Repository source patterns, read only for codebase fit.

## Workflow

1. **Resolve `workstream`**: Use the explicit name or `.spae/current`.
2. **Validate state**: Confirm `SPEC.md` exists and `STATE.json` can
   advance from `phase: plan`; stop early with a clear result if
   blocked.
3. **Reset prior cycle**: Delete `PLAN.md` (ignore if absent) and clear
   the `tasks` registry in `STATE.json` to empty. Run unconditionally.
4. **Analyze spec**: Extract goal, requirements, testing strategy,
   out-of-scope items, and assumptions.
5. **Gather context**: Inspect only the source patterns needed to fit
   existing architecture; never edit repository files.
6. **Draft plan**: Read the template from `references/PLAN.md`.
   Decompose work into `T-000` tasks. Structure `PLAN.md` following this
   template exactly.
7. **Order graph**: Sort tasks by dependency, risk, and vertical value;
   each task must leave the system working.
8. **Finalize**: Write `PLAN.md`. Initialize all new task IDs as `todo`
   in `STATE.json`. Update metrics and set `phase: inspect`.
9. **Report**: Emit the standard result with `SPAE` phase transition
    feedback.

## Directives

- Optimize for agent, token, and context efficiency.
- Keep `PLAN.md` high-signal and minimal.
- Prefer existing codebase patterns over speculative design.
- Slice vertically; avoid infrastructure-only tasks unless required.
- Write acceptance criteria as observable outcomes.
- Write verification as concrete commands or deterministic checks.
- Preserve execution-mode neutrality for `/build`, `/tdd`, and
  `/execute`.
- Never add `SPAE` artifacts beyond core files and ephemeral
  `VERIFY.md`.
- Never stage or commit `.spae/`.

## Constraints

- **Write scope**: `.spae/[workstream]/PLAN.md` and
  `.spae/[workstream]/STATE.json`.
- **Forbidden writes**: source code, tests, configuration files, docs,
  `SPEC.md`, `VERIFY.md`, and any non-`SPAE` project file.
- **Read-only source**: inspect repository code only for fit.
- **Phase boundary**: hand off to `/inspect`; don't execute tasks.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.

## Verification

- `.spae/[workstream]/PLAN.md` contains atomic, acyclic,
  dependency-ordered tasks.
- Every task includes dependencies, acceptance criteria, and
  verification steps.
- `.spae/[workstream]/PLAN.md` structures tasks and metadata matching
  `references/PLAN.md` exactly.
- `.spae/[workstream]/STATE.json` task registry matches `PLAN.md` task
  IDs.
- `.spae/[workstream]/STATE.json` contains `phase: "inspect"` and
  current metrics.
- No files outside the allowed `SPAE` write scope changed.

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
  - [List of key gaps, risks, or notable observations]
- **Summary**:
  - [List of summary of changes]

> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Plan Complete | Blocked | Failed]
> **Phase Complete**: `/plan`
> **Next Phase**: `/inspect`
> **Impact**: [Terse impact statement]
>
> _Run `/inspect` to optimize and verify `PLAN.md`._
```
<!-- prettier-ignore-end -->
