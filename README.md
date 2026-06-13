# State-persistent atomic execution framework

The `SPAE` framework provides a cross-platform, structured, agent-first
workflow for AI agent harnesses.

It follows a five-phase workflow that produces consistent, high-quality,
predictable `LLM` outputs, even when using lower-tier agents.

**spec → plan → inspect → build → verify**

## What `SPAE` does

`SPAE` prevents context drift, hallucination, and scope creep by:

- Decomposing requests into atomic, independently verifiable tasks
- Persisting state in external artifacts (not conversational memory)
- Enforcing phase boundaries so each agent reads only what it needs
- Allowing any harness (Gemini, Claude, OpenAI, Pi, OpenCode, Codex) to
  resume work at any point

---

## Framework design

- **Harness agnostic**—use any combination of Gemini, Claude, OpenAI,
  Pi, OpenCode, or Codex at each phase
- **Zero-knowledge resumption**—any agent resumes any `workstream` by
  reading the artifacts
- **Atomic execution**—every task stays small enough to verify in a
  single cycle
- **Human oversight**—each phase requires explicit invocation; use
  orchestration agents to automate on supported harnesses

---

## Usage

Invoke any agent with `/run <agent> [argument]` (or `$run` in Codex).
Agents encapsulate skills and carry out each phase. See each agent's
invocation for its arguments.

| Agent     | Invocation             |
| --------- | ---------------------- |
| `spec`    | `/run spec <proposal>` |
| `plan`    | `/run plan`            |
| `inspect` | `/run inspect`         |
| `build`   | `/run build`           |
| `verify`  | `/run verify`          |

---

## Workflow

Run phases in order. Each agent reads only its designated inputs and
writes only its designated outputs.

| Phase | Agent                  | Purpose                                       |
| ----- | ---------------------- | --------------------------------------------- |
| 1     | `/run spec <proposal>` | Distill requirements into `SPEC.md`           |
| 2     | `/run plan`            | Decompose `SPEC.md` into an atomic task graph |
| 3     | `/run inspect`         | Perform gap analysis and optimize `PLAN.md`   |
| 4     | `/run build`           | Carry out tasks from `PLAN.md`                |
| 5     | `/run verify`          | Verify implementation against `SPEC.md`       |

Choose one execution mode per `workstream` after `/run inspect`:

- `/run build`—one task per cycle; best for complex or high-risk plans
- `/run tdd`—failing-test-first cycle; best for behavioral changes
- `/run execute`—all tasks at once; best for small, low-risk plans

If `/run verify` finds gaps, it creates `VERIFY.md` and resets the cycle
to `/run spec`. Repeat until `/run verify` passes.

---

## Orchestration (`Pi` only)

> **Orchestration agents and skills are currently only supported in the
> Pi harness.** Orchestration requires nested subagent support; testing
> covered Pi only. Pi users must install
> [mystilleef/pi-subagent](https://github.com/mystilleef/pi-subagent).

Orchestration agents spawn and drive nested `subagents` autonomously,
completing multi-agent workflows without human intervention at each
step.

---

### **SPAE** orchestrators

| Agent         | Invocation                      | Purpose                                               |
| ------------- | ------------------------------- | ----------------------------------------------------- |
| `orchestrate` | `/run orchestrate [<proposal>]` | Run all `SPAE` phases autonomously from current state |
| `prepare`     | `/run prepare [<proposal>]`     | Run preparatory phases only—loops spec, plan, inspect |
| `spawn`       | `/run spawn`                    | Run the build phase only—loops all remaining tasks    |

**`orchestrate`** reads `STATE.json`, determines the current phase, and
spawns the appropriate `SPAE` agent sequentially until the workflow
completes or the agent surfaces a blocker. Pass a proposal on first run
to seed the `spec` phase.

**`prepare`** runs the preparatory phases—spec, plan, and
inspect—autonomously until the workflow reaches the `build` phase. Pass
a proposal on first run to seed the `spec` phase.

**`spawn`** targets the build phase exclusively—iterates all remaining
tasks and spawns a `build` agent per task until the phase advances to
`verify`.

---

### Non-**SPAE** orchestrators

| Agent      | Invocation      | Purpose                                          |
| ---------- | --------------- | ------------------------------------------------ |
| `coverage` | `/run coverage` | Spawn test agents to address code coverage gaps  |
| `clean`    | `/run clean`    | Run `purify` then `refactor` agents sequentially |

---

## Post-verification

After `/run verify` passes, run these agents to refine and ship the
implementation. Follow the order below for best results.

| Order | Agent           | Purpose                             |
| ----- | --------------- | ----------------------------------- |
| 1     | `/run test`     | Fill test coverage gaps             |
| 2     | `/run purify`   | Simplify and optimize code          |
| 3     | `/run refactor` | Improve structure and clarity       |
| 4     | `/run review`   | Review for correctness and style    |
| 5     | `/run commit`   | Stage and commit the implementation |

**Pi only.** `/run test` and `/run clean` are orchestration agents and
require Pi. `/run clean` replaces steps 2–3 by running `purify` then
`refactor` automatically.

---

## Utility agents

These agents run independently of the `SPAE` workflow. Use them at any
point to avoid polluting the main conversation context.

| Agent               | Purpose                                           |
| ------------------- | ------------------------------------------------- |
| `/run work`         | Run ad-hoc tasks in an isolated session           |
| `/run query`        | Answer questions or research without side effects |
| `/run troubleshoot` | Diagnose and fix issues                           |

---

## Artifacts

All artifacts live in `.spae/<workstream>/`. Never commit this
directory—add `.spae/` to `.gitignore`.

| File         | Purpose                                            |
| ------------ | -------------------------------------------------- |
| `STATE.json` | Execution cursor—tracks phase and active task      |
| `SPEC.md`    | Normalized requirements—immutable during execution |
| `PLAN.md`    | Atomic task graph—immutable during execution       |
| `VERIFY.md`  | Ephemeral signal—created when verification fails   |

---

## Prerequisites

- Harness must support the
  [Agent Skills specification](https://agentskills.io/home)
- Subagent support recommended for all harnesses
- Nested subagent support required for orchestration (Pi only)
- Custom commands, skills, or prompts recommended
- Pi users must install
  [mystilleef/pi-subagent](https://github.com/mystilleef/pi-subagent)

---

## Installation

### Skills

Copy the `skills/` directory to `~/.agents/skills`. Skills carry out
each phase and work with any compliant harness.

### Agents

Agents wrap skills in isolated sessions. Each harness requires its own
agent files.

| Harness  | Source             | Destination                  |
| -------- | ------------------ | ---------------------------- |
| Claude   | `claude/agents/`   | `~/.claude/agents/`          |
| Gemini   | `gemini/agents/`   | `~/.gemini/agents/`          |
| Pi       | `pi/agents/`       | `~/.pi/agent/agents/`        |
| OpenCode | `opencode/agents/` | `~/.config/opencode/agents/` |
| Codex    | `codex/agents/`    | `~/.codex/agents/`           |

### Run command

The `/run` command orchestrates subagent invocation. Invoke agents as
`/run <agent> [argument]`. Format varies by harness.

| Harness  | Notes                                                                     |
| -------- | ------------------------------------------------------------------------- |
| Claude   | Copy `claude/commands/` to `~/.claude/commands/`                          |
| Gemini   | Copy `gemini/commands/` to `~/.gemini/commands/`                          |
| Pi       | Install `mystilleef/pi-subagent`; includes a built-in `/run` command      |
| OpenCode | Copy `opencode/commands/` to `~/.config/opencode/commands/`               |
| Codex    | Copy `codex/skills/` to `~/.codex/skills/`; use `$run` in place of `/run` |
