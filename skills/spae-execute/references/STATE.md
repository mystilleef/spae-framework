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

- Read STATE.json at start; confirm `phase: "build"`. Collect all tasks
  with status `"todo"` or `"in_progress"` in PLAN.md order; these tasks
  remain.
- **Per task — mark in progress** (before building each task): write
  `cursor.active_task_id` to the current task ID,
  `cursor.task_status: "in_progress"`, and
  `tasks[task_id]: "in_progress"`.
- **Per task — on task done** (after verification passes):
  - Write `tasks[task_id]: "done"`.
  - Increment `metrics.tasks_completed` by 1.
  - Update `cursor.active_task_id` to the current task;
    `cursor.task_status: "done"`.
- **On blocker** (any task fails verification): write
  `cursor.task_status: "blocked"`, `tasks[task_id]: "blocked"`, append a
  description string to `blockers[]`. Leave remaining tasks as `"todo"`.
  Halt immediately; don't execute further tasks.
- **Exit — all done**: after the final task completes, set
  `phase: "verify"`. The cursor stays on the last task with
  `task_status: "done"`.
- Run each task's verification steps before advancing its STATE.json
  entry.
- Never mutate `workstream`, `version`, `status`, or
  `metrics.tasks_total`.

## Snapshots

**Entry**:

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

**Per-task (in progress)**:

```json
{
  "cursor": {"active_task_id": "T-002", "task_status": "in_progress"},
  "tasks": {"T-001": "done", "T-002": "in_progress", "T-003": "todo"}
}
```

**Exit — all tasks done**:

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

**Exit — blocker**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "build",
  "status": "active",
  "cursor": {"active_task_id": "T-002", "task_status": "blocked"},
  "tasks": {"T-001": "done", "T-002": "blocked", "T-003": "todo"},
  "metrics": {"tasks_total": 3, "tasks_completed": 1},
  "blockers": ["T-002: description of blocker"]
}
```
