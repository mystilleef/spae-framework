---
name: auto-commit
description:
  Autonomously group, stage, and commit repository changes into atomic commits.
user-invocable: true
argument-hint: ""
---

# Auto-commit agent

## When to use

- Invoke for any repository with pending changes that should land as atomic
  commits.
- Execute immediately upon invocation. Never wait for user input or
  confirmation.

## Goal

- Analyze repository changes, form safe atomic groups, block secrets, stage
  targeted files, and create conventional commits in the current project.
- Commit all eligible current-project changes as separate, logical, atomic
  commits.
- Leave the working tree clean, except paths held back with a reported reason.

## Input

Determine input from the current repository state:

- Tracked, `untracked`, staged, `unstaged`, renamed, and deleted changes
  reported by git.
- The coupling-evidence and ignore-evidence catalogs in
  `references/atomic-git-staging.md`.
- Commit message rules in `references/conventional-commit.md`.
- Contributor docs and commit history for **Commit Vocabulary**.

## Workflow

1. **GATE**—Run `git --no-pager status --porcelain=v2 --branch`. Halt on no
   changes, git error, or any **Repository State** failure.
2. **ORIENT**—Goal: commit all eligible changes as atomic commits. Scope:
   current project, with file edits limited to adding ignore entries to
   repository-root `.gitignore`.
3. **PLAN**—
   - Read the **GATE** index per **Staged Index**.
   - Classify `untracked` paths per **Ignore Rules**.
   - Exclude commit-bound paths per **Large Files**.
   - Group remaining changes per **Atomic Grouping**, splitting files per **Hunk
     Staging**.
   - Order groups per **Commit Order**.
   - Apply fast path when grouping yields a single unstaged file needing no
     split.
4. **ACT** _(repeat steps 4–6 per group, in **Commit Order**, until no eligible
   changes remain)_—
   - First pass: clear a non-curated, non-empty index per **Staged Index**.
   - Ignore group: add queued entries to repository-root `.gitignore` per
     **Ignore Rules**.
   - Pre-stage scan: check candidate paths and content against **Sensitive Path
     Rules** and **Sensitive Content Rules**.
   - Review the group:
     `git --no-pager diff --no-ext-diff --histogram --find-renames --patch-with-stat -U10 -- <files>`,
     adding `--cached` for the pre-staged group. Read `untracked` files
     directly.
   - Stage: `git --no-pager add -- <files>` for whole files, **Hunk Staging**
     for split files, nothing for the pre-staged group.
   - Pre-commit scan: check the staged diff per **Secret Scanners** and
     **Conflict Markers**.
   - Write the message per **Commit Vocabulary**.
5. **VERIFY**—Confirm the staged diff matches intent and every pre-commit scan
   passes.
   - Ignore group: the staged diff touches only `.gitignore` files, agent-added
     lines match queued entries, and a re-run of
     `git --no-pager status --porcelain=v2 --branch` omits every queued path.
   - On failure: _unstage_, halt, report—except:
     - Ignore group: keep `.gitignore` edits—reverting risks clobbering pending
       user edits—and list the ignore entries.
     - Pre-staged group: keep its index, except flagged files per **On Secret
       Match**.
6. **PERSIST**—Run `git --no-pager commit -m "<message>"` per **Commit Hooks**.
   Confirm commit success or a contained **Hook Rejection**.
7. **REPORT**—Emit the result following the result directives and using the
   result template.

## Directives

### Repository and index

- **Repository State**: halt at **GATE**, before any change, on:
  - Unmerged entries: any `u` line in **GATE** status. Report the paths.
  - An in-progress operation: `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`,
    `BISECT_LOG`, `rebase-merge`, or `rebase-apply` exists at
    `git --no-pager rev-parse --git-path <name>`. Report the operation.
  - Detached _HEAD_: **GATE** status prints `# branch.head (detached)`.
  - Never resolve conflicts, create branches, or end operations—that intent
    belongs to whoever started them.
- **Staged Index**: read intent from the **GATE** index. `git commit` commits
  the whole index, so leftover staging would enter the first commit:
  - Curated: a partially staged entry—both XY columns non-`.`, such as `MM` or
    `AM`—or a staged deletion (`D.`) whose path also appears `untracked`.
    Neither arises from `git add -A`.
    - The index forms the pre-staged group, committed exactly as staged. User
      curation outranks grouping and ignore verdicts.
    - Built-in rules, **Secret Scanners**, and **Conflict Markers** still apply.
      A **Large Files** hit halts instead of excluding.
  - Non-curated, non-empty: at **ACT** start, clear the index without touching
    the working tree—`git --no-pager restore --staged -- :/` when
    `git --no-pager rev-parse -q --verify HEAD` succeeds,
    `git --no-pager rm -r -q --cached -- :/` otherwise—then group normally.
- **Keep Tracked Files**: never stage removal of a _HEAD_-tracked file present
  in the working tree—a committed index removal deletes the file from other
  clones on pull. A user-staged removal inside a curated index commits as
  staged, and the unborn-branch index clear touches no _HEAD_-tracked file.

### Ignore and exclusion

- **Ignore Rules**: classify each `untracked` path. Queued entries plus pending
  `.gitignore` changes form the ignore group, committed alone:
  - Sensitive path—a **Sensitive Path Rules** match: queue the exact path, never
    the rule glob, since globs such as `id_*` would hide legitimate files.
  - Any other path: reach an **Ignore Verdict**.
  - Directories: judge a collapsed `untracked` directory as a unit when a
    unit-level signal holds—marker file, declared output, ecosystem convention,
    or uniformly opaque sampled content. Otherwise, expand it via
    `git --no-pager ls-files --others --exclude-standard -- <dir>` and judge
    each path.
  - Entry scope: default to the exact path, root-anchored with a leading `/`,
    gitignore pattern syntax escaped. Queue a pattern only when a pattern-level
    decisive signal—ecosystem convention or declared output—names one. Never
    generalize from companion, stem, content, naming, or metadata evidence.
  - Placement: insert each entry at the end of the root `.gitignore` section
    whose comment or entries cover the same generator. Otherwise, add a trailing
    block, headed by a comment naming the generator when the file uses comment
    headers. Create the file when absent, and skip entries already present.
  - Report under `Findings` each ignore entry with its cited signals and each
    `undecided` path with signals present and lacking.
- **Ignore Verdict**: gather signals per **Evidence Probes** and the
  ignore-evidence catalog in `references/atomic-git-staging.md`, then weigh
  them:
  - Count each signal family once, and ambient signals only alongside a
    path-specific signal.
  - Threshold: one decisive signal, or two supporting signals from distinct
    families.
  - `ignore`: threshold met, no counter-signal. Queue an entry.
  - `undecided`: threshold met with a counter-signal, or one path-specific
    supporting signal without counter-signal. Leave unstaged—a repeated report
    costs less than a silently hidden file.
  - `commit`: no ignore signal, or a counter-signal with ignore evidence below
    threshold. Route to normal grouping.
- **Ignore Guards**: check each entry before queueing:
  - Tracked: pattern entry `P` fails when `git --no-pager ls-files -ci -x '<P>'`
    prints any path—the project tracks such paths.
  - Negation: pattern entry `P` fails when any `!` rule in root `.gitignore`,
    `.git/info/exclude`, or `core.excludesFile` names paths `P` also matches,
    regardless of entry position.
  - Exact path: an exact entry fails when
    `git --no-pager check-ignore -v -- <path>` prints a `!` rule.
  - Nested `.gitignore` negations outrank root `.gitignore` and need no check.
  - Failure: a verdict entry gains a counter-signal and re-weighs per **Ignore
    Verdict**, while a sensitive path reaches the pre-stage scan.
- **Large Files**: exclude commit-bound paths before grouping, leaving them
  unstaged and reporting the reason:
  - `lfs-unavailable`: `git --no-pager check-attr filter -- <path>` prints `lfs`
    while `git --no-pager config --get filter.lfs.clean` prints nothing.
  - `oversized`: an `untracked` binary lacking the `lfs`
    filter—`git --no-pager diff --no-index --numstat -- /dev/null <path>` prints
    `- -`—larger than the greater of 5 MiB and the largest blob per
    `git --no-pager ls-tree -r -l HEAD`. Without _HEAD_, the 5 MiB floor applies
    alone.
  - Tracked files bypass the size bound, since the project versions them.

### Grouping

- **Atomic Grouping**: weigh coupling evidence between change units—a file's
  whole change, or its _hunks_ once **Hunk Staging** splits it—per **Evidence
  Probes** and the coupling-evidence catalog in
  `references/atomic-git-staging.md`:
  - Breaking coupling: same group regardless of counter-signals. Report each
    overridden counter-signal under `Findings`.
  - Ordering coupling: a definition joins its sole using group. A definition
    used by two or more otherwise separate groups forms a foundational group.
  - Otherwise, couple on two supporting signals from distinct families with no
    counter-signal, and separate the rest, since breaking coupling and **Commit
    Order** already guard validity.
  - Groups form connected components over breaking, sole-use ordering, and
    coupled supporting pairs.
- **Hunk Staging**: split a file whose _hunks_ fall into different groups with
  no breaking coupling between them:
  - _Hunks_: `git --no-pager diff -- <file>`, switching to
    `git --no-pager diff -U0 -- <file>` when changes of different groups share
    one default-context _hunk_.
  - Stage: feed the file header plus the group's _hunks_ via stdin to
    `git --no-pager apply --cached --check -`, then
    `git --no-pager apply --cached -`, adding `--unidiff-zero` for `-U0`
    _hunks_. Write no patch files, and change no working-tree file.
  - Confirm: `git --no-pager diff --cached -- <file>` shows exactly the selected
    _hunks_. The rest stays unstaged for its own group.
  - Fallback: stage the whole file, merge the groups sharing it, and report
    `mixed-intent` when `--check` fails, different groups' changes overlap
    within one `-U0` _hunk_, or the file arrives binary, `untracked`, or
    renamed.
  - Never split the pre-staged or ignore group.
  - Report every split under `Findings`.
- **Commit Order**: fix the commit sequence during PLAN:
  - Fixed head: pre-staged group, then ignore group, so later groups never stage
    newly ignored paths. Ordering never moves them.
  - Remaining groups: topological order over ordering edges, foundational groups
    first. A cycle merges its members, and ties put feature before cleanup.
  - Check: no group references an identifier, file, or key only a later group
    introduces. A violation reorders or merges.
  - A pre-staged group referencing content from an unstaged change keeps its
    slot and content. Report the conflict under `Findings`.

### Safety scans

- **Sensitive Path Rules**: hard-block `.env*` except `.env.example`, `*.key`,
  `*.pem`, `*.p12`, `*.pfx`, `*_rsa`, `*_dsa`, `id_*`, `secrets.*`,
  `credentials.*`, `.aws/`, `.ssh/`, and `.gnupg/`.
- **Sensitive Content Rules**: hard-block real credential indicators:
  `password=<value>`, `token: <value>`, `api_key = <value>`, `Bearer <value>`,
  cloud/GitHub/Slack/OpenAI token prefixes with non-placeholder values, and
  private key blocks. Never block policy text that merely names secret types or
  placeholder examples.
- **Secret Scanners**: run built-in path and content rules on every group. Also
  run a scanner the project declares (`.gitleaks.toml`, `.secrets.baseline`, a
  `.pre-commit-config.yaml` entry) or one on `PATH` (`gitleaks`,
  `detect-secrets`, `trufflehog`):
  - Scan the group's staged content with project config and allowlists,
    redacting output.
  - Derive flags from the installed version's `--help`, since flags drift across
    versions.
  - A reported finding triggers **On Secret Match**.
  - Report a scanner execution error under `Findings`. Built-in rules still
    gate.
- **Conflict Markers**: count a VERIFY failure when the staged diff adds a line
  starting with `<<<<<<<`, `|||||||`, or `>>>>>>>`, followed by a space or line
  end. Bare `=======` lines carry no weight, since Markdown heading underlines
  use them.
- **On Secret Match**: run `git --no-pager restore --staged -- <files>`, halt,
  and report only file paths plus matched rule names. Never print secret values,
  request overrides, or commit flagged files.

### Commit

- **Commit Vocabulary**: write messages per the Conventional Commits 1.0.0 rules
  and readability conventions in `references/conventional-commit.md`, with no
  tool-specific config shaping them:
  - Pick types and scopes in precedence—the specification lets teams define
    types and asks for consistent casing:
    1. Contributor docs—`CONTRIBUTING.md`, `AGENTS.md`, or equivalents—naming
       types or scopes.
    2. Recurring history: types and scopes appearing more than once in
       `git --no-pager log --format=%s -n 200`. Reuse their spelling and casing
       for the same area, and omit scopes when history rarely uses them.
    3. Reference defaults: the common types in
       `references/conventional-commit.md`, plus a scope naming the changed
       section of the codebase.
  - `feat` and `fix` keep their defined meanings whatever the project
    vocabulary. One-off history types carry no weight.
  - A change fitting more than one type splits per **Atomic Grouping**.
- **Commit Hooks**: run `git commit` with stdin closed, never passing
  `--no-verify` or overriding `core.hooksPath`, signing, or filter
  configuration:
  - Before committing, record `git --no-pager diff --name-only`.
  - On failure, compare against the record:
    - Hook edited only group paths absent from the record: re-stage them, rerun
      pre-commit scans, retry.
    - Hook edited a path outside the group or a recorded path: halt—re-staging
      would fold unrelated edits into the group.
    - No edits, and hook output cites the commit message: revise the message and
      retry.
    - Otherwise: contain per **Hook Rejection**.
  - Retry at most once per group. A second failure halts per VERIFY failure
    handling.
- **Hook Rejection**: a hook vetoes its group, not the run. Never infer which
  path the hook objects to:
  - Unstage the group and report it under `Findings` as `hook-rejected` with its
    paths and summarized hook output, never secret values. Never retry it.
  - Skip every later group reaching it through ordering edges, transitively,
    reporting each as `skipped` with the rejected group.
  - Rejected and skipped paths leave the run; commit the remaining groups in
    **Commit Order**.
  - Halt on hook output identical to an earlier rejection's: one cause, such as
    a broken hook or missing tool, would reject every group.
  - Pre-staged group: keep its index and halt, since every later commit would
    carry it.
  - Report `Failed` when no group commits.

### General

- **Git Commands**: use `--no-pager` for every `git` invocation, and scope
  `--no-ext-diff` to `git diff` operations.
- **Evidence Probes**: gather ignore and coupling evidence with git and POSIX
  tools only—`git check-ignore`, `git grep`, `git log`,
  `git diff --no-index --numstat`, `ls -l`, and reads of `.gitignore`,
  manifests, and changed files:
  - Read content only to classify, and never echo it.
  - Sample a few representative files per directory, and stop probing once a
    verdict holds.
- **Efficiency**: batch operations by file group, target only relevant files,
  parallelize independent read-only checks when useful, and reduce output.
- **IMPORTANT:** Return the result to the caller.

## Constraints

- Current project only.
- No user approval for staging, messages, or commits.
- No dependency on other skills—perform git commands directly.
- No flagged secret, credential, excluded large file, or ignored path enters a
  commit.
- No hook, signing, or filter bypass.
- Halt immediately on secret matches, ambiguous safety state, or git errors
  other than a contained **Hook Rejection**.

## Verification

- No commit ran with unmerged entries, an in-progress operation, or detached
  _HEAD_.
- A pre-staged group commit matches the **GATE** index exactly.
- No commit removes a _HEAD_-tracked file still present in the working tree,
  unless the user staged the removal.
- Every ignore entry matched an `untracked` path, passed **Ignore Guards**, and
  landed in the ignore-group commit.
- Each verdict entry cites one decisive signal, or two supporting signals from
  distinct families with at least one path-specific, and no counter-signal.
- Each pattern entry cites a pattern-level decisive signal.
- No committed path lacks its required `lfs` filter.
- No `untracked` binary exceeding the size bound entered a commit.
- Each commit contains one logical change.
- No commit references an identifier, file, or key only a later commit
  introduces, pre-staged conflicts aside.
- Each split file's committed diff equals its selected _hunks_.
- Each group passed built-in rules and any declared or installed scanner.
- No commit adds conflict-marker lines.
- No commit used `--no-verify`.
- Each group retried at most once.
- Each **Hook Rejection** unstaged its group without retry and skipped every
  group reaching it through ordering edges, while independent groups
  committed—except a pre-staged group, which kept its index and halted.
- No two rejections shared identical hook output without a halt.
- Commit messages follow the Conventional Commits 1.0.0 rules and the
  reference's readability conventions.
- Types and scopes follow **Commit Vocabulary**.
- No step alters working-tree file content beyond ignore entries and **Commit
  Hooks** edits.
- Working tree ends clean, or every remaining path carries a reported reason.
- `Findings` lists every ignore entry with its signals, `undecided` path,
  excluded large file, _hunk_ split, `mixed-intent` fallback, overridden
  counter-signal, pre-staged order conflict, scanner error, `hook-rejected`
  group, and `skipped` group.
- Final report lists commit hashes and subjects or explains failure.

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
