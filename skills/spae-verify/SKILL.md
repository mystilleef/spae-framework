---
name: spae-verify
description:
  Arbiter for the SPAE framework. Compares implementation against
  SPEC.md and determines workstream completion.
user-invocable: true
---

# Verify `SPAE`

## When to use

- `STATE.json` reports `phase: verify`.
- Every `PLAN.md` task reports `done`.

## Goal

- Compare implemented repository state against `SPEC.md`, identify gaps,
  and close or reopen the work stream as the final `SPAE` arbiter.
- Pass: complete the work stream.
- No pass: route actionable gaps back to `/spec`.

## Input

Read:

- `.spae/current/STATE.json`
- `.spae/current/SPEC.md`
- `.spae/current/PLAN.md`
- All source files modified by this **workstream** (committed and
  uncommitted changes). Use `.spae/current/PLAN.md` tasks to scope the
  delta.
- `.spae/current/VERIFY.md`, when present.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Workflow

1. **Initialize**: Check `.spae/current/STATE.json`, confirm
   `phase: verify`, and cross-check that every `.spae/current/PLAN.md`
   task reports `done`. On failure: halt, report which check failed and
   why, make no state changes.
2. **Check**: Run all relevant project checks. If no automated checks
   exist, manually verify observable behavior against each
   `.spae/current/SPEC.md` spec item. Record all results; any check
   failure mapping to a `.spae/current/SPEC.md` spec item classifies as
   a hard block in Step 3.
3. **Inspect**: Compare implementation against each
   `.spae/current/SPEC.md` item using check results as evidence.
   - When `.spae/current/VERIFY.md` exists: treat each prior finding as
     an explicit re-check item; confirm each addressed before moving on.
   - Classify each finding:
     - **Hard block**: regression, contract break, missing or incorrect
       required behavior, check failure mapping to a
       `.spae/current/SPEC.md` spec item—always drives verdict to
       no-pass.
     - **Soft finding**: missing tests for required behavior, unsafe
       optimization—document in `.spae/current/VERIFY.md`; drives
       verdict to no-pass.
     - **Observation**: ambiguous or untestable spec item, minor
       deviation outside SPEC scope—note only; no verdict impact.
4. **Finalize**:
   - **Pass**: remove `.spae/current/VERIFY.md` when present; remove
     `.spae/current` symlink; set `.spae/current/STATE.json` to
     `status: completed`, `phase: done`. Surface observations, if any,
     in the result output under Findings as informational notes.
   - **No pass**: create or overwrite `.spae/current/VERIFY.md` with
     hard blocks and soft findings from the current run only, followed
     by observations as informational notes; set
     `.spae/current/STATE.json` to `status: revision_required`,
     `phase: spec`, `cursor: {}`.
   - **Blocked**: when checks can't run due to broken build, missing
     tooling, or environment failure—write blocker details only to
     `.spae/current/VERIFY.md` (omit observations); set
     `.spae/current/STATE.json` to `status: revision_required`,
     `phase: spec`, `cursor: {}`; emit the Blocked result block.
   - **Result**: emit the required result block.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Focus on the delta between `.spae/current/SPEC.md` and repository
  state.
- Prefer existing project verification commands and patterns.
- Keep `.spae/current/VERIFY.md` findings concrete, reproducible, and
  tied to `.spae/current/SPEC.md` spec items.
- Include enough detail for `/spec` to revise spec items without
  repeating the full investigation.

## Constraints

- Never edit source code, tests, configuration, docs,
  `.spae/current/SPEC.md`, `.spae/current/PLAN.md`, or non-`SPAE`
  project files.
- Preserve the `SPAE` artifact model; don't create extra tracking files.
- Don't stage or commit `.spae/` artifacts.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.

## Verification

- `.spae/current/STATE.json` reflects the final status and phase (before
  symlink removal).
- `.spae/current` symlink absent after a passing run.
- `.spae/current/VERIFY.md` exists only after failure or a blocked run.
- `.spae/current/VERIFY.md` findings map to concrete
  `.spae/current/SPEC.md` gaps or blocker details.
- Required project checks pass or documented blockers explain failures.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Prefer lists, and sub-lists, over long paragraphs and sentences.
- Strictly follow the result template below.

<!-- vale Joblint.Competitive = NO -->
<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of verification actions]
- **Files**:
  - [List of modified SPAE files]
- **Findings**:
  - [List of gaps, blockers, or pass confirmation]
- **Summary**:
  - [Terse result summary]
```

On pass:

```md
> **SPAE Status** • `workstream-name` **Phase Complete**: `/verify`
> (Pass) **Result**: Workstream completed successfully.
```

On failure:

```md
> **SPAE Status** • `workstream-name` **Phase Complete**: `/verify`
> (Fail) **Next Phase**: `/spec`
>
> _Run `/spec` next._
```

On blocked:

```md
> **SPAE Status** • `workstream-name` **Phase Complete**: `/verify`
> (Blocked) **Reason**: [one-line blocker description] **Next Phase**: `/spec`
>
> _Resolve the blocker, then run `/spec` next._
```
<!-- prettier-ignore-end -->
<!-- vale Joblint.Competitive = YES -->
