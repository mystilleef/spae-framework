# `STATE.json`

## Field reference

| Field                   | Type   | Valid values                                                                                       | Category           | Notes                                                        |
| ----------------------- | ------ | -------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------ |
| `version`               | string | `"1.0"`                                                                                            | Derivable Metadata | Fixed; inject `"1.0"` when omitted                           |
| `workstream`            | string | kebab-case slug                                                                                    | Derivable Metadata | Set on init; infer from path or symlink target when omitted  |
| `phase`                 | string | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Execution State    | Advances forward; verify no-pass routes backward to `"spec"` |
| `status`                | string | `"active"` \| `"revision_required"` \| `"completed"`                                               | Derivable Metadata | `revision_required` and `completed` written only by verify   |
| `cursor.active_task_id` | string | `"T-NNN"`                                                                                          | Execution State    | `build`, `check`, `fix`, and `verify` phases only            |
| `tasks`                 | object | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                   | Execution State    | Populated by plan; mutated by execution skills               |

## Directives

- Read `STATE.json` at start; confirm `phase: "verify"` and every task
  in `tasks` reads `"done"`. Self-heal metadata: inject missing
  `version: "1.0"`, `workstream` (from path or symlink target), and
  `status: "active"`. Halt on _unparseable_ JSON, unrecognized `phase`,
  or incomplete tasks.
- **Pass**: write `phase: "done"`, `status: "completed"` to
  `STATE.json`. Preserve `cursor` and `tasks` unchanged.
- **No pass** (hard block or soft finding): write `phase: "spec"`,
  `status: "revision_required"`, `cursor: {}`, `tasks: {}` to
  `STATE.json`.
- **Blocked** (broken build, missing tooling, or environment failure
  prevents checks from running): write `phase: "spec"`,
  `status: "revision_required"`, `cursor: {}`, `tasks: {}` to
  `STATE.json`.
- Maintain consistent `workstream` and `version` fields.
- Write `STATE.json` only once, after the verdict.
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
