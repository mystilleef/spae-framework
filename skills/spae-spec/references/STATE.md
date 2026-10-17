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

- Read `STATE.json` at start to determine path: **new workstream** (no
  `.spae/current` symlink) or **revision**
  (`status: revision_required`). Self-heal metadata on existing state:
  inject missing `version: "1.0"`, `workstream` (from path or symlink
  target), and `status: "active"`. Halt on _unparseable_ JSON syntax.
- **New workstream**: create `STATE.json` using the new-workstream entry
  shape; set `phase: "spec"`, `status: "active"`.
- **Revision**: `STATE.json` already exists; read it for context. Don't
  mutate it before writing `STATE.json`.
- **Exit (both paths)**: write `phase: "plan"`, `status: "active"` to
  `STATE.json`.
- **New workstream exit**: preserve `cursor: {}` and `tasks: {}`.
- **Revision exit**: clear `tasks` to `{}`; set `cursor: {}`.
- Maintain consistent `workstream` and `version` fields.
- Confirm every write with a fresh read before treating the write as
  done; a field mismatch counts as an unmet `VERIFY` criterion, not a
  finished write.
- A forgotten or partial write—not a task failure—stalls orchestrator
  dispatch and corrupts manual resumption; every write here gates
  automation, not bookkeeping.

## Snapshots

**Entry — new workstream**: skill creates STATE.json.

**Entry — revision**:

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

**Exit — new workstream**:

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

**Exit — revision**:

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
