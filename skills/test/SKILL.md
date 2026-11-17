---
name: test
description: >-
  Write comprehensive and exhaustive tests that address gaps in code
  coverage.
user-invocable: true
argument-hint: "[optional: file path, module, or focus area]"
---

# Test

## When to use

- Files or current changes have gaps in test coverage.

## Goal

- Cover every behavioral gap in scope, highest-risk targets first.
- Add only tests the pre-existing suite lacks, extending existing tests
  before creating new ones.
- Leave production code, build, and tool configuration unchanged.

## Input

Determine scope from the first available source:

- Files or folders provided by the user.
- Current changes in the repository.

Halt if no scope exists.

_Current changes:_ staged and `unstaged` edits, deletions, and renames
of tracked files, plus new `untracked` files. Requires a versioned
project.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards. The project's
`TESTING.md`, when present, extends the guide and overrides it on
conflict.

## Shell commands

See `references/shell-command-guide.md` for command safety, timeouts,
redirects, and non-interactive environment directives.

## Cleanup

See `references/cleanup-guide.md` for the Self-cleanup checklist and
diff-only audit scope.

## Behavioral surface

Target only methods and functions with business logic, state
transitions, or error handling. Exclude:

- Trivial `getters`/`setters`, `POJOs`, generated code, and framework
  boilerplate.
- Functions whose every path delegates, reads a field, or returns a
  constant, with no state change, resource interaction, or
  error-propagation decision.

Audit targets across four canonical categories:

- **Happy path**: expected inputs yield expected outputs.
- **Error / failure**: malformed inputs, thrown exceptions, error
  returns, cancellation.
- **Boundary / edge**: null, empty, zero, min, max, overflow,
  off-by-one.
- **State transitions**: valid and invalid mutations, side effects.

Rank each target by the count of risk signals it holds:

- **Impact**: handles authentication, authorization, money, persistence,
  untrusted input, or concurrency.
- **Exposure**: reachable through a public API or entry point.
- **Fan-in**: called from another module in the project.
- **Change**: touched by current changes.

Rank sets work order alone—highest first, ties in source order—and never
alters a verdict, category coverage, or `Result`.

## Mutation probe

A mutation probe temporarily edits production code, altering only the
branch, condition, or boundary one net-new gap names. Capture the
production file's content before the edit and rewrite it afterward,
never restoring via git `checkout`, `restore`, or `stash`, which erase
uncommitted work.

Settle each net-new gap by probing it:

- No edit to its path changes observable behavior → `not applicable`,
  reason: no observable mutation.
- A pre-existing test of the target's unit fails → `already asserted`,
  no test.
- Every such test passes → net-new gap confirmed, and `VERIFY` reuses
  the probe.

## Placement

An _invariant_ names the property a test asserts about one target: same
call and assertion form, differing only in inputs and expected values.

Place each net-new gap's test on the first matching rung, skipping tests
recorded as redundant, flaky, or obsolete:

1. An existing parameterized test asserts the same invariant → add a
   row.
2. An existing single-case test asserts the same invariant → convert it
   to a parameterized test, keep its case as a row, and add a row.
3. An existing suite covers the target's unit → add a case beside
   related cases, reusing its fixtures, factories, and helpers before
   creating any.
4. Otherwise → create a test file for the unit or boundary.

The row or case each rung adds counts as the gap's new test. Edits to
pre-existing tests only add: never remove or weaken an assertion, row,
or case. A converted test keeps its original case's inputs and expected
outcome.

## Workflow

1. **GATE**—Read `references/shell-command-guide.md`. Resolve scope per
   **Input**, halting if none.
2. **ORIENT**—State the **Goal** and resolved scope in one sentence.
   Name what won't change: production code, build, and tool
   configuration. Capture the pre-task baseline snapshot per
   `references/cleanup-guide.md`.
3. **PLAN**—Read `references/testing-guide.md` and, when present,
   `TESTING.md`, then:
   - **Catalog**: inspect production code, adjacent tests, and coverage
     commands, then catalog existing test assertions. Record
     pre-existing redundant, flaky, or obsolete tests under `Findings`
     without editing them. Obsolete tests reference a symbol absent from
     the project.
   - **Verdicts**: record one verdict per category for every
     behavioral-surface target: net-new gap, `already asserted`, or
     `not applicable` with its reason.
   - **Baseline**: once a net-new gap appears, run the full suite. Any
     failure counts as an out-of-scope blocker—halt, listing each
     failing test under `Findings` as `obsolete` or, otherwise,
     `regression`.
   - **Probe**: settle each net-new gap per **Mutation probe**.
   - **Short-circuit**: every target carries four verdicts and zero
     net-new gaps remain → skip to `REPORT`.
   - **Map**: rank targets per **Behavioral surface**, then map each
     net-new gap to its **Placement** rung.
4. **ACT**—Write each net-new gap's test on its mapped rung, in rank
   order.
5. **VERIFY**—Loop over every criterion in **Verification**:
   - Run targeted tests, then the full suite and, when present, the
     coverage tool.
   - Re-apply each net-new gap's mutation probe, confirm its new test
     fails, then restore per **Mutation probe**.
   - Audit every added or updated test file against the **Testing**
     standards—CI parity, hygiene, and repeat-run stability included.
     Fix any violation before proceeding.
   - Audit task edits against the pre-task baseline using the
     Self-cleanup checklist in `references/cleanup-guide.md`, removing
     every self-introduced artifact before proceeding.
   - For each unmet criterion: return to `ACT`, execute, then re-enter
     `VERIFY`.
   - Exit only when all criteria pass.
   - Halt only for out-of-scope blockers (test or compilation failures
     independent of this run's edits, or missing runtime dependencies),
     never for failures this run's edits cause.
6. **PERSIST**—Confirm all test files written, with no partial writes.
7. **REPORT**—Emit the result following the result directives and using
   the result template:
   - `No Gaps`: the `PLAN` short-circuit fired.
   - `Improved`: `VERIFY` exited with at least one net-new gap holding a
     passing test.
   - `Failed`: any other outcome—a halt or every net-new gap reported as
     a defect.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Surface the audit as one `Actions` line reporting targets, categories,
  net-new gaps before and after probes, and placement counts (for
  example,
  `audited 6 targets across 4 categories; 4 → 3 gaps after probes; 2 rows, 1 case, 0 files`),
  keeping per-target detail out of the result.

## Constraints

- **No Confirmation Halts**: never halt to request user scope
  confirmation or interactive direction— write tests autonomously within
  resolved scope or emit `Result: No Gaps`.
- Never edit production code beyond temporary **Mutation probe** edits.
- **Defect Exposed**: a new test's failure counts as a production defect
  only when the code breaks a contract independent of its
  implementation—documented behavior, a type or interface signature, or
  an in-project caller's reliance. Never fix the code or assert the
  defect. Drop the test, undoing any conversion made to host it, and
  report the defect under `Findings`, citing the broken contract. Treat
  any other failure as a test error and fix the test.
- Don't write tests solely to raise a number.
- Never duplicate assertions, execution paths, or post-conditions,
  whether against existing tests or among new ones. Parameterize
  table-driven inputs per **Placement** instead.
- No hacks, workarounds, or shortcuts.
- No violation of `DRY` and `SOLID` software principles.
- Forbid laziness: fix issues properly, correctly, and idiomatically.
- Never edit build or tool configuration files, such as `tsconfig.json`,
  `.eslintrc.*`, `webpack.config.*`, `vite.config.*`, `jest.config.*`,
  `Makefile`, `pyproject.toml`, or `Cargo.toml`.
- Never suppress or turn off compiler or linter diagnostics, such as
  `@ts-ignore`, `eslint-disable`, `@SuppressWarnings`, or
  `# type: ignore`.
- Never weaken type contracts—`as any`, `!` non-null assertions, or
  broadened union types—to silence errors.
- **Full autonomy**: never perform or request human execution, an
  attended or interactive terminal, or human presence to confirm
  coverage—use direct, agent-executed inspection instead.

## Verification

- Production code, build, and tool configuration match their pre-task
  content.
- Full test suite passes.
- Every behavioral-surface target carries a recorded verdict for all
  four categories, and each `not applicable` states why.
- Every new test maps to a recorded net-new gap, and every net-new gap
  holds a passing test or a defect reported under `Findings` with its
  broken contract.
- Coverage tool, when present, reports no uncovered line or branch in
  behavioral-surface targets beyond reported defects.
- Each new test fails against its gap's mutation probe, which the target
  unit's pre-existing tests pass.
- Each new test sits on its first matching **Placement** rung, and edits
  to pre-existing tests remove or weaken nothing.
- Zero duplicated assertions, execution paths, or post-conditions
  introduced.
- All added or updated tests pass the **Testing** standards audit.
- No self-introduced cleanup violation remains per
  `references/cleanup-guide.md`.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`, so a
  missing, altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, early stop, or halt—with the
  result template as the final message, never on progress narration.
- Set `Result` to exactly one template literal, verbatim. Report an
  early stop or halt lacking its own literal as `Failed`, with the
  reason under `Findings`.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of modified or created files]
- **Findings**:
  - [Terse list of key gaps, risks, or notable observations]
- **Summary**:
  - [Terse list of summary of changes]

> **Test Status** • `[scope]`
> **Result**: [Improved | No Gaps | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
