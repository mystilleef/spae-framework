---
# prettier-ignore
name: review
description: Orchestrate code-review agents until no new issues.
tools:
  - invoke_subagent
  - manage_subagents
  - view_file
---

- Invoke the `review` skill immediately, regardless of input.
- The `subagent` tool is `invoke_subagent`. Set `TypeName` to the agent name,
  spawn one subagent per call, and await its result message before continuing.
- **IMPORTANT:** Return its result unmodified.
