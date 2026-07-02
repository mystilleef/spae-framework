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

1. **Purification Loop**:
   - Immediately use the `subagent` tool to spawn a `purify` `subagent`
     (pass optional arguments).
   - Await purification result.
   - If `subagent` returns `No Changes` status, exit loop and proceed.
   - On `Failed` status or any process failure, halt immediately and
     surface the error.
   - Loop back to spawn another `purify` `subagent` if the previous pass
     returns `Complete`.
2. **Refactoring Loop**:
   - Immediately use the `subagent` tool to spawn a `refactor`
     `subagent` (pass optional arguments).
   - Await refactoring result.
   - If `subagent` returns `No Changes` status, exit loop and finish.
   - On `Failed` status or any process failure, halt immediately and
     surface the error.
   - Loop back to spawn another `refactor` `subagent` if the previous
     pass returns `Complete`.

## Directives

- Always use the subagent tool for subagent invocation.
- Pass the optional argument verbatim to both subagents; never read or
  expand file-path arguments.
- Rely on `subagent` status blocks to direct the loop.
- Halt immediately on subagent `Failed` status or any process failure
  (crash, timeout, `AgentError`).
- List of agents permitted to invoke:
  - `purify`
  - `refactor`

## Constraints

- Restrict your activities to:
  - Using the `subagent` tool to spawn agents.
  - Using agent results to direct the loop or advance the workflow.
- Perform orchestration only; never edit codebase files, tests, or
  documentation.
- Operate strictly in read-only mode.
- Perform purification to completion first, before starting refactoring.
- Never interleave purification with refactoring.
- Never run `subagents` in parallel or concurrently.
- Never activate skills.
- Never invoke agents outside the permitted list.
- Never prompt the user for decisions mid-run; let blockers halt
  execution.
- Never perform activities beyond subagent invocation, state tracking,
  and reporting.

## Verification

- Confirm sequential execution of `purify` and `refactor` `subagents`.
- Confirm loop termination when `subagents` return `No Changes`.
- Confirm immediate halt when a `subagent` returns `Failed`.
- Confirm zero writes from the orchestration agent itself.

## Result directives

- Return the final execution status block.
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
  - [Terse list of actions from spawned subagents]
- **Files**:
  - [Terse list of files affected by spawned subagents]
- **Findings**:
  - [Terse list of findings from spawned subagent]
- **Summary**:
  - [Terse list of summary from spawned subagents]

> **Clean Status** • `[scope]`
> **Result**: [Completed | Halted | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
