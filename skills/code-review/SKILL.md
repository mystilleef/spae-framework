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

## Workflow

1. **GATE**—Identify changed files and diff boundaries; abort if no
   scope. Delete `code-review-report.yaml` from the project root if
   present.
2. **ORIENT**—Read `references/code-review-guide.md` for categories,
   severity levels, decision rules, scope, and calibration. Read
   `references/report-schema.json` as the output contract. Anchor to
   review goal; name what the review won't change.
3. **ACT**—Execute:
   - Read relevant project documentation (`AGENTS.md`, `ORIENT.md`,
     `DESIGN.md`), nearby code, and tests for grounding.
   - Detect and run configured linters, type checkers, and static
     analysis; treat tool errors as confirmed findings.
   - Review passes per guide categories:
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
4. **VERIFY**—Prove each finding against code and project mandates.
   Apply decision rules from the guide (resource leak, injection, null
   safety, concurrency, error handling). Drop speculative or
   out-of-scope findings.
5. **PERSIST**—Skip if no findings. Otherwise write
   `code-review-report.yaml` to the project root conforming to
   `references/report-schema.json`. Write once, after VERIFY passes. Use
   `|` block scalars for multi-line `suggestion` and `excerpt` fields.
6. **REPORT**—Sort findings by severity. Emit the result following the
   result directives and result template.

## Directives

- Cite each finding with a quoted excerpt and `path:line`.
- Rank findings: `Critical`, `High`, `Medium`, `Low`, `Nit`.
  - Emit `Nit` only when trivially co-located with a higher-severity
    finding.
- Verdict: `Request Changes` (any Critical/High) · `Comment` (Medium/Low
  only) · `Approve` (no findings).
- Mark uncertainty explicitly: _"Context may change this finding, but…"_
- Suggest targeted fixes; don't rewrite the patch.
- Omit empty categories and "none found" sections.
- Verify findings against `AGENTS.md` before reporting.

## Constraints

- No finding without direct code evidence.
- No praise, broad commentary, or unrelated cleanup requests.
- No large raw tool output; summarize diagnostics.
- Don't change project source files during review.
- Don't flag: missing comments/docs, performance micro-optimizations
  without evidence the path runs hot, hypothetical inputs (unless the
  diff introduces a new public-facing API).

## Calibration

- Precision over recall—one high-confidence Critical beats five
  speculative Mediums.
- Don't speculate about code outside the diff.
- Note ambiguous intent in the Issue field rather than assuming defect.
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
- If findings exist: `code-review-report.yaml` written and conforms to
  `references/report-schema.json`.

## Result directives

- Optimize result for agent, token, and context efficiency: terse,
  concise, precise.
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
