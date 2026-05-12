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

## Workflow

Run phases in order. Each agent reads only its designated inputs and
writes only its designated outputs.

<!-- prettier-ignore -->
| Phase | Skill | Purpose |
| --- | --- | --- |
| 1 | `/spec <task>` | Distill requirements into `SPEC.md` |
| 2 | `/plan` | Decompose `SPEC.md` into an atomic task graph |
| 3 | `/inspect` | Perform gap analysis and optimize `PLAN.md` |
| 4 | `/build` · `/tdd` · `/execute` | Carry out tasks from `PLAN.md` |
| 5 | `/verify` | Verify implementation against `SPEC.md` |

Choose one execution mode per `workstream` after `/inspect`:

- `/build` — one task per cycle; best for complex or high-risk plans
- `/tdd` — failing-test-first cycle; best for behavioral changes
- `/execute` — all tasks at once; best for small, low-risk plans

If `/verify` finds gaps, it creates `VERIFY.md` and resets the cycle to
`/spec`. Repeat until `/verify` passes.

### Extended phases

The full protocol specifies extra phases—`coverage`, `purity`,
`refactor`, `review`, and `commit`—for post-verification refinement. See
[`spae-framework.md`](./spae-framework.md) for the complete specification.

---

## Artifacts

All artifacts live in `.spae/<workstream>/`. Never commit this
directory—add `.spae/` to `.gitignore`.

<!-- prettier-ignore -->
| File | Purpose |
| --- | --- |
| `STATE.json` | Execution cursor—tracks phase and active task |
| `SPEC.md` | Normalized requirements—immutable during execution |
| `PLAN.md` | Atomic task graph—immutable during execution |
| `VERIFY.md` | Ephemeral signal—created when verification fails |

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

<!-- prettier-ignore -->
| Harness | Source | Destination |
| --- | --- | --- |
| Pi | `pi/` | `~/.pi/agent/agents/` |
| Gemini | `gemini/` | `~/.gemini/agents/` |

### Run command

The `/run` command orchestrates subagent invocation. Format varies by
harness.

<!-- prettier-ignore -->
| Harness | Notes |
| --- | --- |
| Pi | Install `mystilleef/pi-subagent`; includes a built-in `/run` command |
| Gemini | Copy `gemini/commands/` to `~/.gemini/commands/` |
