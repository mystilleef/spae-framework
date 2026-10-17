# Cleanup guide

## Purpose

Enforce a zero-self-footprint standard: every code-mutating task removes
artifacts it introduces and no longer needs before finishing. This guide
defines the canonical audit skills embed to stop debug prints, dead
code, and orphan files from accumulating across task cycles.

## Scope—diff only

- Audit only files and lines this task's own invocation introduces or
  modifies against its pre-task baseline.
- Treat pre-existing uncommitted files and modifications strictly as
  external baseline.
- Never remove, rewrite, or "improve" pre-existing code outside this
  task's diff, even inside a file the task otherwise edits—treat that as
  a violation, not a bonus fix.
- Forbid deleting pre-existing _untracked_ files or lines outside the
  task's declared scope.

## Checklist—self-introduced artifacts

- Debug output (`console.*`, `print`, `debugger`, or similar) added to
  production code during this task.
- Files created during this invocation absent from the task's declared
  Scope/Files, satisfying no acceptance criterion.
- Dead code this task introduces: unused imports, variables, or
  functions an abandoned approach leaves behind.
- Commented-out code blocks added during iteration.
- Superseded or duplicate files from a rename during this task—an old
  file left beside the new one.
- Dependencies added during this task but never imported.
- Stray build or cache output written into the tree during this task—
  uncommitted, _untracked_.

## Baseline capture command

Run in code-mutating skills at `ORIENT` to snapshot the pre-task working
tree without staging or workspace pollution:

```sh
out=$(mktemp)
GIT_INDEX_FILE="${out}" git add -A && base_tree=$(GIT_INDEX_FILE="${out}" git write-tree) && rm -f "${out}"
```

## Audit command

Run before `PERSIST`, scoped to `$base_tree` and declared task paths:

```sh
git --no-pager diff --no-ext-diff -U0 "${base_tree}" -- <task-scoped-paths>
```

When auditing without a transient baseline snapshot (for example,
read-only check skills), scope checks strictly to declared task paths:

```sh
git --no-pager diff --no-ext-diff -U0 -- <task-scoped-paths>
```

Never run un-scoped `git status` or un-scoped `git diff` to flag orphan
files. Treat baseline and diff commands purely as read-only snapshot
utilities; never stage files or alter repository commit history.

## Canonical VERIFY sub-step

Embed verbatim in the `VERIFY` step of any skill holding source-edit
authority:

```markdown
- Audit task edits against the pre-task baseline using the Self-cleanup
  checklist in `references/cleanup-guide.md`; remove every
  self-introduced artifact before proceeding.
```

## Canonical gap criterion

Embed verbatim in the Gap-label criteria of any skill that audits
another skill's diff (for example, `/check`):

```markdown
- **Gap** covers only task-introduced violations within the active
  task's declared scope: debug output, dead code, an orphan file, a
  commented-out block, a superseded duplicate, an unused dependency, or
  stray build/cache output this task's own diff introduces and leaves
  behind. Never flag pre-existing uncommitted files outside task scope
  as gaps.
```

## Verification

- The task diff relative to the pre-task baseline carries no added debug
  or commented-out line at `PERSIST`.
- No _untracked_ file created during the task invocation survives
  outside declared Scope/Files.
- No dependency added during this task goes unused.
- Pre-existing uncommitted files outside task scope remain unmodified.
