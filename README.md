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
- Allowing any harness (Gemini, Claude, OpenAI) to resume work at any
  point

---

## Framework design

- **Harness agnostic**—use any combination of Gemini, Claude, OpenAI, or
  Codex at each phase
- **Zero-knowledge resumption**—any agent resumes any `workstream` by
  reading the artifacts
- **Atomic execution**—every task stays small enough to verify in a
  single cycle
- **Human oversight**—you invoke each phase; nothing progresses
  automatically

---

## Usage

Invoke any agent with `/run <agent> [argument]`. Agents encapsulate
skills and carry out each phase. For SPAE agents, only `spec` takes an
argument—a description of the task.

| Agent     | Invocation                |
| --------- | ------------------------- |
| `spec`    | `/run spec <requirement>` |
| `plan`    | `/run plan`               |
| `inspect` | `/run inspect`            |
| `build`   | `/run build`              |
| `tdd`     | `/run tdd`                |
| `execute` | `/run execute`            |
| `verify`  | `/run verify`             |

---

## Workflow

Run phases in order. Each agent reads only its designated inputs and
writes only its designated outputs.

| Phase | Agent                     | Purpose                                       |
| ----- | ------------------------- | --------------------------------------------- |
| 1     | `/run spec <requirement>` | Distill requirements into `SPEC.md`           |
| 2     | `/run plan`               | Decompose `SPEC.md` into an atomic task graph |
| 3     | `/run inspect`            | Perform gap analysis and optimize `PLAN.md`   |
| 4     | `/run build`              | Carry out tasks from `PLAN.md`                |
| 5     | `/run verify`             | Verify implementation against `SPEC.md`       |

Choose one execution mode per `workstream` after `/run inspect`:

- `/run build`—one task per cycle; best for complex or high-risk plans
- `/run tdd`—failing-test-first cycle; best for behavioral changes
- `/run execute`—all tasks at once; best for small, low-risk plans

If `/run verify` finds gaps, it creates `VERIFY.md` and resets the cycle
to `/run spec`. Repeat until `/run verify` passes.

---

## Post-verification

After `/run verify` passes, run these agents to refine and ship the
implementation. Follow the order below for best results.

| Order | Agent           | Purpose                             |
| ----- | --------------- | ----------------------------------- |
| 1     | `/run coverage` | Fill test coverage gaps             |
| 2     | `/run purity`   | Simplify and optimize code          |
| 3     | `/run refactor` | Improve structure and clarity       |
| 4     | `/run review`   | Review for correctness and style    |
| 5     | `/run commit`   | Stage and commit the implementation |

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
- Subagent support recommended
- Custom commands or prompts recommended

---

## Installation

### Skills

Copy the `skills/` directory to `~/.agents/skills`. Skills carry out
each phase and work with any compliant harness.

### Agents

Agents wrap skills in isolated sessions. Each harness requires its own
agent files.

| Harness | Source           | Destination           |
| ------- | ---------------- | --------------------- |
| Claude  | `claude/agents/` | `~/.claude/agents/`   |
| Gemini  | `gemini/agents/` | `~/.gemini/agents/`   |
| Pi      | `pi/agents/`     | `~/.pi/agent/agents/` |

### Run command

The `/run` command orchestrates subagent invocation. Invoke agents as
`/run <agent> [argument]`. Format varies by harness.

| Harness | Notes                                                                |
| ------- | -------------------------------------------------------------------- |
| Claude  | Copy `claude/commands/` to `~/.claude/commands/`                     |
| Gemini  | Copy `gemini/commands/` to `~/.gemini/commands/`                     |
| Pi      | Install `mystilleef/pi-subagent`; includes a built-in `/run` command |
