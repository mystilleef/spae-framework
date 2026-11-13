# Aspect sweep

## Mission

- Trace every proposal claim to a `SPEC.md` disposition before
  `PERSIST`.
- Guard against buried requirements in dense or long input.
- Audit traced claims for proposal defects before disposition.
- Apply to the `Draft` path only.
- Skip on `Revision` (`Revision` consumes `VERIFY.md` `R-NNN` findings
  directly).

## Categories and disposition

- Scan the full proposal against all eight categories each phase before
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
| `Uncategorized` | Ambiguous or unclassified claim | Fit or `Out of scope`   |

- Phase `N` carries heightened focus on category `N` in table order.
  Scan all eight categories each phase.

## Sweep mechanics

- **`PHASE_COUNT`**: `8`, matching the category count.
- **Signature**: `category:section-ref:slug`.
  - `section-ref`: nearest markdown heading path
    (`##Auth/###Refresh-Flow`) or paragraph ordinal (`p12`).
  - `slug`: kebab-case, ≤6 words.
- **Ledger**: append new candidates after each phase, pruning duplicates
  by signature.
- **Completion**: run all `PHASE_COUNT` phases; a phase with zero new
  candidates never ends the sweep.

## Resume seeding

- When the target holds a `SPEC.md`, reverse-map its entries (`R-NNN`,
  `Out of scope`, `Assumptions`, `Testing strategy`) into pre-seeded
  ledger signatures before phase one.
- Mark pre-seeded signatures as covered.
- Still scan the full proposal each phase; pre-seeded signatures only
  remove duplicates.

## Ledger audit

- Run once after the final sweep phase, over the completed ledger.
- Judge claims by content, never by heading name; hand-written proposals
  qualify.
- Check each defect class:
  - **Contradiction**: claims demanding incompatible outcomes—a change
    against a preserved behavior, a design against a decision, an edit
    outside declared scope, a verification outcome an accepted limit
    waives.
  - **Premise**: a claim misstating current code—behavior, symbols,
    files, interfaces—against source.
  - **Gap**: work the goal entails that no claim covers—updates to
    direct dependents a change breaks, companions `AGENTS.md` requires,
    goal or success criteria left unreached.
  - **Regression**: a claim altering behavior outside the goal.
  - **`AGENTS.md` violation**: a claim breaking an `AGENTS.md`
    constraint.
- Record each defect: flag the affected entry with its class; add each
  gap as a new entry under its category with `section-ref` `audit`.
- Dispose per `SKILL.md` **Proposal fidelity**:
  - Contradiction: the winning claim keeps its disposition; the other
    moves to `Out of scope` as superseded, with a one-line rationale.
  - Premise: rewrite the disposition to source reality; `Out of scope`
    when moot.
  - Gap: a new `R-NNN`; `Assumptions` for a precondition.
  - Regression: narrow the claim's disposition to spare the behavior.
  - `AGENTS.md` violation: conform the claim's disposition to
    `AGENTS.md`.

## Section coverage at VERIFY

- List every `section-ref` the proposal yields: each heading, plus each
  paragraph outside any heading.
- Map each one to a ledger signature or mark it `no claim`; pre-seeded
  signatures count.
- Treat an unmapped `section-ref` as an unmet `VERIFY` criterion. The
  ledger alone can't reveal a claim it never recorded.

## Disposition at VERIFY

- Resolve every ledger entry (including `Uncategorized`) to a named
  `SPEC.md` disposition before passing `VERIFY`:
  - Draft missing item.
  - File under `Out of scope` with a one-line rationale on `YAGNI`
    failure.
- Treat orphaned ledger entries as unmet `VERIFY` criteria. Forbid
  silent drops.
- Route `Validation` entries per `verification-guide.md`: translate each
  into the outcome it protects; cheapest admissible evidence →
  `Testing strategy`; none → `Out of scope` residual risk. Never carry
  recipes, rigs, coordinates, or case matrices.
- Route mechanism claims per `outcome-guide.md`: carry each as the
  `R-NNN` stating its contract or outcome; a mechanism a settled
  decision or `AGENTS.md` fixes stays a constraint `R-NNN`.
