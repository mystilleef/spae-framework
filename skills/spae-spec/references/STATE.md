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

- Read STATE.json at start to determine path: **new workstream** (no
  `.spae/current` symlink) or **revision**
  (`status: revision_required`).
- **New workstream**: create STATE.json using the new-workstream entry
  shape; set `phase: "spec"`, `status: "active"`.
- **Revision**: STATE.json already exists; read it for context. Don't
  mutate it before writing STATE.json.
- **Exit (both paths)**: write `phase: "plan"`, `status: "active"` to
  STATE.json.
- **New workstream exit**: preserve `cursor: {}`, `tasks: {}`,
  `metrics: {tasks_total: 0, tasks_completed: 0}`, `blockers: []`.
- **Revision exit**: preserve existing `tasks`, `metrics`, and
  `blockers` unchanged; set `cursor: {}`.
- Never mutate `workstream` or `version`.

## Snapshots

**Entry — new workstream**: skill creates STATE.json.

**Entry — revision**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "spec",
  "status": "revision_required",
  "cursor": {},
  "tasks": {"T-001": "done", "T-002": "done"},
  "metrics": {"tasks_total": 2, "tasks_completed": 2},
  "blockers": []
}
```

**Exit — new workstream**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "plan",
  "status": "active",
  "cursor": {},
  "tasks": {},
  "metrics": {"tasks_total": 0, "tasks_completed": 0},
  "blockers": []
}
```

**Exit — revision**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "plan",
  "status": "active",
  "cursor": {},
  "tasks": {"T-001": "done", "T-002": "done"},
  "metrics": {"tasks_total": 2, "tasks_completed": 2},
  "blockers": []
}
```
