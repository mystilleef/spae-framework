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

- **Prepare never writes STATE.json.** All state transitions belong to
  the `spec`, `plan`, and `inspect` agents prepare invokes.
- **Read at start**: if `.spae/current/STATE.json` is missing, require a
  proposal argument (halt otherwise); if present, confirm `phase` is one
  of `"spec"`, `"plan"`, `"inspect"`. Halt on any other `phase` or
  malformed STATE.json.
- **Read after every spawn**: confirm `phase` differs from the value
  recorded at the start of the iteration.
- **Halt immediately** under these conditions:
  - `phase` matches the value recorded at the start of the iteration.
  - `phase` matches none of `"spec"`, `"plan"`, `"inspect"`.
  - The spawned agent reports `Failed` status, crashes, or times out.
- **Final confirmation**: after `inspect` completes, confirm
  `phase: "build"` before emitting the completion result.
- Trust STATE.json over subagent result text.

## Snapshots

**Entry** (read-only, prepare doesn't write this):

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

**Exit — ready for build** (written by inspect, confirmed by prepare):

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
