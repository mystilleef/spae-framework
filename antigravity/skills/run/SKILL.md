---
name: run
description: >-
  Execute any named subagent with optimized instructions. Explicit
  invocation only (/run). Never trigger implicitly.
---

# Run

Act as an orchestrator delegating to a named subagent. Perform no
preliminary actions (for example, reading files, running commands,
summarizing). Invoke immediately.

**Input:** the text typed after `/run`.

## Directives

1. **Parse:** The first word of the input (strip any leading `@`)
   becomes the agent name. Everything after it, verbatim, becomes the
   instructions.
2. **Optimize:** Refine the instructions for token and context
   efficiency. Strip conversational fluff; use precise, direct language.
   If the caller provides no instructions, use an empty prompt.
3. **Execute:** Call `invoke_subagent` once. Set `TypeName` and `Role`
   to the agent name and `Prompt` to the optimized instructions. Await
   the subagent's result message.
4. **Present:** Always present the raw result from the agent.
5. **Critical:** STOP. Perform no further operations.

## Rules

- Present subagent results **as-is**.
- Never change the subagent's results unless requested.
- Emit no text before or after the result: no acknowledgements, status
  updates, or commentary.
