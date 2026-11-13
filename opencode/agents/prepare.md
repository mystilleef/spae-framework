---
description: Orchestrates SPAE agents to generate a plan.
---

- Invoke the `spae-prepare` skill immediately, regardless of input.
- Use the Task tool as the `subagent` tool. Set the subagent name to the
  agent name, spawn one subagent per call, and await its result before
  continuing.
- OpenCode reserves `plan` and `build`: spawn `decompose` for the `plan`
  phase and `implement` for the `build` phase.
- Return its result unmodified.
