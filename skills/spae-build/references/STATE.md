# `STATE.json`

## Field reference

| Field                   | Type   | Valid values                                                                                       | Category           | Notes                                                                                                        |
| ----------------------- | ------ | -------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------ |
| `version`               | string | `"1.0"`                                                                                            | Derivable Metadata | Fixed; default `"1.0"` when omitted                                                                          |
| `workstream`            | string | kebab-case slug                                                                                    | Derivable Metadata | Infer from path or symlink target when omitted                                                               |
| `phase`                 | string | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Execution State    | Phase to run next; `"done"` ends the `workstream`                                                            |
| `status`                | string | `"active"` \| `"revision_required"` \| `"completed"`                                               | Derivable Metadata | Default `"active"`; `"revision_required"` only with `phase: "spec"`, `"completed"` only with `phase: "done"` |
| `cursor.active_task_id` | string | `"T-NNN"`                                                                                          | Execution State    | Active task ID; `cursor: {}` while `phase` reads `"spec"`, `"plan"`, or `"inspect"`                          |
| `tasks`                 | object | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                   | Execution State    | Maps every task ID to its progress; `tasks: {}` while `phase` reads `"spec"` or `"plan"`                     |

## Directives

- Read `STATE.json` at entry; require `phase: "build"`. Self-heal
  missing metadata: `version: "1.0"`, `workstream` (target directory
  name), and `status: "active"`. Halt on _unparseable_ JSON syntax, any
  other `phase`, or `tasks[active_task_id]` reading `"done"`; `"todo"`
  marks a first attempt, `"in_progress"` a rerun.
- Write `STATE.json` only at the `ORIENT` mark and once at `PERSIST`,
  after `VERIFY` passes; never at any other point.
- **Mark in progress** (`ORIENT`): write
  `tasks[active_task_id]: "in_progress"`.
- **Exit**: write `phase: "check"`; keep the cursor and
  `tasks[active_task_id]: "in_progress"` unchanged.
- **Halt**: write nothing further; `phase` stays `"build"`.
- Confirm every write with a fresh read before treating the write as
  done; on a field mismatch, rewrite and re-read.
- A forgotten or partial write—not a task failure—stalls orchestrator
  dispatch and corrupts manual resumption; every write here gates
  automation, not bookkeeping.

## Snapshots

**Entry**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "build",
  "status": "active",
  "cursor": {"active_task_id": "T-002"},
  "tasks": {"T-001": "done", "T-002": "todo", "T-003": "todo"}
}
```

**After marking in progress**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "build",
  "status": "active",
  "cursor": {"active_task_id": "T-002"},
  "tasks": {"T-001": "done", "T-002": "in_progress", "T-003": "todo"}
}
```

**Exit—task implemented, handed to `/check`**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "check",
  "status": "active",
  "cursor": {"active_task_id": "T-002"},
  "tasks": {"T-001": "done", "T-002": "in_progress", "T-003": "todo"}
}
```

**Exit—failure**: no write after the `ORIENT` mark; state matches
**After marking in progress**, or **Entry** on a `GATE` halt.
