---
name: troubleshoot
description:
  Reproduces a failure, isolates each root cause with evidence, and
  writes a self-contained, fix-ready diagnosis to `<slug>-diagnosis.md`
  in the current folder, or refines an existing diagnosis in place, for
  an independent agent to fix. Use for failures, regressions, unclear
  errors, flaky behavior, broken tests, build issues, runtime faults, or
  unexpected output.
user-invocable: true
argument-hint: "<symptom | path/to/diagnosis.md>"
---

# Troubleshoot

## When to use

- Diagnose failures, regressions, unclear errors, flaky behavior, broken
  tests, build issues, runtime faults, or unexpected output.
- Hand an independent agent, with no memory of this run, a diagnosis it
  fixes without re-investigating.
- Re-diagnose after a failed fix attempt or code drift: refine the
  existing diagnosis.
- Execute immediately upon invocation; don't wait for confirmation.

## Goal

- Reproduce the failure, isolate each root cause with evidence, and
  settle a fix direction; leave no open hypothesis.
- Write the target and change nothing else:
  - `Draft`: a new `./<slug>-diagnosis.md`.
  - `Refine`: the supplied diagnosis, in place.

## Input

- `Draft`: symptom—issue, error, failing command, stack trace, test
  failure, or incorrect output—from the argument, the conversation, or a
  file; failing declared checks when the request names no symptom.
- `Refine`: path to an existing diagnosis, plus any new evidence—failed
  fix attempt, new symptom—from the argument or the conversation.
- Project instruction and architecture docs, when present—for example
  `AGENTS.md`, `CONTRIBUTING.md`, `README.md`.
- Codebase sections the failure touches.
- `references/DIAGNOSIS.md`: section template.
- `references/prose-protocol.md`, `references/outcome-guide.md`,
  `references/verification-guide.md`,
  `references/shell-command-guide.md`.

## Workflow

Select path by argument:

- **`Refine`**: argument names an existing file holding a diagnosis.
- **`Draft`**: otherwise; a file holding only a symptom supplies the
  symptom.

1. **GATE**—Make no writes:
   - Select `Draft` or `Refine`; set the target:
     - `Draft`: require an actionable symptom; absent one, run the
       repository's declared checks and adopt the first failure; derive
       a kebab-case `<slug>` from the symptom; target
       `./<slug>-diagnosis.md`; confirm it doesn't exist.
     - `Refine`: target the supplied file; read it in full.
   - Inside a git repository, record `git --no-pager rev-parse HEAD` and
     `git --no-pager status --porcelain` as `Baseline`.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—Name the failure, scope, and path in one sentence:
   - Every file except the target stays unmodified.
   - Read project instruction and architecture docs in full when
     present.
3. **PLAN**—Declare the work:
   - Read `references/shell-command-guide.md`.
   - `Refine`: build a claim ledger—every finding, hypothesis, and claim
     in the target, with its section.
   - Name the reproduction command and the codebase sections the
     investigation needs.
   - State one likely root cause and one targeted check confirming or
     rejecting it.
4. **ACT**—Reproduce, isolate, draft:
   - Reproduce the failure; record command, output, and exit code; on
     flakiness, measure the failure rate.
     - `Refine`: re-run the target's `Reproduction` first; record drift
       against its `Baseline`.
   - On coexisting issues or expensive reproduction, triage severity and
     scope before observing further.
   - Run the targeted check; on rejection, log it under `Ruled out` and
     return to **PLAN**.
   - After 3 rejections, stop generating hypotheses; trace data flow
     from the entry point.
   - `Draft`: draft per `references/DIAGNOSIS.md` and **Directives**.
   - `Refine`: re-baseline; reconcile every claim-ledger entry against
     the new evidence—confirm, revise, or move to `Ruled out`;
     restructure per `references/DIAGNOSIS.md` and **Directives**.
5. **VERIFY**—Loop over **Verification** criteria:
   - For each failure: return to **ACT**, fix, then re-enter **VERIFY**.
   - Exit only when every criterion passes.
6. **PERSIST**—Write the target—`Draft`: create; `Refine`: overwrite in
   place; re-read it to confirm the content.
7. **REPORT**—Emit result following result directives and using result
   template; then stop.

## Directives

- Optimize for agent, token, and context efficiency.
- Consult `references/prose-protocol.md` and
  `references/outcome-guide.md` before drafting; apply the guide's
  substitution test to `Fix direction`, `Scope`, and `Verification`;
  every other section records evidence or settled items—non-derivable
  facts the guide keeps.
- **Self-contained**: the fixing agent acts on the diagnosis with no
  memory of this run or conversation; keep it self-contained, explicit,
  and token-dense:
  - Define non-standard terms on first use.
  - Cite locations as `path:line` plus enclosing symbol, valid at
    `Baseline`.
  - Inline a minimal reproduction script under `Reproduction` when no
    repository command reproduces the failure.
  - Never reference conversation context, prior runs, or paths absent
    from the repository, such as deleted experiment directories.
- **Claims become scope**: the fixer turns every claim into a change,
  test, or exclusion; write only what merits fixing, preserving, or
  proving.
- **Condense, never drop** (`Refine`): tighten wording; keep every
  finding, hypothesis, and rationale; move a disproven finding to
  `Ruled out`, never silently.
- **Evidence binds**: `Proof` and `Ruled out` record observed,
  repeatable outcomes, never inference stated as fact; state an unrun
  check plainly.
- **One hypothesis at a time**: conclude nothing until a check confirms
  or rejects it.
- **Root cause, not symptom**: trace each finding to the earliest defect
  in its causal chain; a symptom site never qualifies. Name contract
  mismatches and unhandled failure paths explicitly.
- **Confidence**, per finding:
  - `Confirmed`: a check reproduces the causal chain.
  - `Suspected`: evidence narrows the cause but can't confirm it—for
    example, confirmation needs external services, credentials,
    hardware, or production data; pair with `Missing evidence`.
- **Result**, in the target's `Status`:
  - `Diagnosed`: failure reproduced; every finding `Confirmed`.
  - `Inconclusive`: failure reproduced; a finding stays `Suspected`, or
    none located.
  - `Not Reproduced`: no attempt reproduced the symptom; list every
    condition tried under `Reproduction`.
- **Severity triage**:
  - Grade each finding by impact: `critical`—data loss, crash, or
    security; `high`—broken feature or contract; `medium`—degraded
    behavior with a workaround; `low`—cosmetic.
  - Rank findings most severe first.
  - List incidental defects outside the symptom's causal chain under
    `Scope` `Exclude` with `path:line`, never as findings.
- **Fix direction, not a diff**: per finding, name the root-cause site,
  the corrected behavior there, the invariants it keeps, and coupling
  with other findings; never the edit or a code patch—leave
  implementation to the fixer.
- **Rejected fixes**: log each plausible fix carrying a defect, with its
  defect—only candidates this failure invites, never boilerplate:
  - Guards, retries, or timeouts masking an upstream fault.
  - Suppression comments—`@ts-ignore`, `eslint-disable`,
    `# type: ignore`.
  - Type weakening—`as any`, non-null `!`, broadened unions.
  - Weakened, skipped, or deleted tests.
  - Build or tool configuration edits.
- **Regression test**: under `Verification`, specify the triggering
  input and asserted behavior—failing at `Baseline`, passing after the
  fix; leave test location and design to the fixer; when impractical,
  record why under `Accepted limits`.
- **YAGNI**: discard unrequested scope, speculative refactors, and
  theoretical hardening; log each discard under `Rejected fixes` with a
  one-line rationale.
- **Codebase fit**: prefer fix directions matching existing patterns.
- **Size**: scale detail to failure size; write `None` under a section
  without content; keep headers intact.
- **Proportional verification**, per `references/verification-guide.md`:
  - Pair each outcome with the lowest evidence-ladder rung proving it.
  - Require only tooling the repository already declares or installs.
  - File outcomes only a real GUI, browser, or native input can prove
    under `Accepted limits`; require such evidence only when the request
    explicitly asks or the repository already declares the tooling.
  - Never prescribe rigs, recipes, pixel coordinates, key sequences, or
    tooling provisioning.
- **Plan boundary**: omit task decomposition and implementation
  sequencing; leave them to the fixer.

## Constraints

- **Write scope**: author writes only to the target; never edit any
  other repository file, even to instrument; byproducts of the project's
  own commands count as the project's.
- **Read-only commands**: run project commands without write flags—never
  snapshot updates, `--fix`, `--write`, or migrations.
- **Experiments**:
  - Keep each minimal, unattended, timeout-bounded, and confined to a
    `mktemp -d` directory outside the repository; delete it before
    `PERSIST`.
  - Instrument, bisect, or check out history only in a disposable copy
    or clone inside an experiment directory.
  - Use installed tooling only; never provision tooling or build GUI or
    native-input rigs unless the request explicitly asks.
  - Isolate from the user's desktop, input devices, browser profiles,
    accounts, and live services.
- **Autonomy**: never ask the user for input mid-execution; never
  propose steps requiring human execution, an attended terminal, or
  human presence.
- **Version control and release**: never mutate the repository's git
  state; never propose or run package publishing or deployments.
- **No fixes**: after `REPORT`, stop; never apply a fix.
- **Halt conditions**: halt without writing; report `Failed` with a
  diagnostic under `Findings`:
  - `Draft`: no actionable symptom, and every declared check passes.
  - `Draft`: `./<slug>-diagnosis.md` already exists.
  - `Refine`: target unreadable or empty.

## Verification

- The target exists, follows `references/DIAGNOSIS.md` section order,
  and complies with `references/prose-protocol.md`.
- The target stays self-contained: no reference to conversation context,
  prior runs, or paths absent from the repository; non-standard terms
  carry definitions.
- `Reproduction` runs unattended from the repository root and yields its
  `Fails with` outcome at `Baseline`; `Not Reproduced` lists every
  condition tried.
- Each finding cites `path:line` and symbol, causal chain, proof,
  severity, and confidence, at its earliest causal defect; each
  `Suspected` finding names its `Missing evidence`.
- `Status` `Result` matches the **Result** rules.
- Every rejected hypothesis appears under `Ruled out` with its
  disproving check.
- Every finding carries a `Fix direction` entry; every `Fix direction`,
  `Scope`, and `Verification` line passes the
  `references/outcome-guide.md` substitution test; no code patch or
  implementation sequence appears.
- `Refine`: every claim-ledger entry maps to a target section; no claim
  or rationale vanishes.
- Each `Verification` row names existing repository tooling and its
  ladder rung; a regression test spec or its `Accepted limits` rationale
  appears; no new tooling, rig, recipe, coordinate, or key sequence
  appears.
- GUI-, browser-, or native-input-only outcomes sit under
  `Accepted limits`, unless the request opted in.
- Section depth matches failure size.
- No experiment directory remains; no authored edit touches a file
  besides the target.

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
  - [Diagnosis path]
- **Findings**:
  - [Terse list of notable findings, risks, or halt diagnostics]
- **Summary**:
  - **Root causes**: [Terse list of findings with severity and confidence]
  - **Accepted limits**: [Terse list of accepted limits and residual risks]

> **Troubleshoot Status** • `[slug]`
> **Result**: [Diagnosed | Inconclusive | Not Reproduced | Failed]
> **Mode**: [Draft | Refine]
> **Impact**: [Terse impact statement]
> **Path**: `[target path]`
>
> _Fix from the diagnosis in a fresh context._  _(unless failed or not reproduced)_
```
<!-- prettier-ignore-end -->
