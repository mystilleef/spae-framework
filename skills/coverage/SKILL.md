---
name: coverage
description: "Fill coverage gaps with tests."
user-invocable: true
argument-hint: "[optional: file path or module to evaluate]"
---

# Coverage

## When to use

- You want to check whether recent work has enough test coverage
- A file or module looks fragile or under-tested
- You want to add tests without changing behavior

## Process

1. Determine scope in this order: `$ARGUMENTS`, current repository
   changes, available generated coverage reports, then the most recently
   changed testable code.
2. Inspect only relevant production code, adjacent tests, and available
   test or coverage commands.
3. Identify real risk gaps: contracts, failure paths, state changes,
   regressions, and integration points.
4. If no meaningful gap appears, report existing coverage strength and
   stop.
5. Add the smallest set of tests that could catch plausible bugs without
   changing production behavior.
6. Run targeted tests first. Run broader tests or coverage only when
   needed to confirm impact.
7. Report scope, added coverage, commands run, and any remaining gaps.

## Verification

- The target area has clear scope
- New tests cover real risk, not coverage vanity
- The code under test stayed unchanged
- Tests pass

## Rules

- Focus on the smallest set of tests that meaningfully improves
  confidence.
- Add coverage for contract and failure-path behavior before edge-case
  trivia.
- When using coverage data, generate reports with existing project
  coverage tools and commands. Don't invent metrics or add new tooling
  just to measure coverage.
- If the target remains unclear, choose the highest-risk recently
  changed testable code. If no suitable target exists, report that no
  useful coverage work applies and stop.
- Avoid writing tests just to raise a number.
- Avoid adding tests for trivial code or framework behavior.
- If the code already has strong test coverage, say so.

## Standardized feedback

- Keep feedback prose terse, concise, and precise.
- Optimize prose for token and context efficiency.
- If needed, split findings and summary into terse bullet points.

### Coverage summary

<!-- prettier-ignore-start -->
```md
### Execution summary

- **Actions**:
  - [List of terse, short, compact, condensed summary of actions taken]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [List of terse summary of key gaps, risks, or architectural notes]
- **Summary**:
  - [List of terse summary of test coverage changes]

> **Coverage Status** • `[Scope]`
> **Result**: [Improved | No Gaps | > Failed]
> **Impact**: [Terse impact statement]
>
> _Review added tests._
```
<!-- prettier-ignore-end -->
