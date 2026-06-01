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

- Read STATE.json at start; confirm `phase: "verify"` and that every
  task in `tasks` shows `"done"`. Halt without state changes if either
  check fails.
- **Pass**: write `phase: "done"`, `status: "completed"` to STATE.json.
  Preserve `cursor`, `tasks`, `metrics`, and `blockers` unchanged.
- **No pass** (hard block or soft finding): write `phase: "spec"`,
  `status: "revision_required"`, `cursor: {}` to STATE.json. Preserve
  `tasks`, `metrics`, and `blockers` unchanged.
- **Blocked** (broken build, missing tooling, or environment failure
  prevents checks from running): write `phase: "spec"`,
  `status: "revision_required"`, `cursor: {}` to STATE.json. Preserve
  `tasks`, `metrics`, and `blockers` unchanged.
- Don't mutate `workstream`, `version`, `tasks`, `metrics`, or
  `blockers` during the exit step.
- Write STATE.json only once, after the verdict.

## Snapshots

**Entry**:

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

**Exit — pass**:

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

**Exit — fail**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "spec",
  "status": "revision_required",
  "cursor": {},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "done"},
  "metrics": {"tasks_total": 3, "tasks_completed": 3},
  "blockers": []
}
```
