# `SPAE`: Pi

Agent definitions for the [Pi](https://github.com/mystilleef/pi)
harness.

## Installation

Copy skills to `~/.agents/skills/`:

```sh
cp -r ../skills/* ~/.agents/skills/
```

Copy agents to `~/.pi/agent/agents/`:

```sh
cp -r agents/* ~/.pi/agent/agents/
```

Install
[`mystilleef/pi-subagent`](https://github.com/mystilleef/pi-subagent)
for the built-in `/run` command.

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
| `test`         | Fill test coverage gaps                           |
| `purify`       | Simplify and optimize code                        |
| `refactor`     | Improve structure and clarity                     |
| `review`       | Review for correctness and style                  |
| `document`     | Document code                                     |
| `commit`       | Stage and commit the implementation               |
| `work`         | Run ad-hoc tasks in an isolated session           |
| `query`        | Answer questions or research without side effects |
| `troubleshoot` | Diagnose and fix issues                           |

## Orchestration agents

These agents require nested subagent support via
[`mystilleef/pi-subagent`](https://github.com/mystilleef/pi-subagent).

| Agent         | Purpose                                               |
| ------------- | ----------------------------------------------------- |
| `orchestrate` | Run all `SPAE` phases autonomously from current state |
| `prepare`     | Run preparatory phases only—run spec, plan, inspect |
| `spawn`       | Run the build phase only—loops all remaining tasks    |
| `coverage`    | Spawn test agents to address code coverage gaps       |
| `clean`       | Run `purify` then `refactor` agents sequentially      |

See the [top-level README](../README.md) for the full workflow.
