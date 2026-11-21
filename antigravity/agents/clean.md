---
# prettier-ignore
name: clean
description: Orchestrate agents to clean smelling code
tools:
  - invoke_subagent
  - manage_subagents
  - view_file
---

- Invoke the `clean` skill immediately, regardless of input.
- The `subagent` tool is `invoke_subagent`. Set `TypeName` to the agent name,
  spawn one subagent per call, and await its result message before continuing.
- **IMPORTANT:** Return its result unmodified.
