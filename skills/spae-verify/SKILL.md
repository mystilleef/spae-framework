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
- Failure: route actionable gaps back to `/spec`.

## Input

Resolve the work stream from one source:

- User-provided work stream name.
- `.spae/current` symlink.

Read only required context:

- `.spae/<workstream>/STATE.json`
- `.spae/<workstream>/SPEC.md`
- Relevant implementation, tests, configuration, and docs
- `.spae/<workstream>/VERIFY.md`, when present

## Workflow

1. **Initialize**: Resolve the work stream, check `STATE.json`, and
   confirm `phase: verify`.
2. **Inspect**: Compare implementation against each `SPEC.md` item.
   Focus on observable behavior, regressions, contract breaks, missing
   tests, and unsafe optimizations.
3. **Verify**: Run project checks or the smallest matching validation
   that proves the result.
4. **Finalize**: Apply the appropriate pass or failure transition under
   **Constraints** and emit the required result block.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Focus on the delta between `SPEC.md` and repository state.
- Prefer existing project verification commands and patterns.
- Keep `VERIFY.md` findings concrete, reproducible, and tied to
  `SPEC.md` requirements.
- Include enough detail for `/spec` to revise requirements without
  repeating the full investigation.

## Constraints

- **Pass transition**: remove `.spae/<workstream>/VERIFY.md` when
  present; set `.spae/<workstream>/STATE.json` to `status: completed`
  and `phase: done`.
- **Fail transition**: create `.spae/<workstream>/VERIFY.md` with
  findings; set `.spae/<workstream>/STATE.json` to
  `status: revision_required` and `phase: spec`.
- Never edit source code, tests, configuration, docs, `SPEC.md`,
  `PLAN.md`, or non-`SPAE` project files.
- Preserve the `SPAE` artifact model; don't create extra tracking files.
- Don't stage or commit `.spae/` artifacts.

## Verification

- `STATE.json` reflects the final status and phase.
- `VERIFY.md` exists only after failure.
- `VERIFY.md` findings map to concrete `SPEC.md` gaps.
- Required project checks pass or documented blockers explain failures.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
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

> **SPAE Verify Status** • `[workstream-name]`
> **Result**: [Pass | Fail | Failed]
> **Impact**: [Workstream completed | Revision required | Verification blocked]
```
<!-- prettier-ignore-end -->
<!-- vale Joblint.Competitive = YES -->

On pass, include:

```md
> **SPAE Status** • `workstream-name` **Phase Complete**: `/verify`
> (Pass) **Result**: Workstream completed successfully.
```

<!-- vale Joblint.Competitive = NO -->

On failure, include:

```md
> **SPAE Status** • `workstream-name` **Phase Complete**: `/verify`
> (Fail) **Next Phase**: `/spec`
>
> _Run `/spec` next._
```

<!-- vale Joblint.Competitive = YES -->
