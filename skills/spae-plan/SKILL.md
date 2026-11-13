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
- The project's `TESTING.md`, when present, for test commands and
  prerequisites.

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
   - Set `Satisfies` to the `R-NNN` IDs a task implements and its own
     `Verification` proves, and `Intent` to a one-line distillation of
     the goal they serve.
   - Enabling task—tooling setup or a final verification gate:
     `Satisfies: none`; `Intent` names its structural purpose toward the
     plan `## Goal`.
   - Order tasks by dependency, risk, and vertical value.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for `PLAN.md`:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`:
     - Uncovered `R-NNN`: add a task.
     - Task serving no requirement and no enabling purpose: remove it.
     - Granularity: split a non-atomic task; merge a merge candidate.
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
- Keep each task self-contained and isolated per
  `references/outcome-guide.md` **Self-contained units**: fresh,
  isolated agents holding only the task's `PLAN.md` text and the
  repository can build, test, and verify it, each in a separate run;
  write `Context` to supply every fact they need and can't derive,
  including facts surfaced only while planning.
- Slice vertically into atomic tasks with no merge candidate, per
  **Verification**.
- Align with existing codebase patterns; avoid speculative design.
- Write acceptance criteria as observable outcomes, contracts, and
  preserved behaviors at risk; name testable behaviors for a
  `Satisfies`-bearing task (include failure modes and edge cases only
  when specified in `SPEC.md` or required by task logic); state
  structural assurances for a `Satisfies: none` enabling task.
- Write `Verification` as project commands or existing test targets,
  including test execution, each mapped to the outcomes it proves; keep
  each step concrete, deterministic, and proportional per
  `references/verification-guide.md`; never name invocation mechanics,
  test design, or review procedures:
  - Bind each step to tooling available now or installed by a dependency
    task.
  - Schedule a tooling task only for tooling the `SPEC.md`
    `Testing strategy` admits; verify it with one smoke run, never its
    own test suite.
  - Never re-prove in a later task logic an earlier task's tests cover.
  - Carry `SPEC.md` residual risks into `Risk notes`.
- Consult `references/prose-protocol.md` and
  `references/outcome-guide.md` before drafting `PLAN.md`.

## Constraints

- **Write scope**: write only `.spae/current/PLAN.md` and
  `.spae/current/STATE.json`; forbid all other writes. Write incidental
  run outputs—logs, reports, experiment files—to scratch: a private
  temporary directory outside the project, removed when the run ends.
  Scratch writes and byproducts of a command run for evidence, such as a
  formatter's rewrites, never count as this phase's writes; never run a
  command for its write effect outside this scope. Read source code only
  for codebase fit.
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

- `PLAN.md` holds tasks in structure matching `references/PLAN.md`
  exactly.
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
- Every `Satisfies` ID names a requirement the task implements and its
  own `Verification` proves.
- Every task's `Verification` includes test execution—one smoke run for
  an enabling tooling task—maps each step to the outcomes it proves, and
  follows `references/verification-guide.md`; no step carries invocation
  mechanics or presumes human execution, an attended or interactive
  terminal, or human presence.
- Every task stays self-contained and isolated per
  `references/outcome-guide.md` **Self-contained units**: fresh agents
  holding only its text and the repository can build, test, and verify
  it, each in a separate run.
- Every task stays atomic: a change one run can build, leaving the
  system working.
- No merge candidate remains: bordering tasks—linked by a dependency
  edge or sharing `Scope` surface—form one unless any of these holds:
  - Each satisfies a requirement or serves as tooling setup or a final
    verification gate.
  - A third task must run between them.
  - Their merge would outgrow one run.
- Every task line passes the `references/outcome-guide.md` substitution
  test; `Context` holds no derivable fact beyond entry-point paths.
- Zero tasks mandate version control or release operations.
- `STATE.json` specifies `phase: "inspect"`, `status: "active"`,
  `cursor: {}`, and `tasks` mapping every `PLAN.md` task ID to `"todo"`.
- This phase wrote no file outside **Write scope**.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`; a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, abort, or halt—with the
  result template as the final message; never end on progress narration.
- Set `Result` to exactly one template literal, verbatim; report an
  abort or halt lacking its own literal as `Failed`, with the reason
  under `Findings`.
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
