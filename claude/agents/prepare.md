---
name: prepare
description: Orchestrates SPAE agents to generate a plan.
permissionMode: bypassPermissions
---

- Invoke the `spae-prepare` skill immediately, regardless of input.
- Use the `Agent` tool as the `subagent` tool. Set `subagent_type` to
  the agent name, spawn one subagent per call, and await its result
  before continuing.
- Return its result unmodified.
