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

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Shell commands

See `references/shell-command-guide.md` for command safety, timeouts,
redirects, and non-interactive environment directives.

## Cleanup

See `references/cleanup-guide.md` for the self-introduced-artifact
checklist and diff-only audit scope.

## Behavioral surface

Target only methods and functions with business logic, state
transitions, or error handling. Exclude: trivial `getters`/`setters`,
`POJOs`, generated code, framework boilerplate, and any method where
every path delegates trivially, accesses a field, or returns a computed
value with no state change, resource interaction, or error-propagation
decision.

## Workflow

1. **GATE**—Confirm scope: user-provided files or current repository
   changes. Abort immediately if none.
2. **ORIENT**—Goal: cover all behavioral gaps in scope. Production code
   unchanged.
3. **PLAN**—Read `references/testing-guide.md`,
   `references/shell-command-guide.md`, and
   `references/cleanup-guide.md`. Inspect production code,
   adjacent tests, and coverage commands. List every gap across all four
   categories per behavioral-surface target.
   - **Short-circuit**: zero gaps found → emit `Result: No Gaps` and
     halt.
4. **ACT**—Write tests for every enumerated gap. Cover all four
   categories per target before declaring it complete.
5. **VERIFY**—Loop over every criterion declared in PLAN:
   - Run targeted tests; run broader suite or coverage tool.
   - Audit every new test file against CI Parity rules in
     `references/testing-guide.md`; fix any violation before proceeding.
   - Audit the task's own `git diff`/`git status` against the
     Self-cleanup checklist in `references/cleanup-guide.md`; remove
     every self-introduced artifact before proceeding.
   - For each unmet criterion: return to `ACT`, execute, then re-enter
     `VERIFY`.
   - Exit only when all pass and no regressions remain.
   - Halt only for out-of-scope blockers.
6. **PERSIST**—Confirm all test files written; no partial writes.
7. **REPORT**—Emit the result following the result directives and using
   the result template.

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
- **Full autonomy**: Never perform or request human execution, an
  attended or interactive terminal, or human presence to confirm
  coverage; use direct, agent-executed inspection instead.

## Verification

- Production code unchanged;
- Entire test suite passes with no failures.
- All four categories audited per target on the behavioral surface.
- If coverage tool present: no meaningful uncovered lines or branches
  remain; if absent: all five categories confirmed through direct,
  agent-executed inspection, no critical gaps.
- Tests cover real behavioral risk, not vanity coverage.
- All new tests pass CI Parity audit in `references/testing-guide.md`.
- No self-introduced cleanup violation remains per
  `references/cleanup-guide.md`.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
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

> **Coverage Status** • `[scope]`
> **Result**: [Improved | No Gaps | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
