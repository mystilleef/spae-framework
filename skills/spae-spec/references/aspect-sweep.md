# Aspect sweep

## Mission

- Trace every proposal claim to a `SPEC.md` disposition before
  `PERSIST`.
- Guard against buried requirements in dense or long input.
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
