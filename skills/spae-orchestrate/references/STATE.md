# `STATE.json` Reference

## Fields

| Field                     | Type             | Valid values                                                               | Notes                                                      |
| ------------------------- | ---------------- | -------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `version`                 | string           | `"1.0"`                                                                    | Constant value                                             |
| `workstream`              | string           | kebab-case slug                                                            | Set on init; remains constant                              |
| `phase`                   | string           | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"verify"` \| `"done"` | Advances forward; verify failure reverts phase to `"spec"` |
| `status`                  | string           | `"active"` \| `"revision_required"` \| `"completed"`                       | Set only by verify                                         |
| `cursor.active_task_id`   | string           | `"T-NNN"`                                                                  | Exists during build and verify phases                      |
| `cursor.task_status`      | string           | `"todo"` \| `"in_progress"` \| `"done"` \| `"blocked"`                     | Exists during build and verify phases                      |
| `tasks`                   | object           | `{ "T-NNN": "todo" \| "in_progress" \| "done" \| "blocked" }`              | Set by plan; updated by execution agents                   |
| `metrics.tasks_total`     | integer          | ≥ 0                                                                        | Set by plan; remains constant                              |
| `metrics.tasks_completed` | integer          | ≥ 0                                                                        | Increments per task completion                             |
| `blockers`                | array of strings | —                                                                          | Empty array when clear                                     |

## Directives

- **Orchestrate runs in read-only mode.** `subagents` write all state
  updates.
- **Read at start**: resolve the current phase to identify the next
  `subagent`.
- **Read after each task**: verify that the registry marks the active
  task as `"done"`.
- **Halt immediately** under these conditions:
  - Task shows `"todo"`, `"in_progress"`, or `"blocked"` after
    `subagent` returns.
  - `subagent` reports a crash, timeout, or blocker.
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
  "tasks": {},
  "metrics": {"tasks_total": 0, "tasks_completed": 0},
  "blockers": []
}
```

**Build Phase Entry State**:

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

**Completed State**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "done",
  "status": "completed",
  "cursor": {"active_task_id": "T-003", "task_status": "done"},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "done"},
  "metrics": {"tasks_total": 3, "tasks_completed": 3},
  "blockers": []
}
```
