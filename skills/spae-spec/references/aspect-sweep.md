# Aspect sweep

## Mission

- Trace every proposal claim to a `SPEC.md` disposition before `PERSIST`.
- Guard against buried requirements in dense or long input.
- Audit traced claims for proposal defects before disposition.
- Apply to the `Draft` path only.
- Skip on `Revision` (`Revision` consumes `VERIFY.md` `R-NNN` findings
  directly).

## Categories and disposition

- Scan the full proposal against all nine categories each phase before
  consulting the ledger:

| Category        | Example                         | Disposition             |
| --------------- | ------------------------------- | ----------------------- |
| Functional      | Explicit behavior or request    | `R-NNN`                 |
| Constraint      | Non-functional (load, security) | `R-NNN`                 |
| Boundary        | Explicit exclusion in proposal  | `Out of scope`          |
| Precondition    | Assumption or dependency        | `Assumptions`           |
| Acceptance      | Named completion criterion      | `Goal` or `R-NNN`       |
| Validation      | Verification expectation        | `Testing strategy`      |
| Integration     | External code or `workstream`   | `R-NNN` / `Assumptions` |
| Guidance        | Approach, exemplar, or hint     | `## Guidance`           |
| `Uncategorized` | Ambiguous or unclassified claim | Fit or `Out of scope`   |

- Phase `N` carries heightened focus on category `N` in table order. Scan all
  nine categories each phase.

## Sweep mechanics

- **`PHASE_COUNT`**: `9`, matching the category count.
- **Signature**: `category:section-ref:slug`.
  - `section-ref`: nearest markdown heading path (`##Auth/###Refresh-Flow`) or
    paragraph ordinal (`p12`).
  - `slug`: kebab-case, ≤6 words.
- **Ledger**: append new candidates after each phase, pruning duplicates by
  signature.
- **Completion**: run all `PHASE_COUNT` phases—a phase with zero new candidates
  never ends the sweep.

## Resume seeding

- When the target holds a `SPEC.md`, reverse-map its entries (`R-NNN`,
  `Out of scope`, `Assumptions`, `Testing strategy`, `## Guidance`) into
  pre-seeded ledger signatures before phase one.
- Mark pre-seeded signatures as covered.
- Still scan the full proposal each phase—pre-seeded signatures only remove
  duplicates.

## Ledger audit

- Run once after the final sweep phase, over the completed ledger.
- Judge claims by content, never by heading name, so hand-written proposals
  qualify.
- Check each defect class:
  - **Contradiction**: claims demanding incompatible outcomes—a change against a
    preserved behavior, a design against a decision, an edit outside declared
    scope, a verification outcome an accepted limit waives.
  - **Premise**: a claim of current fact the `outcome-guide.md` premise test
    fails—contradicted or unconfirmed.
  - **Observability**: an outcome partitioning runtime states or reacting to
    host or external events that fails the `outcome-guide.md` observability
    test—lacking a confirmed in-scope discriminator or explicitly specified
    mechanism.
  - **Gap**: work the goal entails that no claim covers—updates to direct
    dependents a change breaks, companions `AGENTS.md` requires, and goal or
    success criteria left unreached. Count only gaps on realistic input, as
    `SKILL.md` **Directives** defines it.
  - **Regression**: a claim altering behavior outside the goal.
  - **`AGENTS.md` violation**: a claim breaking an `AGENTS.md` constraint.
- Record each defect: flag the affected entry with its class, and add each gap
  as a new entry under its category with `section-ref` `audit`.
- Dispose per `SKILL.md` **Proposal fidelity**:
  - Contradiction: the winning claim keeps its disposition, and the other moves
    to `Out of scope` as superseded, with a one-line rationale.
  - Premise: rewrite a contradicted claim's disposition to source reality, or
    file it under `Out of scope` when moot. File an unconfirmed claim under
    `Out of scope` as a residual risk.
  - Observability: narrow the disposition to the closest confirmed observable
    boundary and file the unobservable distinction under `Out of scope` as a
    residual risk.
  - Gap: a new closed `R-NNN`, or `Assumptions` for a precondition. **Proposal
    fidelity** governs a gap whose closure requires a rejected alternative, a
    reopened closed list, an open class, an unobservable distinction, or
    disproportionate `KISS`/`YAGNI` machinery for a rare or fallback-only path.
  - Regression: narrow the claim's disposition to spare the behavior.
  - `AGENTS.md` violation: conform the claim's disposition to `AGENTS.md`.

## Section coverage at VERIFY

- List every `section-ref` the proposal yields: each heading, plus each
  paragraph outside any heading.
- Map each one to a ledger signature or mark it `no claim`. Pre-seeded
  signatures count.
- Treat an unmapped `section-ref` as an unmet `VERIFY` criterion. The ledger
  alone can't reveal a claim it never recorded.

## Disposition at VERIFY

- Resolve every ledger entry (including `Uncategorized`) to a named `SPEC.md`
  disposition before passing `VERIFY`:
  - Draft missing item.
  - File under `Out of scope` with a one-line rationale on `YAGNI` failure.
- Treat orphaned ledger entries as unmet `VERIFY` criteria. Forbid silent drops.
- Route `Validation` entries per `verification-guide.md`:
  - Translate each into the outcome it protects over the same input set.
  - Cheapest evidence the ladder admits → `Testing strategy`.
  - None → `Out of scope` residual risk.
  - Never carry recipes, rigs, coordinates, or case matrices.
- Route mechanism claims per `outcome-guide.md`: carry each as the `R-NNN`
  stating its contract or outcome, and carry its mechanism into `## Guidance`
  under that `R-NNN` only after it passes the `outcome-guide.md` premise test
  (stripping unconfirmed hints). A mechanism a settled decision or `AGENTS.md`
  fixes stays a constraint `R-NNN`.
- Keep settled items—`Rejected` entries included—in their binding disposition,
  never duplicated into `## Guidance`.
