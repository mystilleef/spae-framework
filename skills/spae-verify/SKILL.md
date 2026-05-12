---
name: spae-verify
description:
  The Arbiter for the SPAE framework. Compares implementation against
  SPEC.md and determines workstream completion.
user-invocable: true
argument-hint: "[optional-workstream-name] e.g. 'user-auth'"
---

# Verify (`SPAE`)

**Goal**: report gaps between the current changes and `SPEC.md`. Close
the `workstream` if no gaps exist.

## When to use

- When `STATE.json` reaches `phase: verify`.
- After all tasks in `PLAN.md` reach `done`.

## Process

1. **Initialize**: Resolve the `workstream` via the provided name or the
   `.spae/current` symlink. Read `SPEC.md` and the current repository
   state.
2. **Execute**:
   - Compare the current changes against `SPEC.md`.
   - Inspect for gaps, regressions, bugs, or optimizations.
   - Invoke `vibe_check` with `goal` (verifying implementation against
     SPEC.md) and `plan` (verification steps taken so far) to ensure
     rigor and alignment.
3. **Finalize**:
   - **Pass**: Delete `VERIFY.md` and set `status: completed`,
     `phase: done` in `STATE.json`. Output the standardized **Execution
     Summary** and **Workstream Completion Feedback**.
   - **Fail**: Create `VERIFY.md` with findings and set
     `status: revision_required`, `phase: spec` in `STATE.json`. Output
     the standardized **Execution Summary** and **Phase Transition
     Feedback** (Next Phase: `/spec`).

## Verification

- `STATE.json` reflects the correct `status` and `phase`.
- `VERIFY.md` exists only on failure and contains actionable findings.
- All test suites pass.

## Rules

- Optimize all operations for agent, token, and context efficiency.
- Focus on the delta between `SPEC.md` and the implementation.
- **Write Boundaries**: Exercise exclusive authority to edit
  `.spae/current/VERIFY.md` and `.spae/current/STATE.json`.
- **Forbidden Writes**: Never edit application code, tests,
  configuration files, docs, `SPEC.md`, `PLAN.md`, or non-`SPAE` project
  files.
- STATUS: SUCCESS on completion.

## Standardized feedback

- Keep feedback prose terse, concise, and precise.
- Optimize prose for token and context efficiency.
- If needed, split findings and summary into terse bullet points.

### Execution summary

<!-- prettier-ignore-start -->
```md
### Execution summary

- **Actions**:
  - [List of terse, short, compact, condensed summary of actions taken]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [List of terse summary of key gaps, risks, or architectural notes]
```

### **Workstream** completion feedback (_pass_)

```md
> **SPAE Status** • `workstream-name`
> **Phase Complete**: `/verify` (Pass)
> **Result**: Workstream completed successfully.
```

### Phase transition feedback (_fail_)

```md
> **SPAE Status** • `workstream-name`
> **Phase Complete**: `/verify` (Fail)
> **Next Phase**: `/spec`
>
> _Run `/spec` next._
```
<!-- prettier-ignore-end -->
