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

## Goal

- Observe real behavior, test one hypothesis at a time, fix proven root
  causes, and verify the result.
- Identify the root cause with evidence.
- Apply the smallest safe fix.
- Prove the fix through targeted tests and the strongest relevant check.

## Input

Determine input by one of the following:

- Issue, symptom, error, failing command, stack trace, or test failure
  provided by the user.
- Current repository state and failing verification when the user gives
  only a broad troubleshooting request.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Shell Commands

See `references/shell-command-guide.md` for command safety, timeouts,
redirects, and non-interactive environment directives.

## Workflow

1. **GATE**—Require an actionable symptom: error, failure, trace, or
   incorrect output. Halt and ask if none exists.
2. **ORIENT**—Name the failure and scope in one sentence. State what
   won't change.
3. **PLAN**—Read `references/shell-command-guide.md`. State one likely
   root cause and one targeted check to confirm or reject it.
4. **ACT**—Execute:
   - Reproduce the failure.
   - Run the targeted check; on rejection, return to **PLAN**.
   - After 3 rejections, trace data flow from entry point.
   - Read `references/testing-guide.md`. Write a failing test
     reproducing the root cause, when practical.
   - Apply the smallest safe fix after evidence confirms.
5. **VERIFY**—Loop over every criterion declared in PLAN:
   - For each unmet criterion: revert the fix, return to **ACT**,
     execute, then re-enter **VERIFY**.
   - Exit only when all criteria pass.
   - Halt only for out-of-scope blockers.
6. **PERSIST**—Write all fix artifacts once, atomically, after
   **VERIFY** passes. Never precedes **VERIFY**. Never partial.
7. **REPORT**—Emit the result following the result directives and using
   the result template.

## Directives

- Work one hypothesis at a time.
- Don't fix until the test confirms the hypothesis.
- After 3 failed hypotheses, stop generating new ones and trace data
  flow from the entry point.
- When coexisting issues or expensive reproduction arise, assess
  severity and scope before observing.
- Fix root causes, not symptoms.
- Prefer evidence from real failures over inference.
- State missing evidence plainly. If you didn't run a check, say so.
- Fix contract mismatches and unhandled failure paths explicitly.

## Constraints

- Don't broaden scope beyond the failure under investigation.
- Don't mask failures, weaken tests, or remove coverage to pass checks.
- Don't leave speculative changes after a hypothesis fails.
- Don't skip clarification when no actionable symptom exists.
- No violations of `DRY` and `SOLID` software principles.
- No workarounds, hacks, or shortcuts.
- Forbid laziness; fix issues properly, correctly, and idiomatically;
  for example, don't add lint ignore comments.
- Never edit build or tool configuration files; for example,
  `tsconfig.json`, `.eslintrc.*`, `webpack.config.*`, `vite.config.*`,
  `jest.config.*`, `Makefile`, `pyproject.toml`, `Cargo.toml`.
- Never suppress or disable compiler or linter diagnostics; for example,
  `@ts-ignore`, `eslint-disable`, `@SuppressWarnings`, `# type: ignore`.
- Never weaken type contracts to silence errors; for example, `as any`,
  `!` non-null assertions, or broadening union types.

## Verification

- All test suites pass without any issues.
- Reproduced the failure before the fix when practical.
- Root cause identified with evidence.
- Fix covered by a test when practical.
- Strongest relevant checks pass.
- If verification fails, revert the fix and return to step 2.
- Report remaining risks or skipped checks plainly.

## Result directives

- Optimize result for agent, token, and context efficiency: terse,
  concise, precise.
- Split actions, findings, and summaries into terse bullet points.
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

> **Troubleshoot Status** • `[scope]`
> **Result**: [Fixed | No Action | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
