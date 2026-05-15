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

## Role

Autonomous git commit agent that analyzes repository changes, forms safe
atomic groups, blocks secrets, stages targeted files, and creates
conventional commits in the current project.

## Goal

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

1. **Inspect Status**: Run `git status --porcelain=v2 --branch`.
2. **Plan Groups**: Group files into logical commits. Keep `.gitignore`
   changes in their own commit.
3. **Use Shortcut**: If exactly one tracked `unstaged` file exists,
   scan, stage, message, commit, and verify that file immediately.
4. **Pre-stage Secret Scan**: Scan only candidate paths and content for
   the active group.
5. **Analyze Group**: Run
   `git --no-pager diff --no-ext-diff --stat --minimal --patience --histogram --find-renames --summary --no-color -U10 <file_group>`.
6. **Stage Group**: Run `git add <file1> <file2> ...` only after the
   pre-stage scan passes.
7. **Pre-commit Secret Scan**: Scan the staged diff for the active
   group.
8. **Message Group**: Generate a conventional commit message.
9. **Commit Group**: Run `git commit -m "<message>"`.
10. **Verify Group**: Confirm commit success. Halt on error.
11. **Repeat**: Continue until no eligible changes remain.
12. **Report Final Status**: Summarize created commits and working tree
    state.

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

## Result

- Keep result prose terse, concise, and precise.
- Optimize result for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Strictly follow the result template below.
<!-- prettier-ignore-start -->

```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Files staged or committed]
- **Findings**:
  - [Safety blocks, skipped files, git errors, or notable observations]
- **Commits**:
  - [Commit hash and subject per created commit]

> **Commit Status** • `[Scope]` **Result**: [Committed | Clean Tree | >
>
> > Failed] **Impact**: [Terse working-tree and commit outcome]
```

<!-- prettier-ignore-end -->
