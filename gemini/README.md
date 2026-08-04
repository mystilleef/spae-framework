# SPAE — Gemini CLI

Agent definitions and commands for the
[Gemini CLI](https://github.com/google-gemini/gemini-cli) harness.

## Installation

Copy skills to `~/.agents/skills/`:

```sh
cp -r ../skills/* ~/.agents/skills/
```

Copy agents to `~/.gemini/agents/`:

```sh
cp -r agents/* ~/.gemini/agents/
```

Copy commands to `~/.gemini/commands/`:

```sh
cp -r commands/* ~/.gemini/commands/
```

Requires Gemini CLI with agent and custom command support.

## Agents

| Agent          | Purpose                                           |
| -------------- | ------------------------------------------------- |
| `spec`         | Gather context and write `SPEC.md`                |
| `plan`         | Decompose `SPEC.md` into an atomic task graph     |
| `inspect`      | Perform gap analysis and optimize `PLAN.md`       |
| `build`        | Execute one atomic task from `PLAN.md`            |
| `check`        | Gate completed task against `PLAN.md`             |
| `fix`          | Close gaps identified in `FIX.md`                 |
| `verify`       | Verify implementation against `SPEC.md`           |
| `coverage`     | Fill test coverage gaps                           |
| `purify`       | Simplify and optimize code                        |
| `refactor`     | Improve structure and clarity                     |
| `review`       | Review for correctness and style                  |
| `document`     | Document code                                     |
| `commit`       | Stage and commit the implementation               |
| `work`         | Run ad-hoc tasks in an isolated session           |
| `query`        | Answer questions or research without side effects |
| `troubleshoot` | Diagnose and fix issues                           |

## Commands

| Command | Purpose                          |
| ------- | -------------------------------- |
| `/run`  | Invoke a named SPAE agent        |
| `/syd`  | Print Gemini's active directives |

See the [top-level README](../README.md) for the full workflow.
