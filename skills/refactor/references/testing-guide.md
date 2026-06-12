# Testing Guide

## Scope

Prefer unit tests. Escalate to integration only when behavior crosses a
system boundary. Reserve end-to-end tests for critical user flows.

## Structure

- Group related cases logically.
- Name each test as `verb + subject + condition + outcome`.
- Keep test bodies lean; extract repeated setup into helper functions.
- Never commit focused (`only`) or skipped (`skip`, `xit`, `xtest`) tests.

## Isolation

- Each test must pass independently of execution order.
- Restore all mutations to global/shared state after each test.
- Reset all shared registries and stores before each test.

## Async

- Always await async operations; never fire-and-forget inside a test.
- Replace polling loops with condition-based wait helpers.
- Use cancellation primitives to test abort/cancellation paths; never rely
  on real timeouts.

## Mocking

- Mock all event sources; never trigger live events in tests.
- In unit tests: mock all external processes, I/O, and side-effecting
  dependencies.
- In integration and e2e tests: use real dependencies; never mix mocks
  into them.
- Prefer fakes over spies; prefer spies over stubs.
- Restore all mocks after each test.

## Assertions

- Assert observable behavior, not internal implementation.
- Cover the happy path and every distinct failure and cancellation path.
- Fail loudly on missing required values; never let tests silently pass on
  bad state.

## Performance

- Use fake/controlled timers for time-dependent logic; never introduce
  real delays.
- Keep each test focused on one behavior; avoid multi-concern tests.

## Dependencies

- Verify all imports resolve before running a test.
- Confirm required test dependencies exist in the project before writing tests.

## Verification

- Run the test file and confirm it passes before declaring the task done.
- Run the full test suite and confirm zero new failures.
- Verify the test runner lists the new file by name in its output.

## CI Parity

- Never hardcode absolute paths.
- Never reference undeclared environment variables.
- Never assume a running service, database, or external process.
