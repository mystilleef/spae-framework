# Code review guide

## Mission

Defensively review local repository changes for incorrect behavior, data loss,
security vulnerabilities, or crashes. Emit no other findings. Use source
evidence and isolated local checks without developing weaponized exploits,
probing live systems, or bypassing safeguards.

## Scope

**In scope**:

- Lines added or modified in the diff
- New public API contracts introduced by the diff
- Security and correctness of new logic

**Out of scope**:

- Unchanged code visible in context
- Architecture or design concerns
- Missing tests or test coverage
- Style, formatting, naming conventions
- `DRY` / abstraction suggestions

## Severity

Rate likelihood × impact. Every severity this guide assigns sets a default,
never a floor:

- **Critical**: crash in likely path · auth bypass · data loss · secret exposed
- **High**: logic error producing wrong output · resource leak · injection risk
  · failure silently swallowed
- **Medium**: incorrect error handling · API misuse · missing boundary
  validation · unsafe type coercion
- **Low**: suboptimal but non-broken pattern · recoverable edge case unhandled
- **Nit**: emit only if trivially co-located with a higher-severity finding

Cap at **Low** any finding that self-recovers, touches only fallback or degraded
paths, or clears on rerun or restart.

## Categories and checks

### Correctness

- Inverted condition or wrong `boolean` operator → **High**
- Off-by-one in array indexing, loop bounds, or slice range → **High**
- Wrong formula, accumulator, or algorithm → **High**
- Floating-point equality comparison (`==` on floats) → **Medium**
- Integer overflow where result serves as index, size, or count → **High**
- Collection mutated during iteration → **High**

### Null and type safety

- `Dereference` of potentially null/undefined/None value without prior guard →
  **High**
- Type coercion producing wrong result (JS `==`, implicit string→int, etc.) →
  **Medium**
- Result/Option/Either type unwrapped without handling error variant → **High**

### Concurrency

- Shared mutable state accessed across proven concurrent paths without
  synchronization → **High**
- Lock or `mutex` acquired but not released on all exit paths → **High**
- **Read-modify-write** without atomicity under concurrent execution → **High**
- Async: `await` gap between read and dependent write under verified concurrent
  execution → **High**

### Security

- User input reaching SQL query, shell command, or path without _sanitization_ →
  **Critical**
- **Hardcoded** credential, token, or secret → **Critical**
- Auth check absent or open to bypass → **Critical**
- `PII`, tokens, or passwords written to logs, URLs, or error messages →
  **High**
- Unsafe _deserialization_ of _untrusted_ input → **High**
- Missing input validation at trust boundary (HTTP handler, `IPC`, file parser)
  → **Medium**

### Resource management

- File, socket, connection, lock, or allocation acquired without guaranteed
  release → **High**
- Resource acquired in try block but not released in finally/defer/scope-bound
  destructor → **High**
- Unclosed stream passed out of scope without documented ownership transfer →
  **Medium**

### Error handling

- Exception or error caught and silently discarded (empty catch, `_ = err`) →
  **High**
- Error branch returns success value → **High**
- Panic or crash on recoverable error in context → **Medium**
- Error not propagated to caller requiring it → **Medium**

### API misuse

- Deprecated function with documented replacement → **Medium**
- Arguments passed in wrong order → **High**
- Return value encoding success/failure ignored → **Medium**
- Required option or flag omitted → **Medium**

### Data integrity

- Input _unvalidated_ before use as index, size, or database key → **High**
- Serialization contract broken (field renamed, type changed, required field
  dropped) → **High**
- Truncation risk (string to fixed-width column, int cast to smaller type) →
  **Medium**

## Don't flag

Omit items out of scope, plus:

- Missing comments or documentation
- Performance micro-optimizations lacking evidence of hot execution paths
- Defensive bloat, _unrequested_ guardrails, or over-engineered abstractions
  violating `KISS` or `YAGNI`

## Decision rules

- **Resource leak**: trace acquisitions (open, lock, connect, `alloc`) across
  return/panic paths. Flag **High** if any path exits without release.
- **Injection**: trace inputs the `model` leaves _untrusted_ (HTTP
  `params`/headers/body, CLI `args`, file content). Flag **Critical** only when
  input reaches execution boundaries without _sanitization_.
- **Null safety**: verify guards precede _dereference_ of _nullable_ sources
  (optional return, map lookup, `config`, JSON). Flag **High** if unguarded.
- **Concurrency**: trace shared mutable state across runtime execution paths.
  Flag read-then-await-then-write patterns or lock release gaps only when
  runtime model permits concurrent execution.
- **Error handling**: verify catch/except blocks propagate, log, or
  intentionally suppress errors with documented rationale. Flag **High** if
  silently discarded.
- **Intent check**: search commits, PR descriptions, adjacent comments, or user
  intent for change rationales. Move findings with qualifying rationales to
  `suppressed_findings`.
- **Evidence threshold**: establish each test below for every finding, inherited
  entries included, in every category:
  - **Concrete trigger**: named input or state.
  - **Reachable path**: code path from trigger to defect.
  - **Plausible trigger**: a realistic user action, configuration, or
    environment for the project's audience, within the review `model`. Contrived
    inputs—crafted path names, layouts absent from the project, hypothetical
    callers outside new public API—or stacked rare preconditions fail it, as do
    threats outside the `model` (for example, local multi-tenant race attacks on
    single-user CLI tools).
  - **Material impact**: user-observable wrong behavior, data loss, security
    exposure, or crash. Replacements yielding identical output, or ordering
    differences within fallback or degraded paths, fail it.
  - Source evidence and isolated local checks prove mechanism, never
    plausibility: a synthetic reproduction—fixture process, crafted path—leaves
    **Plausible trigger** unmet. Skip exploit construction and live-system
    reproduction.
  - Assess _exploitability_ only for security findings, within the `model`, and
    judge other defects by observable failure and impact.
  - Route failures to `suppressed_findings`, citing the failed test—never emit
    in active `findings`.
- **Fix proportionality**: weigh each `guidance.solution` against `KISS` and
  `YAGNI`. When the minimal fix adds state, timers, protocols, or infrastructure
  for a rare trigger, route the finding to `suppressed_findings`, citing the
  disproportion.

## Calibration

- **Precision over recall**: one high-confidence Critical beats five speculative
  Mediums.
- Limit evaluation to code modified in the diff.
- Note ambiguous intent within findings rather than assuming defect.
- Flag defect directly without editorializing about the author or decision.
- Respect language idioms and standard library patterns—never flag idiomatic
  code.
- Override default severities with language/stack context directives when
  supplied (for example, `Stack: Python 3.12, asyncio`).
