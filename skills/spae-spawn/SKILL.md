---
name: spae-spawn
description: >-
  Executes the build phase of the SPAE structured workflow autonomously.
user-invocable: false
---

# Spawn

## When to use

- The user wants to perform the build phase of the `SPAE` structured
  workflow autonomously.

## Goal

- Orchestrate `build` agents sequentially to complete tasks.
- Ensure `phase: verify` in `STATE.json` after all tasks complete.

## Input

Read `.spae/current/STATE.json` for phase, cursor, task registry, and
metrics.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Workflow

1. **Validate State**: Verify `STATE.json` has `phase: build` and at
   least one remaining task. Halt on malformed or missing `STATE.json`.
2. **Orchestration Loop**: For each remaining task in registry order:
   - a. **Read**: Read `active_task_id` from `STATE.json`.
   - b. **Spawn**: Use the subagent tool to invoke the `build` subagent
     and do nothing else. Don't pass any arguments or parameters to the
     `build` agent.
   - c. **Wait**: Await `build` agent's completion and result.
   - d. **Verify**: Re-read `STATE.json`. Confirm the task from step 2a
     shows `done` in the registry. If it remains `todo` or
     `in_progress`, halt immediately.
   - e. **Blocker**: On `Failed` status or any process failure, halt
     immediately and surface the error.
3. **Finalize Phase**: Confirm `STATE.json` shows `phase: verify`. Emit
   the final completion feedback.

## Directives

- Limit actions entirely to orchestration.
- Always use the subagent tool for subagent invocation.
- Spawn a new `build` agent for each task.
- Trust `STATE.json` over subagent result.
- Halt immediately on subagent `Failed` status or any process failure
  (crash, timeout, `AgentError`).
- List of agents permitted to invoke:
  - `build`

## Constraints

- Restrict your activities to:
  - Reading `.spae/current/STATE.json`.
  - Using the subagent tool to invoke the `build` subagent.
- Never write to any project file.
- Never activate skills.
- Never invoke agents outside the permitted list.
- Never make commits.
- Never run `subagents` in parallel or concurrently.
- Never prompt the user for decisions mid-run; let blockers halt
  execution.
- Never perform activities beyond subagent invocation, state tracking,
  and reporting.

## Verification

- Verify that all tasks show `done` state upon completion.
- Confirm the `workstream` advanced to `phase: verify`.
- Confirm immediate halt when a `subagent` reports a blocker or fails.

## Result directives

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

> **`SPAE` Spawn** • `[workstream]`
> **Result**: [Completed | Halted | Failed]
> **Halted at**: `[Task ID]`  _(if halted)_
> **Remaining**: [Y] tasks    _(if halted)_
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
