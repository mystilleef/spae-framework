# Test pruning guide

Smell catalog and protocol for pruning bloated or obsolete tests and
stabilizing flaky ones. Self-contained; no external references.

## Scope

- Edit only test files in scope; survivors may live outside scope.
- Place new helpers and fixtures in an in-scope file.
- Treat unchanged files outside scope as read-only baseline.

## Smell catalog

Format: **Name | Signals | Fix | Pitfall**

| Name                             | Signals                                                                                          | Fix                                                                            | Pitfall                                         |
| -------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ | ----------------------------------------------- |
| Duplicate invariant              | 2+ tests assert one observable; only literals differ                                             | Parameterize; delete exact duplicates                                          | Merging cases with distinct failure modes       |
| Subsumed test                    | A survivor covers its inputs and asserts a superset                                              | Delete                                                                         | Equal coverage with weaker assertions           |
| Obsolete test                    | References a symbol absent from the project                                                      | Delete; update references after a recorded rename                              | Deleting the only test of moved code            |
| Real delay                       | Sleeps, real timers, polling loops                                                               | Fake timers; condition waits                                                   | Stubbing out the behavior under test            |
| Flaky test                       | Unseeded randomness; test-order dependence; shared state, files, or ports; live clock or network | Seed or inject randomness; isolate state and resources; mock clock and network | Masking a production race                       |
| Repeated heavy setup             | Identical costly setup in 3+ tests                                                               | Shared helper or fixture with per-test reset                                   | Breaking isolation                              |
| Implementation-coupled assertion | Asserts call counts, order, or mocks; no observable                                              | Delete when an observable assertion covers it                                  | Deleting the only boundary-interaction contract |
| Trivial-surface test             | Targets getters, setters, passthroughs, generated code                                           | Delete                                                                         | Targets carrying state, branches, or errors     |

## Protocol

### Order

1. Delete or update obsolete tests; verify green.
2. Edit production code, pruning tests its edits render obsolete; verify
   green.
3. Capture baseline: suite runtime, slowest tests, and coverage when a
   tool exists.
4. Edit tests.

### Deletion evidence

- **Obsolete**—absence proof suffices at any tier: no project file
  defines the referenced symbol.
- **Tier A**—coverage tool present:
  - Line and branch coverage match the baseline.
  - A named surviving test asserts the same observable.
- **Tier B**—no coverage tool: delete only exact duplicates (same call,
  inputs, and assertions); otherwise record in `Findings` and keep.

### Never delete

- The sole test of a happy-path, error, boundary, or state-transition
  path.
- A flaky test; remove its nondeterminism instead.
- Across test levels: delete only within one level (unit, integration,
  e2e); flag cross-level redundancy in `Findings` and keep both tests.

### Speed

- Measure the slowest tests before editing.
- Apply catalog fixes; mock only in unit tests.
- Re-measure; revert any fix that fails to cut runtime.
- Never edit runner or tool configuration to gain speed.

### Stability

- Run each stabilized test three times, shuffling order via an existing
  runner flag when available; keep a fix only when every run passes,
  without retries.

### Report

- List each `deleted → survivor` pair, `obsolete → missing symbol` pair,
  and stabilized test under `Findings`.
- State test-count and runtime deltas under `Impact`.
