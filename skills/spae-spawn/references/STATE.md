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

- **Read-only**: never write `STATE.json`; spawned subagents perform
  every state transition and metadata self-heal.
- Read `phase` at each dispatch-loop start; trust `STATE.json` over
  subagent output text.
- **Exit**: `phase: "verify"`, at start included.
- **Halt**: per **Halt conditions** in `SKILL.md`.

## Snapshots

**Entry** (read-only, spawn doesn't write this):

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

**Exit—all tasks done** (written by build agents, verified by spawn):

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
