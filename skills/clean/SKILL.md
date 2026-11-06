---
name: clean
description: >-
  Orchestrates purification and refactoring agents sequentially.
user-invocable: false
argument-hint: "[optional: files or focus area]"
---

# Clean

## When to use

- The user wants to clean smelly code autonomously using the `purify`
  and `refactor` agents.

## Goal

- Run purification and refactoring `subagents` sequentially to clean
  target code.

## Input

- Accept optional arguments (file or folder paths).

## Workflow

Halt on any **Halt conditions** entry after every spawn.

1. **Purification Loop**:
   - Spawn a `purify` subagent with the optional argument; await its
     result.
   - `Complete`: repeat step 1.
   - `No Changes`: proceed to step 2.
2. **Refactoring Loop**:
   - Spawn a `refactor` subagent with the optional argument; await its
     result.
   - `Complete`: repeat step 2.
   - `No Changes`: proceed to step 3.
3. **Report**: emit the result per **Result directives**:
   - `Result`: `Completed` when the workflow reaches **Report** without
     a halt; `Halted` when a subagent reports `Failed`; `Failed` on any
     other **Halt conditions** entry.

## Directives

- Always use the subagent tool for subagent invocation.
- Pass the argument verbatim to each subagent; never read or expand
  file-path arguments.
- Route only from each subagent's `Result` value.
- Spawn only the subagents the workflow names.

## Constraints

- Restrict activities to spawning subagents, reading their results, and
  reporting; never write files, run git operations, activate skills, or
  prompt the user mid-run.
- Never run subagents in parallel or concurrently.
- **Halt conditions**: halt immediately; report per **Report**, listing
  the diagnostic under `Findings`:
  - A subagent `Failed` result.
  - A subagent result missing or outside the workflow's literals.
  - A process failure (crash, timeout, `AgentError`).

## Verification

- Subagents ran one at a time, in workflow order.
- Every run, halted or not, ended in **Report**.
- The orchestrator wrote no file.

## Result directives

- **Minimum** words. **Maximum** signal.
- Return the final execution status block.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions from spawned subagents]
- **Files**:
  - [Terse list of files affected by spawned subagents]
- **Findings**:
  - [Terse list of findings from spawned subagents]
- **Summary**:
  - [Terse list of summary from spawned subagents]

> **Clean Status** • `[scope]`
> **Result**: [Completed | Halted | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
