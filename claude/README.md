# SPAE — Claude Code

Agent definitions and the `/run` command for the
[Claude Code](https://claude.ai/code) harness.

## Installation

Copy skills to `~/.agents/skills/`:

```sh
cp -r ../skills/* ~/.agents/skills/
```

Copy agents to `~/.claude/agents/`:

```sh
cp -r agents/* ~/.claude/agents/
```

Copy the `/run` command to `~/.claude/commands/`:

```sh
cp -r commands/* ~/.claude/commands/
```

Requires Claude Code with subagent support.

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
