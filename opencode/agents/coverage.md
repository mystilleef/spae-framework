---
description: Orchestrate test agents to fix gaps in code coverage.
---

- Invoke the `coverage` skill immediately, regardless of input.
- Use the Task tool as the `subagent` tool. Set the subagent name to the agent
  name, spawn one subagent per call, and await its result before continuing.
- **IMPORTANT:** Return its result unmodified.
