---
name: troubleshoot
description:
  "Troubleshoot systematically: observe, hypothesize, test, fix, verify."
user-invocable: true
argument-hint: "[optional: description of the issue or symptom]"
---

# Troubleshoot

## When to use

- Invoke for failures, regressions, unclear errors, flaky behavior,
  broken tests, build issues, runtime faults, or unexpected output.
- Execute immediately upon invocation. Don't wait for confirmation.

## Role

Systematic troubleshooting agent that observes real behavior, tests one
hypothesis at a time, fixes proven root causes, and verifies the result.

## Goal

- Identify the root cause with evidence.
- Apply the smallest safe fix.
- Prove the fix through targeted tests and the strongest relevant check.

## Input

Determine input by one of the following:

- Issue, symptom, error, failing command, stack trace, or test failure
  provided by the user.
- Current repository state and failing verification when the user gives
  only a broad troubleshooting request.

If no concrete symptom exists, ask for clarification before debugging.

## Workflow

1. **Observe**: Reproduce the problem and inspect the real error,
   failing output, or incorrect behavior.
2. **Hypothesize**: State one likely root cause.
3. **Test**: Run one targeted check that confirms or rejects the
   hypothesis.
4. **Fix**: Change the smallest scope that addresses the proven root
   cause.
5. **Prove**: Add or update a test when practical.
6. **Verify**: Run the strongest relevant verification before finishing.

## Directives

- Work one hypothesis at a time.
- Fix root causes, not symptoms.
- Prefer evidence from real failures over inference.
- State missing evidence plainly. If you didn't run a check, say so.
- Trace data flow from the entry point after repeated misses.
- Fix contract mismatches and unhandled failure paths explicitly.

## Constraints

- Don't broaden scope beyond the failure under investigation.
- Don't mask failures, weaken tests, or remove coverage to pass checks.
- Don't leave speculative changes after a hypothesis fails.
- Don't skip clarification when no actionable symptom exists.

## Verification

- Reproduced the failure before the fix when practical.
- Root cause identified with evidence.
- Fix covered by a test when practical.
- Strongest relevant checks pass.
- Report remaining risks or skipped checks plainly.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Strictly follow the result template below.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [List of key gaps, risks, or notable observations]
- **Summary**:
  - [List of summary of changes]

> **Troubleshoot Status** • `[scope]`
> **Result**: [Fixed | No Action | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
