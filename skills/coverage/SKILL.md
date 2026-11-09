---
name: coverage
description: >-
  Orchestrates test agents sequentially to cover behavioral gaps.
user-invocable: false
argument-hint: "[optional: files or focus area]"
---

# Coverage

## When to use

- The user wants to address coverage gaps in target code autonomously
  using the `test` agent.

## Goal

- Run test `subagents` sequentially to cover behavioral gaps in target
  code.

## Input

- Accept optional arguments (file or folder paths).

## Workflow

Halt on any **Halt conditions** entry after every spawn.

1. **Testing Loop**:
   - Spawn a `test` subagent with the optional argument; await its
     result.
   - `Improved`: repeat step 1.
   - `No Gaps`: proceed to step 2.
2. **Report**: emit the result per **Result directives**:
   - `Result`: `Completed` when the workflow reaches **Report** without
     a halt; `Halted` when a subagent reports `Failed`; `Failed` on any
     other **Halt conditions** entry.

## Directives

- **Spawn first**: open with the subagent tool; skip all
  preflight—context gathering, environment discovery, path checks, guide
  or knowledge-base reads, and plan reviews.
- Prompt each subagent with the argument verbatim, or `No arguments`
  without one:
  - Never read, list, or expand file-path arguments.
  - Add no context, summaries, or instructions; each subagent gathers
    its own.
- Route only from each subagent's `Result` value.
- Re-spawn the same subagent once, with the same argument, on a result
  missing or outside the workflow's literals; route from the
  replacement's result; list the retry under `Findings`.
- Spawn only the subagents the workflow names.

## Constraints

- Limit tool calls to the subagent tool; run nothing else—no file reads,
  writes, listings, searches, shell or git commands, skill activation,
  or user prompts.
- Never run subagents in parallel or concurrently.
- **Halt conditions**: halt immediately; report per **Report**, listing
  the diagnostic under `Findings`:
  - A subagent `Failed` result.
  - A replacement subagent result missing or outside the workflow's
    literals.
  - A process failure (crash, timeout, `AgentError`).

## Verification

- Subagents ran one at a time, in workflow order.
- Every run, halted or not, ended in **Report**.
- Every tool call spawned a subagent.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`; a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, abort, or halt—with the
  result template as the final message; never end on progress narration.
- Set `Result` to exactly one template literal, verbatim; report an
  abort or halt lacking its own literal as `Failed`, with the reason
  under `Findings`.
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
  - [Terse list of findings from spawned subagents]
- **Summary**:
  - [Terse list of summary from spawned subagents]

> **Coverage Status** • `[scope]`
> **Result**: [Completed | Halted | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
