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

1. **GATE**—Read `.spae/current/STATE.json`; confirm `phase: verify`;
   confirm every `.spae/current/PLAN.md` task reports `done`. Halt
   immediately on failure; report which check failed; make no changes.
2. **ORIENT**—Goal: compare implemented repository state against each
   `.spae/current/SPEC.md` spec item; determine pass, no-pass, or
   blocked verdict.
3. **PLAN**—List `SPEC.md` spec item IDs and source files modified by
   this `workstream` (scoped from `PLAN.md` tasks).
4. **ACT**—Execute:
   - Run all relevant project checks. When no automated checks exist,
     manually verify observable behavior against each `SPEC.md` item.
     Record all results; any check failure mapping to a `SPEC.md` item
     classifies as a hard block.
   - Compare implementation against each `SPEC.md` item using check
     results as evidence. Reference each finding by spec item ID.
   - When `.spae/current/VERIFY.md` exists: treat each prior finding as
     an explicit re-check item; confirm each addressed before
     proceeding.
   - Classify each finding:
     - **Hard block**: regression, contract break, missing or incorrect
       required behavior, check failure mapping to a `SPEC.md` item;
       drives verdict to no-pass.
     - **Soft finding**: absent or thin test coverage of required
       behavior, failure modes, or edge cases; unsafe optimization;
       drives verdict to no-pass.
     - **Observation**: ambiguous or untestable spec item, minor
       deviation outside SPEC scope; note only; no verdict impact.
5. **VERIFY**—Run `vibe-check` on a **PASS** verdict or a verdict held
   under material uncertainty; sanity-check without ceding arbiter role.
   Skip on a clear no-pass. Don't surface its exchange to the user.
6. **PERSIST**—Apply verdict:
   - **Pass**: set `STATE.json` to `status: completed`, `phase: done`;
     remove `.spae/current/VERIFY.md` when present; remove
     `.spae/current` symlink.
   - **No pass**: create or overwrite `.spae/current/VERIFY.md` with
     hard blocks and soft findings from the current run only, followed
     by observations as informational notes; set `STATE.json` to
     `status: revision_required`, `phase: spec`, `cursor: {}`.
   - **Blocked**: write blocker details only to
     `.spae/current/VERIFY.md` (omit observations); set `STATE.json` to
     `status: revision_required`, `phase: spec`, `cursor: {}`.
7. **REPORT**—Emit the result following the result directives and using
   the result template. On pass, surface observations under Findings. On
   blocked, emit the Blocked result block.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Focus on the delta between `.spae/current/SPEC.md` and repository
  state.
- Check test exhaustiveness against the `.spae/current/SPEC.md` testing
  strategy; thin coverage of failure modes or edge cases classifies as a
  soft finding.
- Prefer existing project verification commands and patterns.
- Keep `.spae/current/VERIFY.md` findings concrete, reproducible, and
  tied to `.spae/current/SPEC.md` spec items.
- Include enough detail for `/spec` to rewrite `SPEC.md` from scratch
  without repeating the full investigation.

## Constraints

- Never edit source code, tests, configuration, docs,
  `.spae/current/SPEC.md`, `.spae/current/PLAN.md`, or non-`SPAE`
  project files.
- Preserve the `SPAE` artifact model; don't create extra tracking files.
- Don't stage or commit `.spae/` artifacts.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.
- Never introduce fields to `STATE.json` outside the schema reference.

## Verification

- `.spae/current/STATE.json` reflects the final status and phase (before
  symlink removal).
- `.spae/current` symlink absent after a passing run.
- `.spae/current/VERIFY.md` exists only after failure or a blocked run.
- `.spae/current/VERIFY.md` findings map to concrete
  `.spae/current/SPEC.md` **requirement** IDs or blocker details.
- Required project checks pass or documented blockers explain failures.

## Result directives

- Optimize result for agent, token, and context efficiency: terse,
  concise, precise.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

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
> **Phase Complete**: `/verify` ([Pass | Fail | Blocked])
> **Reason**: [Terse blocker description]  _(if blocked)_
> **Next Phase**: `/spec`  _(if fail or blocked)_
```
<!-- prettier-ignore-end -->
