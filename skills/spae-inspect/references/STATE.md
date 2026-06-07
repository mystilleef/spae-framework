# `STATE.json`

## Field reference

| Field                     | Type             | Valid values                                                               | Notes                                                                           |
| ------------------------- | ---------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `version`                 | string           | `"1.0"`                                                                    | Fixed                                                                           |
| `workstream`              | string           | kebab-case slug                                                            | Set on init; never mutated                                                      |
| `phase`                   | string           | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"verify"` \| `"done"` | Advances forward; verify no-pass routes backward to `"spec"`                    |
| `status`                  | string           | `"active"` \| `"revision_required"` \| `"completed"`                       | `revision_required` and `completed` written only by verify                      |
| `cursor.active_task_id`   | string           | `"T-NNN"`                                                                  | `build` and `verify` phases only                                                |
| `cursor.task_status`      | string           | `"todo"` \| `"in_progress"` \| `"done"` \| `"blocked"`                     | `build` and `verify` phases only                                                |
| `tasks`                   | object           | `{ "T-NNN": "todo" \| "in_progress" \| "done" \| "blocked" }`              | Populated by plan; mutated by execution skills                                  |
| `metrics.tasks_total`     | integer          | ≥ 0                                                                        | Plan sets; inspect re-derives from the refined plan; execution never decrements |
| `metrics.tasks_completed` | integer          | ≥ 0                                                                        | Incremented per task completion                                                 |
| `blockers`                | array of strings | —                                                                          | `[]` when clear; never null                                                     |

## Directives

- Read STATE.json at start; confirm `phase: "inspect"` before
  proceeding.
- Don't mutate STATE.json until the exit step.
- **Exit**: after refining PLAN.md, update STATE.json atomically:
  - Set `phase: "build"`.
  - Set `cursor: {active_task_id: "T-001", task_status: "todo"}`.
  - Rebuild `tasks` to mirror the refined PLAN.md IDs exactly, each
    mapped to `"todo"`; plan already reset prior progress, so no task
    carries a completed state here.
  - Set `metrics.tasks_total` to the refined task count (it may rise or
    fall); set `metrics.tasks_completed` to `0`.
  - Preserve `status`, `version`, `workstream`, and `blockers`
    unchanged.
- Never mutate `workstream`, `version`, or `status` during this phase.

## Snapshots

**Entry**:

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

**Exit**:

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
