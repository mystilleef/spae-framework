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

- Eliminate `KISS`, `YAGNI`, `Idiomatic`, and `Hygiene` violations: dead
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

## Workflow

1. **Survey Scope**: Inspect target code, tests, build commands, and
   recent changes. Detect waste using the `KISS`, `YAGNI`, `Idiomatic`,
   and `Hygiene` sections of `references/refactoring-guide.md`.
   - **Post-Survey Short-Circuit**: Exit immediately if the survey finds
     none of: dead code, redundant abstractions, unused helpers,
     over-engineered constructs, non-idiomatic patterns, or hygiene debt
     (cryptic names, debug artifacts, "what" comments).
   - Skips steps 2–7 (baseline, test runs, multi-pass analysis). Survey
     always runs.
   - Emit `Result: No Changes` via the template below and halt.
2. **Establish Baseline**: Run relevant tests or identify why
   verification can't run.
3. **Remove Waste**: Delete dead code, unused branches, redundant state,
   obsolete helpers, and needless comments.
4. **Collapse Complexity**: Inline thin wrappers, merge duplicate paths,
   simplify conditions, reduce parameters, and replace overbuilt
   abstractions.
5. **Optimize Safely**: Improve hot or wasteful paths only when output
   and intended behavior stay unchanged.
6. **Patch Coverage**: Add or update tests only when needed to lock
   behavior around modified code.
7. **Verify**: Run targeted and broad test suites appropriate to the
   change.

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

- Never introduce `SOLID` or coupling violations; evaluate against the
  `SOLID` sections of `references/refactoring-guide.md`.
- Preserve intended behavior and user-visible output unless the user
  explicitly requests otherwise.
- Don't expand feature scope.
- Don't mask failing tests; fix root causes or report blockers.
- Don't rewrite large areas when small deletions or focused edits
  suffice.
- Abort and report if verification needs unavailable services, secrets,
  or destructive setup.

## Verification

- Relevant tests pass with no new failures.
- Code compiles or type-checks where applicable.
- Coverage protects modified behavior or documented gaps remain.
- Complexity, duplication, dependency count, or runtime cost decreases
  where measurable.

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

> **Purify Status** • `[scope]`
> **Result**: [Complete | No Changes | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
