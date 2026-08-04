# `STATE.json`

## Field reference

| Field                     | Type             | Valid values                                                               | Notes                                                        |
| ------------------------- | ---------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `version`                 | string           | `"1.0"`                                                                    | Fixed                                                        |
| `workstream`              | string           | kebab-case slug                                                            | Set on init; never mutated                                   |
| `phase`                   | string           | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Advances forward; verify no-pass routes backward to `"spec"` |
| `status`                  | string           | `"active"` \| `"revision_required"` \| `"completed"`                       | `revision_required` and `completed` written only by verify   |
| `cursor.active_task_id`   | string           | `"T-NNN"`                                                                  | `build`, `check`, `fix`, and `verify` phases only            |
| `tasks`                   | object           | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                          | Populated by plan; mutated by execution skills               |

## Directives

- **Orchestrate runs in read-only mode.** `subagents` write all state
  updates.
- **Read at start**: resolve the current phase to identify the next
  `subagent`.
- **Read after every spawn**: confirm `phase` differs from the value
  recorded at the start of the iteration.
- **Halt immediately** under these conditions:
  - `phase` matches the value recorded at the start of the iteration.
  - `phase` matches none of `spec`, `plan`, `inspect`, `build`, `check`,
    `fix`, `verify`, `done`.
  - `subagent` reports `Failed` status, crashes, or times out.
- Trust STATE.json over `subagent` text.

## Snapshots

**Spec Phase Initial State**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "spec",
  "status": "active",
  "cursor": {},
  "tasks": {}
}
```

**Build Phase Mid-execution**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "build",
  "status": "active",
  "cursor": {"active_task_id": "T-001"},
  "tasks": {"T-001": "todo", "T-002": "todo", "T-003": "todo"}
}
```

**Verify Phase State**:

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

**Completed State**:

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
