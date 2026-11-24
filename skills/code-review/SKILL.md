---
name: code-review
description: >-
  Find bugs and potential issues in code changes. Use before merge, or rerun on
  an identical scope to surface missed findings.
user-invocable: false
argument-hint: "[optional: diff, commit, PR, file, or focus area]"
---

# Code review agent

## When to use

- Reviewing diffs, commits, PRs, or changed files before merge.
- Auditing generated code or refactors for regressions.
- Rerunning on an identical scope to surface findings an earlier run missed.

## Goal

Conduct a defensive, evidence-based review of local repository changes. Flag
only plausible, material defects—incorrect behavior, data loss, security
vulnerabilities, or crashes. Return prioritized findings with exact code
citations and advisory fix guidance. Repeat runs over an identical scope extend
the prior report and count only additions as new.

## Input

Determine scope from the first available source:

- The diff, commit, `PR`, files, or folders the invocation argument names.
- Current changes in the repository: staged, `unstaged`, and `untracked` files
  in a versioned project.

Gather intent grounding matching the resolved scope:

- Commit or `PR` scope: the commit messages or `PR` title and description.
- Uncommitted-changes or file scope: comments near each changed `hunk`, plus any
  intent the requester stated when invoking the review.

## Workflow

1. **GATE**—Identify changed files and diff boundaries, halting if no scope
   exists. Then resolve the ledger seed:
   - Run `scripts/fingerprint.sh` from the project root with the invocation
     argument verbatim—or `No arguments` without one—as its sole argument, and
     record the printed `fingerprint`.
   - When `code-review-report.yaml` in the project root carries a matching
     `fingerprint`, seed the ledger with its `findings` and
     `suppressed_findings` entries—the inherited entries—and inherit its
     `model`. Otherwise delete the report if present.
2. **ORIENT**—Read `references/code-review-guide.md` for categories, severity
   levels, decision rules, scope, and calibration. Read
   `references/report-schema.json` as the output contract, and
   `references/outcome-guide.md` `## Guidance` for each finding's `guidance`.
   Anchor to review goal and name what the review won't change.
   - Ground the review `model`, refining any inherited one:
     - Runtime execution model (single-threaded CLI, async loop, multi-threaded
       server, isolated worker) and threat model.
     - Trusted inputs—sources the user, project, or plugin controls, such as its
       source tree, install paths, and configuration—carry realistic values,
       never adversarial or contrived ones, in every category.
   - Limit validation to source inspection and isolated local checks, excluding
     live-system probing and exploit development.
   - Gather intent grounding (see Input) for the `hunks` under review before the
     phase sweep.
3. **ACT**—Execute:
   - Read relevant project documentation (`AGENTS.md`, `ORIENT.md`,
     `DESIGN.md`), nearby code, and tests for grounding.
   - Detect and run configured linters, type checkers, and static analysis,
     treating tool errors as confirmed findings.
   - Sweep all `PHASE_COUNT` (8) phases against a running ledger, seeded per
     _GATE_—a phase with zero new candidates never ends the sweep:
     - Each phase scans every category below in full before consulting the
       ledger—produce the complete candidate list first, then dedupe. Skipping
       already-covered ground before scanning defeats the sweep.
     - Phase `N` carries heightened focus on category `N` in the order
       below—focus adds attention without narrowing scope, and every phase still
       scans all 8.
     - Tag each candidate with a defect signature:
       `category:path:line-or-range:short-defect-slug`. Collapse instances
       sharing one root cause across call sites into one candidate, anchored at
       its primary site and naming the sibling sites. Treat a candidate as new
       only when no ledger entry describes the same defect or root
       cause—signatures key the match, and a reworded slug, shifted range, or
       sibling site never makes a known defect new.
     - Append new candidates to the ledger after each phase, then record one
       phase line: focus category, code traced for it (or why none applies), and
       new-candidate count.
   - Categories (every phase scans all):
     - **Correctness**: logic, conditions, bounds, formulas, collection
       mutation.
     - **Null and type safety**: null/undefined `dereferences`, unchecked
       Result/Option types, unsafe coercions.
     - **Concurrency**: shared mutable state, lock release paths,
       `read-modify-write` atomicity, `async` race conditions.
     - **Security**: injection, `hardcoded` credentials, auth bypass, `PII` in
       logs, unsafe `deserialization`, missing boundary validation.
     - **Resource management**: file, socket, connection, lock, or allocation
       without guaranteed release.
     - **Error handling**: silently discarded errors, wrong return on error
       branch, `unpropagated` errors.
     - **API misuse**: deprecated functions, wrong argument order, ignored
       return values, missing required options.
     - **Data integrity**: `unvalidated` index/size/key inputs, broken
       serialization contracts, truncation risk.
4. **VERIFY**—Run once, after the phase sweep completes—never per phase. Prove
   each ledger finding, inherited entries included, against code, project
   mandates, and the `model`, applying the guide's severity rules and decision
   rules:
   - Pass each finding through the evidence threshold—concrete, reachable,
     plausible trigger plus material impact—recorded as its `trigger`.
   - Rate severity by likelihood × impact, and weigh each `guidance.solution`
     for fix proportionality.
   - Drop out-of-scope new candidates. Never drop an inherited entry, so later
     runs keep its signature.
   - Route findings failing the evidence threshold or fix proportionality, or
     carrying qualifying intent evidence, to `suppressed_findings`, citing the
     failed test, the fix disproportion, or the intent evidence—never emit them
     in `findings`.
5. **PERSIST**—Skip only when both `findings` and `suppressed_findings` stay
   empty. Otherwise:
   - Re-run `scripts/fingerprint.sh` as in _GATE_. On output differing from the
     _GATE_ `fingerprint`—reviewed content changed mid-run—halt as `Failed`,
     naming the changed paths under `Findings`.
   - Write `code-review-report.yaml` to the project root per
     `references/report-schema.json`: record the `fingerprint`, the `model`, and
     each entry's `signature`, use `|` block scalars for multi-line values, and
     omit the `suppressed_findings` key when empty.
6. **REPORT**—Sort findings by severity. Emit the result following the result
   directives and result template.

## Directives

- Cite each finding with a quoted excerpt and `path:line`.
- Rank findings: `Critical`, `High`, `Medium`, `Low`, `Nit`.
  - Emit `Nit` only when trivially co-located with a higher-severity finding.
- `Result`, reported in the status block and the report `result`: `Issues Found`
  (any non-inherited `findings` entry) · `No New Issues` (inherited `findings`
  entries only) · `No Issues` (no findings).
- Verdict, reported in the status block and the report `verdict`:
  `Request Changes` (any Critical or High finding) · `Comment` (Medium or Low
  only) · `Approve` (no findings). Derive `Result` and verdict from `findings`
  only—`suppressed_findings` never shift either.
- Hold candidate findings and every `guidance.solution` to the `model`, `KISS`,
  and `YAGNI`: never demand defensive bloat or ungrounded guardrails, and keep
  theoretical defects outside realistic execution paths out of `findings`.
- Mark uncertainty explicitly: _"Context may change this finding, but…"_
- Give every `findings` and `suppressed_findings` entry advisory `guidance` per
  `references/outcome-guide.md` `## Guidance`: the minimal, targeted `solution`,
  plus `pattern`, `avoid`, and `tests` when they help—never a rewrite of the
  patch.
- Omit empty categories and "none found" sections.
- Verify findings against `AGENTS.md` before reporting.
- Keep `PHASE_COUNT` (8) equal to the category count as a single named
  constant—never scatter phase-count literals across the workflow.
- Open the result `Actions` list with the seed line (for example,
  `seeded 4 inherited entries` or `no seed`), then surface each phase line (for
  example, `phase 3 (Concurrency): traced usage cache writes; 1 new`), then the
  total (`ran 8/8 phases`), stating the cause of any shortfall.
- **IMPORTANT:** Return the result to the caller.

## Constraints

- No finding without direct code evidence.
- Preserve security coverage: trace trust boundaries, assess impact, and
  recommend fixes. Don't develop weaponized exploits, access live systems, or
  bypass safeguards to verify findings.
- No praise, broad commentary, or unrelated cleanup requests.
- No large raw tool output—summarize diagnostics.
- Don't change project source files during review.
- Run `VERIFY`, `PERSIST`, and `REPORT` once, after the phase sweep—never per
  phase.

## Verification

- Static analysis output checked when available and practical.
- Findings map to diff or file excerpts and line references, and every active
  finding carries a trigger passing the evidence threshold.
- Severity reflects likelihood × user impact, with security _exploitability_
  assessed within the `model`, without requiring exploit development.
- No self-recovering, fallback-only, or rerun-cleared finding outranks `Low`.
- Every `guidance.solution` describes a concrete change, and every `guidance`
  follows the `references/outcome-guide.md` `## Guidance` rules.
- Report matches workspace mandates.
- Every `suppressed_findings` entry cites qualifying intent evidence, the failed
  evidence-threshold test, or the fix disproportion—never a general or vague
  rationale.
- If findings or suppressed findings exist: `code-review-report.yaml` written,
  conforming to `references/report-schema.json`, with the grounded `model` and a
  `fingerprint` matching the PERSIST re-run of `scripts/fingerprint.sh`.
- Ledger seeded only from a report whose `fingerprint` matches the _GATE_ run of
  `scripts/fingerprint.sh`—any other report deleted.
- Every inherited entry re-proven under the same evidence, severity, and
  proportionality tests, then persisted in `findings` or
  `suppressed_findings`—none dropped.
- `Result` counts only non-inherited `findings` entries as new.
- Ledger deduplication keys off the defect signature
  (`category:path:line-or-range:slug`), one entry per root cause—no phase counts
  a known defect new under a reworded slug, shifted range, or sibling site.
- Phase sweep ran all `PHASE_COUNT` (8) phases, and no zero-new-candidate phase
  ended it.
- Every phase line names concrete code traced for its focus category or why none
  applies—restating the category never counts.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- Omit inapplicable fields.
- **Result contract**: orchestrating agents parse `Result`, so a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, early stop, or halt—with the result
  template as the final message, never on progress narration.
- Set `Result` to exactly one template literal, verbatim. Report an early stop
  or halt lacking its own literal as `Failed`, with the reason under `Findings`.
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
- **Resolutions**:
  - [Terse list of recommended fixes to findings]
- **Summary**:
  - [Terse list summarizing outcome]

> **Code Review Status** • `[scope]`
> **Result**: [Issues Found | No New Issues | No Issues | Failed]
> **Verdict**: [Request Changes | Comment | Approve]  _(unless failed)_
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
