---
name: review
description: >-
  Orchestrates code-review agents sequentially until a pass finds no new issues.
  Use for an exhaustive, multi-pass review that reports without fixing.
user-invocable: false
argument-hint: "[optional: diff, commit, PR, file, or focus area]"
---

# Review

## When to use

- The user wants an exhaustive, multi-pass code review without fixes.

## Goal

- Run code-review agents sequentially until a pass adds no new findings.

## Input

- Accept an optional argument (diff, commit, PR, file, or focus area).

## Workflow

Halt on any **Halt conditions** entry after every spawn.

1. **Review Loop**:
   - Spawn a `code-review` subagent with the optional argument, then await its
     result.
   - `Issues Found`: repeat step 1.
   - `No New Issues` or `No Issues`: proceed to step 2.
2. **Report**: emit the result per **Result directives**:
   - `Result`: `Completed` when the workflow reaches **Report** without a halt,
     `Halted` when a subagent reports `Failed`, `Failed` on any other **Halt
     conditions** entry.
   - `Verdict`: the final subagent result's verdict.

## Directives

- **Spawn first**: open with the subagent tool and skip all preflight—context
  gathering, environment discovery, path checks, guide or knowledge-base reads,
  and plan reviews.
- Prompt each subagent with the argument verbatim, or `No arguments` without
  one:
  - Never read, list, or expand file-path arguments.
  - Add no context, summaries, or instructions, since each subagent gathers its
    own.
- Route only from each subagent's `Result` value.
- Re-spawn the same subagent once, with the same argument, on a result missing
  or outside the workflow's literals, then route from the replacement's result
  and list the retry under `Findings`.
- Spawn only the subagents the workflow names.
- **IMPORTANT:** Return the result to the caller.

## Constraints

- Limit tool calls to the subagent tool, running nothing else—no file reads,
  writes, listings, searches, shell or git commands, skill activation, or user
  prompts.
- Never run subagents in parallel or concurrently.
- **Halt conditions**: halt immediately and report per **Report**, listing the
  diagnostic under `Findings`:
  - A subagent `Failed` result.
  - A replacement subagent result missing or outside the workflow's literals.
  - A process failure (crash, timeout, `AgentError`).

## Verification

- Subagents ran one at a time, in workflow order.
- The loop ended only on `No New Issues`, `No Issues`, or a halt.
- Every run, _halted or not_, ended in **Report**.
- Every tool call spawned a subagent.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`, so a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, early stop, or halt—with the result
  template as the final message, never on progress narration.
- Set `Result` to exactly one template literal, verbatim. Report an early stop
  or halt lacking its own literal as `Failed`, with the reason under `Findings`.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions from spawned subagents]
- **Files**:
  - [Terse list of files from spawned subagent results]
- **Findings**:
  - [Terse, deduplicated list of findings from spawned subagents]
- **Resolutions**:
  - [Terse, deduplicated list of recommended fixes from spawned subagents]
- **Summary**:
  - [Terse list of summary from spawned subagents]

> **Review Status** • `[scope]`
> **Result**: [Completed | Halted | Failed]
> **Verdict**: [Request Changes | Comment | Approve]  _(on `Completed` only)_
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
