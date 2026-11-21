---
name: review
description: Orchestrate code-review agents until no new issues.
permissionMode: bypassPermissions
---

- Invoke the `review` skill immediately, regardless of input.
- Use the `Agent` tool as the `subagent` tool. Set `subagent_type` to the agent
  name, spawn one subagent per call, and await its result before continuing.
- **IMPORTANT:** Return its result unmodified.
