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
- Fix each classified gap fully; match correction depth to finding
  severity, not diff size.
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
   Re-check the `Satisfies` map; flag any `SPEC.md` requirement absent
   from every task as `Must fix`. Flag any task missing an `Intent` as
   `Must fix`, or a vague, non-actionable `Intent` as `Should fix`;
   backfill or sharpen it from `SPEC.md` (or, for an enabling task, from
   its `Context` and the plan `## Goal`) during refinement. Flag any
   task whose Acceptance section omits test requirements — expected
   behavior, failure modes, and edge cases — as `Should fix`. Flag any
   Verification section lacking test execution commands as `Should fix`.
3. **Classify Findings**:
   - `Must fix`: gaps that would break requirements, contracts, safety,
     or verification.
   - `Should fix`: refinements that reduce risk or simplify execution.
   - `Observations`: useful notes that shouldn't expand scope.
4. **Refine Plan**: Rewrite whatever a `Must fix` or `Should fix`
   finding demands — re-split, reorder, add, or remove tasks. Make no
   change absent a classified finding. Preserve atomic, independently
   verifiable tasks and contiguous sequential `T-NNN` IDs.
   - **Renumber atomically**: when adding, removing, or reordering
     tasks, update every `T-NNN` reference in lockstep — task headers,
     the `Task graph` mermaid edges, the dependency overview list, and
     each `Dependencies` field. Leave no dangling or stale ID.
5. **Advance State**: Update `.spae/current/STATE.json`: set
   `phase: build`, set the cursor to `T-001` with `task_status: todo`.
   Rebuild the `tasks` registry to mirror the refined `PLAN.md` IDs
   exactly, each mapped to `"todo"` (plan already reset prior progress).
   Set `metrics.tasks_total` to the refined task count — it may rise or
   fall — and `metrics.tasks_completed` to `0`.

## Directives

- Optimize all work for agent, token, and context efficiency.
- Prefer existing repository patterns over speculative design.
- Keep `/inspect` lightweight; reject process bloat and new approval
  gates.
- Strengthen verification steps with concrete test commands; test
  execution, not just build commands.
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
- Never introduce fields to `STATE.json` outside the schema reference.


## Verification

- `.spae/current/PLAN.md` satisfies `.spae/current/SPEC.md` and reflects
  required refinements.
- Each task remains atomic, ordered, and independently verifiable.
- Every task's Acceptance section names testable behaviors, failure
  modes, and edge cases; tasks lacking these flagged as `Should fix`.
- Every task's Verification section includes test execution commands.
- Every task carries an actionable `Intent` line.
- No dangling or stale `T-NNN` reference survives in
  `.spae/current/PLAN.md` after renumbering.
- Findings use `Must fix`, `Should fix`, or `Observations`.
- `.spae/current/STATE.json` has `phase: build` and cursor `T-001` ready
  for execution.
- `.spae/current/STATE.json` `tasks` registry and `metrics` mirror the
  refined `PLAN.md` task count.
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
