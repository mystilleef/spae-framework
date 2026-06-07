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
   - If `subagent` returns `Failed` status, halt immediately and surface
     the error.
   - Loop back to spawn another `purify` `subagent` if the previous pass
     returns `Complete`.
2. **Refactoring Loop**:
   - Immediately use the `subagent` tool to spawn a `refactor`
     `subagent` (pass optional arguments).
   - Await refactoring result.
   - If `subagent` returns `No Changes` status, exit loop and finish.
   - If `subagent` returns `Failed` status, halt immediately and surface
     the error.
   - Loop back to spawn another `refactor` `subagent` if the previous
     pass returns `Complete`.

## Directives

- Always use the subagent tool for subagent invocation.
- Pass the optional files argument directly to both `subagents`.
- Rely on `subagent` status blocks to direct the loop.
- Halt immediately upon `subagent` timeout, crash, or error status.
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

## Verification

- Confirm sequential execution of `purify` and `refactor` `subagents`.
- Confirm loop termination when `subagents` return `No Changes`.
- Confirm immediate halt when a `subagent` returns `Failed`.
- Confirm zero writes from the orchestration agent itself.

## Result

- Return the final execution status block.
- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Strictly follow the result template below.
- Prefer lists, and sub-lists, over long paragraphs and sentences.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of files read]
- **Findings**:
  - [Terse list of `subagent` outcomes or errors]
- **Summary**:
  - [Terse summary of the cleanup process]

> **Clean Status** • `[scope]`
> **Result**: [Completed | Halted | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
