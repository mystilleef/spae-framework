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

## Workflow

1. **Scope Target**: Identify the smallest production area worth
   refactoring.
2. **Inspect Context**: Read only relevant production code, adjacent
   tests, and existing test or coverage commands.
3. **Verify Tests**: Confirm a solid, automated, self-checking suite
   exists before touching code.
4. **Identify Smells**: Analyze for target `antipatterns` using the
   violation catalog in `references/refactoring-guide.md`.
   - **Post-Smell Short-Circuit**: Exit immediately if smell detection
     finds zero instances of: duplicated logic, long methods, large
     classes, `primitive` obsession, `SOLID` violations.
   - Skips steps 5–9 (dependency analysis, execution, verification).
     Steps 1–4 always run.
   - Emit `Result: No Changes` via the template below and halt.
5. **Analyze Dependencies**: Check package, module, or class boundaries
   for cyclic imports or unresolved downstream consumers before
   restructuring.
6. **Select Mechanism**: Choose the appropriate move from the fix
   playbook; resolve compound violations using the triage rules in
   `references/refactoring-guide.md`.
7. **Execute in Micro-Steps**: Apply one transformation at a time.
8. **Test After Each Step**: Compile and run the full suite after every
   change.
9. **Backtrack on Failure**: Revert to last known-good state; retry with
   smaller steps.

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
