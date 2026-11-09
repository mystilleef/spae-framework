---
name: spae-orchestrate
description: >-
  Lifecycle Orchestrator for the `SPAE` framework. Spawns the subagent
  matching each `STATE.json` phase until the `workstream` completes.
user-invocable: false
argument-hint: "[optional-proposal]"
---

# Orchestrate (`SPAE`)

## When to use

- The user wants to perform all phases of the `SPAE` structured workflow
  autonomously.

## Goal

- Spawn the subagent matching the current `STATE.json` phase, looped
  until the `workstream` completes.

## Input

Read `.spae/current/STATE.json` for `phase` and `workstream`. Accept an
optional argument, the proposal, during initial execution.

## Phase-agent map

Every phase maps to exactly one subagent, spawned the same way
regardless of phase:

| `phase`   | Subagent  |
| --------- | --------- |
| `spec`    | `spec`    |
| `plan`    | `plan`    |
| `inspect` | `inspect` |
| `build`   | `build`   |
| `check`   | `check`   |
| `fix`     | `fix`     |
| `verify`  | `verify`  |

## Workflow

After each read, check the exit first; halt on any **Halt conditions**
entry after every non-exit read and every spawn.

1. **Resolve Workstream**:
   - `.spae/current/STATE.json` present: proceed to step 2; list an
     unused proposal argument under `Findings`.
   - Absent, proposal provided: spawn `spec` with the proposal; await
     completion; proceed to step 2.
2. **Dispatch Loop**:
   - Read `.spae/current/STATE.json`; record `phase`.
   - Exit on `phase: "done"`, or on a missing file after a `verify`
     spawn.
   - Spawn the subagent the map names for `phase`, no arguments; await
     completion.
   - Repeat step 2.
3. **Report**: emit the result per **Result directives**:
   - `Result`: `Completed` on an exit; `Halted` when a subagent reports
     `Failed` or leaves `phase` unchanged; `Failed` on any other **Halt
     conditions** entry.

## Directives

- **Spawn first**: open with the subagent tool, preceded only by the
  `STATE.json` read; skip all preflight—context gathering, environment
  discovery, path checks, guide or knowledge-base reads, and plan
  reviews.
- Route only from `STATE.json` `phase`; trust it over subagent output
  text.
- Spawn only the subagents the phase-agent map names.
- Prompt the bootstrap `spec` spawn with the proposal argument verbatim,
  and every loop spawn with `No arguments`:
  - Never reuse the proposal on later iterations, or read, list, or
    expand file-path arguments.
  - Add no context, summaries, or instructions; each subagent gathers
    its own.

## Constraints

- Limit tool calls to the subagent tool and `.spae/current/STATE.json`
  reads; run nothing else—no other reads, file writes, listings,
  searches, shell or git commands, skill activation, or user prompts.
- Never run subagents in parallel or concurrently.
- **Halt conditions**: halt immediately; report per **Report** with
  `Halted at` and `Reason`:
  - `.spae/current/STATE.json` absent at start, with no proposal
    argument.
  - `STATE.json` missing at a loop read, or holding unparseable JSON
    syntax.
  - `phase` matching no phase-agent map row.
  - `phase` unchanged since the previous spawn.
  - A subagent `Failed` result or process failure (crash, timeout,
    `AgentError`).

## Verification

- Every spawn matched the phase-agent map row for the recorded `phase`.
- The run ended on an exit or a **Halt conditions** entry.
- Every tool call spawned a subagent or read `STATE.json`.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`; a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, abort, or halt—with the
  result template as the final message; never end on progress narration.
- Set `Result` to exactly one template literal, verbatim; report an
  abort or halt lacking its own literal as `Failed`, with the reason
  under `Findings`.
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

> **`SPAE` Orchestrate** • `[workstream]`
> **Result**: [Completed | Halted | Failed]
> **Halted at**: `[Phase / Task ID]`  _(unless completed)_
> **Reason**: [Terse explanation]     _(unless completed)_
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
