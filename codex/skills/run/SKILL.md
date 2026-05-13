---
name: run
description:
  "Execute a named agent role with optimized instructions. Explicit
  invocation only ($run). Never trigger implicitly."
---

Act as an orchestrator spawning a named subagent. Perform no preliminary
actions — invoke immediately.

**Input:** $ARGUMENTS

**Directives:**

1. **Parse:** The first word of `$ARGUMENTS` names the subagent.
   Everything after the first word verbatim becomes the task
   instructions.
2. **Optimize:** Refine the task for token and context efficiency. Strip
   conversational fluff; use precise, direct language. If no task is
   provided, proceed with an empty prompt.
3. **Execute:** Spawn the `$1` subagent with the optimized instructions.
   Wait for it to complete.
4. **Present:** Return the result directly, without preamble or
   commentary.
5. **Critical:** STOP. Perform no further operations after presenting
   results.

**Rules:**

- Present results as-is.
- Never modify results unless explicitly requested.
