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
   - e. **Blocker**: If the subagent reports a blocker or fails, halt
     immediately and surface the error.
3. **Finalize Phase**: Confirm `STATE.json` shows `phase: verify`. Emit
   the final completion feedback.

## Directives

- Limit actions entirely to orchestration.
- Always use the subagent tool for subagent invocation.
- Spawn a new `build` agent for each task.
- Trust `STATE.json` over subagent result.
- Halt execution immediately on any timeout, crash, state mismatch, or
  explicit blocker.
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

## Verification

- Verify that all tasks show `done` state upon completion.
- Confirm the `workstream` advanced to `phase: verify`.
- Confirm immediate halt when a `subagent` reports a blocker or fails.

## Result

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
  - [Terse list of key gaps, risks, blockers, or notable observations]
- **Summary**:
  - [Terse summary of the execution outcome]

> **`SPAE` Spawn** • `[workstream]`
> **Result**: [Completed | Halted | Failed]
> **Halted at**: `[Task ID]`  _(if halted)_
> **Remaining**: [Y] tasks    _(if halted)_
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
