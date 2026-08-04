# SPAE — OpenCode

Agent definitions and the `/run` command for the
[OpenCode](https://opencode.ai) harness.

## Installation

Copy skills to `~/.agents/skills/`:

```sh
cp -r ../skills/* ~/.agents/skills/
```

Copy agents to `~/.config/opencode/agents/`:

```sh
cp -r agents/* ~/.config/opencode/agents/
```

Copy the `/run` command to `~/.config/opencode/commands/`:

```sh
cp -r commands/* ~/.config/opencode/commands/
```

Requires OpenCode with subagent support.

## Usage

Invoke any agent with `/run <agent> [argument]`. Only `spec` takes an
argument—a description of the task. `prepare` and `implement` replace
`plan` and `build` because OpenCode reserves those names for its native
agents.

| Agent       | Invocation                |
| ----------- | ------------------------- |
| `spec`      | `/run spec <requirement>` |
| `prepare`   | `/run prepare`            |
| `inspect`   | `/run inspect`            |
| `implement` | `/run implement`          |
| `check`     | `/run check`              |
| `fix`       | `/run fix`                |
| `verify`    | `/run verify`             |

## Agents

| Agent          | Purpose                                           |
| -------------- | ------------------------------------------------- |
| `spec`         | Gather context and write `SPEC.md`                |
| `prepare`      | Decompose `SPEC.md` into an atomic task graph     |
| `inspect`      | Perform gap analysis and optimize `PLAN.md`       |
| `implement`    | Execute one atomic task from `PLAN.md`            |
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

See the [top-level README](../README.md) for the full workflow.
