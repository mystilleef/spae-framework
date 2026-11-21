---
description: Orchestrate code-review agents until no new issues.
---

- Invoke the `review` skill immediately, regardless of input.
- Use the Task tool as the `subagent` tool. Set the subagent name to the agent
  name, spawn one subagent per call, and await its result before continuing.
- **IMPORTANT:** Return its result unmodified.
