# Cleanup guide

## Purpose

Enforce a zero-self-footprint standard: every code-mutating task
removes artifacts it introduces and no longer needs before finishing.
This guide defines the canonical audit skills embed to stop debug
prints, dead code, and orphan files from accumulating across task
cycles.

## Scope — diff only

- Audit only files and lines this task's own diff introduces or
  modifies.
- Never remove, rewrite, or "improve" pre-existing code outside this
  task's diff, even inside a file the task otherwise edits — treat
  that as a violation, not a bonus fix.
- Use the task's `git diff`/`git status`, never the whole file or
  repo, as the audit surface.

## Checklist — self-introduced artifacts

- Debug output (`console.*`, `print`, `debugger`, or equivalent) added
  to production code this task.
- Files created this invocation absent from the task's declared
  Scope/Files, satisfying no acceptance criterion.
- Dead code this task introduces: unused imports, variables, or
  functions an abandoned approach leaves behind.
- Commented-out code blocks added during iteration.
- Superseded or duplicate files from a rename — an old file left
  beside the new one.
- Dependencies added this task but never imported.
- Stray build or cache output written into the tree — uncommitted,
  untracked.

## Audit command

Run before PERSIST, scoped to the task's declared paths when known:

```sh
git --no-pager status --porcelain -- <task-scoped-paths>
git --no-pager diff --no-ext-diff -U0 -- <task-scoped-paths>
```

Omit `-- <task-scoped-paths>` only when the task names no specific
paths; treat every line either command reports as a candidate
violation against the Checklist above.

## Canonical VERIFY sub-step

Embed verbatim in the VERIFY step of any skill holding source-edit
authority:

```markdown
- Audit the task's own `git diff`/`git status` against the Self-cleanup
  checklist in `references/cleanup-guide.md`; remove every
  self-introduced artifact before proceeding.
```

## Canonical Gap criterion

Embed verbatim in the Gap-label criteria of any skill that audits
another skill's diff (for example, `/check`):

```markdown
- **Gap** also covers a self-introduced cleanup violation: debug
  output, dead code, an orphan file, a commented-out block, a
  superseded duplicate, an unused dependency, or stray build/cache
  output this task's own diff introduces and leaves behind.
```

## Verification

- `git --no-pager status --porcelain` scoped to the workstream shows no
  untracked file outside the task's declared Files list.
- The task's `git diff` carries no added debug or commented-out line
  at PERSIST.
- No dependency this task adds goes unused.
