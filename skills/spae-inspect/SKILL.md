---
name: spae-inspect
description:
  Optimization & Verification for the `SPAE` framework. Performs gap
  analysis on `PLAN.md`.
user-invocable: true
---

# Inspect (`SPAE`)

## When to use

- `STATE.json` has `phase: inspect`.
- `PLAN.md` needs validation against `SPEC.md`, codebase patterns, or
  technical constraints before execution.

## Goal

- Tighten the atomic task graph before execution while keeping the
  repository source read-only.
- Find gaps between `SPEC.md`, `PLAN.md`, and relevant codebase context.
- Improve `PLAN.md` with minimal, high-impact refinements.
- Advance the `workstream` to execution readiness.

## Input

Read only what the inspection requires:

- `.spae/current/SPEC.md`
- `.spae/current/PLAN.md`
- `.spae/current/STATE.json`
- Relevant source files for context only.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Workflow

1. **Load Artifacts**: Read `.spae/current/STATE.json`,
   `.spae/current/SPEC.md`, and `.spae/current/PLAN.md`. Continue only
   when the state expects `phase: inspect`.
2. **Inspect Fit**: Compare requirements, plan tasks, acceptance
   criteria, verification steps, dependencies, and codebase patterns.
3. **Classify Findings**:
   - `Must fix`: gaps that would break requirements, contracts, safety,
     or verification.
   - `Should fix`: refinements that reduce risk or simplify execution.
   - `Observations`: useful notes that shouldn't expand scope.
4. **Refine Plan**: Rewrite only the smallest necessary parts of
   `.spae/current/PLAN.md`; preserve atomic, independently verifiable
   tasks.
5. **Advance State**: Update `.spae/current/STATE.json` to
   `phase: build`, set the cursor to `T-001`, and mark the active task
   `todo`.

## Directives

- Optimize all work for agent, token, and context efficiency.
- Prefer existing repository patterns over speculative design.
- Keep `/inspect` lightweight; reject process bloat and new approval
  gates.
- Strengthen verification steps with concrete commands or observable
  checks.
- Preserve one execution choice per `workstream` after inspection:
  `/build`, `/tdd`, or `/execute`.
- Ensure `.spae/` stays local execution state and never gets staged or
  committed.

## Constraints

- **Write Boundaries**: Edit only `.spae/current/PLAN.md` and
  `.spae/current/STATE.json`.
- **Forbidden Writes**: Never edit source code, tests, configuration,
  docs, `SPEC.md`, `VERIFY.md`, or any non-`SPAE` project file.
- **Artifact Limit**: Don't create new `SPAE` artifacts beyond the
  canonical files.
- **Scope Control**: Don't add requirements, features, tasks, or gates
  not grounded in `SPEC.md` or concrete codebase constraints.
- **Status**: Report `SUCCESS` only after writing the optimized plan and
  advancing state.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.

## Verification

- `.spae/current/PLAN.md` satisfies `.spae/current/SPEC.md` and reflects
  required refinements.
- Each task remains atomic, ordered, and independently verifiable.
- Findings use `Must fix`, `Should fix`, or `Observations`.
- `.spae/current/STATE.json` has `phase: build` and cursor `T-001` ready
  for execution.
- No forbidden files changed.

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
  - [Key gaps, risks, or notable observations]
- **Summary**:
  - [List of summary of changes]

> **SPAE Status** • `[workstream-name]`
> **Phase Complete**: `/inspect`
> **Next Phase**: `/build`, `/tdd`, or `/execute`
> **Result**: [Ready | Revised | Failed]
> **Impact**: [Terse execution-readiness statement]
>
> _Run `/build`, `/tdd`, or `/execute` next. Keep one execution mode for this workstream._
```
<!-- prettier-ignore-end -->
