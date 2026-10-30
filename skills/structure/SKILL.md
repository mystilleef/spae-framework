---
name: structure
description: >-
  Orchestrates refactoring agents sequentially to fix structural
  violations.
user-invocable: false
argument-hint: "[optional: files or focus area]"
---

# Structure

## When to use

- The user wants to fix structural violations autonomously using the
  `refactor` agent.

## Goal

- Run refactoring `subagents` sequentially to fix structural violations
  in target code.

## Input

- Accept optional arguments (file or folder paths).

## Workflow

1. **Refactoring Loop**:
   - Immediately use the `subagent` tool to spawn a `refactor`
     `subagent` (pass optional arguments).
   - Await refactoring result.
   - If `subagent` returns `No Changes` status, exit loop and finish.
   - On `Failed` status or any process failure, halt immediately and
     surface the error.
   - Loop back to spawn another `refactor` `subagent` if the previous
     pass returns `Complete`.
2. **Report**: emit execution summary.

## Directives

- Always use the subagent tool for subagent invocation.
- Pass the optional argument verbatim to the `refactor` subagent without
  reading or expanding file paths.
- Rely on `subagent` status blocks to direct the loop.
- Halt immediately on subagent `Failed` status or any process failure
  (crash, timeout, `AgentError`).
- List of agents permitted to invoke:
  - `refactor`

## Constraints

- Restrict activities to:
  - Using the `subagent` tool to spawn `refactor` agents to advance the
    workflow.
  - Using agent results to direct the loop or advance the workflow.
- Perform orchestration only. Never edit codebase files, tests, or
  documentation.
- Operate strictly in read-only mode with zero file writes.
- Never run `subagents` in parallel or concurrently.
- Never activate skills.
- Never invoke agents outside the permitted list.
- Never prompt the user for decisions mid-run. Let blockers halt
  execution.
- Never perform activities beyond subagent invocation, state tracking,
  and reporting.

## Verification

- Confirm sequential execution of `refactor` `subagents`.
- Confirm loop termination when `subagents` return `No Changes`.
- Confirm immediate halt when a `subagent` returns `Failed`.
- Confirm zero writes from the orchestration agent itself.

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

> **Structure Status** • `[scope]`
> **Result**: [Completed | Halted | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
