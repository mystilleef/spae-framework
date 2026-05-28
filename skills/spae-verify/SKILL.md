---
name: spae-verify
description:
  Arbiter for the SPAE framework. Compares implementation against
  SPEC.md and determines workstream completion.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Verify `SPAE`

## When to use

- `STATE.json` reports `phase: verify`.
- Every `PLAN.md` task reports `done`.

## Role

Final `SPAE` arbiter. Compare implemented repository state against
`SPEC.md`, identify gaps, and close or reopen the work stream.

## Goal

- Pass: complete the work stream.
- No pass: route actionable gaps back to `/spec`.

## Input

Resolve the work stream from one source:

- User-provided work stream name.
- `.spae/current` symlink.

Read only required context:

- `.spae/<workstream>/STATE.json`
- `.spae/<workstream>/SPEC.md`
- `.spae/<workstream>/PLAN.md`
- All source files modified by this **workstream** (committed and
  uncommitted changes). Use `PLAN.md` tasks to scope the delta.
- `.spae/<workstream>/VERIFY.md`, when present.

## Workflow

1. **Initialize**: Resolve the work stream, check `STATE.json`, confirm
   `phase: verify`, and cross-check that every `PLAN.md` task reports
   `done`. On failure: halt, report which check failed and why, make no
   state changes.
2. **Check**: Run all relevant project checks. If no automated checks
   exist, manually verify observable behavior against each `SPEC.md`
   spec item. Record all results; any check failure mapping to a
   `SPEC.md` spec item classifies as a hard block in Step 3.
3. **Inspect**: Compare implementation against each `SPEC.md` item using
   check results as evidence.
   - When `VERIFY.md` exists: treat each prior finding as an explicit
     re-check item; confirm each addressed before moving on.
   - Classify each finding:
     - **Hard block**: regression, contract break, missing or incorrect
       required behavior, check failure mapping to a `SPEC.md` spec
       item—always drives verdict to no-pass.
     - **Soft finding**: missing tests for required behavior, unsafe
       optimization—document in `VERIFY.md`; drives verdict to no-pass.
     - **Observation**: ambiguous or untestable spec item, minor
       deviation outside SPEC scope—note only; no verdict impact.
4. **Finalize**:
   - **Pass**: remove `.spae/<workstream>/VERIFY.md` when present;
     remove `.spae/current`; set `STATE.json` to `status: completed`,
     `phase: done`. Surface observations, if any, in the result output
     under Findings as informational notes.
   - **No pass**: create or overwrite `.spae/<workstream>/VERIFY.md`
     with hard blocks and soft findings from the current run only,
     followed by observations as informational notes; set `STATE.json`
     to `status: revision_required`, `phase: spec`.
   - **Blocked**: when checks can't run due to broken build, missing
     tooling, or environment failure—write blocker details only to
     `.spae/<workstream>/VERIFY.md` (omit observations); set
     `STATE.json` to `status: revision_required`, `phase: spec`; emit
     the Blocked result block.
   - **Result**: emit the required result block.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Focus on the delta between `SPEC.md` and repository state.
- Prefer existing project verification commands and patterns.
- Keep `VERIFY.md` findings concrete, reproducible, and tied to
  `SPEC.md` spec items.
- Include enough detail for `/spec` to revise spec items without
  repeating the full investigation.

## Constraints

- Never edit source code, tests, configuration, docs, `SPEC.md`,
  `PLAN.md`, or non-`SPAE` project files.
- Preserve the `SPAE` artifact model; don't create extra tracking files.
- Don't stage or commit `.spae/` artifacts.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.

## Verification

- `STATE.json` reflects the final status and phase.
- `.spae/current` absent after a passing run.
- `VERIFY.md` exists only after failure or a blocked run.
- `VERIFY.md` findings map to concrete `SPEC.md` gaps or blocker
  details.
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
