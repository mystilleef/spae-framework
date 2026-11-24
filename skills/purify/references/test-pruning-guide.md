# Test pruning guide

Smell catalog and protocol for pruning bloated or obsolete tests and
stabilizing flaky ones. Self-contained, with no external references.

## Scope

- Edit only test files in scope, though survivors may live outside
  scope.
- Place new helpers and fixtures in an in-scope file.
- Treat unchanged files outside scope as read-only baseline.

## Smell catalog

Each smell lists its signals, fix, and pitfall.

- **Duplicate invariant**:
  - **Signals**: 2+ tests assert one observable, differing only in
    literals.
  - **Fix**: parameterize, deleting exact duplicates.
  - **Pitfall**: merging cases with distinct failure modes.
- **Subsumed test**:
  - **Signals**: a survivor covers its inputs and asserts a superset.
  - **Fix**: delete.
  - **Pitfall**: equal coverage with weaker assertions.
- **Obsolete test**:
  - **Signals**: references a symbol absent from the project.
  - **Fix**: delete, or update references after a recorded rename.
  - **Pitfall**: deleting the only test of moved code.
- **Real delay**:
  - **Signals**: sleeps, real timers, or polling loops.
  - **Fix**: fake timers or condition waits.
  - **Pitfall**: stubbing out the behavior under test.
- **Flaky test**:
  - **Signals**:
    - Unseeded randomness.
    - Test-order dependence.
    - Shared state, files, or ports.
    - Live clock or network.
  - **Fix**: seed or inject randomness, isolate state and resources, and
    mock clock and network.
  - **Pitfall**: masking a production race.
- **Repeated heavy setup**:
  - **Signals**: identical costly setup in 3+ tests.
  - **Fix**: shared helper or fixture with per-test reset.
  - **Pitfall**: breaking isolation.
- **Implementation-coupled assertion**:
  - **Signals**: asserts call counts, order, or mocks but no observable.
  - **Fix**: delete when an observable assertion covers it.
  - **Pitfall**: deleting the only boundary-interaction contract.
- **Trivial-surface test**:
  - **Signals**: targets getters, setters, pass-through functions, or
    generated code.
  - **Fix**: delete.
  - **Pitfall**: targets carrying state, branches, or errors.

## Protocol

### Order

1. Delete or update obsolete tests, then verify green.
2. Edit production code, pruning tests its edits render obsolete, then
   verify green.
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
  inputs, and assertions). Record others in `Findings` and keep them.

### Never delete

- The sole test of a happy-path, error, boundary, or state-transition
  path.
- A flaky test—remove its nondeterminism instead.
- Across test levels: delete only within one level (unit, integration,
  e2e), flagging cross-level redundancy in `Findings` and keeping both
  tests.

### Speed

- Measure the slowest tests before editing.
- Apply catalog fixes, mocking only in unit tests.
- Re-measure, reverting any fix that fails to cut runtime.
- Never edit runner or tool configuration to gain speed.

### Stability

- Run each stabilized test three times, shuffling order via an existing
  runner flag when available. Keep a fix only when every run passes,
  without retries.

### Report

- List each `deleted → survivor` pair, `obsolete → missing symbol` pair,
  and stabilized test under `Findings`.
- State test-count and runtime deltas under `Impact`.
