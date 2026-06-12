---
name: spae-spec
description:
  Given a proposal, or task, generate a spec and state file for SPAE
  structured workflow.
user-invocable: true
argument-hint: "[optional-workstream-name] [optional-task]"
---

# Spec (`SPAE`)

## When to use

- Initialize a new `SPAE workstream`.
- Resume interrupted spec work (`phase: spec`, `status: active`).
- Rewrite requirements from scratch after a failed `/verify`
  (`status: revision_required`).

## Goal

- Distill user requests, verification findings, and codebase context
  into concise, testable requirements while preserving `SPAE` phase
  boundaries.
- Generate `.spae/[workstream]/SPEC.md` and advance `STATE.json` to
  `phase: plan`.

## Input

Determine scope by the first available source:

- proposal or task from user
- Existing `STATE.json` and `VERIFY.md` in `.spae/current` when present.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Workflow

Select sub-workflow by `.spae/current` symlink state:

- **New** (absent): [New spec workflow](#new-spec-workflow)
- **Revision** (present):
  [Revision spec workflow](#revision-spec-workflow)

### New spec workflow

1. **GATE**—`.spae/current` absent. Halt if symlink exists (revision
   path).
2. **ORIENT**—Produce `SPEC.md` and `STATE.json` for `[workstream]`.
   Codebase unmodified.
3. **PLAN**—Derive `[workstream]` slug from `args` or auto-generate.
   Identify codebase sections to read.
4. **ACT**—Execute:
   - Initialize `.spae/[workstream]/`; point `.spae/current` symlink;
     create `STATE.json` (`phase: spec`, `status: active`).
   - Read codebase sections narrowly; widen only on uncertainty.
   - Derive goal, requirements, testing strategy, out-of-scope
     boundaries, and assumptions.
5. **VERIFY**—Loop over spec completeness criteria:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when spec complete and structure matches
     `references/SPEC.md`.
   - Halt only for out-of-scope blockers.
6. **PERSIST**—Write `SPEC.md`. Update `STATE.json` (`phase: plan`,
   `status: active`).
7. **REPORT**—Emit result using the Result template.

### Revision spec workflow

1. **GATE**—`.spae/current` present. `VERIFY.md` exists. `STATE.json`
   `status: revision_required`. Halt immediately on any failure.
2. **ORIENT**—Rewrite `SPEC.md` from scratch to address all `VERIFY.md`
   findings. Source code unmodified.
3. **PLAN**—Survey `VERIFY.md` findings; identify source files to
   inspect and requirements to derive.
4. **ACT**—Execute:
   - Read `VERIFY.md` in full; treat all findings as primary
     requirements input.
   - Delete `SPEC.md`.
   - Inspect source files to ground new requirements.
   - Write new `SPEC.md` from scratch; assign fresh `R-NNN` identifiers;
     address all `VERIFY.md` findings.
5. **VERIFY**—Loop over all `VERIFY.md` findings:
   - For each unaddressed finding: return to `ACT`, address it, then
     re-enter `VERIFY`.
   - Exit only when all findings addressed and spec well-formed against
     `references/SPEC.md`.
   - Halt only for out-of-scope blockers.
6. **PERSIST**—Write `SPEC.md`. Update `STATE.json` (`phase: plan`,
   `status: active`).
7. **REPORT**—Emit result using the Result template.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- Write observable, testable, and implementation-neutral requirements.
- Write a testing strategy covering expected behavior, failure modes,
  and edge cases; name all applicable test categories.
- Tag each item with a unique, stable `R-NNN` identifier.
- Document assumptions explicitly instead of guessing scope.
- Match level of detail to task size; avoid process bloat.
- Never stage or commit the `.spae/` directory.

## Constraints

- **Write Scope**: write only `.spae/current` symlink,
  `.spae/[workstream]/SPEC.md`, `.spae/[workstream]/STATE.json`, forbid
  all other writes.
- **Read-only files**: inspect source code to ground requirements and
  confirm fit; stay read-only.
- **Phase boundary**: hand off work to `/plan`; don't decompose tasks.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and blockers stop autonomously.
- **Ambiguity**: resolve from codebase evidence first; fall back to a
  documented conservative assumption only when evidence proves
  insufficient; record under **Assumptions** in `SPEC.md`.
- Never introduce fields to `STATE.json` outside the schema reference.

## Verification

- Ensure `.spae/[workstream]/SPEC.md` contains distilled requirements
  and structure matching `references/SPEC.md` exactly.
- Confirm each item carries a unique `R-NNN` identifier.
- Confirm the testing strategy covers expected behavior, failure modes,
  and edge cases; no generic or single-target statements.
- Ensure `.spae/[workstream]/STATE.json` specifies `phase: "plan"` and
  `status: "active"`.
- Confirm `.spae/current` links to `.spae/[workstream]`.
- Verify new invocations without arguments generate a slugged
  `workstream`.
- Confirm revision processes resolve `VERIFY.md` findings without
  editing forbidden files.
- Confirm invalid `STATE.json` or orphaned artifacts halt with
  diagnostics; no artifacts modified.
- Verify all other halt conditions leave artifacts intact.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Prefer lists, and sub-lists, over long paragraphs and sentences.
- Strictly follow the result template below.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [List of key gaps, risks, or notable observations]
- **Summary**:
  - [Terse summary of spec changes]

> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Spec Complete | Revision Complete | Failed]
> **Phase Complete**: `/spec`
> **Next Phase**: `/plan`
> **Impact**: [Terse impact statement]
>
> _Run `/plan` to decompose `SPEC.md` into atomic tasks._
```
<!-- prettier-ignore-end -->
