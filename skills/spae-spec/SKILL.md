---
name: spae-spec
description:
  Smart Entry & Requirements for the `SPAE` framework. Distills a
  proposal, task, or `VERIFY.md` findings into testable requirements in
  `SPEC.md`.
user-invocable: true
argument-hint: "[optional-workstream-name] [optional-task]"
---

# Spec (`SPAE`)

## When to use

- Initialize a new `SPAE workstream`.
- Finish an interrupted draft (`phase: spec`, `status: active`).
- Rewrite requirements from scratch when `/verify` routes back
  (`status: revision_required`).

## Goal

- Distill user requests, verification findings, and codebase context
  into concise, testable requirements while preserving `SPAE` phase
  boundaries.
- Generate `.spae/[workstream]/SPEC.md` and advance `STATE.json` to
  `phase: plan`.

## Input

Resolve target `workstream` by first matching rule:

- **Explicit**: workstream name argument → `.spae/[name]/`.
- **Implicit active**: no name, no proposal → `.spae/current` target.
- **Implicit new**: no name, proposal → `.spae/current` target when it
  lacks `STATE.json` or reads `phase: spec`, `status: active`; otherwise
  a new kebab-case slug unused under `.spae/`.

Sources:

- `Draft`: proposal or task argument.
- `Revision`: `.spae/[workstream]/VERIFY.md`.
- Both: `AGENTS.md` at project root; codebase.
- `.spae/[workstream]/STATE.json` when present; `references/STATE.md`
  holds field reference, directives, and snapshots.

## Workflow

Select path by target state:

- **`Draft`**: target directory absent, lacks `STATE.json`, or
  `STATE.json` reads `phase: spec`, `status: active`.
- **`Revision`**: `STATE.json` reads `status: revision_required`.

1. **GATE**—Make no writes:
   - Parse `STATE.json` when present; self-heal missing metadata:
     `version` (`"1.0"`), `workstream` (target directory name), `status`
     (`"active"`); `PERSIST` writes the healed fields.
   - Select `Draft` or `Revision`.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal and path in one sentence:
   - Source code and `SPAE` artifacts stay unmodified until `PERSIST`.
   - Read `AGENTS.md` at project root in full when present.
   - `Revision`: read `VERIFY.md` in full.
3. **PLAN**—Identify codebase sections to read:
   - `Draft`: sections the proposal touches.
   - `Revision`: source files each `VERIFY.md` finding names.
4. **ACT**—Draft `SPEC.md` content:
   - Read codebase sections narrowly; widen only on uncertainty.
   - `Draft`:
     - Seed the aspect ledger from an existing `SPEC.md`, when present,
       then sweep the proposal per `references/aspect-sweep.md`.
     - Derive goal, requirements, testing strategy, out-of-scope
       boundaries, and assumptions from the ledger.
   - `Revision`:
     - Convert each hard block into a spec item.
     - Assess soft findings against `YAGNI`; discard soft findings
       adding `unrequested` scope or theoretical complexity.
     - Treat observations as context, not spec items:
       - Re-classify an observation naming a clear `SPEC.md` deviation
         as a hard block, then convert it.
       - Convert an observation to a spec item only when it names
         actionable scope reduction—simplify or remove an existing
         element—never to formalize or expand `unrequested` scope.
       - Otherwise, drop after noting context.
     - Inspect source files to ground new requirements.
     - Write from scratch; never reuse the prior `SPEC.md`; assign fresh
       `R-NNN` identifiers.
   - Apply **Directives** and **Constraints**; follow
     `references/SPEC.md` structure.
5. **VERIFY**—Loop over **Verification** criteria for `SPEC.md`:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - Create `.spae/[workstream]/` when absent.
   - Write `SPEC.md`, replacing any prior version.
   - Write `STATE.json` per `references/STATE.md` exit snapshot.
   - Point `.spae/current` symlink to `.spae/[workstream]`.
   - Re-read `STATE.json` and `.spae/current`; on a mismatch against
     **Verification** state criteria, rewrite and re-read before
     `REPORT`.
7. **REPORT**—Emit result following result directives and using result
   template.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- Filter all requirements and incoming findings against `YAGNI`; discard
  `unrequested` scope, speculative design, or theoretical complexity.
  File YAGNI-discarded ledger aspects under `Out of scope` with a
  one-line rationale, never a silent drop.
  - Filter verification breadth too: carry a proposal's verification
    request as the outcomes it protects, never its recipe, rig, or case
    matrix.
- Write observable, testable, and implementation-neutral requirements;
  tag each with a unique, stable `R-NNN` identifier.
- Match level of detail to task size; avoid process bloat:
  - Require failure modes and edge cases only when the proposal
    introduces complex branching or error paths.
  - Set `Assumptions` to `None` on single-behavior specs unless explicit
    constraints exist.
  - Never invent exclusions, assumptions, edge cases, or failure modes;
    keep section headers intact.
- Consult `references/verification-guide.md`; decide the cheapest
  evidence proving each requirement:
  - Translate manual checks and proposal verification recipes into the
    outcomes they protect.
  - Route each proposal item marked unverified, untested, or open to the
    cheapest evidence proving it; never widen it into broader
    verification.
  - An explicit request admits new tooling only for outcomes no existing
    rung reaches; it never overrides proportionality or the calibration
    rule.
  - Record outcomes lacking admissible, calibration-free evidence as
    `Out of scope` residual risks.
- Consult `references/prose-protocol.md` before drafting `SPEC.md`.
- Refine and optimize `SPEC.md` for agent consumption: agents read it
  for varied purposes, with no memory of this run; keep it
  self-contained, explicit, and token-dense.
- Run the aspect sweep on `Draft` only, per
  `references/aspect-sweep.md`; `Revision` consumes `VERIFY.md` findings
  directly. Reference `PHASE_COUNT` by name only.
- Surface aspect-sweep phases run in the result `Actions` list (for
  example, `aspect sweep: 8/8 phases, 12/12 sections mapped`).

## Constraints

- **`AGENTS.md` authority**: If `AGENTS.md` exists at project root, its
  constraints, conventions, and gates bind all spec requirements;
  contradictions count as spec defects.
- **Write scope**: write only `.spae/current` symlink,
  `.spae/[workstream]/` directory, `SPEC.md`, and `STATE.json`; forbid
  all other writes. Inspect source code to ground requirements and
  confirm fit; stay read-only.
- **Phase boundary**: hand off work to `/plan`; don't decompose tasks.
- **Version control and release**: never author requirements for version
  control (git staging, commits, branches, tags) or release operations
  (package publishing, deployments); place them under `Out of scope`
  with the template's standard rationale. Never stage or commit `.spae/`
  or execute git mutations.
- **Autonomy**: never ask users for input or clarification
  mid-execution; halts and failures stop autonomously. Never author a
  spec item, testing strategy, or assumption presuming human execution,
  an attended or interactive terminal, or human presence; treat such a
  need as a scope defect and resolve before `PERSIST`.
- **Ambiguity**: resolve from codebase evidence first; fall back to a
  documented conservative assumption only when evidence proves
  insufficient; record under **Assumptions** in `SPEC.md`.
- **Contradictions**: audit `SPEC.md` for internal conflict—mutually
  exclusive requirements, a requirement an `Out of scope` item forbids,
  a requirement contradicting `AGENTS.md`, `Assumptions`, or
  `Testing strategy`, or an assumption contradicting source code.
  Self-heal by precedence:
  - `AGENTS.md` overrides requirements.
  - Requirements override `Out of scope`, except version control,
    release, and human-presence exclusions.
  - Requirements override assumptions and testing strategy.
  - Source code overrides assumptions.
  - Otherwise apply the **Ambiguity** fallback; never halt on a
    contradiction.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt without writing; report `Failed` with a
  diagnostic under `Findings`:
  - `.spae/current` missing or dangling when resolution needs it.
  - `STATE.json` holds unparseable JSON syntax.
  - Target state matches neither path.
  - `Draft` without a proposal or task.
  - `Revision` without `VERIFY.md`.

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
- Confirm `Testing strategy` pairs each requirement with its cheapest
  proving evidence; no rig, recipe, coordinate, calibration step,
  inadmissible tooling, or re-proof of logic cheaper evidence covers
  survives.
- Confirm section depth matches task size; no invented edge case,
  failure mode, or exclusion on a single-behavior spec.
- Confirm every `Draft` aspect-ledger entry resolves to an `R-NNN`,
  `Out of scope`, `Assumption`, `Testing strategy` element, or `Goal`
  success criterion—no orphaned aspect.
- Confirm every proposal `section-ref` maps to a ledger signature or
  carries `no claim`, per `references/aspect-sweep.md`.
- Confirm `Revision` runs no aspect sweep; converted `VERIFY.md` items
  map directly to spec items.
- Ensure `.spae/[workstream]/STATE.json` specifies `phase: "plan"`,
  `status: "active"`, `cursor: {}`, and `tasks: {}`.
- Confirm `.spae/current` links to `.spae/[workstream]`.
- Verify invocations without a workstream name, with a proposal, resolve
  per **Input** rules.
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
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`; a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, abort, or halt—with the
  result template as the final message; never end on progress narration.
- Set `Result` to exactly one template literal, verbatim; report an
  abort or halt lacking its own literal as `Failed`, with the reason
  under `Findings`.
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
> **Next Phase**: `/plan`  _(unless failed)_
> **Impact**: [Terse impact statement]
>
> _Run `/plan` to decompose `SPEC.md` into atomic tasks._  _(unless failed)_
```
<!-- prettier-ignore-end -->
