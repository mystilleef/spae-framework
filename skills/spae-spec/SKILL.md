---
name: spae-spec
description:
  Smart Entry & Requirements for the `SPAE` framework. Distills a proposal,
  task, or `VERIFY.md` findings into testable requirements in `SPEC.md`.
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

- Distill user requests, verification findings, and codebase context into
  concise, testable requirements, correcting proven proposal defects, while
  preserving `SPAE` phase boundaries.
- Generate `.spae/[workstream]/SPEC.md` and advance `STATE.json` to
  `phase: plan`.

## Input

Resolve target `workstream` by first matching rule:

- **Explicit**: `workstream` name argument → `.spae/[name]/`.
- **Implicit active**: no name, no proposal → `.spae/current` target.
- **Implicit new**: no name, proposal → the `.spae/current` target when the link
  exists and its target lacks `STATE.json` or reads `phase: spec`,
  `status: active`, else—`.spae/current` missing included—a new kebab-case slug
  unused under `.spae/`.

Sources:

- `Draft`: proposal or task argument.
- `Revision`: `.spae/[workstream]/VERIFY.md`.
- Both:
  - `AGENTS.md` at project root, plus the codebase.
  - Project-root testing guides (`TESTING*.md`) covering the files under test,
    when present, for test commands and prerequisites: `TESTING.md` covers the
    main language, `TESTING-<LANG>.md` the named one (`TESTING-LUA.md` for
    `*.lua`).
- `.spae/[workstream]/STATE.json` when present, with field reference,
  directives, and snapshots in `references/STATE.md`.

## Workflow

Select path by target state:

- **`Draft`**: target directory absent, lacks `STATE.json`, or `STATE.json`
  reads `phase: spec`, `status: active`.
- **`Revision`**: `STATE.json` reads `status: revision_required`.

1. **GATE**—Make no writes:
   - Parse `STATE.json` when present and self-heal missing metadata: `version`
     (`"1.0"`), `workstream` (target directory name), `status` (`"active"`).
     `PERSIST` writes the healed fields.
   - Select `Draft` or `Revision`.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal and path in one sentence:
   - Source code and `SPAE` artifacts stay unmodified until `PERSIST`.
   - Read `AGENTS.md` at project root in full when present.
   - `Revision`: read `VERIFY.md` in full.
3. **PLAN**—Identify codebase sections to read:
   - `Draft`: sections the proposal touches, plus direct dependents—callers,
     importers, configs, tests, and docs—of each interface or behavior it
     changes.
   - `Revision`: source files each `VERIFY.md` finding names.
   - Both:
     - Host or runtime API surfaces backing any runtime-state partition or
       event-reactive behavior, to confirm observable discriminators.
     - The tooling evidence—declared dependencies, configs, scripts, installed
       binaries—behind each candidate `Testing strategy` rung.
4. **ACT**—Draft `SPEC.md` content:
   - Read codebase sections narrowly, widening only on uncertainty.
   - `Draft`:
     - Per `references/aspect-sweep.md`, seed the aspect ledger from an existing
       `SPEC.md` when present, sweep the proposal, then audit the ledger.
       Resolve each defect per **Proposal fidelity**.
     - Derive goal, requirements, testing strategy, out-of-scope boundaries,
       assumptions, and guidance from the ledger.
   - `Revision`:
     - Convert each hard block into a spec item, carrying its `Guidance` into
       `## Guidance` under that item.
     - Assess soft findings against `YAGNI`, discarding those adding
       `unrequested` scope or theoretical complexity.
     - Treat observations as context, not spec items:
       - Re-classify an observation naming a clear `SPEC.md` deviation as a hard
         block, then convert it.
       - Convert an observation to a spec item only when it names actionable
         scope reduction—simplify or remove an existing element—never to
         formalize or expand `unrequested` scope.
       - Otherwise, drop after noting context.
     - Inspect source files to ground new requirements.
     - Write from scratch with fresh `R-NNN` identifiers, never reusing the
       prior `SPEC.md`.
   - Apply **Directives** and **Constraints**, following `references/SPEC.md`
     structure.
5. **VERIFY**—Loop over **Verification** criteria for `SPEC.md`:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - Create `.spae/[workstream]/` when absent.
   - Write `SPEC.md`, replacing any prior version.
   - Write `STATE.json` per `references/STATE.md` exit snapshot.
   - Point `.spae/current` symlink to `.spae/[workstream]`.
   - Re-read `STATE.json` and `.spae/current`. On a mismatch against
     **Verification** state criteria, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit result following result directives and using result template.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Align with existing codebase patterns and avoid speculative design.
- Filter all requirements and incoming findings against `YAGNI`, discarding
  `unrequested` scope, speculative design, or theoretical complexity. An
  audit-proven gap never counts as `unrequested` scope when it rests on
  realistic input—input or state the proposal, task, or `VERIFY.md` names, or
  ordinary use produces, never a theoretical risk, contrived harness, or
  adversarial host bypass. File `YAGNI`-discarded ledger aspects under
  `Out of scope` with a one-line rationale, never a silent drop.
  - Filter verification breadth too: carry a proposal's verification request as
    the outcomes it protects over the same input set—never its recipe, rig, or
    case matrix, and never a wider class.
- Write observable, testable, closed, and implementation-neutral requirements,
  tagging each with a unique, stable `R-NNN` identifier:
  - Apply the `references/outcome-guide.md` closure and observability tests:
    resolve unmapped proposal enums, unbounded trigger quantifiers, and
    unconfirmed host discriminators from codebase, host API, and settled
    decision evidence during `/spec`—never deferring them to `/plan`. Narrow
    unobservable distinctions to the confirmed observable boundary, and file
    unnamed, unmapped, or ambiguous cases, host bypasses, and cut distinctions
    under `Out of scope` as residual risks.
  - Carry a proposal's design claim as the contract or outcome it delivers—a
    restatement, not a correction—and route its mechanism to `## Guidance`. A
    mechanism binds only through a settled decision or `AGENTS.md`.
- Write `## Guidance` keyed by `R-NNN`, per `references/outcome-guide.md`
  `## Guidance`.
- Match level of detail to task size, avoiding process bloat:
  - Require failure modes and edge cases only when the proposal, task, or
    `VERIFY.md` names them, or a branch, error path, or boundary the specified
    change introduces requires them on realistic input.
  - Set `Assumptions` to `None` on single-behavior specs unless explicit
    constraints exist.
  - Never invent exclusions or assumptions absent evidence—an audit-proven gap
    on realistic input supplies evidence. Keep section headers intact.
- Consult `references/verification-guide.md` and decide the cheapest evidence
  proving each spec item:
  - Translate manual checks and proposal verification recipes into the outcomes
    they protect.
  - Route each proposal item marked unverified, untested, or open to the
    cheapest evidence proving it, never widening it into broader verification.
  - An explicit request admits new tooling only for outcomes no existing rung
    reaches and never overrides proportionality or the calibration rule.
  - Record outcomes lacking calibration-free evidence the guide admits as
    `Out of scope` residual risks.
- Consult `references/prose-protocol.md` and `references/outcome-guide.md`
  before drafting `SPEC.md`.
- Refine and optimize `SPEC.md` for agent consumption: agents read it for varied
  purposes, with no memory of this run. Keep it self-contained, explicit, and
  token-dense.
- Run the aspect sweep and ledger audit on `Draft` only, per
  `references/aspect-sweep.md`. `Revision` consumes `VERIFY.md` findings
  directly. Reference `PHASE_COUNT` by name only.
- Surface aspect-sweep phases run and ledger-audit counts by defect class in the
  result `Actions` list (for example,
  `aspect sweep: 9/9 phases, 12/12 sections mapped` and
  `ledger audit: 1 contradiction, 1 premise, 2 gaps`). List each correction
  under `Findings`: claim, defect, disposition.
- **IMPORTANT:** Return the result to the caller.

## Constraints

- **`AGENTS.md` authority**: when `AGENTS.md` exists at project root, its
  constraints, conventions, and gates bind all spec requirements, and
  contradictions count as spec defects.
- **Write scope**: write only `.spae/current` symlink, `.spae/[workstream]/`
  directory, `SPEC.md`, and `STATE.json`. Forbid all other writes. Write
  incidental run outputs—logs, reports, experiment files—to scratch: a private
  temporary directory outside the project, removed when the run ends. Scratch
  writes and byproducts of a command run for evidence, such as formatter
  rewrites, never count as this phase's writes. Never run a command for its
  write effect outside this scope. Inspect source code only to ground
  requirements and confirm fit.
- **Phase boundary**: hand off work to `/plan` without decomposing tasks.
- **Version control and release**: never author requirements for version control
  (git staging, commits, branches, tags) or release operations (package
  publishing, deployments). Place them under `Out of scope` with the template's
  standard rationale. Never stage or commit `.spae/` or execute git mutations.
- **Autonomy**: never ask users for input or clarification mid-execution—halts
  and failures stop autonomously. Never author a spec item, testing strategy, or
  assumption presuming human execution, an attended or interactive terminal, or
  human presence. Treat such a need as a scope defect and resolve before
  `PERSIST`.
- **Ambiguity**: resolve an ambiguous demand from codebase evidence first. Fall
  back to a documented conservative assumption only when evidence proves
  insufficient, and record it under **Assumptions** in `SPEC.md`. A claim of
  current fact or a host/runtime discriminator never takes this fallback: the
  `references/outcome-guide.md` premise and observability tests settle it.
- **Proposal fidelity** (`Draft`): the qualified goal—the proposal goal as its
  settled items narrow it—binds, and every other claim serves it.
  - Settled items: decisions, rejected alternatives, accepted limits, and
    explicit exclusions, under any heading. Each binds unless source code, host
    APIs, or `AGENTS.md` falsifies its premise or observability, or proves it
    leaves the goal unreachable.
  - Correct a claim only on a defect the ledger audit proves. Leave merely
    suboptimal design as written, never redesigning it.
  - Resolve by precedence, highest first: `AGENTS.md`, source code, the
    qualified goal, other claims, own judgment. Between peers, the claim serving
    the qualified goal wins. Otherwise, apply the **Ambiguity** fallback.
  - Apply the smallest correction and cite its evidence.
  - Resolve a gap whose only closure revives a rejected alternative, reopens a
    closed list, demands an open class, or fails the observability test as an
    `Out of scope` residual risk, or as the narrowest closed, observable
    requirement meeting the qualified goal, citing the settled item it
    preserves.
  - Keep a settled enumeration—accepted limits, listed differences, fixed
    texts—closed: extend it only by naming each new member with its evidence,
    never by reference to another requirement.
  - On a premise-void proposal—source falsifies the goal's premise, or the
    codebase already meets the goal—specify the goal outcome against source
    reality, file falsified claims under `Out of scope`, and lead `Findings`
    with the void premise.
  - Never halt on a proposal defect.
- **Contradictions**: audit `SPEC.md` as one self-contained unit per
  `references/outcome-guide.md`.
  - Conflicts:
    - Mutually exclusive requirements, or requirements an `Out of scope` item
      forbids.
    - Requirements contradicting `AGENTS.md`, `Assumptions`, or
      `Testing strategy`.
    - An exception one requirement carves into another without naming the exact
      fields, values, or slots it covers.
    - Evidence demanded from a repository state whose runs breach
      `Testing strategy` or `references/verification-guide.md`.
  - Self-heal by precedence:
    - `AGENTS.md` overrides requirements.
    - Requirements override `Out of scope`, except version control, release,
      human-presence, and settled-item exclusions.
    - Requirements override assumptions and testing strategy.
    - An unbounded exception names its exact fields, values, or slots, else
      drops.
    - `references/verification-guide.md` settles a state-bound evidence
      conflict. Record an outcome it leaves unprovable as an `Out of scope`
      residual risk.
    - Otherwise apply the **Ambiguity** fallback, never halting on a
      contradiction.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt without writing and report `Failed` with a
  diagnostic under `Findings`:
  - `.spae/current` missing or dangling under **Implicit active** resolution.
  - `STATE.json` holds unparseable JSON syntax.
  - Target state matches neither path.
  - `Draft` without a proposal or task.
  - `Revision` without `VERIFY.md`.

## Verification

- Ensure `.spae/[workstream]/SPEC.md` contains distilled requirements and
  structure matching `references/SPEC.md` exactly.
- Confirm each item carries a unique `R-NNN` identifier.
- Confirm all requirements pass the `references/outcome-guide.md` substitution,
  closure, and observability tests, and every binding line passes its premise
  test.
- Confirm `## Guidance` follows the `references/outcome-guide.md` `## Guidance`
  rules and keys only defined `R-NNN` IDs.
- Confirm no **Contradictions** finding survives in `SPEC.md`.
- Confirm zero requirements mandate git operations, package publishing, or
  release deployments.
- Confirm no spec item, testing strategy, or assumption in `SPEC.md` presumes
  human execution, an attended or interactive terminal, or human presence.
- Confirm `Testing strategy`:
  - Covers expected behavior.
  - Names failure modes and edge cases only where **Directives** admit them.
  - Allows single-target verification on single-behavior specs.
  - Pairs each `R-NNN` with its cheapest proving evidence per
    `references/verification-guide.md`. No rig, recipe, coordinate, calibration
    step, inadmissible tooling, scripted assertion over prose wording, re-proof
    of logic cheaper evidence covers, or evidence producing what it judges or
    relying on another run's report or on state that run left outside the
    project survives.
- Confirm section depth matches task size, with no exclusion or assumption
  invented absent evidence.
- Confirm every `Draft` aspect-ledger entry resolves to an `R-NNN`,
  `Out of scope`, `Assumption`, `Testing strategy` element, `Guidance` entry, or
  `Goal` success criterion—no orphaned aspect.
- Confirm every proposal `section-ref` maps to a ledger signature or carries
  `no claim`, per `references/aspect-sweep.md`.
- Confirm every `Draft` ledger-audit defect resolves per
  `references/aspect-sweep.md` **Ledger audit** dispositions, each correction
  citing its evidence, with no settled item yielding without the source, host
  API, or `AGENTS.md` evidence **Proposal fidelity** demands, no requirement
  reviving a rejected alternative, reopening a closed list, or demanding an
  unobservable host distinction, and no gap resting on unrealistic input.
- Confirm `Revision` runs no aspect sweep or ledger audit and maps converted
  `VERIFY.md` items directly to spec items.
- Ensure `.spae/[workstream]/STATE.json` specifies `phase: "plan"`,
  `status: "active"`, `cursor: {}`, and `tasks: {}`.
- Confirm `.spae/current` links to `.spae/[workstream]`.
- Verify invocations without a `workstream` name, with a proposal, resolve per
  **Input** rules.
- Confirm revision processes resolve every `VERIFY.md` hard block and soft
  finding, and each converted observation, without editing forbidden files.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`, so a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, early stop, or halt—with the result
  template as the final message, never on progress narration.
- Set `Result` to exactly one template literal, verbatim. Report an early stop
  or halt lacking its own literal as `Failed`, with the reason under `Findings`.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.
- Source every `SPAE Status` value from confirmed re-read, never from working
  memory of intent.

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
