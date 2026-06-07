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
| `metrics.tasks_total`     | integer          | ≥ 0                                                                        | Set by plan; only `/inspect` may re-derive                   |
| `metrics.tasks_completed` | integer          | ≥ 0                                                                        | Incremented per task completion                              |
| `blockers`                | array of strings | —                                                                          | `[]` when clear; never null                                  |

## Directives

- Read STATE.json at start; confirm `phase: "plan"` before proceeding.
- **Reset prior cycle** (step 2): clear `tasks` to `{}` in STATE.json
  unconditionally before drafting the new plan.
- **Exit**: after writing PLAN.md, update STATE.json atomically:
  - Populate `tasks` with every new task ID mapped to `"todo"`.
  - Set `metrics.tasks_total` to the task count; set
    `metrics.tasks_completed` to `0`.
  - Set `phase: "inspect"`.
  - Keep `cursor: {}`, `status: "active"`, `blockers: []`.
- Never mutate `workstream`, `version`, or `status`.
- Never set `cursor` to anything other than `{}` during this phase.

## Snapshots

**Entry**:

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

**Exit**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "inspect",
  "status": "active",
  "cursor": {},
  "tasks": {"T-001": "todo", "T-002": "todo", "T-003": "todo"},
  "metrics": {"tasks_total": 3, "tasks_completed": 0},
  "blockers": []
}
```
