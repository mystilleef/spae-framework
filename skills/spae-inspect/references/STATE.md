# `STATE.json`

## Field reference

| Field                     | Type             | Valid values                                                               | Notes                                                                           |
| ------------------------- | ---------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `version`                 | string           | `"1.0"`                                                                    | Fixed                                                                           |
| `workstream`              | string           | kebab-case slug                                                            | Set on init; never mutated                                                      |
| `phase`                   | string           | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Advances forward; verify no-pass routes backward to `"spec"`                    |
| `status`                  | string           | `"active"` \| `"revision_required"` \| `"completed"`                       | `revision_required` and `completed` written only by verify                      |
| `cursor.active_task_id`   | string           | `"T-NNN"`                                                                  | `build`, `check`, `fix`, and `verify` phases only                               |
| `tasks`                   | object           | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                          | Populated by plan; mutated by execution skills                                  |

## Directives

- Read STATE.json at start; confirm `phase: "inspect"` before
  proceeding.
- Don't mutate STATE.json until the exit step.
- **Exit**: after refining PLAN.md, update STATE.json atomically:
  - Set `phase: "build"`.
  - Set `cursor: {active_task_id: "T-001"}`.
  - Rebuild `tasks` to mirror the refined PLAN.md IDs exactly, each
    mapped to `"todo"`; plan already reset prior progress, so no task
    carries a completed state here.
  - Preserve `status`, `version`, and `workstream` unchanged.
- Never mutate `workstream`, `version`, or `status` during this phase.
- Confirm every write with a fresh read before treating the write as
  done; a field mismatch counts as an unmet `VERIFY` criterion, not a
  finished write.
- A forgotten or partial write—not a task failure—stalls orchestrator
  dispatch and corrupts manual resumption; every write here gates
  automation, not bookkeeping.

## Snapshots

**Entry**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "inspect",
  "status": "active",
  "cursor": {},
  "tasks": {"T-001": "todo", "T-002": "todo", "T-003": "todo"}
}
```

**Exit**:

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
