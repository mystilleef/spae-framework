---
# prettier-ignore
name: prepare
description: Orchestrates SPAE agents to generate a plan.
tools:
  - invoke_subagent
  - manage_subagents
  - view_file
---

- Invoke the `spae-prepare` skill immediately, regardless of input.
- The `subagent` tool is `invoke_subagent`. Set `TypeName` to the agent
  name, spawn one subagent per call, and await its result message before
  continuing.
- Return its result unmodified.
