---
name: code-review
description: Find bugs and potential issues in code changes.
user-invocable: false
argument-hint: "[optional: diff, commit, PR, file, or focus area]"
---

# Code review agent

## When to use

- Reviewing diffs, commits, PRs, or changed files before merge.
- Auditing generated code or refactors for regressions.

## Goal

Conduct a skeptical, evidence-based review that flags only material
defects—incorrect behavior, data loss, security vulnerabilities, or
crashes. Return prioritized findings with exact code citations.

## Scope

**In scope**:

- Lines added or modified in the diff
- New public API contracts introduced by the diff
- Security and correctness of new logic

**Out of scope**:

- Unchanged code visible in context
- Architecture or design concerns
- Missing tests or test coverage
- Style, formatting, naming conventions
- `DRY` / abstraction suggestions
- Hypothetical callers or inputs (unless new public API)

## Input

Determine scope from the first available source:

- Files or folders provided by the user.
- Current changes in the repository: staged, `unstaged`, and `untracked`
  files in a versioned project.

Abort with a clear message if no scope detected.

Gather intent grounding matching the resolved scope:

- Commit or `PR` scope: the commit message(s) or `PR` title and
  description.
- Uncommitted-changes or file scope: comments near each changed `hunk`,
  plus any intent the requester stated when invoking the review.

## Workflow

1. **GATE**—Identify changed files and diff boundaries; abort if no
   scope. Delete `code-review-report.yaml` from the project root if
   present.
2. **ORIENT**—Read `references/code-review-guide.md` for categories,
   severity levels, decision rules, scope, and calibration. Read
   `references/report-schema.json` as the output contract. Anchor to
   review goal; name what the review won't change.
   - Ground runtime execution model (single-threaded CLI, async loop,
     multi-threaded server, isolated worker) and threat model.
   - Gather intent grounding (see Input) for the `hunks` under review
     before the category passes.
3. **ACT**—Execute:
   - Read relevant project documentation (`AGENTS.md`, `ORIENT.md`,
     `DESIGN.md`), nearby code, and tests for grounding.
   - Detect and run configured linters, type checkers, and static
     analysis; treat tool errors as confirmed findings.
   - Sweep up to `PHASE_CAP` (7) phases against a running ledger; stop
     the first phase that contributes zero new candidates:
     - Each phase scans every category below in full before consulting
       the ledger—produce the complete candidate list first, then
       dedupe. Skipping already-covered ground before scanning defeats
       the sweep.
     - Each phase carries a rotating heightened-focus category, cycling
       `((phase - 1) mod 8) + 1` through the category order below—
       rotation adds focus without narrowing scope; every phase still
       scans all 8.
     - Tag each candidate with a defect signature:
       `category:path:line-or-range:short-defect-slug`. Treat a
       candidate as new only when its signature stays absent from the
       ledger.
     - Append new candidates to the ledger after each phase.
   - Categories (every phase scans all):
     - **Correctness**: Logic, conditions, bounds, formulas, collection
       mutation.
     - **Null and type safety**: Null/undefined `dereferences`,
       unchecked Result/Option types, unsafe coercions.
     - **Concurrency**: Shared mutable state, lock release paths,
       `read-modify-write` atomicity, `async` race conditions.
     - **Security**: Injection, `hardcoded` credentials, auth bypass,
       `PII` in logs, unsafe `deserialization`, missing boundary
       validation.
     - **Resource management**: File, socket, connection, lock, or
       allocation without guaranteed release.
     - **Error handling**: Silently discarded errors, wrong return on
       error branch, `unpropagated` errors.
     - **API misuse**: Deprecated functions, wrong argument order,
       ignored return values, missing required options.
     - **Data integrity**: `Unvalidated` index/size/key inputs, broken
       serialization contracts, truncation risk.
4. **VERIFY**—Run once, after the phase sweep completes—never per phase.
   Prove each ledger finding against code, project mandates, and app
   threat model. Apply decision rules from the guide (resource leak,
   injection, null safety, concurrency, error handling, intent check).
   - Drop speculative, out-of-scope, or `unexploitable` theoretical
     findings from active `findings`.
   - Route findings lacking concrete exploit paths or carrying
     qualifying intent evidence to `suppressed_findings` citing the
     missing trigger scenario—never emit them in `findings`.
5. **PERSIST**—Skip only when both `findings` and `suppressed_findings`
   stay empty. Otherwise write `code-review-report.yaml` to the project
   root conforming to `references/report-schema.json`; omit the
   `suppressed_findings` key entirely when empty. Write once, after
   VERIFY passes. Use `|` block scalars for multi-line `suggestion` and
   `excerpt` fields.
6. **REPORT**—Sort findings by severity. Emit the result following the
   result directives and result template.

## Directives

- Cite each finding with a quoted excerpt and `path:line`.
- Rank findings: `Critical`, `High`, `Medium`, `Low`, `Nit`.
  - Emit `Nit` only when trivially co-located with a higher-severity
    finding.
- Verdict: `Request Changes` (any confirmed, practically exploitable
  Critical/High) · `Comment` (Medium/Low only) · `Approve` (no
  findings). Derive verdict from `findings` only—`suppressed_findings`
  never shifts it.
- Filter candidate findings against the app threat model, `KISS`, and
  `YAGNI`; reject defensive bloat, ungrounded guardrails, and
  theoretical non-exploits.
- Mark uncertainty explicitly: _"Context may change this finding, but…"_
- Suggest targeted, scope-appropriate fixes; don't rewrite the patch.
- Omit empty categories and "none found" sections.
- Verify findings against `AGENTS.md` before reporting.
- Default to `PHASE_CAP` (7) phases as a single named constant—never
  scatter phase-count literals across the workflow.
- Surface phases run in the result `Actions` list (for example,
  `ran 3/7 phases, stopped on saturation`).

## Constraints

- No finding without direct code evidence.
- No praise, broad commentary, or unrelated cleanup requests.
- No large raw tool output; summarize diagnostics.
- Don't change project source files during review.
- Don't flag: missing comments/docs, performance micro-optimizations
  without evidence the path runs hot, hypothetical inputs (unless the
  diff introduces a new public-facing API), or theoretical
  vulnerabilities outside the app threat model.
- Run `VERIFY`, `PERSIST`, and `REPORT` once, after the phase
  sweep—never per phase.

## Calibration

- Precision over recall—one high-confidence Critical beats five
  speculative Mediums.
- Don't speculate about code outside the diff.
- Note ambiguous intent in the finding rather than assuming defect.
- Flag the defect; don't editorialize about the author or decision.
- Language-specific idioms inform findings—don't flag idiomatic use as
  incorrect.
- When a stack context block arrives (for example,
  `Stack: Python 3.12, asyncio`), apply its language-specific severity
  adjustments—it takes precedence.

## Verification

- Static analysis output checked when available and practical.
- Findings map to diff or file excerpts and line references.
- Severity reflects user impact or `exploitability`.
- Suggestions describe concrete changes.
- Report matches workspace mandates.
- Every `suppressed_findings` entry cites qualifying intent
  evidence—never a general or vague rationale.
- If findings or suppressed findings exist: `code-review-report.yaml`
  written and conforms to `references/report-schema.json`.
- Ledger dedup keys off the defect signature
  (`category:path:line-or-range:slug`)—no phase counts a finding new
  without a fresh signature.
- Phase sweep halts on the first zero-new-finding phase, or at
  `PHASE_CAP` (7), whichever comes first.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
- Omit inapplicable fields.
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
> **Result**: [Issues Found | No Issues | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
