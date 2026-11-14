---
# prettier-ignore
name: purity
description: Orchestrate purify agents to optimize and simplify code.
tools:
  - invoke_subagent
  - manage_subagents
  - view_file
---

- Invoke the `purity` skill immediately, regardless of input.
- The `subagent` tool is `invoke_subagent`. Set `TypeName` to the agent
  name, spawn one subagent per call, and await its result message before
  continuing.
- Return its result unmodified.
