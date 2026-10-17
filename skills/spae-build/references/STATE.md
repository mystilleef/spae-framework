# `STATE.json`

## Field reference

| Field                   | Type   | Valid values                                                                                       | Category           | Notes                                                                 |
| ----------------------- | ------ | -------------------------------------------------------------------------------------------------- | ------------------ | --------------------------------------------------------------------- |
| `version`               | string | `"1.0"`                                                                                            | Derivable Metadata | Fixed; inject `"1.0"` when omitted                                    |
| `workstream`            | string | kebab-case slug                                                                                    | Derivable Metadata | Infer from path or symlink target when omitted                        |
| `phase`                 | string | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Execution State    | Advances forward; verify no-pass routes backward to `"spec"`          |
| `status`                | string | `"active"` \| `"revision_required"` \| `"completed"`                                               | Derivable Metadata | Preserve; default to `"active"`; `/build` writes no status transition |
| `cursor.active_task_id` | string | `"T-NNN"`                                                                                          | Execution State    | `build`, `check`, `fix`, and `verify` phases only                     |
| `tasks`                 | object | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                   | Execution State    | Populated by plan; mutated by execution skills                        |

## Directives

- Read `STATE.json` at start; confirm `phase: "build"` and an active
  task in the cursor. Self-heal metadata: inject missing
  `version: "1.0"`, `workstream` (from path or symlink target), and
  `status: "active"`. Halt on state drift: if `tasks[`active_task_id`]`
  reads `"done"`, halt and report; make no `STATE.json` write. `"todo"`
  represents the standard entry state (`ORIENT` marks it `"in_progress"`
  next); `"in_progress"` occurs on a retry after a prior failed
  execution. Halt on _unparseable_ JSON, unrecognized `phase`, or active
  task missing from `PLAN.md`.
- **Mark in progress** (before implementation): write
  `tasks[task_id]: "in_progress"`.
- **On task done** (after verification passes): write `phase: "check"`
  only — `/check` owns the `done` transition and the cursor advance.
- **On failure**: make no `STATE.json` write; report the failure in the
  result only. Don't advance the cursor or change `phase`.
- Run task verification before any `STATE.json` write.
- Maintain consistent `workstream` and `version` fields.
- Confirm every write with a fresh read before treating the write as
  done; a field mismatch counts as an unmet `VERIFY` criterion, not a
  finished write.
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

**Exit — task implemented, handed to `/check`**:

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

**Exit — failure**: no write occurs. State remains identical to entry.
