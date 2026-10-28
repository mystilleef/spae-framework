# State-persistent atomic execution (`SPAE`) for `Gemini CLI`

Agent definitions and commands for the
[`Gemini CLI`](https://github.com/google-gemini/gemini-cli) harness.

> **Deprecated.** `Google` replaced `Gemini CLI` with the
> `Antigravity CLI` (`agy`). Use
> [`antigravity/`](../antigravity/README.md) for new installs. These
> files receive no further updates.

## Installation

From the repository root, `./install.sh gemini` installs the files this
page documents (see [Installation](../README.md#installation)). On
`Windows`, the script runs only under `WSL`.

### Manual installation

Manual steps follow as fallback.

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

Requires `Gemini CLI` with agent and custom command support.

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
`Gemini CLI` remains untested.

| Agent         | Purpose                                               |
| ------------- | ----------------------------------------------------- |
| `orchestrate` | Run all `SPAE` phases autonomously from current state |
| `prepare`     | Run preparatory phases only—run spec, plan, inspect   |
| `spawn`       | Run build phase—cycles build, check, and fix per task |
| `coverage`    | Spawn test agents to address code coverage gaps       |
| `clean`       | Run `purify` then `refactor` agents sequentially      |

## Commands

| Command | Purpose                             |
| ------- | ----------------------------------- |
| `/run`  | Invoke a named `SPAE` agent         |
| `/syd`  | Print active directives in `Gemini` |

See the [top-level README](../README.md) for the full workflow.
