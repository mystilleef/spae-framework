---
name: spae-fix
description:
  Gap Remediation for the `SPAE` framework. Closes the gaps `FIX.md`
  lists for the active task, then routes it to `/check`.
user-invocable: true
---

# Fix (`SPAE`)

## When to use

- `STATE.json` reads `phase: fix`: close the gaps `FIX.md` lists for the
  active task.

## Goal

- Close exactly the `FIX.md` `## Gaps` items for the active task with
  minimal changes, test-first where behavior changes.
- Advance the `workstream` to `phase: check`.

## Input

Read only what the `## Gaps` items require:

- `.spae/current/STATE.json`; `references/STATE.md` holds field
  reference, directives, and snapshots.
- `.spae/current/FIX.md`; it carries all task context: the task ID and
  title in its heading, `## Intent`, and `## Gaps` items with `File`,
  `Expected`, `Actual`, and `Evidence`.
- Repository source, tests, docs, and configuration the `## Gaps` items
  touch.

## Testing

See `references/testing-guide.md` for test structure, isolation,
mocking, assertion, and performance standards.

## Cleanup

See `references/cleanup-guide.md` for the self-introduced-artifact
checklist and diff-only audit scope.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json`; self-heal missing metadata:
     `version` (`"1.0"`), `workstream` (target directory name), `status`
     (`"active"`); `PERSIST` writes the healed fields.
   - Self-heal state drift: treat a `"todo"` or missing
     `tasks[active_task_id]` as `"in_progress"` until `PERSIST`.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - `FIX.md` stays unmodified until `PERSIST` deletes it; directly
     modify no code outside the `## Gaps` items.
   - Read `FIX.md` in full.
   - Capture the pre-task baseline per `references/cleanup-guide.md`.
3. **PLAN**—Declare the remediation path:
   - Read `references/testing-guide.md` and
     `references/shell-command-guide.md`.
   - Map each `## Gaps` item to its minimal edit; for a behavior gap,
     map the test surface: expected behavior, failure modes, and edge
     cases.
   - Halt on any **Halt conditions** entry.
4. **ACT**—Per `## Gaps` item, repeat until re-checking its `Evidence`
   shows the `Expected` result:
   - Behavior gap—runtime behavior misses `Expected`: reproduce it with
     a failing test, reusing an existing test that already fails on it;
     then write the minimal code that passes it.
   - Any other gap—a leftover artifact, diff bloat, a defective test, or
     a static-check failure: make the minimal edit that closes it.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for the `## Gaps`
   items:
   - Audit task edits against the pre-task baseline using the
     Self-cleanup checklist in `references/cleanup-guide.md`; remove
     every self-introduced artifact before proceeding.
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - Write `STATE.json` per `references/STATE.md` exit snapshot.
   - Re-read `STATE.json`; on a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
   - Delete `.spae/current/FIX.md`.
7. **REPORT**—Emit result following result directives and using result
   template:
   - `Result`: `Gaps addressed, FIX.md removed` after `PERSIST`, else
     `Failed`.
   - List each closed gap under `Findings`.

## Directives

- Optimize for agent, token, and context efficiency.
- Align with existing codebase patterns; avoid speculative design.
- For a behavior gap, never write production code before its test
  exists.
- Treat a failing test or check as ordinary fix work; drive it green.
- When closing a gap invalidates an existing test, update that test to
  the new contract.
- Re-check `Evidence` and run project checks per
  `references/verification-guide.md`; never discover, install, or
  calibrate tooling ad hoc.

## Constraints

- **Write scope**: edit only the source, tests, docs, and configuration
  the `## Gaps` items require, plus `.spae/current/STATE.json` and the
  `.spae/current/FIX.md` deletion, both at `PERSIST`; forbid all other
  writes. Byproducts of a command run for evidence, such as a
  formatter's rewrites, never count as this phase's writes; never run a
  command for its write effect outside this scope. Never delete
  pre-existing uncommitted files.
- **Phase boundary**: remediate exactly one task; hand off work to
  `/check`; never mark a task `"done"` or move the cursor.
- **Version control and release**: never execute git mutations (staging,
  commits, branches, tags, pushes) or release operations. Never stage or
  commit `.spae/`.
- **Autonomy**: never ask users for input or clarification
  mid-execution; halts and failures stop autonomously. Never perform or
  request human execution, an attended or interactive terminal, or human
  presence.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt with no further `STATE.json` write; report
  `Failed` with a diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `fix`.
  - `cursor.active_task_id` missing.
  - `tasks[active_task_id]` reads `"done"`.
  - `FIX.md` missing, naming a task other than `cursor.active_task_id`,
    or listing no `## Gaps` item.
  - A gap can't close within its scope: an `Expected` result infeasible
    or contradicting the `## Intent` or another gap, a broken external
    dependency, an unrunnable `Evidence` command or project check, or a
    need for human presence.
- **Scope control**: close each `## Gaps` item as written and change
  nothing else; `## Intent` guides design, never scope. No incidental
  refactoring, cleanup, formatting, or dependency churn.
- **Integrity**: fix issues properly and idiomatically; no hacks,
  workarounds, or shortcuts:
  - Never suppress compiler or linter diagnostics—for example,
    `@ts-ignore`, `eslint-disable`, `@SuppressWarnings`,
    `# type: ignore`.
  - Never weaken type contracts to silence errors—for example, `as any`,
    `!` non-null assertions, or broadened union types.
  - Never edit build or tool configuration as a workaround; change it
    only when a `## Gaps` item requires it.
  - Never weaken, skip, delete, or game a test to force a pass.

## Verification

- Re-checking each `## Gaps` item's `Evidence` shows its `Expected`
  result.
- Every behavior gap carries a passing test covering expected behavior,
  failure modes, and edge cases.
- Relevant project tests pass with no new failures.
- Every added or updated test passes the CI parity rules in
  `references/testing-guide.md`.
- No self-introduced artifact remains per `references/cleanup-guide.md`.
- The task diff changes nothing beyond the `## Gaps` items.
- The task diff breaks no **Integrity** rule.
- `STATE.json` specifies `phase: "check"`,
  `tasks[active_task_id]: "in_progress"`, and the entry cursor.
- This phase wrote no file outside **Write scope**.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- Emit result template as live markdown—never in a code fence.
- Output nothing outside template.
- Source every `SPAE Status` value from confirmed re-read, never from
  working memory of intent.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of remediation actions]
- **Files**:
  - [Terse list of affected source and SPAE artifacts]
- **Findings**:
  - [Terse list of closed gaps or the failure diagnostic]
- **Summary**:
  - [Terse list of summary of changes]

> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Gaps addressed, `FIX.md` removed | Failed]
> **Active Task**: `T-XXX` - [Task title]
>
> _Run `/check` to re-verify the task._  _(unless failed)_
```
<!-- prettier-ignore-end -->
