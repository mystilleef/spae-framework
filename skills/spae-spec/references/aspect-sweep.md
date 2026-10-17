# Aspect sweep

## Mission

- Trace every proposal claim to a `SPEC.md` disposition before
  `PERSIST`.
- Guard against buried requirements in dense or long input.
- Apply to `New` and `Resume` workflows only.
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

- Rotate heightened-focus category per phase
  (`((phase - 1) mod 8) + 1`). Scan all eight categories each phase.

## Sweep mechanics

- **`PHASE_CAP`**: `4` (saturation typically occurs within two phases.
  Cap guards against pathological input).
- **Signature**: `category:section-ref:slug`.
  - `section-ref`: nearest markdown heading path
    (`##Auth/###Refresh-Flow`) or paragraph ordinal (`p12`).
  - `slug`: kebab-case, ≤6 words.
- **Ledger**: append new candidates after each phase, pruning duplicates
  by signature.
- **Halt**: first zero-new-candidate phase or `PHASE_CAP` (4), whichever
  arrives first.

## Resume seeding

- Reverse-map draft `SPEC.md` entries (`R-NNN`, `Out of scope`,
  `Assumptions`, `Testing strategy`) into pre-seeded ledger signatures
  before phase one.
- Mark pre-seeded signatures as covered.
- Sweep uncovered aspects only.

## Disposition at VERIFY

- Resolve every ledger entry (including `Uncategorized`) to a named
  `SPEC.md` disposition before passing `VERIFY`:
  - Draft missing item.
  - File under `Out of scope` with a one-line rationale on `YAGNI`
    failure.
- Treat orphaned ledger entries as unmet `VERIFY` criteria. Forbid
  silent drops.
