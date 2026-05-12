---
name: purify
description: Aggressively simplify and optimize code
user-invocable: false
---

# Goal

Aggressively simplify and optimize code.

## Input

Determine input by one of the following:

- Files, or files inside folders, provided by the user.
- Current changes in the repository.

## Process

1. Study the input and the context relevant to it.
2. Aggressively optimize code relevant to input and context.
3. Aggressively simplify code relevant to input and context.
4. Write or update relevant tests, if needed.

## Rules:

- Follow best software engineering practices
- Write idiomatic code
- Verify your modifications with tests
- Ensure proper test coverage
- Pass all test suites
- Abort if no input found.

## Verification

- Efficient, clean, maintainable, and testable code.
- All test suites pass.

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
  - [List of terse summary of optimizations and simplifications]

> **Simplify Status** • `[Scope]`
> **Result**: [Simplified | No Action | Failed]
> **Impact**: [Terse impact statement]
>
> [_Verify test suites pass._]
```
<!-- prettier-ignore-end -->
