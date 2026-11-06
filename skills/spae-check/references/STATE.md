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

- Read `STATE.json` at entry; require `phase: "check"`. Self-heal
  missing metadata: `version: "1.0"`, `workstream` (target directory
  name), and `status: "active"`; self-heal a `"todo"` or missing
  `tasks[active_task_id]` to `"in_progress"`. Halt on _unparseable_ JSON
  syntax, any other `phase`, or `tasks[active_task_id]` reading
  `"done"`.
- Write `STATE.json` once, at `PERSIST`, after any `FIX.md` write; never
  mutate it earlier.
- **Gap**: write `phase: "fix"`; keep the cursor and
  `tasks[active_task_id]: "in_progress"`.
- **Clear, tasks remain** (another task reads `"todo"`):
  - Write `tasks[active_task_id]: "done"`.
  - Advance `cursor.active_task_id` to the next `"todo"` task in
    `PLAN.md` order.
  - Write `phase: "build"`.
- **Clear, final task** (no task reads `"todo"`):
  - Write `tasks[active_task_id]: "done"`.
  - Keep the cursor.
  - Write `phase: "verify"`.
- Preserve `status: "active"`; never reset the cursor or write a
  `revision_required` or `completed` status.
- **Halt**: write nothing; `phase` stays `"check"`.
- Confirm every write with a fresh read before treating the write as
  done; on a field mismatch, rewrite and re-read.
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

**Exit—gap**:

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

**Exit—clear, tasks remain**:

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

**Exit—clear, final task**:

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
