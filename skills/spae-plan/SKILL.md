---
name: spae-plan
description:
  Task Decomposition for the `SPAE` framework. Decomposes `SPEC.md` into
  a `DAG` of atomic tasks in `PLAN.md`.
user-invocable: true
---

# Plan (`SPAE`)

## When to use

- `STATE.json` reads `phase: plan`: decompose `SPEC.md` into an
  execution plan.

## Goal

- Convert normalized requirements into a concise, acyclic, atomic task
  graph while preserving strict phase and write boundaries.
- Produce `.spae/current/PLAN.md`, initialize task tracking in
  `.spae/current/STATE.json`, and advance the `workstream` to
  `phase: inspect`.

## Input

Use only relevant context from:

- `.spae/current/SPEC.md`.
- `.spae/current/STATE.json`; `references/STATE.md` holds field
  reference, directives, and snapshots.
- Repository source, for codebase fit.

Never read `.spae/current/VERIFY.md`; `SPEC.md` holds every requirement.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json`; self-heal missing metadata:
     `version` (`"1.0"`), `workstream` (target directory name), `status`
     (`"active"`); `PERSIST` writes the healed fields.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - Source code and `SPEC.md` stay unmodified.
   - Reset prior cycle unconditionally—the sole write before `PERSIST`;
     reruns repeat it safely:
     - Delete `PLAN.md` when present.
     - Set `STATE.json` `tasks: {}`.
   - Read `SPEC.md`; extract goal, requirements, testing strategy,
     out-of-scope items, and assumptions; capture every `R-NNN` into a
     coverage checklist.
3. **PLAN**—Identify source patterns needed for codebase fit.
4. **ACT**—Draft `PLAN.md`:
   - Read source narrowly; widen only on uncertainty.
   - Follow `references/PLAN.md`; number tasks from `T-001`.
   - Set `Satisfies` to the `R-NNN` IDs a task implements and `Intent`
     to a one-line distillation of the goal they serve.
   - Enabling task: `Satisfies: none`; `Intent` names its structural
     purpose toward the plan `## Goal`.
   - Order tasks by dependency, risk, and vertical value.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for `PLAN.md`:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`:
     - Uncovered `R-NNN`: add a task.
     - Task serving no requirement and no enabling purpose: remove it.
   - Exit only when every criterion passes.
   - Never halt on requirement content.
6. **PERSIST**—Write in order:
   - Write `PLAN.md`.
   - Write `STATE.json` per `references/STATE.md` exit snapshot.
   - Re-read `STATE.json`; on a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit result following result directives and using result
   template.

## Directives

- Optimize for agent, token, and context efficiency.
- Refine and optimize `PLAN.md` for agent consumption: agents read it
  for varied purposes, with no memory of this run; keep it
  self-contained, explicit, token-dense, and minimal.
- Align with existing codebase patterns; avoid speculative design.
- Slice vertically; avoid infrastructure-only tasks unless required;
  leave the system working after each task.
- Assume each task executes, reviews, and refines under a stateless
  agent with no memory beyond `PLAN.md` text and resulting source; write
  `Context` to supply every fact that agent needs, including facts
  surfaced only while planning.
- Write acceptance criteria as observable outcomes; name testable
  behaviors for a `Satisfies`-bearing task (include failure modes and
  edge cases only when specified in `SPEC.md` or required by task
  logic); state structural assurances for a `Satisfies: none` enabling
  task.
- Write `Verification` as concrete, deterministic commands, including
  test execution, per `references/verification-guide.md`; bind each step
  to tooling available now or installed by a dependency task; schedule
  new tooling as its own task; carry `SPEC.md` residual risks into
  `Risk notes`.
- Consult `references/prose-protocol.md` before drafting `PLAN.md`.

## Constraints

- **Write scope**: write only `.spae/current/PLAN.md` and
  `.spae/current/STATE.json`; forbid all other writes. Read source code
  only for codebase fit.
- **Phase boundary**: hand off work to `/inspect`; don't execute tasks.
- **Version control and release**: never create tasks for version
  control (git staging, commits, branches, tags) or release operations
  (package publishing, deployments); plan scope ends when local tests
  pass. Never stage or commit `.spae/` or execute git mutations.
- **Autonomy**: never ask users for input or clarification
  mid-execution; halts and failures stop autonomously. Never write a
  task step presuming human execution, an attended or interactive
  terminal, or human presence; translate such a need into automated
  evidence, else record it in `Risk notes` as a residual risk.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt without writing; report `Failed` with a
  diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `plan`.
  - `SPEC.md` missing.

## Verification

- `PLAN.md` holds atomic tasks in structure matching
  `references/PLAN.md` exactly.
- Every `SPEC.md` requirement maps to at least one task's `Satisfies`.
- Every task carries an `Intent` distilled from the requirements it
  satisfies, or—for a `Satisfies: none` enabling task—its structural
  purpose toward the plan `## Goal`.
- Every `Dependencies` ID numerically precedes its declaring task; every
  `T-NNN` reference—`Task graph` edges, the overview list, and
  `Dependencies` fields—resolves to a defined task.
- Every `Satisfies`-bearing task's `Acceptance` names testable behaviors
  (failure modes and edge cases when `SPEC.md` specifies them or task
  logic requires them); every enabling task's `Acceptance` states
  structural assurances.
- Every task's `Verification` includes test execution; no step presumes
  human execution, an attended or interactive terminal, or human
  presence.
- Zero tasks mandate version control or release operations.
- `STATE.json` specifies `phase: "inspect"`, `status: "active"`,
  `cursor: {}`, and `tasks` mapping every `PLAN.md` task ID to `"todo"`.
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
> **Result**: [Plan Complete | Failed]
> **Next Phase**: `/inspect`  _(unless failed)_
> **Impact**: [Terse impact statement]
>
> _Run `/inspect` to optimize and verify `PLAN.md`._  _(unless failed)_
```
<!-- prettier-ignore-end -->
