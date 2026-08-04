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
- `.spae/current/STATE.json` (consult `references/STATE.md` for field
  reference, directives, and phase snapshots)
- Relevant source files for context only.

**Never read `.spae/current/VERIFY.md`**—not an input to this phase.
Reading qualifies as content-blocking.

## Workflow

1. **GATE**—Read `.spae/current/STATE.json`, `.spae/current/SPEC.md`,
   and `.spae/current/PLAN.md`. Halt when `phase ≠ inspect`.
2. **ORIENT**—Goal: tighten the task graph for execution readiness.
   Source stays read-only; `SPEC.md` unchanged.
3. **PLAN**—Classify each gap before editing `PLAN.md`. Declare the
   minimal refinements the findings demand.
4. **ACT**—Apply classified findings only. Compare requirements, plan
   tasks, acceptance criteria, verification steps, dependencies, and
   codebase patterns.
   - Flag any `SPEC.md` requirement absent from every task as
     `Must fix`.
   - Flag any task missing an `Intent` as `Must fix`; flag a vague or
     non-actionable `Intent` as `Should fix`; backfill or sharpen it
     from `SPEC.md` (or, for enabling tasks, from `Context` and the plan
     `## Goal`) during refinement.
   - Flag any `Satisfies`-bearing task's Acceptance section omitting
     test requirements specified in `SPEC.md` or required by task logic
     as `Should fix`.
   - Flag any Verification section lacking test execution commands as
     `Should fix`.
   - Flag any `Dependencies` entry with a `T-NNN` ID ≥ the declaring
     task's own ID as `Must fix` (topological violation).
   - Flag any cycle—a task transitively depending on itself—as
     `Must fix`.
   - Flag any `Dependencies` entry referencing a `T-NNN` absent from
     `PLAN.md` as `Must fix` (dangling reference).
   - Flag any mismatch between `Task graph` mermaid edges and per-task
     `Dependencies` fields as `Should fix`.
   - Flag any task with `Satisfies: none` lacking a credible
     enabling-task rationale in its `Context` as `Should fix` (orphan
     task—likely scope creep).
   - Flag any ≥2 adjacent tasks sharing no independent acceptance value
     and no dependency-ordering reason for separation as `Should fix`
     (merge candidate).
   - **Classify findings**:
     - `Must fix`: gaps breaking requirements, contracts, safety, or
       verification.
     - `Should fix`: refinements reducing risk or simplifying execution.
     - `Observations`: useful notes that shouldn't expand scope.
   - **Refine `PLAN.md`**: Rewrite what each `Must fix` or `Should fix`
     demands—re-split, reorder, add, or remove tasks. Make no change
     absent a classified finding. Preserve atomic, independently
     verifiable tasks and contiguous sequential `T-NNN` IDs. Consult
     `references/prose-protocol.md` before rewriting task prose.
     - **Renumber atomically**: when adding, removing, or reordering,
       update every `T-NNN` reference in lockstep—task headers,
       `Task graph` mermaid edges, the dependency overview list, and
       each `Dependencies` field. Leave no dangling or stale ID.
     - **Topological correction**: when fixing a topological violation,
       reorder tasks so every dependency precedes its dependent by ID,
       then renumber atomically.
5. **VERIFY**—Loop over every item in `## Verification`:
   - For each failing item: return to `ACT`, address it, then re-enter
     `VERIFY`.
   - Exit only when all items pass.
   - Fail only for out-of-scope conditions.
6. **PERSIST**—Write `.spae/current/STATE.json` once, atomically: set
   `phase: build`; set cursor `active_task_id` to `T-001`; rebuild the
   `tasks` registry to mirror the refined `PLAN.md` IDs, each mapped to
   **todo**. Re-read `STATE.json` after writing; on a field mismatch,
   rewrite and re-read before `REPORT`.
7. **REPORT**—Emit the result following the result directives and using
   the result template.

## Directives

- Optimize all work for agent, token, and context efficiency.
- Prefer existing repository patterns over speculative design.
- Keep `/inspect` lightweight; reject process bloat and new approval
  gates.
- Strengthen verification steps with concrete test commands; test
  execution, not just build commands.
- Route every `workstream` to `/build` after inspection.
- Ensure `.spae/` stays local execution state and never gets staged or
  committed.
- Consult `references/prose-protocol.md` before editing `PLAN.md`.

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
  mid-execution; halts and failures stop autonomously.
- **Full autonomy**: Never leave or write a task whose Verification
  section depends on human execution, an attended or interactive
  terminal, or human presence; correct it during refinement.
- Never introduce fields to `STATE.json` outside the schema reference.

## Verification

- `.spae/current/PLAN.md` satisfies `.spae/current/SPEC.md` and reflects
  required refinements.
- Each task remains atomic, independently verifiable, and topologically
  ordered—every `Dependencies` ID numerically precedes the declaring
  task; no cycles survive.
- Every `Satisfies`-bearing task's Acceptance section names testable
  behaviors matching `SPEC.md` requirements (flags missing failure modes
  or edge cases as `Should fix` only when specified in `SPEC.md` or
  required by task logic).
- Every task's Verification section includes test execution commands.
- Every task carries an actionable `Intent` line.
- No dangling or stale `T-NNN` reference survives in
  `.spae/current/PLAN.md` after renumbering.
- Findings use `Must fix`, `Should fix`, or `Observations`.
- `.spae/current/STATE.json` has `phase: build` and cursor `T-001` ready
  for execution.
- `.spae/current/STATE.json` `tasks` registry mirrors the refined
  `PLAN.md` task count and IDs.
- No forbidden files changed.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.
- Source every `SPAE Status` value from the confirmed re-read, never
  from working memory of intent.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of affected files]
- **Findings**:
  - [Terse list of notable findings]
- **Summary**:
  - [Terse list of summary of changes]

> **`SPAE` Status** • `[workstream-name]`
> **Phase Complete**: `/inspect`
> **Next Phase**: `/build`
> **Result**: [Ready | Revised | Failed]
> **Impact**: [Terse impact statement]
>
> _Run `/build` next._
```
<!-- prettier-ignore-end -->
