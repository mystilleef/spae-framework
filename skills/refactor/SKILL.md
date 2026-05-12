---
name: refactor
description: "Refactor code to simplify it while preserving behavior."
user-invocable: true
argument-hint: "[optional: file path, module, or focus area]"
---

# Goal

Enhance code structure, readability, and maintainability while strictly
preserving observable behavior.

## Input

Determine input by one of the following:

- Files or folders provided by the user.
- Current changes in the repository.

## Workflow

1. **Inspect**: Identify behavior boundaries, existing tests, and code
   smells.
2. **Plan**: Craft minimal, incremental plans using small, reversible
   steps.
3. **Execute**: Apply structural changes individually.
4. **Validate**: Run targeted tests and linters after each edit. Revert
   upon failure.

## Context optimization

- **Progressive Disclosure**: Maintain lean core instructions. Fetch
  advanced patterns or references on demand.
- **Narrow Scope**: Read only target files, direct callers/callees,
  relevant tests, and type definitions. Forbid repository-wide
  summaries.

## Directives

- **Simplify Aggressively**: Delete dead code, inline trivial wrappers,
  and replace nested conditionals with guard clauses.
- **Collapse Bad Abstractions**: Remove leaky or over-engineered
  abstractions. Flatten when indirection costs more than it saves.
- **Clarify Names**: Assign descriptive, domain-specific names. Replace
  magic values with named constants.
- **Isolate Responsibilities**: Extract functions for distinct concepts.
  Enforce single responsibility per unit.
- **Minimize Duplication**: Apply `DRY` judiciously—deduplicate when
  copies likely diverge accidentally rather than differ intentionally.
- **Reduce Coupling**: Reduce dependencies between modules. Prefer
  dependency injection over hard-wired references. Break cycles.
- **Organize by Abstraction**: Group related functions. Order
  definitions from high-level to low-level. Put the happy path before
  edge cases.

## Constraints

- **Preserve Behavior**: Never alter public `APIs`, return values, side
  effects, or data formats.
- **Contain Scope**: Never mix refactoring with new features, bug fixes,
  or pure formatting churn.
- **Maintain Test Integrity**: Never weaken or change tests to
  accommodate accidental behavior changes.
- **Manage Risk**: Forbid large rewrites. Add characterization tests
  before editing high-risk domains (concurrency, database writes).

## Verification

- The refactor preserves behavior.
- The code reads simpler and avoids over-simplification.
- Tests and build checks pass.

## Standardized feedback

- Keep feedback prose terse, concise, and precise.
- Optimize prose for token and context efficiency.
- If necessary, split findings and summary into terse bullet points.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [List of terse, short, compact, condensed summary of actions taken]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [List of terse summary of key gaps, risks, or architectural notes]
- **Summary**:
  - [List of terse summary of refactorings]

> **Refactor Status** • `[Scope]`
> **Result**: [Complete | No Changes | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
