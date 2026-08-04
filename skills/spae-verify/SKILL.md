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

- `.spae/current/STATE.json` (consult `references/STATE.md` for field
  reference, directives, and phase snapshots)
- `.spae/current/SPEC.md`
- `.spae/current/PLAN.md`
- All source files modified by this **workstream** (scoped from
  `.spae/current/PLAN.md` tasks)
- `.spae/current/VERIFY.md`, when present

## Workflow

1. **GATE**—Read `.spae/current/STATE.json`; confirm `phase: verify`.
   Confirm every `.spae/current/PLAN.md` task reports `done` in the
   `tasks` registry. Halt immediately on failure; report which check
   failed; make no changes.
2. **ORIENT**—Goal: compare implemented repository state against each
   `.spae/current/SPEC.md` spec item; determine pass, no-pass, or
   blocked verdict.
3. **PLAN**—List `SPEC.md` spec item IDs and source files modified by
   this `workstream` (scoped from `PLAN.md` tasks).
4. **ACT**—Execute:
   - Run all relevant project checks. When no automated checks exist,
     inspect observable behavior directly—reading code and logs or
     running scripted probes—never delegating execution or evidence
     capture to a human, an attended terminal, or an interactive
     session. Record all results; any check failure mapping to a
     `SPEC.md` item classifies as a hard block.
   - When a `SPEC.md` item resists verification without human execution,
     an attended or interactive terminal, or human presence: classify it
     as a hard block and record it in `VERIFY.md` as a spec defect for
     `/spec` to resolve; never instruct the user to perform a
     verification step.
   - Compare implementation against each `SPEC.md` item using check
     results as evidence. Reference each finding by spec item ID.
   - When `.spae/current/VERIFY.md` exists: treat each prior finding as
     an explicit re-check item; confirm each addressed before
     proceeding.
   - Classify each finding:
     - **Hard block**: regression, contract break, missing or incorrect
       required behavior, check failure mapping to a `SPEC.md` item;
       drives verdict to no-pass.
     - **Soft finding**: absent test coverage of explicit required
       behavior; unsafe optimization; complexity ungrounded in an
       explicit `SPEC.md` spec item (for example, a validation library
       pulled in for a single basic check); note only; no verdict
       impact.
     - **Observation**: thin edge-case test coverage, ambiguous or
       untestable spec item, minor deviation outside SPEC scope,
       `unrequested` guardrail, theoretical risk; note only; no verdict
       impact.
   - Draft findings against the `references/VERIFY.md` schema; consult
     `references/prose-protocol.md` for phrasing.
5. **VERIFY**—Confirm any drafted `VERIFY.md` content matches
   `references/VERIFY.md` structure.
6. **PERSIST**—Apply verdict:
   - **Pass**: set `STATE.json` to `status: completed`, `phase: done`;
     remove `.spae/current/VERIFY.md` when present; remove
     `.spae/current` symlink.
   - **No pass**: create or overwrite `.spae/current/VERIFY.md` using
     the `references/VERIFY.md` schema with hard blocks from the current
     run only, followed by soft findings and observations as
     informational notes; set `STATE.json` to
     `status: revision_required`, `phase: spec`, `cursor: {}`,
     `tasks: {}`.
   - **Blocked**: write blocker details only to
     `.spae/current/VERIFY.md` (omit observations); set `STATE.json` to
     `status: revision_required`, `phase: spec`, `cursor: {}`,
     `tasks: {}`.
   - **All verdicts**: re-read `STATE.json` after writing; on a field
     mismatch, rewrite and re-read. On **Pass**, confirm the re-read
     before removing `.spae/current`.
7. **REPORT**—Emit the result following the result directives and using
   the result template. On pass, surface observations under Findings. On
   blocked, emit the Blocked result block.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Consult `references/shell-command-guide.md` for command safety,
  timeouts, redirects, and environment directives.
- Focus on the delta between `.spae/current/SPEC.md` and repository
  state.
- Enforce `KISS` and `YAGNI` principles; penalize over-engineering,
  defensive bloat, or speculative abstractions.
- Ground bloat findings in the diff itself; never flag a hypothetical
  future risk, stylistic preference, or `unshipped` edge case.
- Classify theoretical gaps, `unrequested` guardrails, and minor edge
  cases strictly as observations; forbid theoretical gaps from driving a
  no-pass verdict.
- Confine verification evaluation strictly to documented SPEC.md
  requirements.
- Prefer existing project verification commands and patterns.
- Keep `.spae/current/VERIFY.md` findings concrete, reproducible, and
  tied to `.spae/current/SPEC.md` spec items.
- Include enough detail for `/spec` to rewrite `SPEC.md` from scratch
  without repeating the full investigation.
- Draft `VERIFY.md` matching the `references/VERIFY.md` schema.
- Consult `references/prose-protocol.md` before drafting `VERIFY.md`.

## Constraints

- Never edit source code, tests, configuration, docs,
  `.spae/current/SPEC.md`, `.spae/current/PLAN.md`, or non-`SPAE`
  project files.
- Preserve the `SPAE` artifact model; don't create extra tracking files.
- Don't stage or commit `.spae/` artifacts.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and failures stop autonomously.
- **Full autonomy**: Never require, request, or instruct human
  execution, an attended or interactive terminal, or human presence to
  reach a verdict; treat any such dependency as a spec defect, not a
  pass condition, and never surface it as an instruction to the user.
- Never introduce fields to `STATE.json` outside the schema reference.

## Verification

- `.spae/current/STATE.json` reflects final verdict state:
  `status: "completed"`, `phase: "done"` on pass; or
  `status: "revision_required"`, `phase: "spec"`, `cursor: {}`,
  `tasks: {}` on no pass.
- `.spae/current` symlink absent after a passing run.
- `.spae/current/VERIFY.md` exists only after failure or a blocked run.
- `.spae/current/VERIFY.md` findings map to concrete
  `.spae/current/SPEC.md` **requirement** IDs or blocker details,
  matching `references/VERIFY.md` structure.
- Required project checks pass or documented findings explain failures.
- No `VERIFY.md` finding or result output instructs the user to perform
  a verification step, attach a terminal, or supply evidence.
- No speculative abstraction, defensive bloat, or `SPEC.md`-ungrounded
  complexity survives the implementation `unflagged`.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.
- Source every `SPAE Status` value from the confirmed re-read, never
  from working memory of intent.

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
