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
- Revise requirements after a failed `/verify`
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
- Existing `STATE.json`, `SPEC.md`, and `VERIFY.md` in `.spae/current`
  when present.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Workflow

Follow the appropriate sub-workflow depending on the existence of
`.spae/current` symlink:

- **New Workstream** (symlink absent): follow the
  [New spec workflow](#new-spec-workflow).
- **Existing Workstream** (symlink present): follow the
  [Revision spec workflow](#revision-spec-workflow).

### New spec workflow

1. **Initialize Directory**:
   - Create `.spae/[workstream]/`.
   - Point `.spae/current` to `.spae/[workstream]/`.
   - Create `STATE.json` with `phase: spec` and `status: active`.
2. **Gather Context**:
   - Inspect minimal source files to resolve prompt ambiguity.
3. **Formulate Spec**:
   - Derive goal, requirements, testing strategy, out-of-scope
     boundaries, and assumptions.
4. **Finalize**:
   - Write `SPEC.md`, using `references/SPEC.md` as a template.
   - Update `STATE.json` (`phase: plan`, `status: active`).
   - Output the execution summary.

### Revision spec workflow

1. **Validate State**:
   - Confirm `VERIFY.md` exists and `STATE.json` status equals
     `revision_required`.
   - Abort immediately if either condition fails.
2. **Gather Context**:
   - Read the existing `SPEC.md` in full.
   - Read `VERIFY.md` in full.
   - Inspect source files to resolve findings.
3. **Formulate Spec**:
   - Rewrite `SPEC.md` to address all findings and gaps from
     `VERIFY.md`.
4. **Finalize**:
   - Overwrite `SPEC.md` with the revised version, using
     `references/SPEC.md` as a template.
   - Update `STATE.json` (`phase: plan`, `status: active`).
   - Output the execution summary.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- Write observable, testable, and implementation-neutral requirements.
- Document assumptions explicitly instead of guessing scope.
- Match level of detail to task size; avoid process bloat.
- Never stage or commit the `.spae/` directory.

## Constraints

- **Write Scope**: write only `.spae/current` symlink,
  `.spae/[workstream]/SPEC.md`, `.spae/[workstream]/STATE.json`, forbid
  all other writes.
- **Read-only files**: inspect source code only to verify project fit.
- **Phase boundary**: hand off work to `/plan`; don't decompose tasks.
- **Autonomy**: never request input from user.
- **Ambiguity**: resolve ambiguous requirements using conservative
  assumptions; document these in `SPEC.md` under **Assumptions**.

## Verification

- Ensure `.spae/[workstream]/SPEC.md` contains distilled requirements
  and structure matching `references/SPEC.md` exactly.
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

> **SPAE Status** • `[workstream-name]`
> **Result**: [Spec Complete | Revision Complete | Failed]
> **Phase Complete**: `/spec`
> **Next Phase**: `/plan`
> **Impact**: [Terse impact statement]
>
> _Run `/plan` to decompose `SPEC.md` into atomic tasks._
```
<!-- prettier-ignore-end -->
