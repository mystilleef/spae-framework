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
   - On `Failed` status or any process failure, halt immediately and
     surface the error.
   - Loop back to spawn another `test` `subagent` if the previous pass
     returns `Improved`.
2. **Report**: Emit execution summary.

## Directives

- Always use the subagent tool for subagent invocation.
- Pass the optional argument verbatim to the `test` subagent; never read
  or expand file-path arguments.
- Rely on `subagent` status blocks to direct the loop.
- Halt immediately on subagent `Failed` status or any process failure
  (crash, timeout, `AgentError`).
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
- Never perform activities beyond subagent invocation, state tracking,
  and reporting.

## Verification

- Confirm sequential execution of `test` `subagents`.
- Confirm loop termination when `subagents` return `No Gaps`.
- Confirm immediate halt when a `subagent` returns `Failed`.
- Confirm zero writes from the orchestration agent itself.

## Result directives

- **Minimum** words. **Maximum** signal.
- Return the final execution status block.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
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
  - [Terse list of findings from spawned subagents]
- **Summary**:
  - [Terse list of summary from spawned subagents]

> **Coverage Status** • `[scope]`
> **Result**: [Completed | Halted | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
