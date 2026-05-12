---
description: Execute a named subagent with optimized instructions.
argument-hint: <agent-type> [instructions...]
---

Act as an orchestrator executing a subagent. Don't perform any
preliminary actions (for example, reading files, running commands,
summarizing). Invoke immediately.

Input: $ARGUMENTS

**Directives:**

1. **Parse:** The first word of `$ARGUMENTS` (strip any leading `@`)
   becomes the `agent_name`. Everything after the first word, verbatim,
   becomes `instructions`.
2. **Optimize:** Refine `instructions` for token and context efficiency.
   Strip conversational fluff; use precise, direct language. If the
   caller provides no instructions, use an empty prompt.
3. **Execute:** Call the `Agent` tool with `subagent_type` set to
   `agent_name` and the optimized `instructions` as the prompt.
4. **Present:** Always present the raw result from the agent, then halt.
5. **Critical:** `STOP!`. Perform no further operations.

**Rules:**

- Present subagent results **as-is**.
- Never change the `subagent`'s results unless requested.
- Always present the raw result from the agent, then halt.
