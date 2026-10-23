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

Determine target `workstream` and scope by first available source:

- Explicit argument: target directory `.spae/[workstream]/`.
- Implicit active: resolve target directory via `.spae/current` symlink.
- Implicit new: auto-generate slug, target directory `.spae/[slug]/`.

## Workflow

Select sub-workflow by target `workstream` state:

- **New**: Target directory missing → `New spec workflow`.
- **Resume**: Target directory exists with `STATE.json` (`phase: spec`,
  `status: active`) → `Resume spec workflow`.
- **Revision**: Target directory exists with `STATE.json`
  (`status: revision_required`) and `VERIFY.md` present →
  `Revision spec workflow`.

### New spec workflow

Follow this workflow when target `workstream` directory missing.

1. **GATE**—Confirm target `workstream` directory absent. Halt if target
   directory exists.
2. **ORIENT**—Initialize `.spae/[workstream]/` directory; create
   `STATE.json` (`phase: spec`, `status: active`, `cursor: {}`,
   `tasks: {}`). Read `AGENTS.md` at project root in full when present;
   treat constraints, conventions, and gates as non-negotiable spec
   inputs. Source code unmodified.
3. **PLAN**—Identify codebase sections to read.
4. **ACT**—Execute:
   - Read codebase sections narrowly; widen only on uncertainty.
   - Consult `references/prose-protocol.md` before drafting.
   - Sweep the proposal for aspect coverage per
     `references/aspect-sweep.md`: scan all categories each phase,
     dedupe new candidates against the ledger, halt on the first
     zero-new-candidate phase or `PHASE_CAP` (4).
   - Derive goal, requirements, testing strategy, out-of-scope
     boundaries, and assumptions from the ledger; reflect all
     `AGENTS.md` constraints.
   - Assess derived requirements against `YAGNI`; discard `unrequested`
     scope, speculative features, or theoretical complexity;
     YAGNI-discarded ledger aspects land in `Out of scope` with a
     one-line rationale, never a silent drop.
   - Automatically place all version control operations (git staging,
     commits, branches, tags) and release operations (publishing,
     deployments) into `Out of scope`.
   - Forbid creating any `R-NNN` requirement covering git mutations,
     package publishing, or release workflows.
5. **VERIFY**—Loop over spec completeness criteria:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when spec complete, structure matches
     `references/SPEC.md`, every aspect-ledger entry resolves to a named
     `SPEC.md` disposition—no orphaned aspect—and no **Contradictions**
     finding survives.
   - Halt only for out-of-scope conditions.
6. **PERSIST**—Write `SPEC.md`. Point `.spae/current` symlink to
   `.spae/[workstream]`. Update `STATE.json` (`phase: plan`,
   `status: active`, `cursor: {}`, `tasks: {}`). Re-read `STATE.json`
   after writing; on a field mismatch, rewrite and re-read before
   `REPORT`.
7. **REPORT**—Emit result using Result template.

### Resume spec workflow

Follow this workflow when target `workstream` directory exists with
`phase: spec`, `status: active`.

1. **GATE**—Target directory exists; `STATE.json` contains
   `phase: spec`. Self-heal metadata: inject missing `version`
   (`"1.0"`), `workstream` (from symlink or directory path), and
   `status` (`"active"`). Halt on unparseable JSON or phase mismatch.
2. **ORIENT**—Read `AGENTS.md` at project root in full when present;
   treat constraints as binding. Source code unmodified.
3. **PLAN**—Survey existing draft artifacts and prompt context. Identify
   codebase sections to inspect.
4. **ACT**—Execute:
   - Inspect codebase sections narrowly to complete missing details.
   - Consult `references/prose-protocol.md` before drafting.
   - Seed the aspect ledger from the current `SPEC.md` draft's existing
     `R-NNN`, `Out of scope`, `Assumptions`, and `Testing strategy`
     entries (mark covered), then sweep remaining proposal or task
     context per `references/aspect-sweep.md`: scan all categories each
     phase, dedupe against the ledger, halt on the first
     zero-new-candidate phase or `PHASE_CAP` (4).
   - Complete `SPEC.md` draft following `references/SPEC.md` structure.
   - Assess requirements against `YAGNI`; discard `unrequested` scope or
     speculative features; YAGNI-discarded ledger aspects land in
     `Out of scope` with a one-line rationale, never a silent drop.
   - Automatically place all version control operations (git staging,
     commits, branches, tags) and release operations (publishing,
     deployments) into `Out of scope`.
   - Forbid creating any `R-NNN` requirement covering git mutations,
     package publishing, or release workflows.
5. **VERIFY**—Loop over spec completeness criteria:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when spec complete, structure matches
     `references/SPEC.md`, every aspect-ledger entry resolves to a named
     `SPEC.md` disposition—no orphaned aspect—and no **Contradictions**
     finding survives.
   - Halt only for out-of-scope conditions.
6. **PERSIST**—Write `SPEC.md`. Point `.spae/current` symlink to
   `.spae/[workstream]`. Update `STATE.json` (`phase: plan`,
   `status: active`, `cursor: {}`, `tasks: {}`). Re-read `STATE.json`
   after writing; on a field mismatch, rewrite and re-read before
   `REPORT`.
7. **REPORT**—Emit result using Result template.

### Revision spec workflow

Follow this workflow when target `workstream` directory exists with
`status: revision_required`.

1. **GATE**—Target directory exists. Self-heal metadata: inject missing
   `version` (`"1.0"`) and `workstream` (from symlink or directory
   path). Halt with a diagnostic on:
   - Target directory missing or orphaned symlink.
   - `STATE.json` missing or unparseable JSON syntax.
   - `VERIFY.md` absent.
   - `STATE.json` `status` ≠ `revision_required`.
2. **ORIENT**—Delete `SPEC.md`. Set `STATE.json` (`phase: spec`,
   `status: active`). Read `AGENTS.md` at project root in full when
   present before inspecting source files; treat constraints as binding;
   reflect in revised requirements. Source code unmodified.
3. **PLAN**—Survey `VERIFY.md` findings; identify source files to
   inspect and requirements to derive.
4. **ACT**—Execute:
   - Read `VERIFY.md` in full. Convert each hard block into a spec item.
     Assess soft findings against `YAGNI`; discard soft findings adding
     `unrequested` scope or theoretical complexity.
   - Treat observations as context, not spec items:
     - Re-classify an observation naming a clear `SPEC.md` deviation as
       a hard block, then convert it.
     - Convert an observation to a spec item only when it names
       actionable scope reduction—simplify or remove an existing
       element—never to formalize or expand `unrequested` scope.
     - Otherwise, drop after noting context.
   - Inspect source files to ground new requirements.
   - Consult `references/prose-protocol.md` before drafting.
   - Write new `SPEC.md` from scratch; never reuse old spec; assign
     fresh `R-NNN` identifiers; address every item converted from
     `VERIFY.md` hard blocks.
5. **VERIFY**—Loop over every `VERIFY.md` hard block, each accepted item
   converted under `ACT`, and each **Contradictions** finding:
   - For each unaddressed item: return to `ACT`, address it, then
     re-enter `VERIFY`.
   - Exit only when every item resolves and spec matches
     `references/SPEC.md`.
   - Halt only for out-of-scope conditions.
6. **PERSIST**—Write `SPEC.md`. Point `.spae/current` symlink to
   `.spae/[workstream]`. Update `STATE.json` (`phase: plan`,
   `status: active`, `cursor: {}`, `tasks: {}`). Re-read `STATE.json`
   after writing; on a field mismatch, rewrite and re-read before
   `REPORT`.
7. **REPORT**—Emit result following result directives and using result
   template.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- Filter all requirements and incoming findings against `YAGNI`; discard
  `unrequested` scope, speculative design, or theoretical complexity.
- Write observable, testable, and implementation-neutral requirements.
- Match testing strategy detail to task size; require failure modes and
  edge cases only when proposal introduces complex branching or error
  paths.
- Treat `manual` testing strategy as agent-executed, unattended
  inspection only; never encode a spec item, approach, or assumption
  presuming human execution, an attended or interactive terminal, or
  human presence.
- Tag each item with a unique, stable `R-NNN` identifier.
- Document assumptions explicitly instead of guessing scope.
- Match level of detail to task size; avoid process bloat.
- Consult `references/prose-protocol.md` before drafting `SPEC.md`.
- Consult `references/aspect-sweep.md` before running the `New` or
  `Resume` aspect sweep; default to `PHASE_CAP` (4) as a single named
  constant—never scatter phase-count literals across the workflow.
- Surface aspect-sweep phases run in the result `Actions` list (for
  example, `aspect sweep: 2/4 phases, stopped on saturation`).
- Aspect sweep applies to `New` and `Resume` workflows only; `Revision`
  consumes `VERIFY.md`'s pre-itemized `R-NNN` findings directly—no
  sweep.
- Set `Out of scope` and `Assumptions` to `None` on single-behavior
  specs unless explicit constraints exist; avoid invented exclusions or
  assumptions; keep section headers intact.
- Automatically place all version control operations (git staging,
  commits, branches, tags) and release operations (publishing,
  deployments) into `Out of scope` with a standard rationale; never
  create an `R-NNN` requirement for them.
- Never stage or commit `.spae/` directory or execute git mutations.

## Constraints

- **`AGENTS.md` authority**: If `AGENTS.md` exists at project root,
  constraints, conventions, and gates bind all spec requirements;
  contradictions count as spec defects.
- **Write Scope**: write only `.spae/current` symlink,
  `.spae/[workstream]/SPEC.md`, `.spae/[workstream]/STATE.json`; forbid
  all other writes.
- **Scope boundary**: Never author requirements for git operations,
  package publishing, or release workflows.
- **Read-only files**: inspect source code to ground requirements and
  confirm fit; stay read-only.
- **Phase boundary**: hand off work to `/plan`; don't decompose tasks.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and failures stop autonomously.
- **Full autonomy**: Never author a spec item, testing strategy, or
  assumption presuming human execution, an attended or interactive
  terminal, or human presence; treat such a need as a scope defect and
  resolve before writing `SPEC.md`.
- **Ambiguity**: resolve from codebase evidence first; fall back to a
  documented conservative assumption only when evidence proves
  insufficient; record under **Assumptions** in `SPEC.md`.
- **Contradictions**: audit `SPEC.md` for internal conflict—mutually
  exclusive requirements, a requirement an `Out of scope` item forbids,
  a requirement contradicting `AGENTS.md`, `Assumptions`, or
  `Testing strategy`, or an assumption contradicting source code.
  Self-heal by precedence: `AGENTS.md` overrides requirements;
  requirements override assumptions and testing strategy; source code
  overrides assumptions. Otherwise apply the **Ambiguity** fallback;
  never halt on a contradiction.
- Never introduce fields to `STATE.json` outside schema reference.

## Verification

- Ensure `.spae/[workstream]/SPEC.md` contains distilled requirements
  and structure matching `references/SPEC.md` exactly.
- Confirm each item carries a unique `R-NNN` identifier.
- Confirm no **Contradictions** finding survives in `SPEC.md`.
- Confirm zero requirements mandate git operations, package publishing,
  or release deployments.
- Confirm no spec item, testing strategy, or assumption in `SPEC.md`
  presumes human execution, an attended or interactive terminal, or
  human presence.
- Confirm testing strategy covers expected behavior; require failure
  modes and edge cases only for complex proposals; allow single-target
  verification on single-behavior specs.
- Confirm section depth matches task size; no invented edge case,
  failure mode, or exclusion on a single-behavior spec.
- Confirm every `New`/`Resume` aspect-ledger entry resolves to an
  `R-NNN`, `Out of scope`, `Assumption`, `Testing strategy` element, or
  `Goal` success criterion—no orphaned aspect.
- Confirm `Revision` runs no aspect sweep; converted `VERIFY.md` items
  map directly to spec items.
- Ensure `.spae/[workstream]/STATE.json` specifies `phase: "plan"`,
  `status: "active"`, `cursor: {}`, and `tasks: {}`.
- Confirm `.spae/current` links to `.spae/[workstream]`.
- Verify new invocations without arguments generate a slugged
  `workstream`.
- Confirm revision processes resolve every `VERIFY.md` hard block and
  soft finding, and each converted observation, without editing
  forbidden files.
- Confirm unparseable `STATE.json` or orphaned artifacts halt with
  diagnostics; no artifacts modified.
- Verify all other halt conditions leave artifacts intact.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
- Emit result template as live markdown—never in a code fence.
- Output nothing outside template.
- Source every `SPAE Status` value from confirmed re-read, never from
  working memory of intent.

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
