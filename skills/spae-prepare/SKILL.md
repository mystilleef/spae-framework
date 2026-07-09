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

See `references/STATE.md` for field reference, directives, and
snapshots.

## Workflow

1. **GATE**:
   - Locate `.spae/current/STATE.json`.
   - If missing:
     - Halt if no proposal argument provided.
     - If provided, proceed to step 2.
   - If present, confirm `phase` is one of: `spec`, `plan`, `inspect`.
   - Halt immediately if `phase` is `build`, `verify`, `done`, or
     unrecognized.
2. **ORIENT**:
   - Goal: advance the `workstream` through `spec → plan → inspect` and
     halt when `STATE.json` shows `phase: build`.
   - Scope: orchestration only; no file writes.
3. **PLAN**:
   - Determine starting phase from `STATE.json`:
     - Missing with proposal provided: start at `spec`.
     - Present: start at the current `phase`.
4. **ACT**:
   - Re-read `.spae/current/STATE.json` before each spawn.
   - Match `phase` to select and spawn the subagent:
     - `spec`:
       - First run with a proposal argument: spawn `spec` agent with the
         proposal.
       - Otherwise: spawn `spec` agent without arguments.
     - `plan`: spawn `plan` agent without arguments.
     - `inspect`: spawn `inspect` agent without arguments.
   - Await each agent's completion before proceeding.
   - On `Failed` status or any process failure, halt immediately and
     surface the error.
   - Re-read `STATE.json` after each agent and loop to the next phase.
   - Stop looping when `STATE.json` shows `phase: build`.
5. **VERIFY**:
   - After each agent completes, confirm `STATE.json` phase advanced.
   - After `inspect` agent completes, confirm `phase: build`.
   - Halt immediately on phase mismatch.
   - On `Failed` status or any process failure, halt immediately and
     surface the error.
6. **PERSIST**:
   - No state writes; orchestration operates in read-only mode.
7. **REPORT**:
   - Emit execution summary upon completion or halt.

## Directives

- Always use the subagent tool for subagent invocation.
- Rely only on `STATE.json` for all orchestration decisions.
- Operate strictly in read-only mode; make no file writes.
- Trust the machine-readable state file over subagent output text.
- Pass the proposal argument verbatim to the `spec` subagent; never read
  or expand file-path arguments.
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
- Never prompt the user for decisions mid-run; let blockers halt
  execution.
- Never perform activities beyond subagent invocation, state tracking,
  and reporting.

## Verification

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
