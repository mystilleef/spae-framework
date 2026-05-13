# SPAE — Codex

Agent definitions and the `$run` skill for the
[Codex](https://openai.com/codex) harness.

## Installation

Copy shared skills to `~/.agents/skills/`:

```sh
cp -r ../skills/* ~/.agents/skills/
```

Copy the `$run` skill to `~/.codex/skills/`:

```sh
cp -r skills/* ~/.codex/skills/
```

Copy agents to `~/.codex/agents/`:

```sh
cp -r agents/* ~/.codex/agents/
```

Requires Codex with subagent support.

## Usage

Codex does not support custom commands. The `$run` skill replaces the
`/run` command. Activate skills with `$`—invoke agents as
`$run <agent> [argument]`. Only `spec` takes an argument—a description
of the task.

| Agent     | Invocation                |
| --------- | ------------------------- |
| `spec`    | `$run spec <requirement>` |
| `plan`    | `$run plan`               |
| `inspect` | `$run inspect`            |
| `build`   | `$run build`              |
| `tdd`     | `$run tdd`                |
| `execute` | `$run execute`            |
| `verify`  | `$run verify`             |

## Agents

| Agent          | Purpose                                           |
| -------------- | ------------------------------------------------- |
| `spec`         | Gather context and write `SPEC.md`                |
| `plan`         | Decompose `SPEC.md` into an atomic task graph     |
| `inspect`      | Perform gap analysis and optimize `PLAN.md`       |
| `build`        | Execute one atomic task from `PLAN.md`            |
| `tdd`          | Run a failing-test-first build cycle              |
| `execute`      | Execute all tasks from `PLAN.md` sequentially     |
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
