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

- Read `STATE.json` at entry and require `phase: "plan"`. Self-heal missing
  metadata: `version: "1.0"`, `workstream` (target directory name), and
  `status: "active"`. Halt on _unparseable_ JSON syntax or any other `phase`.
- **Reset prior cycle** (`ORIENT`): set `tasks: {}` unconditionally before
  drafting—the sole write before `PERSIST`.
- **Exit**: after writing `PLAN.md`, write the full exit snapshot—`version`,
  `workstream`, `phase: "inspect"`, `status: "active"`, `cursor: {}`, and
  `tasks` mapping every new task ID to `"todo"`.
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
  "phase": "plan",
  "status": "active",
  "cursor": {},
  "tasks": {}
}
```

**Exit**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "inspect",
  "status": "active",
  "cursor": {},
  "tasks": {"T-001": "todo", "T-002": "todo", "T-003": "todo"}
}
```
