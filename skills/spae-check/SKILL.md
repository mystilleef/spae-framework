---
name: spae-check
description: >-
  Per-task verification gate for SPAE. Compares active task Intent,
  Acceptance, and Verification against repo evidence; routes gaps to
  /fix or advances a clear task.
user-invocable: true
---

# Check (`SPAE`)

## When to use

- `STATE.json` reports `phase: check`.
- Cursor names active task.

## Goal

- Compare active task implementation against PLAN.md Intent, Acceptance,
  and Verification.
- Route gaps to /fix or advance clear task.

## Input

Read:

- `.spae/current/STATE.json` (consult `references/STATE.md` for field
  reference, directives, and phase snapshots)
- Active task section from `.spae/current/PLAN.md` (`Intent`,
  `Acceptance`, `Verification`)
- Source files and test logs scoped to active task

## Workflow

1. **GATE**—Read `.spae/current/STATE.json`; confirm `phase: check` and
   `active_task_id`. Self-heal state drift: if `tasks[`active_task_id`]`
   reads `"todo"`, correct it to `"in_progress"` and write `STATE.json`
   before proceeding. Halt on state drift: if `tasks[`active_task_id`]`
   reads `"done"`, halt. Read active `PLAN.md` task section; confirm
   title, `Intent`, `Acceptance`, `Verification`. Halt on missing or
   malformed input; report and make no changes.
2. **ORIENT**—Verify active task; hand off to `/fix`, `/build`, or
   `/verify`. Leave source, tests, `config`, docs, `PLAN.md`, `SPEC.md`,
   task scope, and `workstream` completion untouched.
3. **PLAN**—List active-task `Acceptance` outcomes and `Verification`
   steps. Map evidence for declared `Intent`; scope source/test reads to
   active task. Never read `SPEC.md`.
4. **ACT**—Execute:
   - Run active-task verification steps and project checks. Without
     automation, inspect source, logs, or scripted probes for observable
     behavior.
   - Confirm every `Acceptance` outcome and `Intent` against evidence.
   - Label findings with exactly two tags:
     - **Gap**: unmet `Acceptance`, failed `Verification`, `Intent`
       mismatch, speculative abstraction, _unrequested_ complexity,
       defensive bloat beyond task `Scope`, or a self-introduced cleanup
       violation per `references/cleanup-guide.md`. Include unmet item,
       file:line, expected vs actual, reproducible evidence. Blocks a
       clear result.
     - **Observation**: minor concern outside task scope, `unrequested`
       edge-case coverage, theoretical risk. Report only; never write to
       `FIX.md` or affect the verdict.
   - Draft gaps per `references/FIX.md` schema; consult
     `references/prose-protocol.md`.
5. **VERIFY**—Reconcile every `Acceptance`, `Verification`, and `Intent`
   against evidence. Clear verdict only with zero gaps. Confirm drafted
   `FIX.md` matches `references/FIX.md` structure.
6. **PERSIST**—Apply one verdict:
   - **Gap found**: create/overwrite `.spae/current/FIX.md` per
     `references/FIX.md`. Write `STATE.json`: `phase: fix`; preserve
     status, cursor, task registry, version, workstream. Active task
     stays `in_progress`.
   - **Task clear, tasks remain**: write `STATE.json`: mark active task
     `done`, advance cursor to next `"todo"` task, `phase: build`.
   - **Final task clear**: write `STATE.json`: mark active task `done`,
     retain cursor active task ID, `phase: verify`.
   - **All branches**: re-read `STATE.json` after writing; on a field
     mismatch, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit result per directives. Template B after gap, D after
   clear _nonfinal_ task, E after clear final task. Observations under
   Findings only.

## Directives

- Optimize for agent, token, and context efficiency.
- Consult `references/shell-command-guide.md` for command safety,
  timeouts, redirects, and environment directives.
- Consult `references/cleanup-guide.md` for self-introduced-artifact
  scope and criteria.
- Follow canonical `SPAE` Step 5 `/check` contract on conflicts.
- Focus on active-task evidence; prefer existing project checks.
- Enforce `KISS` and `YAGNI`; flag `Intent` mismatches over speculative
  scope or defensive bloat.
- Ground bloat findings in the diff; never flag hypothetical future
  risk, stylistic preference, or _unshipped_ edge case.
- Relegate `unrequested` edge-case coverage, theoretical risks, and
  defensive bloat suggestions to observations; forbid writing them to
  `FIX.md`.
- Keep gaps concrete, reproducible, enough for `/fix` without `PLAN.md`.
- Preserve task-plan wording verbatim in `FIX.md` `## Intent`.
- Write only current actionable gaps to `FIX.md` per
  `references/FIX.md`; report observations in summary only.
- Consult `references/prose-protocol.md` before drafting `FIX.md`.

## Constraints

- Read source, tests, `config`, docs, logs only; write only
  `.spae/current/FIX.md` and `.spae/current/STATE.json`.
- Never read/edit `.spae/current/SPEC.md`; never edit
  `.spae/current/PLAN.md`.
- Never edit source, tests, `config`, docs, or non-`SPAE` project files.
- Never claim `workstream` completion (only `/verify` holds that
  authority).
- Never add artifacts beyond canonical `SPAE` files or fields beyond
  `STATE.json` schema.
- Never stage/commit `.spae/` artifacts.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and failures stop autonomously.
- **Full autonomy**: Never ask for human execution, attended terminal,
  interactive session, or human presence. Surface any such dependency as
  a `Gap`.

## Verification

- `STATE.json` enters with `phase: check` and matching active
  in-progress task.
- Every `Acceptance`, `Verification`, and `Intent` reviewed against
  evidence.
- Only `Gap`/`Observation` labels used; every unmet item flagged `Gap`.
- Gap run writes `FIX.md` matching schema, verbatim intent, actionable
  evidence; active task stays `in_progress`; phase → `fix`.
- No speculative abstraction, _unrequested_ complexity, defensive bloat
  beyond task `Scope`, or self-introduced cleanup violation per
  `references/cleanup-guide.md` survives _unflagged_.
- Clear run marks one task `done`, routes to `build` or `verify` with
  correct cursor state.
- `SPEC.md`, `PLAN.md`, source, tests, `config`, docs, unrelated files
  unchanged.
- Output uses template B, D, or E verbatim.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, summaries into terse bullet points.
- Use lists/sub-lists over paragraphs and long sentences.
- Emit result as live markdown—never in a code fence.
- Output nothing outside the template.
- Source every `SPAE Status` value from the confirmed re-read, never
  from working memory of intent.

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

Emit exactly one, matching the verdict.

### Gap found

<!-- prettier-ignore-start -->
```md
> **SPAE Status** • `workstream-name` **Active Task**: `T-XXX` - [Task
> title] **Result**: Gaps found, `FIX.md` written
>
> _Run `/fix` to close the gaps._
```
<!-- prettier-ignore-end -->

### Clear, tasks remain

<!-- prettier-ignore-start -->
```md
> **SPAE Status** • `workstream-name` **Progress**: Task [X] of [Y] ([Z]
> remaining) **Completed**: `T-XXX` - [Task title] **Next Task**:
> `T-YYY` - [Next task title]
>
> _Run `/build` to execute the next task._
```
<!-- prettier-ignore-end -->

### Clear, final task

<!-- prettier-ignore-start -->
```md
> **SPAE Status** • `workstream-name` **Progress**: All [X] tasks
> completed **Completed**: `T-001` through `T-XXX` **Next Phase**:
> `/verify`
>
> _Run `/verify` to validate the implementation against the
> specification._
```
<!-- prettier-ignore-end -->
