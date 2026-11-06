# `STATE.json`

## Field reference

| Field                   | Type   | Valid values                                                                                       | Category           | Notes                                                                                                        |
| ----------------------- | ------ | -------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------------------------------ |
| `version`               | string | `"1.0"`                                                                                            | Derivable Metadata | Fixed; default `"1.0"` when omitted                                                                          |
| `workstream`            | string | kebab-case slug                                                                                    | Derivable Metadata | Infer from path or symlink target when omitted                                                               |
| `phase`                 | string | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Execution State    | Phase to run next; `"done"` ends the `workstream`                                                            |
| `status`                | string | `"active"` \| `"revision_required"` \| `"completed"`                                               | Derivable Metadata | Default `"active"`; `"revision_required"` only with `phase: "spec"`, `"completed"` only with `phase: "done"` |
| `cursor.active_task_id` | string | `"T-NNN"`                                                                                          | Execution State    | Active task ID; `cursor: {}` while `phase` reads `"spec"`, `"plan"`, or `"inspect"`                          |
| `tasks`                 | object | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                   | Execution State    | Maps every task ID to its progress; `tasks: {}` while `phase` reads `"spec"` or `"plan"`                     |

## Directives

- Read `STATE.json` at entry when present. Self-heal missing metadata:
  `version: "1.0"`, `workstream` (target directory name), and
  `status: "active"`. Halt on _unparseable_ JSON syntax.
- **`Draft` path**: target lacks `STATE.json`, or `STATE.json` reads
  `phase: "spec"`, `status: "active"`.
- **`Revision` path**: `STATE.json` reads `status: "revision_required"`.
- Write `STATE.json` once, at `PERSIST`, after `SPEC.md`; never mutate
  it earlier on either path.
- **Exit (both paths)**: write the full exit snapshot—`version`,
  `workstream`, `phase: "plan"`, `status: "active"`, `cursor: {}`, and
  `tasks: {}`.
- Confirm every write with a fresh read before treating the write as
  done; on a field mismatch, rewrite and re-read.
- A forgotten or partial write—not a task failure—stalls orchestrator
  dispatch and corrupts manual resumption; every write here gates
  automation, not bookkeeping.

## Snapshots

**Entry—`Draft`**: `STATE.json` absent, or `phase: "spec"`,
`status: "active"`.

**Entry—`Revision`**:

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

**Exit—both paths**:

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
