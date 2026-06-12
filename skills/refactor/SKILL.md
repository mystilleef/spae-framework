---
name: refactor
description:
  "Refactor code to fix DRY, SOLID, and Structure violations while
  preserving behavior."
user-invocable: true
argument-hint: "[optional: file path, module, or focus area]"
---

# Refactoring agent

## When to use

- **Rule of Three**: Third instance triggers extraction. Exception:
  security and validation logic warrants unification at 2+.
- **Adding features**: Restructure to accommodate the change first.
- **Fixing bugs**: Clarify structure to expose the error.
- **Code review**: Improve unfamiliar code incrementally.
- **Smells detected**: See violation catalog in
  `references/refactoring-guide.md`.

## Goal

- Execute disciplined, semantics-preserving transformations to remove
  `DRY`, `SOLID`, and `Structure` violations, improving maintainability
  without altering observable behavior.

## Input

Determine scope by the first available source:

- Files or folders provided by the user.
- Current changes in the repository.

Abort if no scope exists.

_Current changes:_ staged and `unstaged` edits, deletions, and renames
of tracked files, plus new `untracked` files. Requires a versioned
project. Abort with a clear message if none detected.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Workflow

1. **GATE**—Precondition guard. Halt immediately on failure.
   - Abort if no scope exists.
   - Read `references/testing-guide.md`.
   - Read relevant production code, adjacent tests, and test commands.
   - Confirm automated test suite passes before touching code.
   - Detect `antipatterns` using the violation catalog in
     `references/refactoring-guide.md`.
   - **Short-circuit**: halt and emit `Result: No Changes` if none
     detected: duplicated logic, long methods, large classes,
     `primitive` obsession, `SOLID` violations.
2. **ORIENT**—Name the smallest production area worth refactoring and
   what won't change.
3. **PLAN**—Declare the minimal change and rationale.
   - Analyze package, module, or class boundaries for cyclic imports and
     unresolved downstream consumers.
   - Select the fix from the playbook; resolve compound violations using
     the triage rules in `references/refactoring-guide.md`.
4. **ACT**—Apply one transformation at a time. Execute only what PLAN
   declared.
5. **VERIFY**—Loop over every criterion declared in PLAN:
   - Run the full suite after each `ACT` step.
   - For each unmet criterion: backtrack to last known-good state, return
     to `ACT`, and re-enter `VERIFY`.
   - Exit only when all criteria pass.
   - Halt only for out-of-scope blockers.
6. **REPORT**—Emit result using the Result template.

## Directives

- **Two Hats**: Never add features or new tests while refactoring.
- **Violations**: Detect and fix using the violation catalog and fix
  playbook in `references/refactoring-guide.md`.

## Constraints

- **Zero Behavioral Change**: External function and observable behavior
  must remain identical.
- **Defer if Broken**: Stabilize failing code before refactoring.
- **Inherit Baseline**: Treat the test suite as-found at refactor start
  as the authoritative baseline, regardless of prior tooling in the same
  session.
- No hacks, workarounds, or shortcuts.
- Forbid laziness; fix issues properly, correctly, and idiomatically.
- Never edit build or tool configuration files; for example,
  `tsconfig.json`, `.eslintrc.*`, `webpack.config.*`, `vite.config.*`,
  `jest.config.*`, `Makefile`, `pyproject.toml`, `Cargo.toml`.
- Never suppress or disable compiler or linter diagnostics; for example,
  `@ts-ignore`, `eslint-disable`, `@SuppressWarnings`, `# type: ignore`.
- Never weaken type contracts to silence errors; for example, `as any`,
  `!` non-null assertions, or broadening union types.

## Verification

- Full test suite passes 100% with no new failures or errors.
- Code compiles without warnings or missing dependencies.
- Complexity metrics (class size, method length, parameter count) show
  measurable reduction.
- No dangling references or unintended interface breaks.
- Re-run smell detection against the violation catalog to confirm no new
  violations introduced.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
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

> **Refactor Status** • `[scope]`
> **Result**: [Complete | No Changes | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
