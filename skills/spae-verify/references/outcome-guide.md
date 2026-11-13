# Outcome guide

## Purpose

State _what_ to achieve and _why_; leave _how_ to the consumer.
Acceptance and verification hold every consumer accountable.

## Keep: what-content

- **Outcome**: observable behavior the work produces.
- **Contract**: behavior observable across a boundary—public API or CLI
  signatures, HTTP status and body shapes, file formats, config keys,
  schemas, persisted data, UI output; literal values belong.
- **Constraint**: behavior to preserve, a change boundary, or an
  `AGENTS.md` rule.
- **Decision**: a settled choice citing its source—a proposal decision,
  an `AGENTS.md` rule, or a codebase constraint—with its rationale.
- **Non-derivable fact**: rationale, rejected approaches, hazards found
  while authoring, cross-task contracts, external facts.

## Cut: how-content

- Approach and edit lists.
- Internal mechanism: call paths, helper names, declaration placement.
- Symbol inventories.
- Test design: files, fixtures, case matrices, mocks, test structure.
- Command invocation mechanics: wrappers, timeouts, redirects,
  environment flags, log paths.
- Engineering standards consumers already carry.

## Rules

- **Substitution test**: keep a line only when it holds under every
  approach meeting the outcomes, or cites the decision fixing it;
  restate any other line as the outcome or constraint it protects, else
  cut it.
- **Derivation test**: keep a context fact only when the consumer can't
  recover it from the repository or its own instructions; entry-point
  paths pass as pointers.
- **Examples**: admit a concrete input→output example only to pin a
  behavior prose leaves ambiguous; never a case matrix.
- **Accountability**: state every outcome as observable and falsifiable;
  leaner content demands sharper acceptance.
- **Self-contained units**: write each unit a consumer acts on
  independently to stand alone:
  - A fresh, isolated agent holding only the unit, the repository, and
    its own instructions can act on it and prove it.
  - Its outcomes, constraints, and verification stay jointly
    satisfiable: some reachable sequence of states meets them all at
    once.
  - Repair a failing unit before writing it; failure shapes include two
    outcomes demanding incompatible states, an outcome requiring a state
    a constraint forbids, evidence demanded from a state its run
    constraints forbid, verification producing what it judges, and
    reliance on another unit's unstated content or on state another run
    left behind.
