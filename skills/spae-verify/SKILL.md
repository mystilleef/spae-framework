---
name: spae-verify
description:
  Arbiter for the `SPAE` framework. Judges the implementation against `SPEC.md`,
  then completes the `workstream` or routes it to `/spec`.
user-invocable: true
argument-hint: ""
---

# Verify (`SPAE`)

## When to use

- `STATE.json` reads `phase: verify`: judge the implementation against
  `SPEC.md`.

## Goal

- Judge the implemented `workstream` against every `SPEC.md` `R-NNN` as the
  final arbiter, recording every hard block in `VERIFY.md`.
- On `Pass`, complete the `workstream` (`phase: done`). On `Revision required`,
  route it to `phase: spec`.

## Input

Read only what the verdict requires:

- `.spae/current/STATE.json`, with field reference, directives, and snapshots in
  `references/STATE.md`.
- `.spae/current/SPEC.md`.
- `.spae/current/PLAN.md`: task IDs and `Scope` fields.
- Repository source, tests, docs, configuration, and logs the `workstream`
  changed, for analysis.

Never read `.spae/current/VERIFY.md`, since `SPEC.md` holds all requirements.

## Workflow

1. **GATE**—Make no writes:
   - Parse `.spae/current/STATE.json` and self-heal missing metadata: `version`
     (`"1.0"`), `workstream` (target directory name), `status` (`"active"`).
     `PERSIST` writes the healed fields.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal in one sentence:
   - `SPEC.md` and `PLAN.md` stay unmodified, no direct edit reaches source or
     tests, and no write precedes `PERSIST`.
   - Read `SPEC.md` in full, capturing every `R-NNN` into a coverage checklist.
   - Read `PLAN.md` task `Scope` fields to bound `workstream` changes.
3. **PLAN**—Declare the evidence map:
   - Read `references/verification-guide.md` and
     `references/shell-command-guide.md`.
   - Map each `R-NNN` to the evidence that proves it: a `Testing strategy`
     command, a project check, or source.
   - Halt on any **Halt conditions** entry.
4. **ACT**—Gather evidence and label findings:
   - Run the project checks and every `SPEC.md` `Testing strategy` command.
   - Judge each `R-NNN` against command output, `workstream` changes, and
     source.
   - Label each finding with exactly one tag:
     - **Hard block**—drives `Revision required`. Cite reproducible evidence on
       realistic input—input or state `SPEC.md` explicitly names or ordinary use
       produces, never a theoretical risk, contrived harness, or adversarial
       host bypass:
       - Missing or incorrect required behavior on realistic input.
       - Harm the `workstream` changes cause on realistic input. Cite the
         contract, invariant, or regression it breaks:
         - A crash, or wrong or corrupted output.
         - A regression.
         - A broken contract: one the code, tests, docs, or `SPEC.md` already
           state—never one inferred anew.
       - A project-check failure the `workstream` causes.
       - A spec defect: an `R-NNN` no available automated evidence proves—such
         as one needing human presence or tooling the repository never
         declares—or one lacking a confirmed observable host discriminator.
     - **Soft finding**—never a verdict input:
       - Absent test coverage of explicit required behavior.
       - An unsafe optimization.
       - Speculative abstraction, defensive bloat, or complexity no `R-NNN`
         grounds, cited from `workstream` changes—never a theoretical risk or
         stylistic preference. Code preventing a defect reproducible on
         realistic input counts as grounded.
     - **Observation**—never a verdict input, even when reproduced:
       - Thin edge-case coverage.
       - A coverage extension: handling missing for a member outside an
         `R-NNN`'s named members while every named member works and the changes
         cause no harm.
       - Harm or an `R-NNN` miss surfacing only under contrived input, crafted
         paths or layouts absent from the project, or adversarial host bypasses.
       - An ambiguous `R-NNN`, or a minor deviation outside `SPEC.md` scope.
       - An _unrequested_ guardrail, a theoretical risk, or an `Out of scope`
         residual risk.
       - A check failure the `workstream` doesn't cause.
   - Head each finding with the `R-NNN` it concerns, else `none`.
   - On any `Hard block`, draft `VERIFY.md` per `references/VERIFY.md`.
   - Apply **Directives** and **Constraints**.
5. **VERIFY**—Loop over **Verification** criteria for the verdict and the
   `VERIFY.md` draft:
   - For each failure: return to `ACT`, complete the evaluation, then re-enter
     `VERIFY`.
   - Exit only when every criterion passes.
   - Halt only on a **Halt conditions** entry.
6. **PERSIST**—Write in order:
   - On a `Revision required` verdict, write `.spae/current/VERIFY.md`,
     replacing any prior copy.
   - Write `STATE.json` per the `references/STATE.md` exit snapshot matching the
     verdict.
   - Re-read `STATE.json`. On a mismatch against **Verification** state
     criteria, rewrite and re-read before `REPORT`.
   - On a `Pass` verdict, delete `.spae/current/VERIFY.md` when present, then
     remove the `.spae/current` symlink.
7. **REPORT**—Emit result following result directives and using result template:
   - `Result` by re-read `phase`: `done`→`Pass`, `spec`→`Revision required`, a
     halt→`Failed`.
   - List each `Hard block`, then each `Soft finding`, then each `Observation`
     under `Findings`.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Refine and optimize `VERIFY.md` for agent consumption: agents read it for
  varied purposes, with no memory of this run. Keep it self-contained, explicit,
  and token-dense, and make each `Hard block` actionable without repeating the
  investigation: the unmet `R-NNN` outcome with evidence. No `Expected` or
  `Concern` prescribes a remedy. Place an advisory remedy hint under a hard
  block's `Guidance` only when its evidence points at one, per
  `references/outcome-guide.md` `## Guidance`.
- Consult `references/prose-protocol.md` and `references/outcome-guide.md`
  before drafting `VERIFY.md`.
- **IMPORTANT:** Return the result to the caller.

## Constraints

- **Write scope**: write only `.spae/current/VERIFY.md` and
  `.spae/current/STATE.json`. On `Pass`, delete `VERIFY.md` and the
  `.spae/current` symlink. Forbid all other writes. Write incidental run
  outputs—logs, reports, experiment files—to scratch: a private temporary
  directory outside the project, removed when the run ends. Scratch writes and
  byproducts of a command run for evidence, such as formatter rewrites, never
  count as this phase's writes. Never run a command for its write effect outside
  this scope. Read source code only for analysis.
- **Phase boundary**: judge the whole `workstream`, then complete it or hand off
  work to `/spec`.
- **Version control and release**: never execute git mutations (staging,
  commits, branches, tags, pushes) or release operations. Never stage or commit
  `.spae/`.
- **Autonomy**: never ask users for input or clarification mid-execution—halts
  and failures stop autonomously. Never perform or request human execution, an
  attended or interactive terminal, or human presence.
- **State schema**: never introduce `STATE.json` fields outside
  `references/STATE.md`.
- **Halt conditions**: halt without writing and report `Failed` with a
  diagnostic under `Findings`:
  - `.spae/current` missing or dangling.
  - `STATE.json` missing or holds unparseable JSON syntax.
  - `STATE.json` `phase` other than `verify`.
  - `SPEC.md` or `PLAN.md` missing.
  - A `PLAN.md` task absent from `tasks` or reading other than `"done"`.
  - Evidence can't run for a cause outside the repository: a broken external
    dependency or an environment failure.
- **Scope control**: judge only `SPEC.md` requirements and `workstream`-caused
  regressions and harm, adding no requirements or verdict inputs beyond them,
  and never widening a closed bound. `SPEC.md` `## Guidance` never acts as a
  verdict input.

## Verification

- Every `R-NNN` judged against cited automated evidence.
- Every finding matching a `Hard block` or `Soft finding`
  item—`workstream`-added bloat included—carries that tag, and every other
  finding—coverage extensions and harm or `R-NNN` misses surfacing only under
  contrived input or adversarial host bypasses included—carries `Observation`.
- Every harm `Hard block` cites the contract, invariant, or regression it
  breaks.
- Verdict reads `Pass` only with zero `Hard block` findings—any `Hard block`
  yields `Revision required`.
- On `Revision required`, the `VERIFY.md` draft matches `references/VERIFY.md`:
  - Every finding headed by its `R-NNN`, else `none`.
  - Every `Hard block` with `File`, `Expected`, `Actual`, and reproducible
    `Evidence`.
  - Every `Expected` names the unmet `R-NNN` outcome.
  - No `Expected` or `Concern` prescribes a remedy, and every `Guidance` rests
    on its hard block's `Evidence` and follows the `references/outcome-guide.md`
    `## Guidance` rules.
- No `VERIFY.md` finding requests human execution, an attended or interactive
  terminal, or human presence.
- `STATE.json` matches the `references/STATE.md` exit snapshot for the verdict.
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
- **Findings**:
  - [Terse list of notable findings]
- **Summary**:
  - [Terse list of summary of changes]

> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Pass | Revision required | Failed]
> **Next Phase**: `/spec`  _(if revision required)_
```
<!-- prettier-ignore-end -->
