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
- A revision cycle re-enters planning after `/spec` reprocesses
  findings.

## Goal

- Convert normalized requirements into a concise, acyclic, atomic task
  graph while preserving strict phase and write boundaries.
- Produce `.spae/current/PLAN.md`, initialize task tracking in
  `.spae/current/STATE.json`, and advance the `workstream` to
  `phase: inspect`.

## Input

Use only relevant context from:

- `.spae/current/SPEC.md`.
- `.spae/current/STATE.json` (consult `references/STATE.md` for field
  reference, directives, and phase snapshots).
- Repository source patterns, read only for codebase fit.

**Never read `.spae/current/VERIFY.md`**—not an input to this phase.
Reading qualifies as content-blocking.

## Workflow

1. **GATE**—Confirm `.spae/current/SPEC.md` exists and
   `.spae/current/STATE.json` reports `phase: plan`. Halt immediately
   with a clear result on failure. Make no changes.
2. **ORIENT**—Extract goal, requirements, testing strategy, out-of-scope
   items, and assumptions from `SPEC.md`. Capture every `R-NNN` item
   into an in-memory coverage checklist. Gather only the source patterns
   needed for codebase fit; never edit repository files.
3. **PLAN**—Decompose work to cover the spec without over-splitting.
4. **ACT**—Delete `.spae/current/PLAN.md` (ignore if absent) and clear
   the `tasks` registry in `.spae/current/STATE.json` to empty —
   unconditionally. Read the template from `references/PLAN.md`; consult
   `references/prose-protocol.md` before drafting task prose. Decompose
   work into atomic tasks numbered from `T-001`. Set each task's
   `Satisfies` to the `R-NNN` IDs it implements and its `Intent` to a
   one-line distillation of the goal those requirements serve—or, for an
   enabling task, the structural purpose it serves toward the plan
   `## Goal`. Sort tasks by dependency, risk, and vertical value; each
   task must leave the system working.
5. **VERIFY**—Loop over every plan validity criterion:
   - For any `R-NNN` gap: return to `ACT`, add the missing task, then
     re-enter `VERIFY`. Treat `Satisfies: none` as intentional; flag
     empty or missing `Satisfies` as a scope-creep observation.
   - For any graph violation—cycle or forward-order failure: return to
     `ACT`, correct it, then re-enter `VERIFY`.
   - Exit only when all `R-NNN` items map to tasks and the graph has no
     violations.
   - Fail only for out-of-scope conditions.
6. **PERSIST**—Write `.spae/current/PLAN.md`. Initialize all task IDs as
   `todo` in `.spae/current/STATE.json`. Clear `cursor` to `{}`. Set
   `phase: inspect`. Write once, atomically. Re-read `STATE.json` after
   writing; on a field mismatch, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit the result following the result directives and using
   the result template.

## Directives

- Optimize for agent, token, and context efficiency.
- Keep `PLAN.md` high-signal and minimal.
- Prefer existing codebase patterns over speculative design.
- Slice vertically; avoid infrastructure-only tasks unless required.
- Write acceptance criteria as observable outcomes; name testable
  behaviors for a `Satisfies`-bearing task (include failure modes and
  edge cases only when specified in `SPEC.md` or required by task
  logic); state structural assurances for a `Satisfies: none` enabling
  task.
- Write verification as concrete test commands and deterministic checks;
  every task's Verification section must include test execution.
- Reject verification steps that presume human execution, an attended or
  interactive terminal, or human presence; flag as a spec defect instead
  of encoding them in `PLAN.md`.
- Never add `SPAE` artifacts beyond core files and ephemeral
  `VERIFY.md`.
- Never stage or commit `.spae/`.
- Consult `references/prose-protocol.md` before drafting `PLAN.md`.

## Constraints

- **Write scope**: `.spae/current/PLAN.md` and
  `.spae/current/STATE.json`.
- **Forbidden writes**: source code, tests, configuration files, docs,
  `SPEC.md`, `VERIFY.md`, and any non-`SPAE` project file.
- **Read-only source**: inspect repository code only for fit.
- **Phase boundary**: hand off to `/inspect`; don't execute tasks.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and failures stop autonomously.
- **Full autonomy**: Never write a task whose Verification section
  depends on human execution, an attended or interactive terminal, or
  human presence.
- Never introduce fields to `STATE.json` outside the schema reference.

## Verification

- `.spae/current/PLAN.md` contains atomic, acyclic, dependency-ordered
  tasks—no cycles; every `Dependencies` ID numerically precedes its
  declaring task.
- Every task includes dependencies, acceptance criteria, and
  verification steps.
- Every `Satisfies`-bearing task's Acceptance section names testable
  behaviors (includes failure modes and edge cases when specified in
  `SPEC.md` or required by task logic); a `Satisfies: none` task's
  Acceptance states structural assurances provided instead.
- Every task's Verification section includes test execution commands.
- No task's Verification section depends on human execution, an attended
  or interactive terminal, or human presence.
- Every task includes an `Intent` line distilled from the requirements
  it satisfies, or—for an enabling task—its structural purpose toward
  the plan `## Goal`.
- `.spae/current/PLAN.md` structures tasks and metadata matching
  `references/PLAN.md` exactly.
- Every `T-NNN` reference in `PLAN.md` — `Task graph` edges, the
  dependency overview list, and `Dependencies` fields—resolves to a
  defined task.
- `.spae/current/STATE.json` task registry matches `PLAN.md` task IDs.
- Every `SPEC.md` requirement maps to at least one task's `Satisfies`.
- `.spae/current/STATE.json` contains `phase: "inspect"`.
- No files outside the allowed `SPAE` write scope changed.

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
> **Result**: [Plan Complete | Failed]
> **Phase Complete**: `/plan`
> **Next Phase**: `/inspect`
> **Impact**: [Terse impact statement]
>
> _Run `/inspect` to optimize and verify `PLAN.md`._
```
<!-- prettier-ignore-end -->
