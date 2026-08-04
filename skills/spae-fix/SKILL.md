---
name: spae-fix
description: >-
  Remediates pre-classified SPAE task gaps. Use after /check writes
  FIX.md and moves an active task to phase fix.
user-invocable: true
---

# Fix (`SPAE`)

## When to use

- `STATE.json` reports `phase: fix`.
- `FIX.md` lists pre-classified gaps for the active in-progress task.

## Goal

- Close only the active task's named `FIX.md` gaps through minimal,
  test-driven changes.
- Return the _workstream_ to `/check` without task completion, cursor
  movement, plan edits, or scope expansion.

## Input

Read:

- _STATE.json_ in `.spae/current/` for task management (consult
  `references/STATE.md` for field reference, directives, and phase
  snapshots).
- _FIX.md_ in `.spae/current/` for gaps to address.
- Project source, tests, configuration, docs, and command output
  required by the named gaps.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Cleanup

See `references/cleanup-guide.md` for the self-introduced-artifact
checklist and diff-only audit scope.

## Workflow

1. **GATE**—Read `.spae/current/STATE.json`; confirm `phase: fix` and an
   active task identifier. Self-heal state drift: if
   `tasks[`active_task_id`]` reads `"todo"`, correct it to
   `"in_progress"` and write `STATE.json` before proceeding. Halt on
   state drift: if `tasks[`active_task_id`]` reads `"done"`, halt. Read
   `.spae/current/FIX.md`; confirm its task identifier matches the
   active task and its `## Gaps` list supplies concrete actionable gaps.
   Halt on missing, malformed, or mismatched input; report the failed
   precondition; make no changes.
2. **ORIENT**—Goal: close the named gaps for one active task and return
   it to `/check`. Leave `PLAN.md`, `SPEC.md`, task completion, cursor
   movement, forward tasks, and unrelated project concerns untouched.
3. **PLAN**—List each pre-classified `FIX.md` gap. Map its required test
   surface: expected behavior, failure modes, and edge cases. Use the
   task `Intent` only for context; never expand scope from it,
   `Acceptance`, `Verification`, forward tasks, seams, or observations.
4. **ACT**—For each named gap:
   - Write a failing or gap-reproducing test covering expected behavior,
     failure modes, and edge cases.
   - Write the minimal source, test, configuration, or documentation
     change required by that gap.
   - Run targeted checks; repeat `test→implement` until the gap passes.

   Ignore `Observations` for source changes. Stop after every listed gap
   has passing test coverage. Never write production code before its
   test exists.

5. **VERIFY**—Loop over every named gap and its relevant project checks:
   - Audit changed tests for project CI parity; correct violations.
   - Audit the task's own `git diff`/`git status` against the
     Self-cleanup checklist in `references/cleanup-guide.md`; remove
     every self-introduced artifact before proceeding.
   - For each unmet gap or failing check: return to **ACT**, remediate,
     then re-enter **VERIFY**.
   - Exit only after every gap test and relevant task check passes.
   - Fail the task only for an infeasible finding, plan or spec defect,
     or broken external dependency. Leave `FIX.md` and state transition
     untouched.
6. **PERSIST**—After every named gap passes, delete
   `.spae/current/FIX.md` and write `.spae/current/STATE.json` once with
   `phase: check`. Keep the active task `in_progress`; never mark it
   `done` or alter the cursor. Re-read `STATE.json` after writing; on a
   field mismatch, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit the result under Result directives. After successful
   remediation, use guide template C verbatim. On a failure, report it
   under Findings and never claim gap closure.

## Directives

- Optimize work for agent, token, and context efficiency.
- Consult `references/shell-command-guide.md` for command safety,
  timeouts, redirects, and non-interactive environment directives.
- Consult `references/cleanup-guide.md` for self-introduced-artifact
  scope and checklist.
- Follow canonical _SPAE_ Step 6 `/fix` whenever guidance conflicts.
- Remediate exactly one active task per invocation.
- Scope every change solely from `FIX.md` `## Gaps`; consume those
  pre-classified gaps as written.
- Treat `Observations` as informational only; never classify, promote,
  or act on them.
- Prefer existing project patterns; apply _KISS_ and _YAGNI_.
- Drive every listed gap through test→*implement*; treat red checks as
  ordinary remediation work.
- Hold exclusive authority for source edits during `/fix`, limited to
  files required by named gaps.
- Never inspect forward tasks or preserve forward seams; remediation
  closes named gaps only.
- When closing a named gap invalidates an existing test's now-incorrect
  expectation, update that test to match; make no other contract change
  beyond what the named gap requires; never weaken, skip, or delete
  tests to force green.

## Constraints

- May edit source, tests, documentation, configuration, and other
  _non-SPAE_ project files only when named gaps require them.
- May delete `.spae/current/FIX.md` and update
  `.spae/current/STATE.json` only after successful verification.
- Never read or edit `.spae/current/PLAN.md` or `.spae/current/SPEC.md`.
- Never mark a task `done`, advance a cursor, change task registry
  entries, or claim _workstream_ completion.
- Never add _SPAE_ artifacts or `STATE.json` fields.
- Never act on observations, invent findings, inspect forward tasks, or
  expand remediation beyond named gaps.
- Never stage or commit `.spae/` artifacts.
- **Autonomy**: Never ask users for input or clarification
  mid-execution; halts and failures stop autonomously.
- **Full autonomy**: Never request or require human execution, an
  attended terminal, an interactive session, or human presence. Treat
  such a dependency as an out-of-scope failure.
- No hacks, workarounds, shortcuts, suppressed diagnostics, or weakened
  type contracts.

## Verification

- Entry state contains `phase: fix` and one matching active in-progress
  task.
- `FIX.md` task identifier matches state; every `## Gaps` item receives
  a passing test and relevant project-check evidence.
- Every changed project file maps to a named gap; no change follows an
  observation, plan acceptance item, verification item, forward task, or
  unrelated concern.
- Changed tests cover expected behavior, failure modes, and edge cases
  without CI-parity violations.
- No self-introduced cleanup violation remains per
  `references/cleanup-guide.md`.
- Successful remediation deletes `FIX.md`, changes only state `phase` to
  `check`, retains the active task `in_progress`, and leaves cursor,
  task registry, status, version, and _workstream_ untouched.
- Successful output uses guide template C verbatim; no extra _SPAE_
  status block appears.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
- Emit the selected result as live markdown—never in a code fence.
- Output nothing outside the execution summary and applicable guide
  template.
- Source every `SPAE Status` value from the confirmed re-read, never
  from working memory of intent.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**: [Terse remediation actions]
- **Files**: [Terse affected source and SPAE artifacts]
- **Findings**: [Closed gaps or failure]

> **SPAE Status** • `workstream-name`
> **Active Task**: `T-XXX` - [Task title]
> **Result**: Gaps addressed, `FIX.md` removed
>
> _Run `/check` to re-verify the task._
```
<!-- prettier-ignore-end -->
