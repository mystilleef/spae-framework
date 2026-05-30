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
- Revise requirements after a failed `/verify` (`VERIFY.md` present).

## Goal

- Distill user requests, verification findings, and codebase context
  into concise, testable requirements while preserving `SPAE` phase
  boundaries.
- Generate `.spae/[workstream]/SPEC.md` and advance `STATE.json` to
  `phase: plan`.

## Input

Use only relevant context from:

- User prompt and optional `workstream` argument.
- `.spae/current` symlink or explicit `.spae/[workstream]/` path.
- Existing `STATE.json`, `SPEC.md`, and `VERIFY.md` when present.
- Repository source patterns, read only for codebase fit.

## Workflow

1. **Resolve `workstream`**: Use the explicit name, `.spae/current`
   symlink, or a generated slug. Update `.spae/current` for new or
   explicitly named `workstream`s.
2. **Determine mode**:
   - Missing `.spae/current`: initialize a new `.spae/[workstream]/`.
   - `.spae/current` exists with `VERIFY.md`: revise `SPEC.md` using
     `VERIFY.md` findings.
   - `.spae/current` exists without `VERIFY.md`: report current state
     and exit without changes.
3. **Gather context**: Inspect only the minimal source files and
   artifacts required to resolve ambiguity.
4. **Draft spec**: Read the template from `references/SPEC.md`. Define
   the goal, requirements, testing strategy, out-of-scope boundaries,
   and assumptions. Structure `SPEC.md` following this template exactly.
5. **Finalize**: Write `SPEC.md`, set `STATE.json` to `phase: plan` and
   `status: active`, then output the execution summary.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- Write observable, testable, and implementation-neutral requirements.
- Document assumptions explicitly instead of guessing scope.
- Match level of detail to task size; avoid process bloat.
- Limit `SPAE` artifacts to core files and ephemeral `VERIFY.md`.
- Never stage or commit the `.spae/` directory.

## Constraints

- **Write scope**: `.spae/current` symlink,
  `.spae/[workstream]/SPEC.md`, `.spae/[workstream]/STATE.json`, and
  their parent directories.
- **Forbidden writes**: source files, tests, configuration,
  documentation, `PLAN.md`, `VERIFY.md`, and all non-`SPAE` files.
- **Read-only files**: inspect source code only to verify project fit.
- **Phase boundary**: Hand off work to `/plan`; don't decompose tasks.
- **Autonomy**: Avoid mid-execution user queries; halt or block
  autonomously.
- **Ambiguity**: Resolve ambiguous requirements using conservative
  assumptions; document these in `SPEC.md` under **Assumptions**.

## Verification

- Ensure `.spae/[workstream]/SPEC.md` contains distilled requirements
  and structure matching `references/SPEC.md` exactly.
- Ensure `.spae/[workstream]/STATE.json` specifies `phase: "plan"` and
  `status: "active"`.
- Confirm `.spae/current` links to `.spae/[workstream]`.
- Verify new invocations without arguments generate a slugged
  `workstream`.
- Confirm revision processes resolve `VERIFY.md` findings without
  editing forbidden files.
- Verify halt conditions leave all artifacts intact.

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
