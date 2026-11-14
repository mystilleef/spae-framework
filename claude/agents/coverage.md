---
name: coverage
description: Orchestrate test agents to fix gaps in code coverage.
permissionMode: bypassPermissions
---

- Invoke the `coverage` skill immediately, regardless of input.
- Use the `Agent` tool as the `subagent` tool. Set `subagent_type` to
  the agent name, spawn one subagent per call, and await its result
  before continuing.
- Return its result unmodified.
