---
name: spae-check
description:
  Task Verification Gate for the `SPAE` framework. Compares the active
  `PLAN.md` task's `Intent`, `Acceptance`, and `Verification` against
  repository evidence; routes gaps to `/fix` or advances the task.
user-invocable: true
---

# Check (`SPAE`)

## When to use

- `STATE.json` reads `phase: check`: verify the active `PLAN.md` task
  against repository evidence.

## Goal

- Judge the active task's implementation against its `Intent`,
  `Acceptance`, and `Verification`; record every gap in `FIX.md`.
- Advance the `workstream` to `phase: fix` on a gap; else mark the task
  `done` and advance to `phase: build` or `phase: verify`.

## Input

Read only what the check requires:

- `.spae/current/STATE.json`; `references/STATE.md` holds field
  reference, directives, and snapshots.
- `.spae/current/PLAN.md`: the active task in full, plus task titles and
  order.
- Repository source, tests, docs, configuration, and logs the active
  task touches, for analysis.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json`; self-heal missing metadata:
     `version` (`"1.0"`), `workstream` (target directory name), `status`
     (`"active"`); `PERSIST` writes the healed fields.
   - Self-heal state drift: treat a `"todo"` or missing
     `tasks[active_task_id]` as `"in_progress"` until `PERSIST`.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - `PLAN.md` stays unmodified; directly modify no source or tests;
     write nothing before `PERSIST`.
   - Read the active task in full, plus `PLAN.md` task titles and order.
3. **PLAN**—Declare the evidence map:
   - Read `references/verification-guide.md` and
     `references/shell-command-guide.md`.
   - Map each `Acceptance` outcome, each `Verification` step, and the
     `Intent` to the evidence that proves it.
   - Halt on any **Halt conditions** entry.
4. **ACT**—Gather evidence and label findings:
   - Run every task `Verification` step and the project checks.
   - Read the task diff with the scoped audit command in
     `references/cleanup-guide.md`.
   - Judge each `Acceptance` outcome and the `Intent` against step
     output, the diff, and source.
   - Label each finding with exactly one tag:
     - **Gap**—blocks a clear verdict; cite reproducible evidence, never
       a hypothetical risk or stylistic preference:
       - An unmet `Acceptance` outcome, a failing `Verification` step,
         or behavior diverging from the `Intent`.
       - A project-check failure the task diff causes.
       - Speculative abstraction, _unrequested_ complexity, or defensive
         bloat the diff adds beyond the task `Scope`.
       - A task-written test breaking
         `references/verification-guide.md`.
       - **Gap** covers only task-introduced violations within the
         active task's declared scope: debug output, dead code, an
         orphan file, a commented-out block, a superseded duplicate, an
         unused dependency, or stray build/cache output this task's own
         diff introduces and leaves behind. Never flag pre-existing
         uncommitted files outside task scope as gaps.
     - **Observation**—never a verdict input: a concern outside task
       scope, _unrequested_ edge-case coverage, a defensive-code
       suggestion, or a theoretical risk.
   - On any `Gap`, draft `FIX.md` per `references/FIX.md`.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for the verdict and
   the `FIX.md` draft:
   - For each failure: return to `ACT`, complete the evaluation, then
     re-enter `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - On a `Gap` verdict, write `.spae/current/FIX.md`, replacing any
     prior copy.
   - Write `STATE.json` per the `references/STATE.md` exit snapshot
     matching the verdict.
   - Re-read `STATE.json`; on a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit result following result directives and using result
   template:
   - Status block by re-read `phase`: `fix`→`Gap found`,
     `build`→`Clear, tasks remain`, `verify`→`Clear, final task`; a
     halt→`Failed`.
   - List each `Gap`, then each `Observation`, under `Findings`.

## Directives

- Optimize for agent, token, and context efficiency.
- Refine and optimize `FIX.md` for agent consumption: agents read it for
  varied purposes, with no memory of this run; keep it self-contained,
  explicit, and token-dense; make each gap closable without `PLAN.md`.
- Consult `references/prose-protocol.md` before drafting `FIX.md`.

## Constraints

- **Write scope**: write only `.spae/current/FIX.md` and
  `.spae/current/STATE.json`; forbid all other writes. Byproducts of a
  command run for evidence, such as a formatter's rewrites, never count
  as this phase's writes; never run a command for its write effect
  outside this scope. Read source code only for analysis.
- **Phase boundary**: judge exactly one task; hand off work to `/fix`,
  `/build`, or `/verify`.
- **Version control and release**: never execute git mutations (staging,
  commits, branches, tags, pushes) or release operations. Never stage or
  commit `.spae/`.
- **Autonomy**: never ask users for input or clarification
  mid-execution; halts and failures stop autonomously. Never perform or
  request human execution, an attended or interactive terminal, or human
  presence.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt without writing; report `Failed` with a
  diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `check`.
  - `PLAN.md` missing, `cursor.active_task_id` missing, or the active
    task absent from `PLAN.md`.
  - `tasks[active_task_id]` reads `"done"`.
  - A planned `Verification` step can't run for a cause outside the task
    diff: missing tooling, a broken external dependency, or a need for
    human presence.
- **Scope control**: ignore pre-existing uncommitted files and
  modifications outside the active task's declared scope; they yield no
  finding.

## Verification

- Every `Acceptance` outcome, `Verification` step, and the `Intent`
  judged against cited evidence.
- Every defect matching a `Gap` item—diff bloat and cleanup violations
  included—carries `Gap`; every other finding carries `Observation`.
- Verdict reads clear only with zero `Gap` findings.
- On a `Gap` verdict, the `FIX.md` draft matches `references/FIX.md`:
  `## Intent` verbatim from `PLAN.md`; every `Gap` with `File`,
  `Expected`, `Actual`, and reproducible `Evidence`; no `Observation`.
- `STATE.json` matches the `references/STATE.md` exit snapshot for the
  verdict.
- This phase wrote no file outside **Write scope**.

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
  - [Terse list of checks and verdict work]
- **Files**:
  - [Terse list of affected SPAE artifacts]
- **Findings**:
  - [Gaps or observations]
- **Summary**:
  - [Terse task outcome]
```
<!-- prettier-ignore-end -->

Emit exactly one status block below, matching the outcome.

### Gap found

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Gaps found, `FIX.md` written
> **Active Task**: `T-XXX` - [Task title]
>
> _Run `/fix` to close the gaps._
```
<!-- prettier-ignore-end -->

### Clear, tasks remain

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Clear, tasks remain
> **Progress**: Task [X] of [Y] ([Z] remaining)
> **Completed**: `T-XXX` - [Task title]
> **Next Task**: `T-YYY` - [Next task title]
>
> _Run `/build` to execute the next task._
```
<!-- prettier-ignore-end -->

### Clear, final task

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Clear, final task
> **Progress**: All [X] tasks completed
> **Completed**: `T-001` through `T-XXX`
> **Next Phase**: `/verify`
>
> _Run `/verify` to validate the implementation against the specification._
```
<!-- prettier-ignore-end -->

### Failed

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Failed
> **Active Task**: `T-XXX` - [Task title]
```
<!-- prettier-ignore-end -->
