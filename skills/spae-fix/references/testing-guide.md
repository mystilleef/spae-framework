# Testing guide

## Scope

Prefer unit tests. Escalate to integration only when behavior crosses a
system boundary. Reserve end-to-end tests for critical user flows.

## Structure

- Group related cases logically.
- Name each test as `verb + subject + condition + outcome`.
- Keep test bodies lean by extracting repeated setup into helper
  functions.
- Extend existing test suites when covering established units. Create
  standalone test files only for new modules or distinct boundaries.
- Prefer parameterized tests over copy-pasted test bodies for
  table-driven input variations on identical invariants.
- Never commit focused (`only`) or unconditionally skipped (`skip`,
  `xit`, `xtest`) tests. Every conditional skip guard names its missing
  prerequisite in the skip reason.

## Isolation

- Each test must pass independently of execution order.
- Restore all mutations to global/shared state after each test.
- Reset all shared registries and stores before each test.
- Seed or inject every random source so no outcome hinges on unseeded
  randomness.
- Never share files, ports, or sockets across tests. Give each test its
  own temp directory and an OS-assigned port (`0`).

## CI parity

- Never `hardcode` absolute paths. Use `path.join(__dirname, …)` or a
  framework path helper.
- Never reference undeclared environment variables. Declare all required
  vars with defaults or a skip guard.
- Never assume a running service, database, or external process. Mock or
  skip-guard instead.
- Never assume a writable working directory. Use `os.tmpdir()` or a
  framework temp helper.
- Never assume the runner's privilege level: root and `CAP_DAC_OVERRIDE`
  bypass read/write mode bits in containers and cloud sessions.
  - Simulate `EACCES`/`EPERM` only in unit tests, by mocking or
    injecting the filesystem failure, never via `chmod`.
  - Never assert mode-bit access denial in integration or e2e tests.
  - Assert permission-setting behavior through `stat` mode values, never
    through denied access.
- Never access live networks. Mock all HTTP clients and `DNS` resolution
  in unit tests.
- Never assume a specific timezone or locale. Freeze or mock time and
  locale in tests.
- Use cross-platform commands and path separators, never OS-specific
  ones.
- Never assume filesystem case sensitivity. Normalize paths and
  filenames explicitly.

## Asynchronous

- Always await `async` operations—never fire-and-forget inside a test.
- Replace polling loops with condition-based wait helpers.
- Use cancellation primitives, never real timeouts, to test cancellation
  paths.

## Mocking

- Mock all event sources—never trigger live events in tests.
- In unit tests: mock all external processes, I/O, and side-effecting
  dependencies.
- In integration and e2e tests: use real dependencies, with no mocks
  mixed in.
- Prefer fakes over spies, and spies over stubs.
- Restore all mocks after each test.

## Assertions

- Assert observable behavior, not internal implementation.
- Assert unordered collections (sets, map keys, concurrent results)
  without depending on iteration order.
- Remove redundant assertions and never duplicate existing test
  coverage.
- Cover the happy path and every distinct failure and cancellation path.
- Raise an error for missing required values so no test silently passes
  on bad state.

## Hygiene

- Never leave `console.*`, `print`, `fmt.Println`, or similar
  debug-output calls in committed test bodies. Assert instead of print.
- Never leave `debugger` statements or active breakpoints in committed
  tests.
- When a test intentionally exercises stdout/stderr output (for example,
  asserting on a CLI's printed output), capture the stream and assert on
  the captured value instead of letting it pass through to the real
  stdout.
- Mock or suppress expected error/warning logs from the code under test.
  A clean test run must produce no incidental log output.

## Performance

- Use fake/controlled timers, never real delays, for time-dependent
  logic.
- Keep each test focused on one behavior, avoiding multi-concern tests.

## Dependencies

- Verify all imports resolve before running a test.
- Confirm required test dependencies exist in the project before writing
  tests.

## Verification

- Run each new or changed test file three times, shuffling order via an
  existing runner flag when available. Every run must pass, without
  retries, before declaring the task done.
- Run the full test suite and confirm zero new failures.
- Verify the test runner executes the added or updated tests.
- Scan every new or changed test file for stray console/print/debugger
  calls and remove them before declaring the task done.
