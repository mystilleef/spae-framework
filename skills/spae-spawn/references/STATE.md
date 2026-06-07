# `STATE.json`

## Field reference

| Field                     | Type             | Valid values                                                               | Notes                                                        |
| ------------------------- | ---------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `version`                 | string           | `"1.0"`                                                                    | Fixed                                                        |
| `workstream`              | string           | kebab-case slug                                                            | Set on init; never mutated                                   |
| `phase`                   | string           | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"verify"` \| `"done"` | Advances forward; verify no-pass routes backward to `"spec"` |
| `status`                  | string           | `"active"` \| `"revision_required"` \| `"completed"`                       | `revision_required` and `completed` written only by verify   |
| `cursor.active_task_id`   | string           | `"T-NNN"`                                                                  | `build` and `verify` phases only                             |
| `cursor.task_status`      | string           | `"todo"` \| `"in_progress"` \| `"done"` \| `"blocked"`                     | `build` and `verify` phases only                             |
| `tasks`                   | object           | `{ "T-NNN": "todo" \| "in_progress" \| "done" \| "blocked" }`              | Populated by plan; mutated by execution skills               |
| `metrics.tasks_total`     | integer          | ≥ 0                                                                        | Set by plan; never decremented                               |
| `metrics.tasks_completed` | integer          | ≥ 0                                                                        | Incremented per task completion                              |
| `blockers`                | array of strings | —                                                                          | `[]` when clear; never null                                  |

## Directives

- **Spawn never writes STATE.json.** All state transitions belong to the
  `build` agents spawn invokes.
- **Read at start**: confirm `phase: "build"` and at least one remaining
  task. Halt on malformed or missing STATE.json.
- **Read after each build agent completes**: re-read STATE.json to
  verify the task the agent ran now shows `"done"` in `tasks`.
- **Halt immediately** when any of the following holds after a build
  agent returns:
  - The task still shows `"todo"` or `"in_progress"`.
  - The task shows `"blocked"`.
  - The build agent reports a crash, timeout, or explicit blocker.
- **Final confirmation**: after the orchestration loop ends, re-read
  STATE.json and confirm `phase: "verify"` before emitting the
  completion result.
- Trust STATE.json over subagent result text.

## Snapshots

**Entry** (read-only, spawn doesn't write this):

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "build",
  "status": "active",
  "cursor": {"active_task_id": "T-001", "task_status": "todo"},
  "tasks": {"T-001": "todo", "T-002": "todo", "T-003": "todo"},
  "metrics": {"tasks_total": 3, "tasks_completed": 0},
  "blockers": []
}
```

**Exit — all tasks done** (written by build agents, verified by spawn):

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "verify",
  "status": "active",
  "cursor": {"active_task_id": "T-003", "task_status": "done"},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "done"},
  "metrics": {"tasks_total": 3, "tasks_completed": 3},
  "blockers": []
}
```
