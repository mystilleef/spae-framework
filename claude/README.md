# State-persistent atomic execution (`SPAE`) for `Claude Code`

Agent definitions and the `/run` command for the
[`Claude Code`](https://claude.ai/code) harness.

## Installation

From the repository root, `./install.sh claude` installs the files this
page documents (see [Installation](../README.md#installation)). On
`Windows`, the script runs only under `WSL`.

### Manual installation

Manual steps follow as fallback.

Copy skills to `~/.claude/skills/`:

```sh
cp -r ../skills/* ~/.claude/skills/
```

Copy agents to `~/.claude/agents/`:

```sh
cp -r agents/* ~/.claude/agents/
```

Copy the `/run` command to `~/.claude/commands/`:

```sh
cp -r commands/* ~/.claude/commands/
```

Requires `Claude Code` with subagent support.

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

These agents require nested subagent support. Orchestration on
`Claude Code` remains untested.

| Agent         | Purpose                                               |
| ------------- | ----------------------------------------------------- |
| `orchestrate` | Run all `SPAE` phases autonomously from current state |
| `prepare`     | Run preparatory phases only—run spec, plan, inspect   |
| `spawn`       | Run build phase—cycles build, check, and fix per task |
| `coverage`    | Spawn test agents to address code coverage gaps       |
| `clean`       | Run `purify` then `refactor` agents sequentially      |
| `purity`      | Spawn `purify` agents to optimize and simplify code   |
| `structure`   | Spawn `refactor` agents to improve code structure     |

See the [top-level README](../README.md) for the full workflow.
