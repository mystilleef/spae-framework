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
- Existing `STATE.json` (consult `references/STATE.md` for field
  reference, directives, and phase snapshots) and `VERIFY.md` in
  `.spae/current` when present.

## Workflow

Select sub-workflow by `.spae/current` symlink state:

- **New** (symlink absent): `New spec workflow`
- **Revision** (symlink present): `Revision spec workflow`

### New spec workflow

If absent symlink follow this workflow.

1. **GATE**—`.spae/current` absent. Halt if symlink exists (revision
   path).
2. **ORIENT**—Produce `SPEC.md` and `STATE.json` for `[workstream]`.
   Codebase unmodified.
3. **PLAN**—Derive `[workstream]` slug from `args` or auto-generate.
   Identify codebase sections to read.
4. **ACT**—Execute:
   - Initialize `.spae/[workstream]/`; point `.spae/current` symlink;
     create `STATE.json` (`phase: spec`, `status: active`).
   - If `AGENTS.md` exists at the project root, read it in full
     **before** any codebase sections; treat its constraints,
     conventions, and gates as non-negotiable spec inputs.
   - Read codebase sections narrowly; widen only on uncertainty.
   - Consult `references/prose-protocol.md` before drafting.
   - Derive goal, requirements, testing strategy, out-of-scope
     boundaries, and assumptions; reflect all `AGENTS.md` constraints.
   - Assess derived requirements against `YAGNI`; discard `unrequested`
     scope, speculative features, or theoretical complexity.
5. **VERIFY**—Loop over spec completeness criteria:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when spec complete and structure matches
     `references/SPEC.md`.
   - Fail only for out-of-scope conditions.
6. **PERSIST**—Write `SPEC.md`. Update `STATE.json` (`phase: plan`,
   `status: active`, `cursor: {}`, `tasks: {}`). Re-read `STATE.json`
   after writing; on a field mismatch, rewrite and re-read before
   `REPORT`.
7. **REPORT**—Emit result using the Result template.

### Revision spec workflow

If present symlink follow this workflow.

1. **GATE**—`.spae/current` present. `VERIFY.md` exists. `STATE.json`
   `status: revision_required`. Halt immediately on any failure.
2. **ORIENT**—Delete `SPEC.md` and rewrite it from scratch to address
   every `VERIFY.md` hard block. Source code unmodified.
3. **PLAN**—Survey `VERIFY.md` findings; identify source files to
   inspect and requirements to derive.
4. **ACT**—Execute:
   - Delete `SPEC.md`. Don't reuse.
   - Read `VERIFY.md` in full. Convert each hard block into a spec item.
     Assess soft findings against `YAGNI`; discard soft findings adding
     `unrequested` scope or theoretical complexity.
   - Treat observations as context, not spec items:
     - Re-classify an observation naming a clear `SPEC.md` deviation as
       a hard block, then convert it.
     - Convert an observation to a spec item only when it names
       actionable scope reduction—simplify or remove an existing
       element—never to formalize or expand `unrequested` scope.
     - Otherwise, drop it after noting the context.
   - If `AGENTS.md` exists at the project root, read it in full
     **before** inspecting source files; treat its constraints as
     binding; reflect them in the revised requirements.
   - Inspect source files to ground new requirements.
   - Consult `references/prose-protocol.md` before drafting.
   - Write new `SPEC.md` from scratch; never reuse old spec; assign
     fresh `R-NNN` identifiers; address every item converted from
     `VERIFY.md` hard blocks.
5. **VERIFY**—Loop over every `VERIFY.md` hard block, plus each accepted
   item converted under `ACT`:
   - For each unaddressed item: return to `ACT`, address it, then
     re-enter `VERIFY`.
   - Exit only when every item resolves and the spec matches
     `references/SPEC.md`.
   - Fail only for out-of-scope conditions.
6. **PERSIST**—Write `SPEC.md`. Update `STATE.json` (`phase: plan`,
   `status: active`, `cursor: {}`, `tasks: {}`). Re-read `STATE.json`
   after writing; on a field mismatch, rewrite and re-read before
   `REPORT`.
7. **REPORT**—Emit the result following the result directives and using
   the result template.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- Filter all requirements and incoming findings against `YAGNI`; reject
  `unrequested` scope, speculative design, or theoretical complexity.
- Write observable, testable, and implementation-neutral requirements.
- Match testing strategy detail to task size; require failure modes and
  edge cases only when proposal introduces complex branching or error
  paths.
- Treat `manual` testing strategy as agent-executed, unattended
  inspection only; never encode a spec item, approach, or assumption
  that presumes human execution, an attended or interactive terminal, or
  human presence.
- Tag each item with a unique, stable `R-NNN` identifier.
- Document assumptions explicitly instead of guessing scope.
- Match level of detail to task size; avoid process bloat.
- Consult `references/prose-protocol.md` before drafting `SPEC.md`.
- Set `Out of scope` and `Assumptions` to `None` on single-behavior
  specs unless explicit constraints exist; avoid invented exclusions or
  assumptions; keep section headers intact.
- Never stage or commit the `.spae/` directory.

## Constraints

- **`AGENTS.md` authority**: If `AGENTS.md` exists at the project root,
  its constraints, conventions, and gates bind all spec requirements;
  contradictions count as spec defects.
- **Write Scope**: write only `.spae/current` symlink,
  `.spae/[workstream]/SPEC.md`, `.spae/[workstream]/STATE.json`, forbid
  all other writes.
- **Read-only files**: inspect source code to ground requirements and
  confirm fit; stay read-only.
- **Phase boundary**: hand off work to `/plan`; don't decompose tasks.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and failures stop autonomously.
- **Full autonomy**: Never author a spec item, testing strategy, or
  assumption that presumes human execution, an attended or interactive
  terminal, or human presence; treat such a need as a scope defect and
  resolve it before writing `SPEC.md`.
- **Ambiguity**: resolve from codebase evidence first; fall back to a
  documented conservative assumption only when evidence proves
  insufficient; record under **Assumptions** in `SPEC.md`.
- Never introduce fields to `STATE.json` outside the schema reference.

## Verification

- Ensure `.spae/[workstream]/SPEC.md` contains distilled requirements
  and structure matching `references/SPEC.md` exactly.
- Confirm each item carries a unique `R-NNN` identifier.
- Confirm no spec item, testing strategy, or assumption in `SPEC.md`
  presumes human execution, an attended or interactive terminal, or
  human presence.
- Confirm testing strategy covers expected behavior; require failure
  modes and edge cases only for complex proposals; allow single-target
  verification on single-behavior specs.
- Confirm section depth matches task size; no invented edge case,
  failure mode, or exclusion on a single-behavior spec.
- Ensure `.spae/[workstream]/STATE.json` specifies `phase: "plan"`,
  `status: "active"`, `cursor: {}`, and `tasks: {}`.
- Confirm `.spae/current` links to `.spae/[workstream]`.
- Verify new invocations without arguments generate a slugged
  `workstream`.
- Confirm revision processes resolve every `VERIFY.md` hard block and
  soft finding, and each converted observation, without editing
  forbidden files.
- Confirm invalid `STATE.json` or orphaned artifacts halt with
  diagnostics; no artifacts modified.
- Verify all other halt conditions leave artifacts intact.

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
> **Result**: [Spec Complete | Revision Complete | Failed]
> **Phase Complete**: `/spec`
> **Next Phase**: `/plan`
> **Impact**: [Terse impact statement]
>
> _Run `/plan` to decompose `SPEC.md` into atomic tasks._
```
<!-- prettier-ignore-end -->
