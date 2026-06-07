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

- Files, or changed code, have gaps in coverage

## Goal

- Write comprehensive and exhaustive tests that address gaps in code
  coverage.

## Input

Determine scope from the first available source:

- Files or folders provided by the user.
- Current changes in the repository.

Abort if no scope exists.

_Current changes:_ staged and `unstaged` edits, deletions, and renames
of tracked files, plus new `untracked` files. Requires a versioned
project. Abort with a clear message if none detected.

## Behavioral surface

Target only methods and functions with business logic, state
transitions, or error handling. Exclude: trivial `getters`/`setters`,
`POJOs`, generated code, framework boilerplate, and any method where
every path delegates trivially, accesses a field, or returns a computed
value with no state change, resource interaction, or error-propagation
decision.

## Workflow

1. **Scope**: Identify the target scope and their relevant context.
2. **Inspect**: Read relevant production code, adjacent tests, and
   test/coverage commands. Run the coverage tool if available to collect
   metrics and identify uncovered lines and branches.
3. **Enumerate gaps**: For each target on the behavioral surface, audit
   all four categories and document every gap:
   - **Happy path**—expected inputs yield expected outputs
   - **Error / failure**—malformed inputs, exceptions, and error returns
   - **Boundary / edge**—null, empty, zero, min, max, overflow,
     off-by-one
   - **State transitions**—valid and malformed state changes and side
     effects
   - **Post-Audit Short-Circuit**: Exit immediately if the audit finds
     zero behavioral gaps (all categories already exhaustively covered).
     Skips steps 4–5. Emit `Result: No Gaps` via the template below and
     halt.
4. **Write tests**: Cover every gap from the enumeration. All four
   categories must cover each target before declaring it complete.
5. **Run checks**: Run targeted tests; run broader suite or coverage
   tool when needed to confirm completeness and catch regressions.
6. **Report**: Summarize scope, files, commands, coverage added, and any
   remaining gaps with justification.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Cover all four categories per target before declaring coverage
  complete.
- Use coverage tooling when available; when absent, use static analysis.
- Keep tests focused, deterministic, and close to the behavior under
  test.
- Don't limit yourself to just unit tests; write any category of tests
  necessary to prove, verify, and confirm your solution.

## Constraints

- Don't change production behavior.
- Don't write tests solely to raise a number.
- Don't test outside the behavioral surface.
- No hacks, workarounds, or shortcuts.
- No violation of `DRY` and `SOLID` software principles.
- Forbid laziness; fix issues properly, correctly, and idiomatically.
- Never edit build or tool configuration files; for example,
  `tsconfig.json`, `.eslintrc.*`, `webpack.config.*`, `vite.config.*`,
  `jest.config.*`, `Makefile`, `pyproject.toml`, `Cargo.toml`.
- Never suppress or disable compiler or linter diagnostics; for example,
  `@ts-ignore`, `eslint-disable`, `@SuppressWarnings`, `# type: ignore`.
- Never weaken type contracts to silence errors; for example, `as any`,
  `!` non-null assertions, or broadening union types.

## Verification

- Production code unchanged;
- Entire test suite passes with no failures.
- All four categories audited per target on the behavioral surface.
- If coverage tool present: no meaningful uncovered lines or branches
  remain; if absent: all five categories manually confirmed, no critical
  gaps.
- Tests cover real behavioral risk, not vanity coverage.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Prefer lists, and sub-lists, over long paragraphs and sentences.
- Strictly follow the result template below.

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

> **Coverage Status** • `[scope]`
> **Result**: [Improved | No Gaps | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
