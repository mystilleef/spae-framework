---
name: auto-commit
description:
  Autonomously group, stage, and commit all changes in a repository into
  atomic commits.
user-invocable: true
argument-hint: ""
---

# Goal

Autonomously group, stage, and commit all changes in a repository into
atomic commits for the current project.

## When to use

- Always. Execute immediately upon invocation without waiting for user
  input or confirmation.

## Process

1. **Analyze Status**: Execute `git status --porcelain=v2 --branch` to
   identify all changes.
2. **Identify Atomic Groups**: Use heuristics from
   `references/atomic-git-staging.md` to group files into logical
   changes. Isolate `.gitignore` changes into their own commit.
   - **Shortcut**: If exactly one tracked `unstaged` file exists, stage
     and commit it immediately.
3. **Sensitive Data Gate**: For each atomic group, scan candidate
   paths/content before staging and scan the staged diff before commit.
   Check only current candidate files. Hard-block any path or diff
   matching likely secrets:
   - **Paths**: `.env*` except `.env.example`, `*.key`, `*.pem`,
   `*.p12`, `*.pfx`, `*_rsa`, `*_dsa`, `id_*`, `secrets.*`,
   `credentials.*`, `.aws/`, `.ssh/`, `.gnupg/`.
   <!-- vale off -->

   - **Content**: Flag secret-like assignments or credential values, not
     policy text that merely names secret types. Match indicators such
     as `password=...`, `token: ...`, `api_key = ...`, `Bearer <value>`,
     cloud/GitHub/Slack/OpenAI token prefixes with non-placeholder
     values, or private key blocks. Do not block documentation that only
     lists secret rule names or examples without real values.

   <!-- vale on -->
   - **On match**: remove affected files from staging with
     `git restore --staged -- <files>`, halt, and report only file paths
     plus matched rule names. Never print secret values, ask for
     override, or commit flagged files.

4. **Loop through Groups**:
   1. **Analyze Group**: Use
      `git --no-pager diff --no-ext-diff --stat --minimal --patience --histogram --find-renames --summary --no-color -U10 <file_group>`
      to understand the changes.
   2. **Stage**: After the pre-stage sensitive data scan passes, execute
      `git add <file1> <file2> ...`.
   3. **Message**: Generate a conventional commit message based on
      `references/conventional-commit.md`.
   4. **Commit**: After the staged-diff sensitive data scan passes,
      execute `git commit -m "<message>"`.
   5. **Verify**: Verify the commit succeeded. If `ERROR`, halt and
      report.
5. **Repeat**: Continue until achieving a clean working tree.
6. **Final Status**: Output a concise summary of the commits created
   (for example, a list of commit hashes and subjects) to confirm
   successful execution.

## Verification

- The working tree remains clean.
- Separate, atomic commits group all logical changes.
- Commit messages follow the conventional commit format.
- The commit excludes sensitive or build-related files.

## Rules

- **Git Commands**: Use `--no-pager` and `--no-ext-diff` for all diff
  operations.
- **Atomic Grouping**: Group files that _must_ exist together (for
  example, implementation + test).
- **Unconditional**: Execute immediately upon invocation. Never wait for
  user input, confirmation, or additional context before running
  `git status`.
- **No User Input**: Autonomously perform commits without awaiting user
  approval for messages.
- **Current Project**: Only commit changes in the current project.
- **Self-Contained**: Don't depend on or invoke any other skills.
  Perform git commands directly.
- **Efficiency**:
  - Optimize all operations for agent, token, and context efficiency.
  - Batch operations on file groups; avoid individual file processing.
  - Use parallel execution when possible.
  - Target only relevant files.
  - Reduce token usage.
- **Safety**: Intelligently handle `untracked` files and avoid staging
  sensitive or build-related files (refer to `atomic-git-staging.md`).

## Standardized feedback

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [List of terse, short, compact, condensed summary of actions taken]
- **Files**:
  - [List of modified or created files]
- **Findings**:
  - [List of terse summary of key gaps, risks, or architectural notes]
- **Commits**:
  - [List of commit summaries]

> **Commit Status** • `[Scope]`
> **Result**: [`Committed` | `Clean Tree` | `Failed`]
> **Status**: [Working tree summary]
```
<!-- prettier-ignore-end -->
