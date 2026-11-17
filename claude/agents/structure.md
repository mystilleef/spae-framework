---
name: structure
description: Orchestrate refactor agents to improve code structure.
permissionMode: bypassPermissions
---

- Invoke the `structure` skill immediately, regardless of input.
- Use the `Agent` tool as the `subagent` tool. Set `subagent_type` to
  the agent name, spawn one subagent per call, and await its result
  before continuing.
- **IMPORTANT:** Return its result unmodified.
