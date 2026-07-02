# Code review guide

## Mission

Flag defects in the reviewed diff that cause incorrect behavior, data
loss, security vulnerabilities, or crashes. Emit no other findings.

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
- Integer overflow where the result serves as index, size, or count →
  **High**
- Collection mutated during iteration → **High**

### Null and type safety

- `Dereference` of a potentially null/undefined/None value without a
  prior guard → **High**
- Type coercion producing wrong result (JS `==`, implicit string→int,
  etc.) → **Medium**
- Result/Option/Either type unwrapped without handling the error variant
  → **High**

### Concurrency

- Shared mutable state accessed without synchronization → **High**
- Lock or `mutex` acquired but not released on all exit paths → **High**
- **Read-modify-write** without atomicity → **High**
- Async: `await` gap between read and dependent write on shared state →
  **High**

### Security

- User input reaching SQL query, shell command, or file path without
  _sanitization_ → **Critical**
- **Hardcoded** credential, token, or secret → **Critical**
- Auth or _auth_ check absent or open to bypass → **Critical**
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
- Unclosed stream passed out of scope with no documented ownership
  transfer → **Medium**

### Error handling

- Exception or error caught and silently discarded (empty catch,
  `_ = err`) → **High**
- Error branch returns a success value → **High**
- Panic or crash on a recoverable error in context → **Medium**
- Error not propagated to a caller that requires it → **Medium**

### API misuse

- Deprecated function with a documented replacement → **Medium**
- Arguments passed in wrong order → **High**
- Return value encoding success/failure ignored → **Medium**
- Required option or flag omitted → **Medium**

### Data integrity

- Input not validated before use as index, size, or database key →
  **High**
- Serialization contract broken (field renamed, type changed, required
  field dropped) → **High**
- Truncation risk (string to fixed-width column, int cast to smaller
  type) → **Medium**

## Don't flag

Beyond the out-of-scope items in the Scope table, also omit:

- Missing comments or documentation
- Hypothetical inputs—unless the diff introduces a new public-facing API
  and the input appears realistic given visible callers
- Performance micro-optimizations without evidence the path runs hot

## Decision rules

**Resource leak**: for each acquisition (open, lock, connect,
**alloc**), trace all return and throw/panic paths. Flag **High** if any
path exits without release.

**Injection**: trace user-controlled inputs (HTTP
**params**/headers/body, CLI **args**, file content). Flag **Critical**
if any reach a query, command, or path without **sanitization** at or
before the call site.

**Null safety**: if a value comes from a **nullable** source (optional
return, map lookup, **config** read, JSON field), verify a guard
precedes the _dereference_. Flag **High** if not.

**Concurrency**: if the diff introduces shared mutable state, verify all
access paths hold the same lock before read or write. For _async_/await,
flag read-then-await-then-write patterns on shared state as races—the
`await` acts as a preemption point even in single-threaded _async_
_runtimes_. Example: reading `self.count`, awaiting an I/O call, then
writing `self.count + 1` creates a race condition.

**Error handling**: for each catch/rescue/except block, verify the
caller propagates, logs, or intentionally suppresses the error.
Intentional suppression requires a visible comment or documented
contract. Flag **High** if silently discarded.

## Output format

Emit a summary block followed by per-finding entries, grouped by file.

**Summary block** (always emit):

    ## Review Summary
    **Verdict**: `Approve` | `Request Changes` | `Comment`
    **Finding counts**: Critical: N · High: N · Medium: N · Low: N
    **Overview**: One or two sentences on the nature of the diff and any dominant risk theme.

Verdict rules:

- Any Critical or High → `Request Changes`.
- Medium or Low only → `Comment`.
- No findings → `Approve`.

**Per-finding entries**:

    ### <Severity>: <Short title>
    **Location**: `path/to/file:line`
    **Category**: <Category>
    **Issue**: One sentence — what is wrong and what is the consequence.
    **Fix** (optional): One-line description or minimal code snippet.

If no findings meet the threshold: emit the summary block with `Approve`
verdict and `No findings.` as the overview.

## Calibration

- **Precision over recall.** One high-confidence Critical beats five
  speculative Mediums.
- Don't speculate about code not in the diff.
- When intent appears ambiguous, note it in the Issue field rather than
  assuming defect.
- Flag the defect; don't editorialize about the author or the decision.
- Language-specific idioms and standard library behavior should inform
  findings—don't flag idiomatic use as incorrect.
- When a language/stack context block arrives (for example,
  `Stack: Python 3.12, asyncio`), apply its language-specific severity
  adjustments and idioms—it takes precedence.
