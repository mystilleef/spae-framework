---
name: spae-build
description:
  Atomic Execution for the `SPAE` framework. Executes exactly one atomic task
  from `PLAN.md`.
user-invocable: true
argument-hint: ""
---

# Build (`SPAE`)

## When to use

- `STATE.json` reads `phase: build`: build the active `PLAN.md` task.

## Goal

- Build exactly the active `PLAN.md` task so it meets every `Acceptance`
  criterion, proves its runtime behavior through comprehensive, robust tests,
  serves its `Intent` and the plan `## Goal`, and leaves seams for forward
  tasks.
- Advance the `workstream` to `phase: check`.

## Input

Read only what the active task requires:

- `.spae/current/STATE.json`, with field reference, directives, and snapshots in
  `references/STATE.md`.
- `.spae/current/PLAN.md`, carrying all goal context and the task's advisory
  `Guidance`.
- Repository source, tests, docs, and configuration the active task touches.

## Testing

See `references/testing-guide.md` for test structure, isolation, mocking,
assertion, and performance standards, and for selecting project testing guides
(`TESTING*.md` at the project root). Project guides override it on conflict.

## Cleanup

See `references/cleanup-guide.md` for the Self-cleanup checklist and diff-only
audit scope.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json` and self-heal missing metadata: `version`
     (`"1.0"`), `workstream` (target directory name), `status` (`"active"`).
     `PERSIST` writes the healed fields.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - `PLAN.md` stays unmodified, forward tasks stay unimplemented, and the task
     diff stays within the task `Scope` and its tests.
   - Read the plan `## Goal` and the active task in full. Read the `Acceptance`
     of its `Dependencies` tasks as the contracts it may rely on, and of forward
     tasks as seams to keep open.
   - Capture the pre-task baseline per `references/cleanup-guide.md`.
   - Mark in progress—the sole write before `PERSIST`, which reruns repeat
     safely: set `STATE.json` `tasks[active_task_id]` to `"in_progress"`.
3. **PLAN**—Declare the implementation path:
   - Read `references/testing-guide.md`, each project testing guide covering the
     files under test, and `references/shell-command-guide.md`.
   - Map the test surface per behavior criterion—expected behavior, failure
     modes, and edge cases—and the covering test per preserved behavior at risk.
   - `PLAN.md` fixes outcomes, `Scope`, and `Context` decisions, never method.
     Choose among valid implementations by fit to the task `Intent`, the plan
     `## Goal`, and forward seams, not local convenience. Weigh the task's
     advisory `Guidance` by the same fit, never following it blindly: accept,
     partially accept, or ignore it. Binding lines and the repository win on
     conflict.
   - Halt on any **Halt conditions** entry.
4. **ACT**—Per `Acceptance` criterion, repeat until it passes:
   - Behavior criterion—runtime behavior the task adds or changes: the minimal
     code meeting it and tests covering its test surface, written in either
     order.
   - Preserved behavior at risk—existing runtime behavior the task's edits could
     break: an existing or new covering test passing on the pre-task and
     post-task state.
   - Any other criterion—tooling, configuration, or docs: the minimal edit
     meeting it, proven by its planned `Verification` step, or by reading for
     prose per `references/verification-guide.md`—never a dedicated test.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for the active task:
   - Audit task edits against the pre-task baseline using the Self-cleanup
     checklist in `references/cleanup-guide.md`, removing every self-introduced
     artifact before proceeding.
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - Write `STATE.json` per `references/STATE.md` exit snapshot.
   - Re-read `STATE.json`. On a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
7. **REPORT**—Emit result following result directives and using result template:
   - `Result`: `Implemented, pending check` after `PERSIST`, else `Failed`.
   - List under `Findings`: each assumption made, each forward task designed
     around, and one line per divergence from `Guidance`:
     `diverged from Guidance: <why>`.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Align with existing codebase patterns and avoid speculative design.
- Write every test category the task demands—unit, integration,
  end-to-end—deriving each test from its `Acceptance` criterion, never from the
  implementation's output.
- Treat a failing test or check as ordinary build work and drive it green by
  correcting its cause.
- When the task legitimately changes a contract, update the tests it invalidates
  to the new contract.
- Execute `Verification` steps as planned per
  `references/verification-guide.md`—never discover, install, or calibrate
  tooling ad hoc.
- Resolve requirements the task leaves open with the assumption most consistent
  with the task `Intent` and the plan `## Goal`, then proceed. Never ship a
  locally correct, globally wrong implementation.
- **IMPORTANT:** Return the result to the caller.

## Constraints

- **Write scope**: edit only the source, tests, docs, and configuration the
  active task requires, plus `.spae/current/STATE.json`. Forbid all other
  writes. Write incidental run outputs—logs, reports, experiment files—to
  scratch: a private temporary directory outside the project, removed when the
  run ends. Scratch writes and byproducts of a command run for evidence, such as
  formatter rewrites, never count as this phase's writes. Never run a command
  for its write effect outside this scope. Never delete pre-existing uncommitted
  files.
- **Phase boundary**: execute exactly one task and hand off work to `/check`,
  never marking a task `"done"` or moving the cursor.
- **Version control and release**: never execute git mutations (staging,
  commits, branches, tags, pushes) or release operations. Never stage or commit
  `.spae/`.
- **Autonomy**: never ask users for input or clarification mid-execution—halts
  and failures stop autonomously. Never perform or request human execution, an
  attended or interactive terminal, or human presence.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt with no further `STATE.json` write and report
  `Failed` with a diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `build`.
  - `PLAN.md` missing, `cursor.active_task_id` missing, or the active task
    absent from `PLAN.md`.
  - `tasks[active_task_id]` reads `"done"`.
  - A `Dependencies` task not `"done"` in `tasks`.
  - The task can't pass within its scope:
    - An infeasible `Acceptance` criterion, including one requiring ungrounded
      host assumptions, private-API access, or out-of-scope or excluded edits
      for lack of an observable discriminator.
    - A broken external dependency, a planned `Verification` step that can't
      run, or a step requiring human presence.
    - The task as written contradicting the plan `## Goal`, its `Intent`, or a
      forward task—an undeniable conflict, not a subjective doubt.
- **Scope control**: keep the task diff within the task `Scope` and its tests,
  with no incidental refactoring, cleanup, formatting, or dependency churn, and
  no speculative abstraction, _unrequested_ complexity, or defensive bloat
  beyond what `Intent` and `Acceptance` require.
- **Integrity**: fix issues properly and idiomatically, with no hacks,
  workarounds, or shortcuts:
  - Never suppress compiler or linter diagnostics—for example, `@ts-ignore`,
    `eslint-disable`, `@SuppressWarnings`, `# type: ignore`.
  - Never weaken type contracts to silence errors—for example, `as any`, `!`
    non-null assertions, or broadened union types.
  - Never edit build or tool configuration as a workaround—change it only when
    an `Acceptance` criterion requires it.
  - Never weaken, skip, delete, or game a test to force a pass.
  - Never mask an upstream fault at its symptom site—for example, a guard,
    retry, timeout, catch-all, or special case keyed to a test or `Verification`
    input.

## Verification

- Every `Acceptance` criterion passes.
- Every task `Verification` step passes.
- Relevant project tests pass with no new failures.
- Every behavior criterion carries passing tests covering its test surface
  exhaustively, and every preserved behavior at risk a test passing on the
  pre-task and post-task state.
- Every added or updated test fails when the behavior it covers breaks and
  passes the CI parity rules in `references/testing-guide.md`.
- No self-introduced artifact remains per `references/cleanup-guide.md`.
- Implementation advances the task `Intent` and the plan `## Goal`, with no
  forward-task work performed.
- The task diff breaks no **Scope control** or **Integrity** rule.
- `STATE.json` specifies `phase: "check"`,
  `tasks[active_task_id]: "in_progress"`, and the entry cursor.
- This phase wrote no file outside **Write scope**.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`, so a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, early stop, or halt—with the result
  template as the final message, never on progress narration.
- Set `Result` to exactly one template literal, verbatim. Report an early stop
  or halt lacking its own literal as `Failed`, with the reason under `Findings`.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.
- Source every `SPAE Status` value from confirmed re-read, never from working
  memory of intent.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of affected files]
- **Tests**:
  - [Terse list of tests written—behaviors, failure modes, and edge cases covered]
- **Findings**:
  - [Terse list of notable findings]
- **Summary**:
  - [Terse list of summary of changes]

> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Implemented, pending check | Failed]
> **Active Task**: `T-XXX` - [Task title]
>
> _Run `/check` to verify the completed task._  _(unless failed)_
```
<!-- prettier-ignore-end -->
