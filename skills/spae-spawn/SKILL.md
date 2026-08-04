---
name: spae-spawn
description: >-
  Executes the build phase of the SPAE structured workflow autonomously,
  cycling build, check, and fix per task.
user-invocable: false
---

# Spawn

## When to use

- The user wants to perform the build phase of the `SPAE` structured
  workflow autonomously.

## Goal

- Spawn the subagent matching the current `STATE.json` phase, looped
  until every task completes.
- Ensure `phase: verify` in `STATE.json` once the loop exits.

## Input

Read `.spae/current/STATE.json` for phase, cursor, and task registry.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and
phase snapshots.

## Phase-agent map

Every phase maps to exactly one subagent, spawned the same way
regardless of phase:

| `phase` | Subagent |
| ------- | -------- |
| `build` | `build`  |
| `check` | `check`  |
| `fix`   | `fix`    |

## Workflow

1. **Validate State**: Confirm `STATE.json` has `phase` in `"build"`,
   `"check"`, `"fix"` and a populated `cursor.active_task_id`. Halt on
   malformed or missing `STATE.json`, or an unrecognized `phase`.
2. **Dispatch Loop**:
   - Re-read `.spae/current/STATE.json`; record `phase`.
   - Exit on `phase: "verify"`.
   - Halt immediately if `phase` matches none of the phase-agent map's
     rows.
   - Spawn the subagent the map names for the recorded `phase`, no
     arguments.
   - Await completion; halt immediately on `Failed` status or any
     process failure (crash, timeout, `AgentError`).
   - Re-read `.spae/current/STATE.json`; halt immediately if `phase`
     matches the value recorded at the start of this iteration.
   - Repeat step 2.
3. **Finalize Phase**: Confirm `STATE.json` shows `phase: "verify"`.
   Emit the final completion feedback.

## Directives

- Limit actions entirely to orchestration.
- Always use the subagent tool for subagent invocation.
- Trust `STATE.json` over subagent result.
- Halt immediately on subagent `Failed` status or any process failure
  (crash, timeout, `AgentError`).
- List of agents permitted to invoke:
  - `build`
  - `check`
  - `fix`

## Constraints

- Restrict your activities to:
  - Reading `.spae/current/STATE.json`.
  - Using the subagent tool to spawn agents the phase-agent map names.
- Never write to any project file.
- Never activate skills.
- Never invoke agents outside the permitted list.
- Never make commits.
- Never run `subagents` in parallel or concurrently.
- Never prompt the user for decisions mid-run; let failures halt
  execution.
- Never perform activities beyond subagent invocation, state tracking,
  and reporting.

## Verification

- Confirm every spawned subagent's phase matches the phase-agent map at
  spawn time.
- Confirm `phase` changes on every iteration; halt on a stalled phase.
- Confirm all tasks show `done` state upon completion.
- Confirm the `workstream` advanced to `phase: verify`.
- Confirm zero project writes from the orchestration agent itself.

## Result directives

- **Minimum** words. **Maximum** signal.
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
