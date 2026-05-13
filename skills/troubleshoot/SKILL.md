---
name: troubleshoot
description:
  "Troubleshoot systematically: observe, hypothesize, test, fix, verify."
user-invocable: true
argument-hint: "[optional: description of the issue or symptom]"
---

# Troubleshoot

## When to use

- Always. Execute immediately upon invocation without waiting for user
  input or confirmation.

## Process

1. Reproduce the problem and read the real error or failing output.
2. Form one hypothesis about the root cause.
3. Run one targeted check to confirm or reject that hypothesis.
4. Fix the root cause and add a test that proves it.
5. Run the strongest relevant verification before finishing.

## Verification

- Reproduce the problem before the fix
- Identify the root cause; avoid guessing
- Cover the fix with a test where possible
- The final checks pass

## Rules

- **Unconditional**: Execute immediately upon invocation. Never wait for
  user input, confirmation, or additional context before starting.
- Make the smallest safe fix for the proven root cause.
- If the issue comes from a contract mismatch or unhandled failure path,
  fix that explicitly.
- Clarify the problem before troubleshooting if no concrete issue or
  symptom exists.
- One hypothesis at a time.
- Fix root cause, not symptoms.
- Don't hide missing evidence. If you didn't run it, say so.
- If repeated attempts keep missing the cause, step back and trace the
  data flow from the entry point.

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
  - [List of terse summary of fixes, if any]

> **Simplify Status** • `[Scope]`
> **Result**: [Fixed | No Action | Failed]
> **Impact**: [Terse impact statement]
>
> [_Verify test suites pass._]
```
<!-- prettier-ignore-end -->
