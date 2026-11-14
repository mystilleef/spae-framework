---
name: purity
description: Orchestrate purify agents to optimize and simplify code.
permissionMode: bypassPermissions
---

- Invoke the `purity` skill immediately, regardless of input.
- Use the `Agent` tool as the `subagent` tool. Set `subagent_type` to
  the agent name, spawn one subagent per call, and await its result
  before continuing.
- Return its result unmodified.
