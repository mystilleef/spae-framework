# Outcome guide

## Purpose

State _what_ to achieve and _why_ as binding content, and offer _how_ as
advisory `Guidance`. Acceptance and verification hold every consumer
accountable, while `Guidance` binds no one.

## Keep what-content

- **Outcome**: observable behavior the work produces.
- **Contract**: behavior observable across a boundary—public API or CLI
  signatures, HTTP status and body shapes, file formats, config keys, schemas,
  persisted data, UI output. Literal values and closed member lists belong.
- **Constraint**: behavior to preserve, a change boundary, or an `AGENTS.md`
  rule.
- **Decision**: a settled choice citing its source—a proposal decision, an
  `AGENTS.md` rule, or a codebase constraint—with its rationale.
- **Non-derivable fact**: rationale, rejected approaches, hazards found while
  authoring, cross-task contracts, external facts.

## Route how-content

- Move to `Guidance`:
  - Approaches and edit lists.
  - Internal mechanism: call paths, helper names, declaration placement.
  - Symbol inventories.
  - Test design: files, fixture construction, case layout, mocks, test
    structure.
- Cut:
  - Command invocation mechanics: wrappers, timeouts, redirects, environment
    flags, log paths.
  - Engineering standards consumers already carry.

## Guidance

An optional, advisory field beside a unit's binding content, holding any of
these kinds:

- **Pattern**: an existing exemplar to mirror—`path:line` and symbol.
- **Solution**: a recommended solution sketch naming key sites and steps. Admit
  a snippet of a few lines only to pin a subtle API or idiom—never a diff or
  full patch.
- **Avoid**: a tempting wrong approach no settled decision rejects, with its
  defect.
- **Tests**: a test file to extend, fixtures to reuse, notable cases.

Write it by these rules:

- **Advisory**: consumers weigh it on its merits, never following it blindly,
  then accept, partially accept, or ignore it for a better solution meeting the
  same outcomes. No judgment grades adherence.
- **Grounded**: trace every hint to source read while authoring, naming no
  unverified symbol.
- **Subordinate**: binding content and the repository win on conflict. State no
  outcome, constraint, or decision—binding content holds every one.
- **Self-contained**: rely on another unit only through its binding outcomes,
  never its `Guidance`.
- **Proportional**: omit `Guidance` from a unit needing none.

## Rules

- **Substitution test**: keep a binding line only when it holds under every
  approach meeting the outcomes, or cites the decision fixing it. Restate any
  other line as the outcome or constraint it protects and move its method to
  `Guidance`, else cut it.
- **Closure test**: keep a binding line only when closed—every class it
  quantifies over names its members, an input set, or a cited decision bounding
  it—so a consumer decides it met with finite evidence.
  - An open qualifier admits unnamed members: `routine`, `such as`, an
    unterminated `including`, `any form`, `applicable`, `safe`, `where known`.
  - Restate an open line as its named members, and file the unnamed members as a
    residual risk among the unit's exclusions.
  - A closed member list counts as contract content—named values, encodings,
    cases—never a case matrix, and test wiring around it stays `Guidance`.
- **Derivation test**: keep a binding context fact only when the consumer can't
  recover it from the repository or its own instructions. Entry-point paths pass
  as pointers. `Guidance` may point at derivable facts.
- **Examples**: admit a concrete input→output example only to pin a behavior
  prose leaves ambiguous—never a case matrix.
- **Accountability**: state every outcome as observable, falsifiable, and
  closed, since leaner content demands sharper acceptance.
- **Self-contained units**: write each unit a consumer acts on independently to
  stand alone:
  - A fresh, isolated agent holding only the unit, the repository, and its own
    instructions can act on it and prove it, with its `Guidance` ignored.
  - Its outcomes, constraints, and verification stay jointly satisfiable: some
    reachable sequence of states meets them all at once.
  - Repair a failing unit before writing it. Failure shapes:
    - Two outcomes demanding incompatible states.
    - An outcome requiring a state a constraint forbids.
    - Evidence demanded from a state its run constraints forbid.
    - An exception one line carves into another without naming the exact fields,
      values, or slots it covers.
    - Verification producing what it judges.
    - Reliance on another unit's unstated content, another run's report, or
      state that run left outside the project.
