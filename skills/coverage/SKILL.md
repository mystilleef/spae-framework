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

1. **Testing Loop**:
   - Immediately use the `subagent` tool to spawn a `test` `subagent`
     (pass optional arguments).
   - Await test result.
   - If `subagent` returns `No Gaps` status, exit loop and finish.
   - If `subagent` returns `Failed` status, halt immediately and surface
     the error.
   - Loop back to spawn another `test` `subagent` if the previous pass
     returns `Improved`.
2. **Report**: Emit execution summary.

## Directives

- Always use the subagent tool for subagent invocation.
- Pass the optional files argument directly to the `test` `subagent`.
- Rely on `subagent` status blocks to direct the loop.
- Halt immediately upon `subagent` timeout, crash, or error status.
- List of agents permitted to invoke:
  - `test`

## Constraints

- Restrict your activities to:
  - Using the `subagent` tool to spawn `test` agents to advance the
    workflow.
  - Using agent results to direct the loop or advance the workflow.
- Perform orchestration only; never edit codebase files, tests, or
  documentation.
- Operate strictly in read-only mode; make no file writes.
- Never run `subagents` in parallel or concurrently.
- Never activate skills.
- Never invoke agents outside the permitted list.
- Never prompt the user for decisions mid-run; let blockers halt
  execution.

## Verification

- Confirm sequential execution of `test` `subagents`.
- Confirm loop termination when `subagents` return `No Gaps`.
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
  - [Terse summary of the coverage process]

> **Coverage Status** • `[scope]`
> **Result**: [Completed | Halted | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
