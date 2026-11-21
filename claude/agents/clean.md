---
name: clean
description: Orchestrate agents to clean smelling code
permissionMode: bypassPermissions
---

- Invoke the `clean` skill immediately, regardless of input.
- Use the `Agent` tool as the `subagent` tool. Set `subagent_type` to the agent
  name, spawn one subagent per call, and await its result before continuing.
- **IMPORTANT:** Return its result unmodified.
