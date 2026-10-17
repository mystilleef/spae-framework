# `STATE.json`

## Field reference

| Field                   | Type   | Valid values                                                                                       | Category           | Notes                                                        |
| ----------------------- | ------ | -------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------ |
| `version`               | string | `"1.0"`                                                                                            | Derivable Metadata | Fixed; defaults to `"1.0"` when omitted                      |
| `workstream`            | string | kebab-case slug                                                                                    | Derivable Metadata | Set on init; infer from path or symlink target when omitted  |
| `phase`                 | string | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Execution State    | Advances forward; verify no-pass routes backward to `"spec"` |
| `status`                | string | `"active"` \| `"revision_required"` \| `"completed"`                                               | Derivable Metadata | `revision_required` and `completed` written only by verify   |
| `cursor.active_task_id` | string | `"T-NNN"`                                                                                          | Execution State    | `build`, `check`, `fix`, and `verify` phases only            |
| `tasks`                 | object | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                   | Execution State    | Populated by plan; mutated by execution skills               |

## Directives

- **Prepare never writes `STATE.json`.** All state transitions and
  metadata self-healing belong to the `spec`, `plan`, and `inspect`
  agents prepare invokes.
- **Read at start**: if `.spae/current/STATE.json` is missing, require a
  proposal argument (halt otherwise); if present, confirm `phase`
  includes one of `"spec"`, `"plan"`, `"inspect"`. Halt on any other
  `phase` or _unparseable_ JSON syntax.
- **Read after every spawn**: confirm `phase` differs from the value
  recorded at the start of the iteration.
- **Halt immediately** under these conditions:
  - `phase` matches the value recorded at the start of the iteration.
  - `phase` matches none of `"spec"`, `"plan"`, `"inspect"`.
  - JSON syntax fails parsing.
  - The spawned agent reports `Failed` status, crashes, or times out.
- **Final confirmation**: after `inspect` completes, confirm
  `phase: "build"` before emitting the completion result.
- Trust `STATE.json` over subagent result text.

## Snapshots

**Entry** (read-only, prepare doesn't write this):

```json
{
  "version": "1.0",
  "workstream": "example-workstream",
  "phase": "spec",
  "status": "active",
  "cursor": {},
  "tasks": {}
}
```

**Exit — ready for build** (written by inspect, confirmed by prepare):

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
