# `STATE.json`

## Field reference

| Field                   | Type   | Valid values                                                                                       | Category           | Notes                                                                |
| ----------------------- | ------ | -------------------------------------------------------------------------------------------------- | ------------------ | -------------------------------------------------------------------- |
| `version`               | string | `"1.0"`                                                                                            | Derivable Metadata | Fixed; inject `"1.0"` when omitted                                   |
| `workstream`            | string | kebab-case slug                                                                                    | Derivable Metadata | Infer from path or symlink target when omitted                       |
| `phase`                 | string | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Execution State    | Advances forward; verify no-pass routes backward to `"spec"`         |
| `status`                | string | `"active"` \| `"revision_required"` \| `"completed"`                                               | Derivable Metadata | Preserve; default to `"active"`; `/plan` writes no status transition |
| `cursor.active_task_id` | string | `"T-NNN"`                                                                                          | Execution State    | `build`, `check`, `fix`, and `verify` phases only                    |
| `tasks`                 | object | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                   | Execution State    | Populated by plan; mutated by execution skills                       |

## Directives

- Read `STATE.json` at start; confirm `phase: "plan"`. Self-heal
  metadata: inject missing `version: "1.0"`, `workstream` (from path or
  symlink target), and `status: "active"`. Halt on _unparseable_ JSON,
  unrecognized `phase`, or missing `SPEC.md`.
- **Reset prior cycle** (`ACT`): clear `tasks` to `{}` and set
  `cursor: {}` in `STATE.json` unconditionally before drafting the new
  plan.
- **Exit**: after writing `PLAN.md`, update `STATE.json` atomically:
  - Populate `tasks` with every new task ID mapped to `"todo"`.
  - Set `phase: "inspect"`.
  - Keep `cursor: {}` and `status: "active"`.
  - Maintain consistent `workstream` and `version` fields.
- Never set `cursor` to anything other than `{}` during this phase.
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
  "phase": "plan",
  "status": "active",
  "cursor": {},
  "tasks": {}
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
  "tasks": {"T-001": "todo", "T-002": "todo", "T-003": "todo"}
}
```
