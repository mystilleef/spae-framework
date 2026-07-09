---
name: auto-commit
description:
  Autonomously group, stage, and commit repository changes into atomic
  commits.
user-invocable: true
argument-hint: ""
---

# Auto-commit agent

## When to use

- Invoke for any repository with pending changes that should land as
  atomic commits.
- Execute immediately upon invocation. Never wait for user input or
  confirmation before `git status`.

## Goal

- Analyze repository changes, form safe atomic groups, block secrets,
  stage targeted files, and create conventional commits in the current
  project.
- Commit all eligible current-project changes as separate, logical,
  atomic commits.
- Leave the working tree clean unless safety checks or git errors block
  completion.

## Input

Determine input from the current repository state:

- Tracked, `untracked`, staged, `unstaged`, renamed, deleted, and
  ignored changes reported by git.
- Atomic grouping heuristics from `references/atomic-git-staging.md`.
- Commit message rules from `references/conventional-commit.md`.

## Workflow

1. **GATE**—Run `git status --porcelain=v2 --branch`. Halt on no changes
   or git error.
2. **ORIENT**—Goal: commit all eligible changes as atomic commits.
   Scope: current project. No changes outside git state.
3. **PLAN**—Group files into logical commits. Isolate `.gitignore`
   changes. Apply fast path for a single unstaged file.
4. **ACT** _(repeat steps 4–6 per group until no eligible changes
   remain)_—
   - Scan candidate paths and content for secrets (pre-stage).
   - Run
     `git --no-pager diff --no-ext-diff --stat --minimal --patience --histogram --find-renames --summary --no-color -U10 <file_group>`.
   - Run `git add <file1> <file2> ...`.
   - Scan staged diff for secrets (pre-commit).
   - Generate conventional commit message.
5. **VERIFY**—Confirm staged diff matches intent and all secret checks
   pass. On failure: unstage, halt, report.
6. **PERSIST**—Run `git commit -m "<message>"`. Confirm commit success.
7. **REPORT**—Emit the result following the result directives and using
   the result template.

## Directives

- **Atomic Grouping**: Commit files together only when they must change
  together, such as implementation plus matching tests.
- **Gitignore Isolation**: Commit `.gitignore` changes separately.
- **Sensitive Path Rules**: Hard-block `.env*` except `.env.example`,
  `*.key`, `*.pem`, `*.p12`, `*.pfx`, `*_rsa`, `*_dsa`, `id_*`,
  `secrets.*`, `credentials.*`, `.aws/`, `.ssh/`, and `.gnupg/`.

<!-- vale off -->

- **Sensitive Content Rules**: Hard-block real credential indicators:
  `password=...`, `token: ...`, `api_key = ...`, `Bearer <value>`,
  cloud/GitHub/Slack/OpenAI token prefixes with non-placeholder values,
  and private key blocks. Do not block policy text that merely names
  secret types or placeholder examples.

<!-- vale on -->

- **On Secret Match**: Run `git restore --staged -- <files>`, halt, and
  report only file paths plus matched rule names. Never print secret
  values, request overrides, or commit flagged files.
- **Diff Commands**: Use `--no-pager` and `--no-ext-diff` for all diff
  operations.
- **Generated Files**: Avoid staging sensitive or build-related files
  unless source control should track them.
- **Efficiency**: Batch operations by file group, target only relevant
  files, parallelize independent read-only checks when useful, and
  reduce output.

## Constraints

- Current project only.
- No user approval for staging, messages, or commits.
- No dependency on other skills; perform git commands directly.
- No flagged secret, credential, or unsafe generated file may enter a
  commit.
- Halt immediately on git errors, failed secret scans, or ambiguous
  safety state.

## Verification

- Working tree ends clean, or remaining files have explicit safety or
  error reasons.
- Each commit contains one logical change.
- Commit messages follow conventional commit format.
- Commits exclude sensitive and inappropriate build-related files.
- Final report lists commit hashes and subjects or explains failure.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists over paragraphs and long sentences.
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
- **Commits**:
  - [Commit hash and subject per created commit]

> **Commit Status** • `[scope]`
> **Result**: [Committed | Clean Tree | Failed]
> **Impact**: [Terse impact statement]
>
> _[Terse working tree summary]_
```
<!-- prettier-ignore-end -->
