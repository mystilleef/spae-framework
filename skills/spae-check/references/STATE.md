# `STATE.json`

## Field reference

| Field                     | Type             | Valid values                                                                                       | `/check` notes                                                         |
| ------------------------- | ---------------- | -------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `version`                 | string           | `"1.0"`                                                                                            | Fixed                                                                  |
| `workstream`              | string           | kebab-case slug                                                                                    | Set on init; never mutate                                              |
| `phase`                   | string           | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Enter `check`; gaps route `fix`; clear tasks route `build` or `verify` |
| `status`                  | string           | `"active"` \| `"revision_required"` \| `"completed"`                                               | Preserve; `/check` writes no status transition                         |
| `cursor.active_task_id`   | string           | `"T-NNN"`                                                                                          | Must name the active in-progress task                                  |
| `tasks`                   | object           | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                  | `/check` owns the active task `done` transition                        |

## Directives

- **Entry**: read `STATE.json`; require `phase: "check"` and a cursor
  active task ID. Self-heal state drift: if `tasks[`active_task_id`]`
  reads `"todo"`, correct it to `"in_progress"` and write `STATE.json`
  to disk before proceeding. Halt on state drift: if
  `tasks[`active_task_id`]` reads `"done"`, halt and report; make no
  further `STATE.json` write.
- **Gap**: write `phase: "fix"` only. Preserve `status`, `cursor`,
  `tasks`, `version`, and `workstream`; leave the active task
  `in_progress`.
- **Clear, tasks remain**:
  - Write `tasks[`active_task_id`]: "done"`.
  - Advance `cursor.active_task_id` to the next `"todo"` task in
    `PLAN.md` order.
  - Write `phase: "build"`.
- **Clear, final task**:
  - Write `tasks[`active_task_id`]: "done"`.
  - Keep the active task ID.
  - Write `phase: "verify"`.
- Preserve `status: "active"`; never reset the cursor or create a
  `revision_required` or `completed` status.
- Write `STATE.json` once, atomically, after the verdict.
- Never mutate `workstream` or `version`.
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
  "phase": "check",
  "status": "active",
  "cursor": {"active_task_id": "T-002"},
  "tasks": {"T-001": "done", "T-002": "in_progress", "T-003": "todo"}
}
```

**Exit — gap**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "fix",
  "status": "active",
  "cursor": {"active_task_id": "T-002"},
  "tasks": {"T-001": "done", "T-002": "in_progress", "T-003": "todo"}
}
```

**Exit — clear, tasks remain**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "build",
  "status": "active",
  "cursor": {"active_task_id": "T-003"},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "todo"}
}
```

**Exit — clear, final task**:

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
