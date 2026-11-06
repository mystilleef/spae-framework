---
name: spae-inspect
description:
  Optimization & Verification for the `SPAE` framework. Performs gap
  analysis on `PLAN.md`.
user-invocable: true
---

# Inspect (`SPAE`)

## When to use

- `STATE.json` reads `phase: inspect`: validate `PLAN.md` against
  `SPEC.md` and codebase constraints before execution.

## Goal

- Find gaps and contradictions between `SPEC.md`, `PLAN.md`, and
  relevant codebase context; fix each fully, matching correction depth
  to finding severity, not diff size.
- Advance the `workstream` to `phase: build`.

## Input

Read only what the inspection requires:

- `.spae/current/SPEC.md`.
- `.spae/current/PLAN.md`.
- `.spae/current/STATE.json`; `references/STATE.md` holds field
  reference, directives, and snapshots.
- Repository source, for analysis.

Never read `.spae/current/VERIFY.md`; `SPEC.md` holds every requirement.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json`; self-heal missing metadata:
     `version` (`"1.0"`), `workstream` (target directory name), `status`
     (`"active"`); `PERSIST` writes the healed fields.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - Source code and `SPEC.md` stay unmodified; write nothing before
     `PERSIST`.
   - Read `SPEC.md` and `PLAN.md` in full; capture every `R-NNN` into a
     coverage checklist.
3. **PLAN**—Run gap analysis:
   - Evaluate `PLAN.md` against every **Verification** `Must fix` and
     `Should fix` criterion; record each failure as a finding of that
     class.
   - Record any other gap against `SPEC.md` or the codebase—concrete
     bug, regression, contract break—under the class its impact matches.
   - Log notes that shouldn't expand scope as `Observations`; they
     change nothing.
   - Declare each finding's repair; halt on any **Halt conditions**
     entry.
4. **ACT**—Apply each finding's repair to a working draft of `PLAN.md`;
   change nothing absent a `Must fix` or `Should fix` finding:
   - Uncovered `R-NNN`: add or extend a task to implement it.
   - Missing or vague `Intent`: backfill or sharpen from `SPEC.md`; for
     an enabling task, from `Context` and the plan `## Goal`.
   - Plan↔spec contradiction: rewrite the task to conform; `SPEC.md`
     wins.
   - Task conflict: reconcile against `SPEC.md`; where `SPEC.md` stays
     silent, conform the later task to the earlier task's `Acceptance`
     contract.
   - Other `SPEC.md` tension short of a **Halt conditions** entry: favor
     its requirements; log it under `Observations`.
   - Hidden coupling: add the missing dependency, or rebind the reliance
     to the dependency's stated `Acceptance` contract.
   - Unjustified enabling task: state its rationale in `Context`, else
     remove it.
   - Granularity: split a non-atomic task; merge a merge candidate.
   - Version control or release step: strip it; remove a task left
     empty.
   - Ordering: reorder so every dependency precedes its dependent; break
     a cycle by dropping an ungrounded edge, else merging its tasks.
   - Renumber after any add, remove, or reorder, or on non-contiguous
     IDs: assign contiguous IDs from `T-001`; update every `T-NNN`
     reference in lockstep—task headers, `Task graph` edges, the
     overview list, and `Dependencies` fields.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for `PLAN.md`:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - Write the refined `PLAN.md` when any repair changed it.
   - Write `STATE.json` per `references/STATE.md` exit snapshot.
   - Re-read `STATE.json`; on a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit result following result directives and using result
   template:
   - `Result`: `Revised` when `PERSIST` wrote `PLAN.md`, else `Ready`.
   - List findings under `Findings` by class: `Must fix`, `Should fix`,
     `Observations`.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- Refine and optimize `PLAN.md` for agent consumption: agents read it
  for varied purposes, with no memory of this run; keep rewritten tasks
  self-contained, explicit, and token-dense; write each task's `Context`
  to supply every fact a stateless executor needs, including facts
  surfaced only during inspection.
- Strengthen each task's `Verification` with concrete, deterministic
  test-execution commands per `references/verification-guide.md`;
  challenge each step's feasibility and isolation; rewrite a failing
  step or demote it to `Risk notes`.
- Consult `references/prose-protocol.md` before editing `PLAN.md`.

## Constraints

- **Write scope**: write only `.spae/current/PLAN.md` and
  `.spae/current/STATE.json`; forbid all other writes. Read source code
  only for analysis.
- **Phase boundary**: hand off work to `/build`; don't execute tasks.
- **Version control and release**: never permit tasks for version
  control (git staging, commits, branches, tags) or release operations
  (package publishing, deployments). Never stage or commit `.spae/` or
  execute git mutations.
- **Autonomy**: never ask users for input or clarification
  mid-execution; halts and failures stop autonomously. Never leave a
  task step presuming human execution, an attended or interactive
  terminal, or human presence; translate such a need into automated
  evidence, else record it in `Risk notes` as a residual risk.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt without writing; report `Failed` with a
  diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `inspect`.
  - `SPEC.md` or `PLAN.md` missing.
  - A `SPEC.md`-internal conflict no `PLAN.md` edit can resolve:
    mutually exclusive requirements, or a requirement an `Out of scope`
    item forbids.
- **Scope control**: keep `/inspect` lightweight; add no requirement,
  feature, task, or approval gate absent grounding in `SPEC.md` or a
  concrete codebase constraint.

## Verification

- Every recorded `Must fix` and `Should fix` finding resolved in
  `PLAN.md`.
- **`Must fix`** criteria—failure breaks a requirement, contract,
  safety, or verification:
  - Every `SPEC.md` requirement maps to at least one task's `Satisfies`.
  - Every task carries an `Intent` line.
  - Task IDs run contiguously from `T-001`; every `T-NNN`
    reference—`Task graph` edges, the overview list, and `Dependencies`
    fields—resolves to a defined task.
  - Every `Dependencies` ID numerically precedes its declaring task.
  - No hidden coupling: each task's `Scope` and `Acceptance` rely only
    on outputs of its `Dependencies` tasks, and only through their
    stated `Acceptance` contracts.
  - No task's `Intent`, `Scope`, `Acceptance`, `Context`, or
    `Verification` contradicts its `Satisfies` requirements,
    `Out of scope`, `Assumptions`, or `Testing strategy`.
  - No two tasks linked by a dependency edge or sharing `Scope` files or
    symbols assert incompatible behavior, contracts, or file states.
  - Zero tasks mandate version control or release operations.
  - No task step presumes human execution, an attended or interactive
    terminal, or human presence.
- **`Should fix`** criteria—failure adds risk or complicates execution:
  - Every `Intent` names an actionable goal.
  - Every task stays atomic and independently verifiable; adjacent tasks
    stay separate only with independent acceptance value or a
    dependency-ordering reason.
  - Every `Satisfies`-bearing task's `Acceptance` names testable
    behaviors, with failure modes and edge cases when `SPEC.md`
    specifies them or task logic requires them.
  - Every task's `Verification` includes test execution commands.
  - `Task graph` edges mirror per-task `Dependencies` fields.
  - Every `Satisfies: none` task's `Context` states a credible enabling
    rationale.
- `STATE.json` specifies `phase: "build"`, `status: "active"`,
  `cursor: {"active_task_id": "T-001"}`, and `tasks` mapping every
  `PLAN.md` task ID to `"todo"`.
- No files outside **Write scope** changed.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- Emit result template as live markdown—never in a code fence.
- Output nothing outside template.
- Source every `SPAE Status` value from confirmed re-read, never from
  working memory of intent.

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
> **Result**: [Ready | Revised | Failed]
> **Next Phase**: `/build`  _(unless failed)_
> **Impact**: [Terse impact statement]
>
> _Run `/build` next._  _(unless failed)_
```
<!-- prettier-ignore-end -->
