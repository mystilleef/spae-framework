---
description: Orchestrate purify agents to optimize and simplify code.
---

- Invoke the `purity` skill immediately, regardless of input.
- Use the Task tool as the `subagent` tool. Set the subagent name to the
  agent name, spawn one subagent per call, and await its result before
  continuing.
- Return its result unmodified.
