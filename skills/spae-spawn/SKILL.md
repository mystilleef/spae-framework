---
name: spae-spawn
description: >-
  Execution Orchestrator for the `SPAE` framework. Spawns the `build`,
  `check`, and `fix` subagents per task until the `workstream` reaches
  `phase: verify`.
user-invocable: false
---

# Spawn (`SPAE`)

## When to use

- The user wants to perform the build phase of the `SPAE` structured
  workflow autonomously.

## Goal

- Spawn the subagent matching the current `STATE.json` phase, looped
  until the `workstream` reaches `phase: verify`.

## Input

Read `.spae/current/STATE.json` for phase, cursor, and task registry.

## `STATE.json`

See `references/STATE.md` for the field reference, directives, and phase
snapshots.

## Phase-agent map

Every phase maps to exactly one subagent, spawned the same way
regardless of phase:

| `phase` | Subagent |
| ------- | -------- |
| `build` | `build`  |
| `check` | `check`  |
| `fix`   | `fix`    |

## Workflow

After each read, check the exit first; halt on any **Halt conditions**
entry after every non-exit read and every spawn.

1. **Dispatch Loop**:
   - Read `.spae/current/STATE.json`; record `phase`.
   - Exit on `phase: "verify"`.
   - Spawn the subagent the map names for `phase`, no arguments; await
     completion.
   - Repeat step 1.
2. **Report**: emit the result per **Result directives**:
   - `Result`: `Completed` on an exit; `Halted` when a subagent reports
     `Failed` or leaves `phase` unchanged; `Failed` on any other **Halt
     conditions** entry.

## Directives

- Always use the subagent tool for subagent invocation.
- Route only from `STATE.json` `phase`; trust it over subagent output
  text.
- Spawn only the subagents the phase-agent map names.

## Constraints

- Restrict activities to spawning subagents, reading
  `.spae/current/STATE.json`, and reporting; never write files, run git
  operations, activate skills, or prompt the user mid-run.
- Never run subagents in parallel or concurrently.
- **Halt conditions**: halt immediately; report per **Report** with
  `Halted at` and `Reason`:
  - `STATE.json` missing at a loop read, or holding unparseable JSON
    syntax.
  - `phase` matching no phase-agent map row.
  - `cursor.active_task_id` missing.
  - `phase` unchanged since the previous spawn.
  - A subagent `Failed` result or process failure (crash, timeout,
    `AgentError`).

## Verification

- Every spawn matched the phase-agent map row for the recorded `phase`.
- The run ended on an exit or a **Halt conditions** entry.
- The orchestrator wrote no file.

## Result directives

- **Minimum** words. **Maximum** signal.
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

> **`SPAE` Spawn** • `[workstream]`
> **Result**: [Completed | Halted | Failed]
> **Halted at**: `[Task ID]`  _(unless completed)_
> **Reason**: [Terse explanation]     _(unless completed)_
> **Remaining**: [Y] tasks    _(unless completed)_
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
