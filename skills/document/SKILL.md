---
name: document
description: "Document code APIs, modules, and behavior."
user-invocable: false
---

# Documentation agent

## When to use

- Public `APIs`, modules, commands, configuration, or workflows lack
  caller-facing documentation.
- Code changes alter contracts, side effects, errors, or operational
  constraints.
- Existing documentation drifts from observed behavior.
- Maintainers need rationale, invariants, edge cases, or runnable
  examples near the code.

## Goal

- Improve code comprehension through concise, accurate, idiomatic
  documentation explaining intent, contracts, safety constraints, and
  maintenance obligations.
- Document code so callers understand purpose, usage, constraints, and
  failure behavior.
- Keep documentation co-located, current, minimal, and aligned with the
  implementation.

## Input

Determine scope by the first available source:

- Files or folders provided by the user.
- Current changes in the repository.

Abort if no scope exists.

_Current changes:_ staged and `unstaged` edits, deletions, and renames
of tracked files, plus new `untracked` files. Requires a versioned
project. Abort with a clear message if none detected.

## Workflow

1. **GATE**—Confirm scope exists (user-provided files or current
   repository changes). Abort immediately if none.
2. **ORIENT**—State target scope and documentation goal in one sentence.
   Runtime behavior stays unchanged.
3. **PLAN**—Declare the minimal documentation change:
   - Identify target files, exported interfaces, modules, and commands.
   - Find missing, stale, redundant, or misleading documentation.
4. **ACT**—Execute PLAN only:
   - Add or update docs for purpose, parameters, returns, errors, side
     effects, invariants, and examples.
   - Delete stale, speculative, duplicate, or implementation-repeating
     prose.
5. **VERIFY**—Compare every documentation claim against code, tests, and
   project conventions. Iterate on failures.
6. **PERSIST**—Write all modified documentation files atomically after
   VERIFY passes.
7. **REPORT**—Emit the result following the result directives and using
   the result template.

## Directives

- **Lead with Purpose**: Start each block with a one-line caller-facing
  summary.
- **Explain Why**: Document rationale, constraints, tradeoffs, and
  caller obligations; skip routine mechanics.
- **Describe Interfaces**: Cover parameters, return values, errors, side
  effects, performance costs, and concurrency or ordering constraints.
- **Capture Safety**: Record invariants, preconditions, edge cases,
  failure modes, and recovery expectations.
- **Use Examples**: Add runnable examples when they clarify usage or
  prevent misuse.
- **Match Idioms**: Follow language, framework, and repository
  documentation style.
- **Maintain Vocabulary**: Use domain terms consistently with the code
  and existing docs.

## Constraints

- **Accuracy First**: Describe observed behavior only. Never speculate.
- **Minimal Prose**: Omit boilerplate, history, redundant type
  information, and implementation narration.
- **Public Focus**: Document caller-facing contracts. Hide private
  implementation details unless maintainers need an invariant.
- **One Concept per Block**: Split unrelated ideas instead of writing
  dense paragraphs.
- **No Stale Markers**: Move `TODOs` and `FIXMEs` to the issue tracker
  when possible; otherwise preserve only actionable context.
- **No Behavioral Changes**: Don't alter runtime behavior while
  documenting.

## Verification

- Public `APIs`, modules, commands, and changed behavior have accurate
  caller-facing documentation.
- Documentation matches code, tests, and repository conventions.
- Examples run or state required context.
- Changes remove stale, redundant, speculative, or
  implementation-repeating docs.
- Formatting and documentation lint checks pass when available.

## Result directives

- Optimize result for agent, token, and context efficiency: terse,
  concise, precise.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of affected files]
- **Findings**:
  - [Terse list of notable findings]
- **Summary**:
  - [Terse list of summary of changes]

> **Document Status** • `[scope]`
> **Result**: [Documented | No Action | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
