---
# prettier-ignore
name: coverage
description: Orchestrate test agents to fix gaps in code coverage.
tools:
  - invoke_subagent
  - manage_subagents
  - view_file
---

- Invoke the `coverage` skill immediately, regardless of input.
- The `subagent` tool is `invoke_subagent`. Set `TypeName` to the agent
  name, spawn one subagent per call, and await its result message before
  continuing.
- Return its result unmodified.
