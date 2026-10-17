# `STATE.json`

## Field reference

| Field                   | Type   | Valid values                                                                                       | Category           | `/fix` notes                                                        |
| ----------------------- | ------ | -------------------------------------------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------- |
| `version`               | string | `"1.0"`                                                                                            | Derivable Metadata | Fixed; inject `"1.0"` when omitted                                  |
| `workstream`            | string | kebab-case slug                                                                                    | Derivable Metadata | Infer from path or symlink target when omitted                      |
| `phase`                 | string | `"spec"` \| `"plan"` \| `"inspect"` \| `"build"` \| `"check"` \| `"fix"` \| `"verify"` \| `"done"` | Execution State    | Enter `fix`; exit `check` on success only                           |
| `status`                | string | `"active"` \| `"revision_required"` \| `"completed"`                                               | Derivable Metadata | Preserve; default to `"active"`; `/fix` writes no status transition |
| `cursor.active_task_id` | string | `"T-NNN"`                                                                                          | Execution State    | Must name the active in-progress task; never move it                |
| `tasks`                 | object | `{ "T-NNN": "todo" \| "in_progress" \| "done" }`                                                   | Execution State    | Active task must read `in_progress`; `/fix` never changes it        |

## Directives

- **Entry**: read `STATE.json` at start; confirm `phase: "fix"` and an
  active task. Self-heal metadata: inject missing `version: "1.0"`,
  `workstream` (from path or symlink target), and `status: "active"`.
  Self-heal state drift: if `tasks[`active_task_id`]` reads `"todo"` or
  lacks an entry, correct it to `"in_progress"` and write `STATE.json`
  to disk before proceeding. Halt on state drift: if
  `tasks[`active_task_id`]` reads `"done"`, halt and report; make no
  further `STATE.json` write. Halt on _unparseable_ JSON, unrecognized
  `phase`, or missing `FIX.md`.
- **Success**: write `phase: "check"` only. Preserve `status`, `cursor`,
  `tasks`, `version`, and `workstream` exactly.
- **Failure**: make no `STATE.json` write. Leave `FIX.md` and every
  field untouched; halt and report the failure in the result only.
- Write `STATE.json` once, atomically, and only on success.
- Maintain consistent `workstream` and `version` fields.
- Confirm the write with a fresh read before treating the write as done;
  a field mismatch counts as an unmet `VERIFY` criterion, not a finished
  write.
- A forgotten write—not a task failure—stalls orchestrator dispatch and
  corrupts manual resumption; the write here gates automation, not
  bookkeeping.

## Snapshots

**Entry**:

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

**Exit — success**:

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

**Exit — failure**: no write occurs. State remains identical to entry.
