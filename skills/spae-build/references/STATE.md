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

- Read STATE.json at start; confirm `phase: "build"` and an active task
  in the cursor.
- **Mark in progress** (before implementation): write
  `cursor.task_status: "in_progress"` and
  `tasks[task_id]: "in_progress"`.
- **On task done** (after verification passes):
  - Write `tasks[task_id]: "done"`.
  - Increment `metrics.tasks_completed` by 1.
  - If more `"todo"` tasks remain: advance `cursor.active_task_id` to
    the next task ID in PLAN.md order; set `cursor.task_status: "todo"`.
  - If no tasks remain: set `phase: "verify"`; keep `cursor` pointing to
    the last completed task with `task_status: "done"`.
- **On blocker**: write `cursor.task_status: "blocked"`,
  `tasks[task_id]: "blocked"`, append a description string to
  `blockers[]`. Don't advance the cursor or change `phase`.
- Run task verification before any STATE.json write.
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
  "cursor": {"active_task_id": "T-002", "task_status": "todo"},
  "tasks": {"T-001": "done", "T-002": "todo", "T-003": "todo"},
  "metrics": {"tasks_total": 3, "tasks_completed": 1},
  "blockers": []
}
```

**After marking in progress**:

```json
{
  "cursor": {"active_task_id": "T-002", "task_status": "in_progress"},
  "tasks": {"T-001": "done", "T-002": "in_progress", "T-003": "todo"}
}
```

**Exit — task done, more remain**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "build",
  "status": "active",
  "cursor": {"active_task_id": "T-003", "task_status": "todo"},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "todo"},
  "metrics": {"tasks_total": 3, "tasks_completed": 2},
  "blockers": []
}
```

**Exit — final task done**:

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
