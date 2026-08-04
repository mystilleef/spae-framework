# `STATE.json`

## Field reference

| Field                     | Type             | Valid values                                                                                       | Notes                                                        |
| ------------------------- | ---------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `version`                 | string           | `"1.0"`                                                                                            | Fixed                                                        |
| `workstream`              | string           | kebab-case slug                                                                                    | Set on init; never mutated                                   |
| `phase`                   | string           | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Advances forward; verify no-pass routes backward to `"spec"` |
| `status`                  | string           | `"active"` \| `"revision_required"` \| `"completed"`                                               | `revision_required` and `completed` written only by verify   |
| `cursor.active_task_id`   | string           | `"T-NNN"`                                                                                          | `build`, `check`, `fix`, and `verify` phases only            |
| `tasks`                   | object           | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                  | Populated by plan; mutated by execution skills               |

## Directives

- Read STATE.json at start; confirm `phase: "verify"` and every task in
  `tasks` reads `"done"`; halt otherwise.
- **Pass**: write `phase: "done"`, `status: "completed"` to STATE.json.
  Preserve `cursor` and `tasks` unchanged.
- **No pass** (hard block or soft finding): write `phase: "spec"`,
  `status: "revision_required"`, `cursor: {}`, `tasks: {}` to
  STATE.json.
- **Blocked** (broken build, missing tooling, or environment failure
  prevents checks from running): write `phase: "spec"`,
  `status: "revision_required"`, `cursor: {}`, `tasks: {}` to
  STATE.json.
- Don't mutate `workstream` or `version` during the exit step.
- Write STATE.json only once, after the verdict.
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
  "phase": "verify",
  "status": "active",
  "cursor": {"active_task_id": "T-003"},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "done"}
}
```

**Exit — pass**:

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "done",
  "status": "completed",
  "cursor": {"active_task_id": "T-003"},
  "tasks": {"T-001": "done", "T-002": "done", "T-003": "done"}
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
  "tasks": {}
}
```
