# Code review guide

## Mission

Flag defects in the reviewed diff causing incorrect behavior, data loss,
security vulnerabilities, or crashes. Emit no other findings.

## Scope

| In scope                                        | Out of scope                                           |
| ----------------------------------------------- | ------------------------------------------------------ |
| Lines added or modified in the diff             | Unchanged code visible in context                      |
| New public API contracts introduced by the diff | Architecture or design concerns                        |
| Security and correctness of new logic           | Missing tests or test coverage                         |
|                                                 | Style, formatting, naming conventions                  |
|                                                 | `DRY` / abstraction suggestions                        |
|                                                 | Hypothetical callers or inputs (unless new public API) |

## Severity

| Level        | Criteria                                                                                         |
| ------------ | ------------------------------------------------------------------------------------------------ |
| **Critical** | Crash in likely path · auth bypass · data loss · secret exposed                                  |
| **High**     | Logic error producing wrong output · resource leak · injection risk · failure silently swallowed |
| **Medium**   | Incorrect error handling · API misuse · missing boundary validation · unsafe type coercion       |
| **Low**      | Suboptimal but non-broken pattern · recoverable edge case unhandled                              |
| **Nit**      | Emit only if trivially co-located with a higher-severity finding                                 |

## Categories and checks

### Correctness

- Inverted condition or wrong `boolean` operator → **High**
- Off-by-one in array indexing, loop bounds, or slice range → **High**
- Wrong formula, accumulator, or algorithm → **High**
- Floating-point equality comparison (`==` on floats) → **Medium**
- Integer overflow where result serves as index, size, or count →
  **High**
- Collection mutated during iteration → **High**

### Null and type safety

- `Dereference` of potentially null/undefined/None value without prior
  guard → **High**
- Type coercion producing wrong result (JS `==`, implicit string→int,
  etc.) → **Medium**
- Result/Option/Either type unwrapped without handling error variant →
  **High**

### Concurrency

- Shared mutable state accessed across proven concurrent paths without
  synchronization → **High**
- Lock or `mutex` acquired but not released on all exit paths → **High**
- **Read-modify-write** without atomicity under concurrent execution →
  **High**
- Async: `await` gap between read and dependent write under verified
  concurrent execution → **High**

### Security

- User input reaching SQL query, shell command, or path without
  _sanitization_ → **Critical**
- **Hardcoded** credential, token, or secret → **Critical**
- Auth check absent or open to bypass → **Critical**
- `PII`, tokens, or passwords written to logs, URLs, or error messages →
  **High**
- Unsafe _deserialization_ of _untrusted_ input → **High**
- Missing input validation at trust boundary (HTTP handler, `IPC`, file
  parser) → **Medium**

### Resource management

- File, socket, connection, lock, or allocation acquired without
  guaranteed release → **High**
- Resource acquired in try block but not released in finally/defer/RAII
  destructor → **High**
- Unclosed stream passed out of scope without documented ownership
  transfer → **Medium**

### Error handling

- Exception or error caught and silently discarded (empty catch,
  `_ = err`) → **High**
- Error branch returns success value → **High**
- Panic or crash on recoverable error in context → **Medium**
- Error not propagated to caller requiring it → **Medium**

### API misuse

- Deprecated function with documented replacement → **Medium**
- Arguments passed in wrong order → **High**
- Return value encoding success/failure ignored → **Medium**
- Required option or flag omitted → **Medium**

### Data integrity

- Input _unvalidated_ before use as index, size, or database key →
  **High**
- Serialization contract broken (field renamed, type changed, required
  field dropped) → **High**
- Truncation risk (string to fixed-width column, int cast to smaller
  type) → **Medium**

## Don't flag

Omit items out of scope, plus:

- Missing comments or documentation
- Hypothetical inputs (unless diff introduces new public API with
  realistic callers)
- Performance micro-optimizations lacking evidence of hot execution
  paths
- Theoretical vulnerabilities, race conditions, or edge cases outside
  app threat model (for example, local multi-tenant race attacks on
  single-user CLI tools)
- Defensive bloat, _unrequested_ guardrails, or over-engineered
  abstractions violating `KISS` or `YAGNI`

## Decision rules

- **Resource leak**: Trace acquisitions (open, lock, connect, `alloc`)
  across return/panic paths. Flag **High** if any path exits without
  release.
- **Injection**: Trace _untrusted_ inputs (HTTP `params`/headers/body,
  CLI `args`, file content). Flag **Critical** only when input reaches
  execution boundaries without _sanitization_.
- **Null safety**: Verify guards precede _dereference_ of _nullable_
  sources (optional return, map lookup, `config`, JSON). Flag **High**
  if unguarded.
- **Concurrency**: Trace shared mutable state across runtime execution
  paths. Flag read-then-await-then-write patterns or lock release gaps
  only when runtime model permits concurrent execution.
- **Error handling**: Verify catch/except blocks propagate, log, or
  intentionally suppress errors with documented rationale. Flag **High**
  if silently discarded.
- **Intent check**: Search commits, PR descriptions, adjacent comments,
  or user intent for change rationales. Move findings with qualifying
  rationales to `suppressed_findings`. Route theoretical security,
  concurrency, or null safety findings lacking practical exploit paths
  to `suppressed_findings` citing missing trigger scenario—never emit in
  active `findings`.

## Calibration

- **Precision over recall**: One high-confidence Critical beats five
  speculative Mediums.
- Limit evaluation to code modified in the diff.
- Note ambiguous intent within findings rather than assuming defect.
- Flag defect directly without editorializing.
- Respect language idioms and standard library patterns—never flag
  idiomatic code.
- Override default severities with language/stack context directives
  when supplied (for example, `Stack: Python 3.12, asyncio`).
