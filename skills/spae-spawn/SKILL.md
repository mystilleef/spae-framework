---
name: spae-spawn
description: >-
  Execution Orchestrator for the `SPAE` framework. Spawns the `build`, `check`,
  and `fix` subagents per task until the `workstream` reaches `phase: verify`.
user-invocable: false
---

# Spawn (`SPAE`)

## When to use

- The user wants to perform the build phase of the `SPAE` structured workflow
  autonomously.

## Goal

- Spawn the subagent matching the current `STATE.json` phase, looped until the
  `workstream` reaches `phase: verify`.

## Input

Read `.spae/current/STATE.json` for `phase`, `workstream`, `cursor`, and
`tasks`.

## Phase-agent map

Every phase maps to exactly one subagent, spawned the same way regardless of
phase:

| `phase` | Subagent |
| ------- | -------- |
| `build` | `build`  |
| `check` | `check`  |
| `fix`   | `fix`    |

## Workflow

After each read, check the exit first. Halt on any **Halt conditions** entry
after every non-exit read and every spawn.

1. **Dispatch Loop**:
   - Read `.spae/current/STATE.json` and record `phase`.
   - Exit on `phase: "verify"`.
   - Spawn the subagent the map names for `phase`, no arguments, and await
     completion.
   - Repeat step 1.
2. **Report**: emit the result per **Result directives**:
   - `Result`:
     - `Completed` on an exit.
     - `Halted` when a subagent reports `Failed` or leaves `phase` unchanged.
     - `Failed` on any other **Halt conditions** entry.

## Directives

- **Spawn first**: open with the subagent tool, preceded only by the
  `STATE.json` read. Skip all preflight—context gathering, environment
  discovery, path checks, guide reads, knowledge-base reads, and plan reviews.
- Route only from `STATE.json` `phase`, trusting it over subagent output text.
- Spawn only the subagents the phase-agent map names.
- Prompt every spawn with `No arguments`, adding no context, summaries, or
  instructions—each subagent gathers its own.
- **IMPORTANT:** Return the result to the caller.

## Constraints

- Limit tool calls to the subagent tool and `.spae/current/STATE.json` reads.
  Run nothing else—no other reads, file writes, listings, searches, shell
  commands, git commands, skill activation, or user prompts.
- Never run subagents in parallel or concurrently.
- **Halt conditions**: halt immediately and report per **Report** with
  `Halted at` and `Reason`:
  - `STATE.json` missing at a loop read, or holding unparseable JSON syntax.
  - `phase` matching no phase-agent map row.
  - `cursor.active_task_id` missing.
  - `phase` unchanged since the previous spawn.
  - A subagent `Failed` result or process failure (crash, timeout,
    `AgentError`).

## Verification

- Subagents ran one at a time, in workflow order.
- Every spawn matched the phase-agent map row for the recorded `phase`.
- The run ended on an exit or a **Halt conditions** entry.
- Every tool call spawned a subagent or read `STATE.json`.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`, so a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, early stop, or halt—with the result
  template as the final message, never on progress narration.
- Set `Result` to exactly one template literal, verbatim. Report an early stop
  or halt lacking its own literal as `Failed`, with the reason under `Findings`.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions from spawned subagents]
- **Files**:
  - [Terse list of files from spawned subagent results]
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
