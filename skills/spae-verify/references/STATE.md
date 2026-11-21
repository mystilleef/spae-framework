# `STATE.json`

## Field reference

- **`version`** (string, Derivable Metadata): `"1.0"`. Fixed, defaulting to
  `"1.0"` when omitted.
- **`workstream`** (string, Derivable Metadata): kebab-case slug. Infer from
  path or symlink target when omitted.
- **`phase`** (string, Execution State): `"spec"` | `"plan"` | `"inspect"` |
  `"build"` | `"check"` | `"fix"` | `"verify"` | `"done"`. Names the phase to
  run next, and `"done"` ends the `workstream`.
- **`status`** (string, Derivable Metadata): `"active"` | `"revision_required"`
  | `"completed"`. Defaults to `"active"`, allowing `"revision_required"` only
  with `phase: "spec"` and `"completed"` only with `phase: "done"`.
- **`cursor.active_task_id`** (string, Execution State): `"T-NNN"`. Holds the
  active task ID, with `cursor: {}` while `phase` reads `"spec"`, `"plan"`, or
  `"inspect"`.
- **`tasks`** (object, Execution State):
  `{ "T-NNN": "todo" | "in_progress" | "done" }`. Maps every task ID to its
  progress, with `tasks: {}` while `phase` reads `"spec"` or `"plan"`.

## Directives

- Read `STATE.json` at entry and require `phase: "verify"` and every `PLAN.md`
  task reading `"done"`. Self-heal missing metadata: `version: "1.0"`,
  `workstream` (target directory name), and `status: "active"`. Halt on
  _unparseable_ JSON syntax, any other `phase`, or a task not reading `"done"`.
- Write `STATE.json` once, at `PERSIST`, after any `VERIFY.md` write and before
  any deletion—never mutate it earlier.
- **Pass** (zero hard blocks): write `phase: "done"` and `status: "completed"`,
  keeping `cursor` and `tasks`.
- **Revision required** (any hard block): write `phase: "spec"`,
  `status: "revision_required"`, `cursor: {}`, and `tasks: {}`.
- **Halt**: write nothing, leaving `phase` at `"verify"`.
- Confirm every write with a fresh read before treating the write as done.
  Rewrite and re-read on any field mismatch.
- A forgotten or partial write—not a task failure—stalls orchestrator dispatch
  and corrupts manual resumption: every write here gates automation, not
  bookkeeping.

## Snapshots

**Entry**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "verify",
  "status": "active",
  "cursor": {"active_task_id": "T-003"},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "done"}
}
```

**Exit—pass**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "done",
  "status": "completed",
  "cursor": {"active_task_id": "T-003"},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "done"}
}
```

**Exit—revision required**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "spec",
  "status": "revision_required",
  "cursor": {},
  "tasks": {}
}
```
