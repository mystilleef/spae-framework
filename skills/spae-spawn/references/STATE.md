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

- **Spawn never writes STATE.json.** All state transitions belong to
  the `build`, `check`, and `fix` agents spawn invokes.
- **Read at start**: confirm `phase` is one of `"build"`, `"check"`,
  `"fix"`, and a populated `cursor.active_task_id` exists. Halt on
  malformed or missing STATE.json.
- **Read after every spawn**: confirm `phase` differs from the value
  recorded at the start of the iteration.
- **Halt immediately** under these conditions:
  - `phase` matches the value recorded at the start of the iteration.
  - `phase` matches none of `"build"`, `"check"`, `"fix"`, `"verify"`.
  - The spawned agent reports `Failed` status, crashes, or times out.
- **Final confirmation**: after the loop exits, confirm `phase:
  "verify"` before emitting the completion result.
- Trust STATE.json over subagent result text.

## Snapshots

**Entry** (read-only, spawn doesn't write this):

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

**Exit — all tasks done** (written by build agents, verified by spawn):

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
