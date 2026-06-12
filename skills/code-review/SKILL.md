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

- Conduct skeptical, evidence-based reviews to find material issues
  only, citing code for every finding.
- Identify defects that could break behavior or compromise security.
- Return prioritized, actionable findings tied to exact code excerpts.
- Avoid praise, generic summaries, and preference-only comments.

## Input

Determine scope by the first available source:

- Files or folders provided by the user.
- Current changes in the repository.

Abort if no scope exists.

_Current changes:_ staged and `unstaged` edits, deletions, and renames
of tracked files, plus new `untracked` files. Requires a versioned
project. Abort with a clear message if none detected.

## Workflow

1. **GATE**—Identify changed files and diff boundaries; abort if no
   scope exists.
2. **ORIENT**—Read `references/report-schema.json` as the output contract. Anchor to review goal; name what the review won't change.
3. **ACT**—Execute:
   - Read relevant `AGENTS.md`, descriptions, nearby code, and tests.
   - Detect configured linters, type checkers, and static analysis; run
     safe checks when practical; treat tool errors as confirmed
     findings.
   - Review passes:
     - **Intent**: Compare implementation against stated goal.
     - **Correctness**: Check logic, state, edge cases, errors, and
       tests.
     - **Security**: Check auth, input validation, injection, secrets,
       `deserialization`, and data exposure.
     - **Performance**: Check for leaks, races, deadlocks, and unbounded
       growth.
4. **VERIFY**—Prove each finding against code and project mandates; drop
   speculative or low-value comments.
5. **PERSIST**—Skip if no findings. Otherwise write
   `code-review-report.yaml` to the project root, conforming to
   `references/report-schema.json`. Write once, after VERIFY passes.
   Use `|` block scalars for multi-line code in `suggestion` and
   `excerpt` fields.
6. **REPORT**—Sort findings by severity; group when count exceeds seven.
   Emit result using the Result template.

## Directives

- Cite each finding with a quoted excerpt and `path:line` when
  available.
- Rank each finding `Blocker`, `High`, `Medium`, or `Nit`.
- Prioritize `Blocker` and `High` findings in the summary.
- Mark uncertainty explicitly: _"Context may change this finding, but…"_
- Suggest targeted fixes; don't rewrite the patch.
- Omit empty categories and "none found" sections.
- Verify findings against `AGENTS.md` before reporting.

## Constraints

- No finding without direct code evidence.
- No praise, broad commentary, or unrelated cleanup requests.
- No large raw tool output in the review; summarize diagnostics.
- Don't change project source files during review.

## Verification

- Static analysis output checked when available and practical.
- Findings map to diff or file excerpts and line references.
- Severity reflects user impact or `exploitability`.
- Suggestions describe concrete changes.
- Report matches workspace mandates.
- If findings exist: `code-review-report.yaml` written to project root
  and conforms to `references/report-schema.json`.

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Strictly follow the result template below.
- Prefer lists, and sub-lists, over long paragraphs and sentences.
- Omit inapplicable fields.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of review actions taken]
- **Files**:
  - [Reviewed paths]
- **Findings**:
  - [Severity] path:line
    > quoted excerpt from the code
    **Finding**: one sentence stating the problem.
    **Suggestion**: concrete change, not vague advice.
- **Summary**:
  - [Blocker/High first; terse overall outcome]

> **Code Review Status** • `[scope]`
> **Result**: [Issues Found | LGTM | Failed]
> **Impact**: [Terse impact statement]
```
<!-- prettier-ignore-end -->
