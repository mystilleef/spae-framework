---
name: spae-orchestrate
description: >-
  Orchestrate SPAE subagents sequentially through the structured
  workflow and lifecycle.
user-invocable: false
argument-hint: "[optional-proposal]"
---

# Orchestrate `SPAE`

## When to use

- The user wants to perform all phases of the `SPAE` structured workflow
  autonomously.

## Goal

- Spawn appropriate `subagents` sequentially based on `STATE.json`
  status and phase.
- Stop the workflow successfully upon completion, or halt immediately on
  errors.

## Input

Read `.spae/current/STATE.json` to resolve the current execution phase
and cursor. Accept an optional argument, the proposal, during initial
execution.

## `STATE.json`

See `references/STATE.md` for field reference, directives, and
snapshots.

## Workflow

1. **Resolve Workstream**:
   - Locate `.spae/current/STATE.json`.
   - If missing:
     - Halt if the user provided no proposal argument.
     - If provided, immediately spawn `spec` agent passing the proposal.
   - If present, proceed to step 2.
2. **Orchestrate Phase**:
   - Re-read `.spae/current/STATE.json` before each step.
   - Match `phase` to select the subagent:
     - `spec`:
       - First run with a command-line proposal argument: Immediately
         spawn `spec` agent with the proposal.
       - Otherwise (for example, revision cycles): Immediately spawn
         `spec` agent without arguments.
     - `plan`: Immediately spawn `plan` agent without arguments.
     - `inspect`: Immediately spawn `inspect` agent without arguments.
     - `build`:
       - Loop through remaining tasks in registry order.
       - Immediately spawn `build` agent without arguments for the
         active task.
       - Re-read `STATE.json` after each task finishes.
       - Halt if the task fails, remains unfinished, or reports a
         blocker.
     - `verify`:
       - Immediately spawn `verify` agent without arguments.
       - Re-read `STATE.json` after completion.
       - Handle outcomes:
         - Pass (`phase: done` or `status: completed` or missing
           symlink): Complete successfully.
         - Unsuccessful or blocked (`phase: spec` and
           `status: revision_required`): Restart the cycle by spawning
           `spec` agent without arguments.
         - Failed (agent crash, timeout, or explicit `Failed` status):
           Halt immediately and surface the error.
3. **Wait & Resume**:
   - Await each spawned `subagent`'s result.
   - Proceed sequentially; run no phases or tasks in parallel.
4. **Exceptional Conditions**:
   - Halt immediately on any `subagent` timeout, crash, or explicit
     blocker.
5. **Finalize**:
   - Emit execution summary upon workflow completion or halt.

## Directives

- Always use the subagent tool for subagent invocation.
- Rely only on `STATE.json` for all orchestration decisions.
- Operate strictly in read-only mode; make no file writes.
- Trust the machine-readable state file over subagent output text.
- When verify routes back to spec, continue the loop by spawning `spec` agent without arguments.
- List of agents permitted to invoke:
  - `spec`
  - `plan`
  - `inspect`
  - `build`
  - `verify`

## Constraints

- Perform orchestration only; never edit codebase files, tests, or
  documentation.
- Restrict your activities to:
  - Using the `subagent` tool to spawn relevant agents to orchestrate
    the `SPAE` workflow.
  - Reading `STATE.json` to orchestrate the `SPAE` workflow.
- Never run `subagents` in parallel or concurrently.
- Never activate skills.
- Never invoke agents outside the permitted list.
- Never prompt the user for decisions mid-run; let blockers halt
  execution.

## Verification

- Confirm successful sequential spawning of all required phase agents.
- Confirm automatic recovery/restart when verification fails.
- Confirm zero project writes from the orchestration agent itself.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Prefer lists, and sub-lists, over long paragraphs and sentences.
- Strictly follow the result template below.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of orchestration actions taken]
- **Files**:
  - [Terse list of files read]
- **Findings**:
  - [Terse list of observations, blockers, or failures]
- **Summary**:
  - [Terse summary of the workstream outcome]

> **`SPAE` Orchestrate** • `[workstream]`
> **Result**: [Completed | Halted | Failed]
> **Halted at**: `[Phase / Task ID]`  _(if halted)_
> **Reason**: [Terse explanation]     _(if halted)_
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
