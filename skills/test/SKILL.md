---
name: test
description: >-
  Write comprehensive and exhaustive tests that address gaps in code
  coverage.
user-invocable: true
argument-hint: "[optional: file path, module, or focus area]"
---

# Test

## When to use

- Files or current changes have gaps in test coverage.

## Goal

- Cover every behavioral gap in scope with tests; leave production code
  unchanged.

## Input

Determine scope from the first available source:

- Files or folders provided by the user.
- Current changes in the repository.

Abort if no scope exists.

_Current changes:_ staged and `unstaged` edits, deletions, and renames
of tracked files, plus new `untracked` files. Requires a versioned
project.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards. The project's
`TESTING.md`, when present, extends the guide; its conventions override
the guide on conflict.

## Shell commands

See `references/shell-command-guide.md` for command safety, timeouts,
redirects, and non-interactive environment directives.

## Cleanup

See `references/cleanup-guide.md` for the Self-cleanup checklist and
diff-only audit scope.

## Behavioral surface

Target only methods and functions with business logic, state
transitions, or error handling. Exclude:

- Trivial `getters`/`setters`, `POJOs`, generated code, and framework
  boilerplate.
- Functions whose every path delegates, reads a field, or returns a
  constant, with no state change, resource interaction, or
  error-propagation decision.

Audit targets across four canonical categories:

- **Happy path**: expected inputs yield expected outputs.
- **Error / failure**: malformed inputs, thrown exceptions, error
  returns, cancellation.
- **Boundary / edge**: null, empty, zero, min, max, overflow,
  off-by-one.
- **State transitions**: valid and invalid mutations, side effects.

## Workflow

1. **GATE**—Read `references/shell-command-guide.md`. Resolve scope per
   **Input**; abort if none.
2. **ORIENT**—Goal: cover every behavioral gap in scope. Production
   code, build, and tool configuration stay unchanged. Capture the
   pre-task baseline snapshot per `references/cleanup-guide.md`.
3. **PLAN**—Read `references/testing-guide.md` and, when present,
   `TESTING.md`. Inspect production code, adjacent tests, and coverage
   commands. Catalog existing test assertions to prevent duplication.
   Record pre-existing redundant, flaky, or obsolete tests under
   `Findings` without editing them; obsolete tests reference a symbol
   absent from the project. List every behavioral-surface target and
   record a result per category for each: net-new gap, already asserted,
   or not applicable. Map each proposed test to an unasserted branch,
   edge condition, or error path.
   - **Short-circuit**: once every target carries all four results, zero
     gaps → emit `Result: No Gaps` and halt.
   - **Baseline**: run the full suite before `ACT`; any failure counts
     as an out-of-scope blocker—halt, listing each failing test under
     `Findings` as `obsolete` or `regression`.
4. **ACT**—Write tests for every enumerated net-new gap.
5. **VERIFY**—Loop over every criterion declared in PLAN:
   - Run targeted tests, then the full suite and, when available, the
     coverage tool.
   - Confirm each new test fails against a temporary mutation of its
     targeted logic. Capture the production file's content first and
     rewrite it afterward; never restore via git `checkout`, `restore`,
     or `stash`, which erase uncommitted work.
   - Audit every added or updated test file against
     `references/testing-guide.md`, CI parity, hygiene, and repeat-run
     stability included; fix any violation before proceeding.
   - Audit task edits against the pre-task baseline using the
     Self-cleanup checklist in `references/cleanup-guide.md`; remove
     every self-introduced artifact before proceeding.
   - For each unmet criterion: return to `ACT`, execute, then re-enter
     `VERIFY`.
   - Exit only when all pass and no regressions remain.
   - Halt only for out-of-scope blockers (failing baseline tests,
     pre-existing compilation errors, or missing runtime dependencies).
6. **PERSIST**—Confirm all test files written; no partial writes.
7. **REPORT**—Emit the result following the result directives and using
   the result template:
   - `No Gaps`: the PLAN short-circuit fired.
   - `Improved`: `VERIFY` exited with at least one gap closed.
   - `Failed`: any other outcome—abort, halt, or zero gaps closed.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Surface the audit as one `Actions` line (for example,
  `audited 6 targets across 4 categories; 2 gaps`); keep per-target
  detail out of the result.

## Constraints

- **No Confirmation Halts**: Never halt to request user scope
  confirmation or interactive direction; write tests autonomously within
  detected scope or emit `Result: No Gaps`.
- Never edit production code beyond `VERIFY`'s temporary mutations.
- **Defect Exposed**: when a new test fails because production code
  misbehaves, never fix the code or assert the defect; drop the test and
  report the defect under `Findings`.
- Don't write tests solely to raise a number.
- Never duplicate assertions, execution paths, or post-conditions,
  whether against existing tests or among new ones; parameterize
  table-driven inputs instead.
- No hacks, workarounds, or shortcuts.
- No violation of `DRY` and `SOLID` software principles.
- Forbid laziness; fix issues properly, correctly, and idiomatically.
- Never edit build or tool configuration files; for example,
  `tsconfig.json`, `.eslintrc.*`, `webpack.config.*`, `vite.config.*`,
  `jest.config.*`, `Makefile`, `pyproject.toml`, `Cargo.toml`.
- Never suppress or disable compiler or linter diagnostics; for example,
  `@ts-ignore`, `eslint-disable`, `@SuppressWarnings`, `# type: ignore`.
- Never weaken type contracts to silence errors; for example, `as any`,
  `!` non-null assertions, or broadening union types.
- **Full autonomy**: Never perform or request human execution, an
  attended or interactive terminal, or human presence to confirm
  coverage; use direct, agent-executed inspection instead.

## Verification

- Production code matches its pre-task content.
- Full test suite passes.
- Every behavioral-surface target carries a recorded result for all four
  categories; each `not applicable` states why.
- Every added test maps to a recorded net-new gap; every net-new gap
  holds a passing test or a defect reported under `Findings`.
- Coverage tool, when present, reports no uncovered line or branch in
  behavioral-surface targets beyond reported defects.
- Each new test fails against a mutation of its targeted logic.
- Zero redundant test assertions or duplicated execution paths
  introduced.
- All added or updated tests pass the `references/testing-guide.md`
  audit.
- No self-introduced cleanup violation remains per
  `references/cleanup-guide.md`.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`; a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, abort, or halt—with the
  result template as the final message; never end on progress narration.
- Set `Result` to exactly one template literal, verbatim; report an
  abort or halt lacking its own literal as `Failed`, with the reason
  under `Findings`.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of modified or created files]
- **Findings**:
  - [Terse list of key gaps, risks, or notable observations]
- **Summary**:
  - [Terse list of summary of changes]

> **Test Status** • `[scope]`
> **Result**: [Improved | No Gaps | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
