# SPAE — Pi

Agent definitions for the [Pi](https://github.com/mystilleef/pi) harness.

## Installation

Copy agents to `~/.pi/agent/agents/`:

```sh
cp -r agents/* ~/.pi/agent/agents/
```

Install [`mystilleef/pi-subagent`](https://github.com/mystilleef/pi-subagent)
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
