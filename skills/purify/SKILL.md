---
name: purify
description:
  "Eliminate KISS, YAGNI, Idiomatic, and Hygiene violations while
  preserving intended behavior."
user-invocable: true
argument-hint: "[optional: file path, module, or focus area]"
---

# Purification agent

## When to use

- Code contains visible waste, ceremony, duplication, or dead paths.
- Existing implementation looks correct but heavier than necessary.
- Performance, readability, or maintainability can improve without
  changing intended behavior.

## Goal

- Remove `KISS`, `YAGNI`, `Idiomatic`, and `Hygiene` violations: dead
  code, redundant abstractions, over-engineering, non-idiomatic
  patterns, and hygiene debt.
- Reduce code to the smallest clear, idiomatic, maintainable form.
- Improve efficiency only through safe, verified changes.
- Strengthen tests when simplification or optimization exposes coverage
  gaps.

## Input

Determine scope by the first available source:

- Files or folders provided by the user.
- Current changes in the repository.

Abort if no scope exists.

_Current changes:_ staged and `unstaged` edits, deletions, and renames
of tracked files, plus new `untracked` files. Requires a versioned
project, abort with a clear message if none detected.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Shell Commands

See `references/shell-command-guide.md` for command safety, timeouts,
redirects, and non-interactive environment directives.

## Workflow

1. **GATE**—Survey scope and establish baseline. Inspect target code,
   tests, build commands, and recent changes. Detect waste using the
   `KISS`, `YAGNI`, `Idiomatic`, and `Hygiene` sections of
   `references/refactoring-guide.md`. Read
   `references/shell-command-guide.md`. Run relevant tests; identify why
   verification can't run if tests don't pass.
   - If scope resolves to current changes, the project contains
     TypeScript or JavaScript sources, and `fallow` resolves
     (`fallow --version`): run
     `git diff HEAD | fallow audit -f json -q --diff-stdin` and treat
     confirmed findings as additional dead-code signal. Treat all
     findings as unverified candidates; apply judgment during PLAN. Skip
     silently if `fallow` cannot be found or the project lacks TS/JS
     sources.
   - Exit immediately if the survey finds none of: dead code, redundant
     abstractions, unused helpers, over-engineered constructs,
     non-idiomatic patterns, or hygiene debt. Emit `Result: No Changes`
     via the template below and halt.
2. **ORIENT**—State goal and scope in one sentence. Name what won't
   change: behavior, public interfaces, and feature scope.
3. **PLAN**—Read `references/testing-guide.md`. Declare minimal changes:
   which violations to remove, which files to touch, and in what order.
   Check ambiguous or risky slices before acting.
4. **ACT**—Execute only what PLAN declared. Nothing more.
   - Remove dead code, unused branches, redundant state, obsolete
     helpers, and needless comments.
   - Inline thin wrappers, merge duplicate paths, simplify conditions,
     reduce parameters, and replace overbuilt abstractions.
   - Improve hot or wasteful paths only when output and intended
     behavior stay unchanged.
   - Add or update tests only when needed to lock behavior around
     modified code.
5. **VERIFY**—Loop over every criterion in `Verification`:
   - For each unmet criterion: return to `ACT`, execute, then re-enter
     `VERIFY`.
   - Exit only when all criteria pass.
   - Halt only for out-of-scope blockers.
6. **PERSIST**—Confirm all edits written. Run final compilation or
   type-check where applicable.
7. **REPORT**—Emit the result following the result directives and using
   the result template. Confirm what changed matches ORIENT.

## Directives

- Prefer deletion over abstraction.
- Prefer direct, idiomatic language features over custom machinery.
- Prefer data flow that reads once, transforms directly, and avoids
  hidden mutation.
- Replace cleverness with direct code.
- Keep public interfaces stable unless the user requested an interface
  cleanup.
- Treat comments as debt unless they explain intent, invariants, or
  external constraints.
- Remove dependencies, files, and configuration only after confirming
  nothing uses them.
- Optimize measurable or visible waste; avoid speculative tuning.

## Constraints

- Never introduce `SOLID` or coupling violations; check against the
  `SOLID` sections of `references/refactoring-guide.md`.
- Preserve intended behavior and user-visible output unless the user
  explicitly requests otherwise.
- Don't expand feature scope.
- Don't mask failing tests; fix root causes or report blockers.
- Don't rewrite large areas when small deletions or focused edits
  suffice.
- Abort and report if verification needs unavailable services, secrets,
  or destructive setup.
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

- Relevant tests pass with no new failures.
- Code compiles or type-checks where applicable.
- Coverage protects modified behavior or documented gaps remain.
- Complexity, duplication, dependency count, or runtime cost decreases
  where measurable.

## Result directives

- Optimize result for agent, token, and context efficiency: terse,
  concise, precise.
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
  - [Terse list of affected files]
- **Findings**:
  - [Terse list of notable findings]
- **Summary**:
  - [Terse list of summary of changes]

> **Purify Status** • `[scope]`
> **Result**: [Complete | No Changes | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
