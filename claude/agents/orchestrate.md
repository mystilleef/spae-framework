---
name: orchestrate
description: Orchestrates SPAE agents for each phase to complete tasks.
permissionMode: bypassPermissions
---

- Invoke the `spae-orchestrate` skill immediately, regardless of input.
- Use the `Agent` tool as the `subagent` tool. Set `subagent_type` to
  the agent name, spawn one subagent per call, and await its result
  before continuing.
- Return its result unmodified.
