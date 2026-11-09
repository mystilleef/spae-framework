---
name: spae-verify
description:
  Arbiter for the `SPAE` framework. Judges the implementation against
  `SPEC.md`; completes the `workstream` or routes it to `/spec`.
user-invocable: true
---

# Verify (`SPAE`)

## When to use

- `STATE.json` reads `phase: verify`: judge the implementation against
  `SPEC.md`.

## Goal

- Judge the implemented `workstream` against every `SPEC.md` requirement
  as the final arbiter; record every hard block in `VERIFY.md`.
- On `Pass`, complete the `workstream` (`phase: done`); on
  `Revision required`, route it to `phase: spec`.

## Input

Read only what the verdict requires:

- `.spae/current/STATE.json`; `references/STATE.md` holds field
  reference, directives, and snapshots.
- `.spae/current/SPEC.md`.
- `.spae/current/PLAN.md`: task IDs and `Scope` fields.
- Repository source, tests, docs, configuration, and logs the
  `workstream` changed, for analysis.

Never read `.spae/current/VERIFY.md`; `SPEC.md` holds every requirement.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json`; self-heal missing metadata:
     `version` (`"1.0"`), `workstream` (target directory name), `status`
     (`"active"`); `PERSIST` writes the healed fields.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - `SPEC.md` and `PLAN.md` stay unmodified; directly modify no source
     or tests; write nothing before `PERSIST`.
   - Read `SPEC.md` in full; capture every `R-NNN` into a coverage
     checklist.
   - Read `PLAN.md` task `Scope` fields to bound `workstream` changes.
3. **PLAN**—Declare the evidence map:
   - Read `references/verification-guide.md` and
     `references/shell-command-guide.md`.
   - Map each `R-NNN` to the evidence that proves it: a
     `Testing strategy` command, a project check, or source.
   - Halt on any **Halt conditions** entry.
4. **ACT**—Gather evidence and label findings:
   - Run the project checks and every `SPEC.md` `Testing strategy`
     command.
   - Judge each `R-NNN` against command output, `workstream` changes,
     and source.
   - Label each finding with exactly one tag:
     - **Hard block**—drives `Revision required`; cite reproducible
       evidence:
       - Missing or incorrect required behavior, a contract break, or a
         regression.
       - A project-check failure the `workstream` causes.
       - A spec defect: an `R-NNN` no available automated evidence
         proves, such as one needing human presence or tooling the
         repository never declares.
     - **Soft finding**—never a verdict input:
       - Absent test coverage of explicit required behavior.
       - An unsafe optimization.
       - Speculative abstraction, defensive bloat, or complexity no
         `R-NNN` grounds, cited from `workstream` changes—never a
         hypothetical risk or stylistic preference.
     - **Observation**—never a verdict input: thin edge-case coverage,
       an ambiguous requirement, a minor deviation outside `SPEC.md`
       scope, an _unrequested_ guardrail, a theoretical risk, an
       `Out of scope` residual risk, or a check failure the `workstream`
       doesn't cause.
   - Head each finding with the `R-NNN` it concerns, else `none`.
   - On any `Hard block`, draft `VERIFY.md` per `references/VERIFY.md`.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for the verdict and
   the `VERIFY.md` draft:
   - For each failure: return to `ACT`, complete the evaluation, then
     re-enter `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - On a `Revision required` verdict, write `.spae/current/VERIFY.md`,
     replacing any prior copy.
   - Write `STATE.json` per the `references/STATE.md` exit snapshot
     matching the verdict.
   - Re-read `STATE.json`; on a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
   - On a `Pass` verdict, delete `.spae/current/VERIFY.md` when present,
     then remove the `.spae/current` symlink.
7. **REPORT**—Emit result following result directives and using result
   template:
   - `Result` by re-read `phase`: `done`→`Pass`,
     `spec`→`Revision required`; a halt→`Failed`.
   - List each `Hard block`, then each `Soft finding`, then each
     `Observation` under `Findings`.

## Directives

- Optimize for agent, token, and context efficiency.
- Refine and optimize `VERIFY.md` for agent consumption: agents read it
  for varied purposes, with no memory of this run; keep it
  self-contained, explicit, and token-dense; make each `Hard block`
  actionable without repeating the investigation.
- Consult `references/prose-protocol.md` before drafting `VERIFY.md`.

## Constraints

- **Write scope**: write only `.spae/current/VERIFY.md` and
  `.spae/current/STATE.json`; on `Pass`, delete `VERIFY.md` and the
  `.spae/current` symlink; forbid all other writes. Byproducts of a
  command run for evidence, such as a formatter's rewrites, never count
  as this phase's writes; never run a command for its write effect
  outside this scope. Read source code only for analysis.
- **Phase boundary**: judge the whole `workstream`; complete it or hand
  off work to `/spec`.
- **Version control and release**: never execute git mutations (staging,
  commits, branches, tags, pushes) or release operations. Never stage or
  commit `.spae/`.
- **Autonomy**: never ask users for input or clarification
  mid-execution; halts and failures stop autonomously. Never perform or
  request human execution, an attended or interactive terminal, or human
  presence.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt without writing; report `Failed` with a
  diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `verify`.
  - `SPEC.md` or `PLAN.md` missing.
  - A `PLAN.md` task absent from `tasks` or reading other than `"done"`.
  - Evidence can't run for a cause outside the repository: a broken
    external dependency or an environment failure.
- **Scope control**: judge only `SPEC.md` requirements and
  `workstream`-caused regressions; add no requirement or verdict input
  beyond them.

## Verification

- Every `R-NNN` judged against cited automated evidence.
- Every finding matching a `Hard block` or `Soft finding`
  item—`workstream`-added bloat included—carries that tag; every other
  finding carries `Observation`.
- Verdict reads `Pass` only with zero `Hard block` findings; any
  `Hard block` yields `Revision required`.
- On `Revision required`, the `VERIFY.md` draft matches
  `references/VERIFY.md`: every finding headed by its `R-NNN`, else
  `none`; every `Hard block` with `File`, `Expected`, `Actual`, and
  reproducible `Evidence`.
- No `VERIFY.md` finding requests human execution, an attended or
  interactive terminal, or human presence.
- `STATE.json` matches the `references/STATE.md` exit snapshot for the
  verdict.
- This phase wrote no file outside **Write scope**.

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
- Emit result template as live markdown—never in a code fence.
- Output nothing outside template.
- Source every `SPAE Status` value from confirmed re-read, never from
  working memory of intent.

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

> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Pass | Revision required | Failed]
> **Next Phase**: `/spec`  _(if revision required)_
```
<!-- prettier-ignore-end -->
