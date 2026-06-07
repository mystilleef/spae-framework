---
name: spae-plan
description:
  Task Decomposition for the `SPAE` framework. Decomposes `SPEC.md` into
  a `DAG` of atomic tasks in `PLAN.md`.
user-invocable: true
---

# Plan (`SPAE`)

## When to use

- `SPEC.md` exists and needs an execution plan.
- `STATE.json` reports `phase: plan`.
- A revision cycle re-enters planning after `/spec` reprocesses findings.

## Goal

- Convert normalized requirements into a concise, acyclic, atomic task
  graph while preserving strict phase and write boundaries.
- Produce `.spae/current/PLAN.md`, initialize task tracking in
  `.spae/current/STATE.json`, and advance the `workstream` to
  `phase: inspect`.

## Input

Use only relevant context from:

- `.spae/current/SPEC.md`.
- `.spae/current/STATE.json`.
- Repository source patterns, read only for codebase fit.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Workflow

1. **Validate state**: Confirm `.spae/current/SPEC.md` exists and
   `.spae/current/STATE.json` can advance from `phase: plan`; stop early
   with a clear result if blocked.
2. **Reset prior cycle**: Always delete `.spae/current/PLAN.md` (ignore
   if absent) and clear the `tasks` registry in
   `.spae/current/STATE.json` to empty. Run unconditionally.
3. **Analyze spec**: Extract goal, requirements, testing strategy,
   out-of-scope items, and assumptions. Capture every requirement into
   an in-memory coverage checklist, keyed by `R-NNN` ID.
4. **Gather context**: Inspect only the source patterns needed to fit
   existing architecture; never edit repository files.
5. **Draft plan**: Read the template from `references/PLAN.md`.
   Decompose work into atomic tasks numbered from `T-001`. Structure
   `PLAN.md` following this template exactly. Set each task's `Satisfies`
   to the requirement IDs
   it implements, and its `Intent` to a one-line distillation of the
   goal those requirements serve — or, for an enabling task, the
   structural purpose it serves toward the plan `## Goal`.
6. **Reconcile coverage**: Confirm every requirement maps to at least
   one task via `Satisfies`; for any requirement without a task, return
   to drafting and add one. Treat `Satisfies: none` as an intentional
   exemption; note a task with empty or missing `Satisfies` as a
   possible scope-creep observation.
7. **Order graph**: Sort tasks by dependency, risk, and vertical value;
   each task must leave the system working. Enforce before writing:
   **(1) no cycles** — no task transitively depends on itself;
   **(2) forward order** — every `Dependencies` ID numerically precedes
   the declaring task. Detect and correct both before finalizing.
8. **Finalize**: Write `.spae/current/PLAN.md`. Initialize all new task
   IDs as `todo` in `.spae/current/STATE.json`. Update metrics and set
   `phase: inspect`.
9. **Report**: Emit the standard result with `SPAE` phase transition
    feedback.

## Directives

- Optimize for agent, token, and context efficiency.
- Keep `PLAN.md` high-signal and minimal.
- Prefer existing codebase patterns over speculative design.
- Slice vertically; avoid infrastructure-only tasks unless required.
- Write acceptance criteria as observable outcomes; name the behaviors,
  failure modes, and edge cases tests must cover.
- Write verification as concrete test commands and deterministic checks;
  every task's Verification section must include test execution.
- Preserve execution-mode neutrality for `/build`, `/tdd`, and
  `/execute`.
- Never add `SPAE` artifacts beyond core files and ephemeral
  `VERIFY.md`.
- Never stage or commit `.spae/`.

## Constraints

- **Write scope**: `.spae/current/PLAN.md` and
  `.spae/current/STATE.json`.
- **Forbidden writes**: source code, tests, configuration files, docs,
  `SPEC.md`, `VERIFY.md`, and any non-`SPAE` project file.
- **Read-only source**: inspect repository code only for fit.
- **Phase boundary**: hand off to `/inspect`; don't execute tasks.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.
- Never introduce fields to `STATE.json` outside the schema reference.

## Verification

- `.spae/current/PLAN.md` contains atomic, acyclic, dependency-ordered
  tasks — no cycles; every `Dependencies` ID numerically precedes its
  declaring task.
- Every task includes dependencies, acceptance criteria, and
  verification steps.
- Every task's Acceptance section names the behaviors, failure modes,
  and edge cases tests must cover.
- Every task's Verification section includes test execution commands.
- Every task includes an `Intent` line distilled from the requirements
  it satisfies, or — for an enabling task — its structural purpose
  toward the plan `## Goal`.
- `.spae/current/PLAN.md` structures tasks and metadata matching
  `references/PLAN.md` exactly.
- Every `T-NNN` reference in `PLAN.md` — `Task graph` edges, the
  dependency overview list, and `Dependencies` fields — resolves to a
  defined task.
- `.spae/current/STATE.json` task registry matches `PLAN.md` task IDs.
- Every `SPEC.md` requirement maps to at least one task's `Satisfies`.
- `.spae/current/STATE.json` contains `phase: "inspect"` and current
  metrics.
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
