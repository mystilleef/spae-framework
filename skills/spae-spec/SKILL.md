---
name: spae-spec
description:
  Requirements Engineering for the SPAE framework. Distills requests
  into unambiguous requirements in SPEC.md.
user-invocable: true
argument-hint: "[optional-workstream-name] [optional-task]"
---

# Spec (`SPAE`)

**Goal**: distill user requests into unambiguous requirements in
`SPEC.md`.

## When to use

- To initialize a new `workstream`.
- When `STATE.json` reaches `phase: spec` or
  `status: revision_required`.
- To refine requirements based on `VERIFY.md` findings.

## Process

1. **Initialize**: Resolve the `workstream` via the provided name, the
   _`.spae/current`_ symlink (for revisions), or a generated slug (for
   fresh `WORKSTREAMS`). Update the _`.spae/current`_ symlink.
2. **Execute**:
   - Synthesize requirements from `STATE.json`, `VERIFY.md`, and
     relevant codebase patterns.
   - Draft a minimal, unambiguous specification.
   - Invoke `vibe_check` with `goal` (writing the spec) and `plan`
     (steps taken so far) to remove feature creep and ensure codebase
     alignment.
3. **Finalize**:
   - Write `SPEC.md`.
   - Update `STATE.json` (phase: `plan`, status: `active`).
   - Output the standardized **Execution Summary** and **Phase
     Transition Feedback** (Next Phase: `/plan`).

## Verification

- `.spae/[workstream-name]/SPEC.md` exists with distilled requirements.
- `.spae/[workstream-name]/STATE.json` exists with `phase: "plan"`.
- `.spae/current` symlink points to `.spae/[workstream-name]`.
- Omitted `workstream` names result in a newly created folder.

## Rules

- Optimize all operations for agent, token, and context efficiency.
- Reject speculative design; prefer codebase fit.
- Write `SPEC.md` using concise, testable language for maximal signal.
- Treat repository source code as read-only.
- **Write Boundaries**: Exercise exclusive authority to edit
  `.spae/current/SPEC.md`, `.spae/current/STATE.json`, and the
  `.spae/current` symlink.
- **Forbidden Writes**: Never edit application code, tests,
  configuration files, docs, `PLAN.md`, or non-`SPAE` project files.
- STATUS: SUCCESS on completion.

## Standardized feedback

- Keep feedback prose terse, concise, and precise.
- Optimize prose for token and context efficiency.
- If needed, split findings and summary into terse bullet points.

### Execution summary

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
  - [List of terse summary of spec]
```

### Phase transition feedback

```md
> **SPAE Status** • `workstream-name`
> **Phase Complete**: `/spec`
> **Next Phase**: `/plan`
>
> _Run `/plan` next._
```
<!-- prettier-ignore-end -->
