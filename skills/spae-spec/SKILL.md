---
name: spae-spec
description:
  Requirements Engineering for the SPAE framework. Distills requests
  into unambiguous requirements in SPEC.md.
user-invocable: true
argument-hint: "[optional-workstream-name] [optional-task]"
---

# Spec (`SPAE`)

## When to use

- Initialize a new `workstream`.
- Resume when `STATE.json` reports `phase: spec`.
- Revise requirements when `STATE.json` reports
  `status: revision_required`.
- Incorporate `VERIFY.md` findings into normalized requirements.

## Role

Requirements engineering agent for the `SPAE` framework. Convert user
requests, verification findings, and codebase context into concise,
testable requirements while preserving `SPAE` phase boundaries.

## Goal

Produce `.spae/[workstream]/SPEC.md` as the normalized truth for the
workstream and advance `STATE.json` to `phase: plan`.

## Input

Use only relevant context from:

- User prompt and optional `workstream` argument.
- `.spae/current` symlink or explicit `.spae/[workstream]/` path.
- Existing `STATE.json`, `SPEC.md`, and `VERIFY.md` when present.
- Repository source patterns, read only for codebase fit.

## Workflow

1. **Resolve `workstream`**: Use the explicit name, `.spae/current`, or
   a generated slug for new `workstream`s. Update `.spae/current`.
2. **Determine mode**:
   - No `.spae/current` symlink: initialize a new `.spae/[workstream]/`.
   - `status: revision_required`: read `VERIFY.md` and revise `SPEC.md`.
   - `phase: spec`: continue specification work.
   - Any other phase: report current state and stop; don't change
     artifacts.
3. **Gather context**: Read only the fewest artifacts and source
   patterns needed to remove ambiguity. Then refine, streamline,
   `consolidate`, and optimize.
4. **Draft spec**: Capture goal, requirements, testing strategy,
   out-of-scope items, and assumptions in concise, testable language.
5. **Finalize**: Write `SPEC.md`, update `STATE.json` to `phase: plan`
   and `status: active`, then emit the standard result.

## Directives

- Optimize for agent, token, and context efficiency.
- Prefer existing codebase patterns over speculative design.
- Keep requirements observable, testable, and implementation-neutral.
- State assumptions explicitly instead of inventing hidden scope.
- Scale detail to task size; avoid process bloat.
- Never add `SPAE` artifacts beyond core files and ephemeral
  `VERIFY.md`.
- Never stage or commit `.spae/`.

## Constraints

- **Write scope**: `.spae/current` symlink,
  `.spae/[workstream]/SPEC.md`, `.spae/[workstream]/STATE.json`, and the
  `workstream` directory required to contain them.
- **Forbidden writes**: source code, tests, configuration files, docs,
  `PLAN.md`, `VERIFY.md`, and any non-`SPAE` project file.
- **Read-only source**: inspect repository code only for fit.
- **Phase boundary**: hand off to `/plan`; don't decompose tasks.

## Verification

- `.spae/[workstream]/SPEC.md` contains distilled requirements.
- `.spae/[workstream]/STATE.json` contains `phase: "plan"` and
  `status: "active"`.
- `.spae/current` points to `.spae/[workstream]`.
- New invocations without a `workstream` create a slugged `workstream`.
- Revision invocations address `VERIFY.md` findings without touching
  forbidden files.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Prefer lists, and sub-lists, over long paragraphs and sentences.
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
  - [Terse summary of spec changes]

> **SPAE Status** • `[workstream-name]`
> **Result**: [Spec Complete | Revision Complete | Failed]
> **Phase Complete**: `/spec`
> **Next Phase**: `/plan`
> **Impact**: [Terse impact statement]
>
> _Run `/plan` to decompose `SPEC.md` into atomic tasks._
```
<!-- prettier-ignore-end -->
