# SPAE: Agy

Agent definitions and the `/run` skill for the
[Antigravity CLI](https://antigravity.google/docs/cli/) (`agy`), the
successor to the deprecated Gemini CLI.

## Installation

From the repository root, `./install.sh agy` installs the files this
page documents (see [Installation](../README.md#installation)). On
Windows, the script runs only under `WSL`. Manual steps follow as
fallback.

Copy skills to `~/.gemini/config/skills/`:

```sh
cp -r ../skills/* ~/.gemini/config/skills/
```

Copy agents to `~/.gemini/config/agents/`:

```sh
cp -r agents/* ~/.gemini/config/agents/
```

Copy the `/run` skill to `~/.gemini/config/skills/`:

```sh
cp -r skills/run ~/.gemini/config/skills/
```

To scope the install to one project, use `.agents/skills/` and
`.agents/agents/` at the repository root instead.

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

These agents drive nested subagents through Agy's native
`invoke_subagent` tool.

| Agent         | Purpose                                               |
| ------------- | ----------------------------------------------------- |
| `orchestrate` | Run all `SPAE` phases autonomously from current state |
| `prepare`     | Run preparatory phases only—run spec, plan, inspect   |
| `spawn`       | Run build phase—cycles build, check, and fix per task |
| `coverage`    | Spawn test agents to address code coverage gaps       |
| `clean`       | Run `purify` then `refactor` agents sequentially      |

## Commands

Agy has no custom command files. It converts every skill into a slash
command, so `/run` ships as a skill.

| Command                  | Purpose                   |
| ------------------------ | ------------------------- |
| `/run <agent> [message]` | Invoke any named subagent |

## Notes

- Agents are Markdown files with YAML frontmatter; the body becomes the
  system prompt.
- Each agent lists its `tools`. Agy gives agents without `tools` no
  shell, edit, or subagent tools.
- Agy rejects a `tools` entry it doesn't recognize, so use exact tool
  names.
- `grep_search` and `find_by_name` skip git-ignored paths such as
  `.spae/`. Phase agents fall back to `view_file`, `list_dir`, and
  `run_command`.
- Run any agent as the main agent with `agy --agent <name>`.
- Orchestration relies on nested subagents. Testing covered Agy. `Pi`
  remains the recommended harness.

See the [top-level README](../README.md) for the full workflow.
