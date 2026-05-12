---
name: document
description: Document code
user-invocable: false
---

# Goal

Document code following idiomatic presentation and best practices.

## Input

Determine input by one of the following:

- Files or folders provided by the user.
- Current changes in the repository.

## Process

Document the resolved input following the instructions and rules below.

### Instructions

1.  **Rationale**: Explain _why_ and _constraints_. Never _what_.
2.  **Interface**: Detail purpose, parameters, returns, errors, and side
    effects.
3.  **Safety**: Define invariants, preconditions, edge cases, and
    failure modes.
4.  **Utility**: Lead with one-line summary. Co-locate docs. Add
    runnable examples. Flag performance.
5.  **Maintenance**: Use domain terminology. Sync docs with code
    changes.

### Rules

- **Content**: Document rationale or caller requirements only. Skip
  self-explanatory code.
- **Brevity**: Keep prose brief, concise, and precise while maintaining
  clarity. Omit boilerplate, history, and redundant types.
- **Accuracy**: Describe actual behavior. Never speculate. Purge stale
  docs immediately.
- **Scope**: Hide private implementation details. Address one concept
  per block.
- **Hygiene**: Use active voice. Move `TODOs`/`FIXMEs` to the issue
  tracker.

## Verification

- Code has well-documented Public `APIs` and modules.
- Documentation follow best practices.
- Documentation use idiomatic presentation.

## Standardized feedback

- Keep feedback prose terse, concise, and precise.
- Optimize prose for token and context efficiency.
- If needed, split findings and summary into terse bullet points.

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
  - [List of terse summary of documented code]

> **Documentation Status** • `[Scope]`
> **Result**: [Documented | No Action | Failed]
> **Impact**: [Terse impact statement]
>
```
<!-- prettier-ignore-end -->
