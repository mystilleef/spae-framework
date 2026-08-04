````md
# PLAN: [workstream — goal title]

## Goal

[Clear explanation of what the change accomplishes and why]

- **Success criteria**: [Measurable success criteria]

## Assumptions

- **Assumption**: [assumption]
- **Out of scope**: [excluded item]

## Task graph

```mermaid
flowchart TD
  T01[T-001] --> T02[T-002]
```

- T-001: [title]
- T-002: [title] (depends on T-001)

## Tasks

### T-001: [Task title]

- **Dependencies**: [none | T-00N, T-00M]
- **Satisfies**: [R-001, R-003 | none (enabling task, see Context)]
- **Intent**: [One line: the goal this task serves and why it matters]
- **Context**: [Target files, current behavior, and seams]
- **Scope**:
  - [Atomic change 1]
  - [Atomic change 2]
- **Acceptance**:
  - [Expected behavior — outcome when inputs are valid]
  - [Failure mode / Edge case — if specified in SPEC.md or required by
    task logic]
- **Verification**:
  - `[test command covering acceptance criteria above]`
  - `[build or lint command]`

## Risk notes

- [Risk, data loss potential, or fallback path]

## Source audit notes

- [file path, seam, or test file]
````
