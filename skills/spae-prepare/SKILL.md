---
name: spae-prepare
description: >-
  Orchestrate SPAE subagents sequentially through the spec, plan, and
  inspect phases of the structured workflow.
user-invocable: false
argument-hint: "[optional-proposal]"
---

# Prepare `SPAE`

## When to use

- The user wants to run the preparatory phases of the `SPAE` structured
  workflow autonomously: spec, plan, and inspect.

## Goal

- Spawn `spec`, `plan`, and `inspect` subagents sequentially based on
  `STATE.json` status and phase.
- Halt successfully when the `workstream` reaches `phase: build`, or
  halt immediately on errors.

## Input

Read `.spae/current/STATE.json` to resolve the current execution phase
and cursor. Accept an optional argument, the proposal, during initial
execution.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and
phase snapshots.

## Phase-agent map

Every phase maps to exactly one subagent, spawned the same way
regardless of phase:

| `phase`   | Subagent  |
| --------- | --------- |
| `spec`    | `spec`    |
| `plan`    | `plan`    |
| `inspect` | `inspect` |

## Workflow

1. **Resolve Workstream**:
   - Locate `.spae/current/STATE.json`.
   - Missing, no proposal argument: halt.
   - Missing, proposal provided: spawn `spec` with the proposal; await
     completion; proceed to step 2.
   - Present: proceed to step 2 without spawning.
2. **Dispatch Loop**:
   - Re-read `.spae/current/STATE.json`; record `phase`.
   - Exit on `phase: "build"`.
   - Halt immediately if `phase` matches none of the phase-agent map's
     rows.
   - Spawn the subagent the map names for the recorded `phase`, no
     arguments.
   - Await completion; halt immediately on `Failed` status or any
     process failure (crash, timeout, `AgentError`).
   - Re-read `.spae/current/STATE.json`; halt immediately if `phase`
     matches the value recorded at the start of this iteration.
   - Repeat step 2.
3. **Finalize**: Emit the execution summary.

## Directives

- Always use the subagent tool for subagent invocation.
- Rely only on `STATE.json` for all orchestration decisions.
- Operate strictly in read-only mode; make no file writes.
- Trust the machine-readable state file over subagent output text.
- Pass the proposal argument verbatim to the bootstrap `spec` spawn
  only; never reuse it on later iterations, and never read or expand
  file-path arguments.
- Halt immediately on subagent `Failed` status or any process failure
  (crash, timeout, `AgentError`).
- List of agents permitted to invoke:
  - `spec`
  - `plan`
  - `inspect`

## Constraints

- Perform orchestration only; never edit codebase files, tests, or
  documentation.
- Restrict your activities to:
  - Using the `subagent` tool to spawn relevant agents.
  - Reading `STATE.json` to orchestrate the workflow.
- Never run `subagents` in parallel or concurrently.
- Never activate skills.
- Never invoke agents outside the permitted list.
- Never prompt the user for decisions mid-run; let failures halt
  execution.
- Never perform activities beyond subagent invocation, state tracking,
  and reporting.

## Verification

- Confirm every spawned subagent's phase matches the phase-agent map at
  spawn time.
- Confirm `phase` changes on every iteration; halt on a stalled phase.
- Confirm sequential spawning of `spec`, `plan`, and `inspect` agents.
- Confirm the `workstream` reaches `phase: build` upon completion.
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

> **`SPAE` Prepare** • `[workstream]`
> **Result**: [Completed | Halted | Failed]
> **Halted at**: `[Phase]`  _(if halted)_
> **Reason**: [Terse explanation]     _(if halted)_
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
