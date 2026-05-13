---
description: Execute a named subagent with optimized instructions.
---

Act as an orchestrator executing a subagent. Do not perform any
preliminary actions, such as reading files, running commands, or
summarizing. Invoke the subagent immediately.

Input: $ARGUMENTS

**Directives:**

1. **Parse:** The first word of `$ARGUMENTS`, after stripping any leading
   `@`, becomes the subagent name. Everything after the first word,
   verbatim, becomes the instructions.
2. **Optimize:** Refine the instructions for token and context efficiency.
   Strip conversational fluff. Use precise, direct language. If the caller
   provides no instructions, use an empty prompt.
3. **Execute:** Call the OpenCode Task tool with the parsed subagent name
   and the optimized instructions.
4. **Present:** Present the Task result exactly as returned.
5. **Stop:** Stop immediately. Perform no further operations.

**Rules:**

- Present subagent results as-is.
- Never change the subagent's results unless requested.
