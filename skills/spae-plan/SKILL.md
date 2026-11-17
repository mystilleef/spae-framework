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
- `.spae/current/STATE.json`, with field reference, directives, and
  snapshots in `references/STATE.md`.
- Repository source, for codebase fit.
- The project's `TESTING.md`, when present, for test commands and
  prerequisites.

Never read `.spae/current/VERIFY.md`, since `SPEC.md` holds all
requirements.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json` and self-heal missing metadata:
     `version` (`"1.0"`), `workstream` (target directory name), `status`
     (`"active"`). `PERSIST` writes the healed fields.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - Source code and `SPEC.md` stay unmodified.
   - Reset prior cycle unconditionally—the sole write before `PERSIST`,
     which reruns repeat safely:
     - Delete `PLAN.md` when present.
     - Set `STATE.json` `tasks: {}`.
   - Read `SPEC.md` and extract goal, requirements, testing strategy,
     out-of-scope items, and assumptions. Capture every `R-NNN` into a
     coverage checklist.
3. **PLAN**—Identify source patterns needed for codebase fit.
4. **ACT**—Draft `PLAN.md`:
   - Read source narrowly, widening only on uncertainty.
   - Follow `references/PLAN.md`, numbering tasks from `T-001`.
   - Set `Satisfies` to the `R-NNN` IDs a task implements and proves
     through its own `Verification`—or its `Acceptance`, for prose—and
     `Intent` to a one-line distillation of the goal they serve.
   - Enabling task—tooling setup or a final verification gate:
     `Satisfies: none`, with an `Intent` naming its structural purpose
     toward the plan `## Goal`.
   - Order tasks by dependency, risk, and vertical value.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for `PLAN.md`:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`:
     - Uncovered `R-NNN`: add a task.
     - Task serving no `R-NNN` and no enabling purpose: remove it.
     - Granularity: split a non-atomic task, and merge a merge
       candidate.
   - Exit only when every criterion passes.
   - Never halt on the content of requirements.
6. **PERSIST**—Write in order:
   - Write `PLAN.md`.
   - Write `STATE.json` per `references/STATE.md` exit snapshot.
   - Re-read `STATE.json`. On a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit result following result directives and using result
   template.

## Directives

- Optimize for agent, token, and context efficiency.
- Refine and optimize `PLAN.md` for agent consumption: agents read it
  for varied purposes, with no memory of this run. Keep it
  self-contained, explicit, token-dense, and minimal.
- Keep each task self-contained and isolated per
  `references/outcome-guide.md` **Self-contained units**: fresh,
  isolated agents holding only the task's `PLAN.md` text and the
  repository can build, test, and verify it, each in a separate run.
  Write `Context` to supply every fact they need and can't derive,
  including facts surfaced only while planning.
- Slice vertically into atomic tasks with no merge candidate, per
  **Verification**.
- Align with existing codebase patterns and avoid speculative design.
- Write acceptance criteria as observable outcomes, contracts, and
  preserved behaviors at risk:
  - For a `Satisfies`-bearing task, name testable behaviors, including
    failure modes and edge cases only when `SPEC.md` specifies them or
    task logic requires them.
  - For prose, per `references/verification-guide.md`, name what the
    text must convey.
  - For a `Satisfies: none` enabling task, state structural assurances.
- Write `Verification` as project commands or existing test targets,
  including test execution—project checks alone when `Acceptance` holds
  only prose—each mapped to the outcomes it proves. Keep each step
  concrete, deterministic, and proportional per
  `references/verification-guide.md`, and never name invocation
  mechanics, test design, or review procedures:
  - Bind each step to tooling available now or installed by a dependency
    task.
  - Schedule a tooling task only for tooling the `SPEC.md`
    `Testing strategy` admits, verifying it with one smoke run, never
    its own test suite.
  - Never re-prove in a later task logic an earlier task's tests cover.
  - Carry `SPEC.md` residual risks into `Risk notes`.
- Consult `references/prose-protocol.md` and
  `references/outcome-guide.md` before drafting `PLAN.md`.

## Constraints

- **Write scope**: write only `.spae/current/PLAN.md` and
  `.spae/current/STATE.json`. Forbid all other writes. Write incidental
  run outputs—logs, reports, experiment files—to scratch: a private
  temporary directory outside the project, removed when the run ends.
  Scratch writes and byproducts of a command run for evidence, such as
  formatter rewrites, never count as this phase's writes. Never run a
  command for its write effect outside this scope. Read source code only
  for codebase fit.
- **Phase boundary**: hand off work to `/inspect` without executing
  tasks.
- **Version control and release**: never create tasks for version
  control (git staging, commits, branches, tags) or release operations
  (package publishing, deployments). Plan scope ends when local tests
  pass. Never stage or commit `.spae/` or execute git mutations.
- **Autonomy**: never ask users for input or clarification
  mid-execution—halts and failures stop autonomously. Never write a task
  step presuming human execution, an attended or interactive terminal,
  or human presence. Translate such a need into automated evidence, else
  record it in `Risk notes` as a residual risk.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt without writing and report `Failed` with a
  diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `plan`.
  - `SPEC.md` missing.

## Verification

- `PLAN.md` holds tasks in structure matching `references/PLAN.md`
  exactly.
- Every `SPEC.md` `R-NNN` maps to at least one task's `Satisfies`.
- Every task carries an `Intent` distilled from the requirements it
  satisfies, or—for a `Satisfies: none` enabling task—its structural
  purpose toward the plan `## Goal`.
- Every `Dependencies` ID numerically precedes its declaring task, and
  every `T-NNN` reference—`Task graph` edges, the overview list, and
  `Dependencies` fields—resolves to a defined task.
- Every `Satisfies`-bearing task's `Acceptance` names testable behaviors
  (failure modes and edge cases when `SPEC.md` specifies them or task
  logic requires them), and for prose, what the text must convey. Every
  enabling task's `Acceptance` states structural assurances.
- Every `Satisfies` ID names an `R-NNN` the task implements and proves
  through its own `Verification`—or its `Acceptance`, for prose.
- Every task's `Verification` includes test execution—one smoke run for
  an enabling tooling task, project checks alone when `Acceptance` holds
  only prose—maps each step to the outcomes it proves, and follows
  `references/verification-guide.md`. No step carries invocation
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
  - Each satisfies an `R-NNN` or serves as tooling setup or a final
    verification gate.
  - A third task must run between them.
  - Their merge would outgrow one run.
- Every task line passes the `references/outcome-guide.md` substitution
  test, and `Context` holds no derivable fact beyond entry-point paths.
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
- **Result contract**: orchestrating agents parse `Result`, so a
  missing, altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, early stop, or halt—with the
  result template as the final message, never on progress narration.
- Set `Result` to exactly one template literal, verbatim. Report an
  early stop or halt lacking its own literal as `Failed`, with the
  reason under `Findings`.
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
