# State-persistent atomic execution (`SPAE`) framework

The `SPAE` framework provides a high-bandwidth, state-persistent
protocol for large language model (`LLM`) agents. It enables complex
technical execution across many sessions, models, and harnesses without
relying on conversational memory. It enforces rigorous engineering
practices: reading before writing, slicing work vertically, and proving
outcomes before advancing.

## Core principles

- **Zero-knowledge resumption**: Agents keep no internal state. Every
  invocation begins fresh, reading only external artifacts to determine
  the execution cursor.
- **Harness agnosticism**: The protocol requires only file `I/O` and
  large language model prompting. It functions independently of specific
  tool wrappers or proprietary memory systems.
- **Maximum token density**: The system aggressively prunes context.
  Phases load only specific file sections required for the immediate
  task.
- **Atomic execution**: The framework decomposes all work into
  single-cycle, independently verifiable tasks that leave the system in
  a working state.

## Execution guardrails

The framework prioritizes forward motion over workflow theater. To
prevent process inflation, agents maintaining or extending this
framework must enforce these constraints:

- **Protect the artifact limit**: Reject any proposal to add new files
  beyond the core three and the ephemeral `VERIFY.md` signal.
- **Scale detail to task size**: do not force large-process behavior
  (heavy documentation) onto small tasks.
- **Prefer codebase fit**: Reject speculative, new design in favor of
  existing patterns.
- **Reject process bloat**: Reject any new phase or approval gate that
  doesn't materially improve execution reliability.
- **Prohibit `.spae` commits**: Never stage or commit the `.spae/`
  directory. These artifacts maintain local execution state and do not
  belong in version control. Always ensure the project's `.gitignore`
  includes `.spae/`.
- **Enforce phase write boundaries**: `/spec`, `/plan`, and `/inspect`
  may read repository code for context, but they may only write their
  designated `SPAE` artifacts. Only `/build`, `/tdd`, or `/execute` may
  edit source code, tests, configuration files, docs, or any other
  non-`SPAE` project file.
- **Enforce one execution mode per `workstream`**: After `/inspect`,
  users choose `/build`, `/tdd`, or `/execute`. They must not mix them
  within the same `workstream`.

## Artifact location and workspace management

The framework isolates artifacts using the **`Workstream` Directory
Pattern** within a `.spae/` directory at the project root. This prevents
root clutter and supports concurrent tasks.

### Directory structure

```text
.spae/
├── current -> user-auth-oauth/  (Symlink to active workstream)
├── user-auth-oauth/
│   ├── STATE.json
│   ├── SPEC.md
│   └── PLAN.md
└── database-migration/
    ├── STATE.json
    ├── SPEC.md
    └── PLAN.md
```

### Path resolution protocol

1. **Explicit**: If the user provides a `workstream` name (for example,
   `/spec user-auth` or `/plan user-auth`), the agent operates in
   `.spae/user-auth/` and updates the `current` symlink.
2. **Implicit creation**: If the user omits the name during `/spec`, the
   agent generates a slug (for example, `google-oauth-login`), creates
   the directory, and updates the `current` symlink.
3. **Implicit resumption**: If the user omits the name during `/plan`,
   `/inspect`, `/build`, `/tdd`, or `/execute`, the agent resolves the
   `current` symlink to locate the artifacts.

## The canonical artifacts

The framework restricts all state to three core files and one ephemeral
signal per `workstream`.

### 1. `STATE.json` (The execution cursor)

The machine-readable source of truth for orchestration. It dictates the
next action, tracks progress, and maintains the status of all tasks.

```json
{
  "version": "1.0",
  "workstream": "user-auth-oauth",
  "phase": "build",
  "status": "active",
  "cursor": {
    "active_task_id": "T-003",
    "task_status": "in_progress"
  },
  "tasks": {
    "T-001": "done",
    "T-002": "done",
    "T-003": "in_progress",
    "T-004": "todo"
  },
  "metrics": {
    "tasks_total": 4,
    "tasks_completed": 2
  },
  "blockers": []
}
```

### 2. `SPEC.md` (The normalized truth)

Contains distilled requirements and boundaries. Agents must read the
codebase first to ensure the spec fits existing patterns.

- **What**: Core goal.
- **Requirements**: Specific, testable conditions.
- **Testing strategy**: Global validation plan.
- **Out of scope**: Explicit boundaries.
- **Assumptions**: Explicitly stated assumptions.

### 3. `PLAN.md` (The atomic task graph)

Defines the execution sequence. Each task represents a single,
verifiable unit of work. The framework treats this file as immutable
during the execution phase (`/build`, `/tdd`, or `/execute`).

- **Dependencies**: Prerequisite task IDs that form the `DAG` edges.
- **Satisfies**: `SPEC.md` requirement IDs the task implements, or
  `none` for an enabling task.
- **Intent**: One-line goal the task serves, so execution stays
  goal-aware.
- **Context**: Least setup needed for execution.
- **Scope**: Atomic changes the task makes.
- **Acceptance**: Outcomes, not implementation steps.
- **Verification**: Concrete commands or steps to prove success.

### 4. `VERIFY.md` (The ephemeral signal)

Created only when `/verify` detects gaps between implementation and
specification. Contains technical findings, bugs, and optimizations.
`/spec` consumes this file to trigger a revision cycle. `/verify`
deletes this file upon a successful pass.

## The execution loop

Users orchestrate the workflow by manually invoking these skills in
sequence. After `/inspect`, they pick exactly one execution skill for
the workstream: `/build` for direct atomic execution, `/tdd` for
failing-test-first execution, or `/execute` for comprehensive execution.

### Step 1: `/spec` (Smart entry & requirements)

- **Input**: `STATE.json` + `VERIFY.md` (if revising) + `SPEC.md` + raw
  user prompt + codebase context.
- **Action**: Resolve workstream using explicit argument or
  `.spae/current` target. For new workstreams, create the directory,
  update the symlink, and initialize state. For existing workstreams,
  abort if `STATE.json` status lacks `revision_required` or `VERIFY.md`
  does not exist; otherwise, rewrite `SPEC.md` to resolve all findings
  in `VERIFY.md`.
- **Output**: Overwrites `SPEC.md`. Updates `STATE.json` with
  `phase: plan` and `status: active`. Updates `.spae/current`.
- **Write scope**: `SPEC.md`, `STATE.json`, `.spae/current`, and the
  `workstream` directory structure required to create them.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `PLAN.md`, and any other non-`SPAE` project file.

### Step 2: `/plan` (Task decomposition)

- **Input**: `SPEC.md`.
- **Action**: Decomposes the specification into a Directed Acyclic Graph
  (`DAG`) of atomic tasks. Orders tasks by dependency and risk. Ensures
  each task leaves the system in a working state. Treats repository code
  as read-only.
- **Output**: Overwrites `PLAN.md`. Initializes the `tasks` registry in
  `STATE.json`. Updates `STATE.json` phase to `inspect`.
- **Write scope**: `PLAN.md` and `STATE.json`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, and any other non-`SPAE` project file.

### Step 3: `/inspect` (Optimization and verification)

- **Input**: `SPEC.md` + `PLAN.md` + optional source-code context.
- **Action**: Performs gap analysis. Prioritizes concrete bugs,
  regressions, contract breaks, and verification strength. It must not
  evolve into a heavyweight governance stage. Reports findings as
  `Must fix`, `Should fix`, or `Observations`. Reads source code for
  analysis only.
- **Output**: Overwrites `PLAN.md` with the optimized version. When
  refinement resizes the task set, renumbers to contiguous `T-NNN` IDs,
  updates every in-plan reference, and re-derives the `STATE.json`
  `tasks` registry and `metrics.tasks_total` to match. Updates
  `STATE.json` phase to `build`, which signals execution readiness for
  `/build`, `/tdd`, or `/execute`.
- **Write scope**: `PLAN.md` and `STATE.json`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, and any other non-`SPAE` project file.

### Step 4: Execution (`/build`, `/tdd`, or `/execute`)

Choose one execution skill per `workstream` after `/inspect`. All skills
read the same `STATE.json` cursor and the same active task from
`PLAN.md`. Both `/build` and `/tdd` advance the `workstream` one atomic
task at a time, while `/execute` processes all tasks in the plan
sequentially. Avoid alternating between them within the same
`workstream`.

Across all three, agents write exhaustive tests first — expected
behavior, failure modes, and edge cases — then implement the minimal
code to satisfy them. They drive task verification to green by iterating
test→implement, treating a failing check as ordinary work rather than a
stop signal. They halt with a blocker only when a task cannot
pass within its scope — an infeasible acceptance criterion, a plan or
spec defect, or a broken external dependency — never by gaming a test or
editing the plan. When a task legitimately changes a contract, they
update the tests it invalidates to match; they never weaken, skip, or
delete a test to force a pass.

#### Option A: `/build` (Atomic execution)

- **Input**: `STATE.json` (cursor) + `PLAN.md` (plan `Goal` + active
  task
  - `Intent`) + source code.
- **Action**: Executes exactly one atomic task. Writes exhaustive tests
  first — expected behavior, failure modes, and edge cases — then writes
  the minimal code that satisfies them. Runs project checks. Reads
  forward tasks to avoid foreclosing them but never implements beyond
  the active task. Holds exclusive authority to edit source code and
  other non-`SPAE` project files.
- **Output**: Mutates source code. Updates the `tasks` registry in
  `STATE.json` to mark the task as `done`. Advances the cursor. If the
  plan concludes, updates `phase: verify`. The agent never edits
  `PLAN.md` during this phase.

#### Option B: `/tdd` (Test-first atomic execution)

- **Input**: `STATE.json` (cursor) + `PLAN.md` (plan `Goal` + active
  task
  - `Intent`) + source code.
- **Action**: Executes exactly one atomic task with a failing-test-first
  cycle: write a failing test, make the minimal change needed to pass
  and serve the task `Intent` and plan goal, and then refactor while
  keeping tests green. Use this path for behavioral changes where
  explicit test-first proof adds clarity.
- **Output**: Mutates source code and tests. Updates the `tasks`
  registry in `STATE.json` to mark the task as `done`. Advances the
  cursor. If the plan concludes, updates `phase: verify`. The agent
  never edits `PLAN.md` during this phase.

#### Option C: `/execute` (Comprehensive execution)

- **Input**: `STATE.json` (cursor) + `PLAN.md` (plan `Goal` + tasks +
  `Intent`) + source code.
- **Action**: Executes all tasks in plan order, each slice aimed at its
  `Intent` and the plan goal. Writes exhaustive tests first — expected
  behavior, failure modes, and edge cases — then writes the minimal code
  that satisfies them. Runs project checks for each task. Holds
  exclusive authority to edit source code and other non-`SPAE` project
  files.
- **Output**: Mutates source code. Updates the `tasks` registry in
  `STATE.json` to mark all completed tasks as `done`. Updates
  `phase: verify`. The agent never edits `PLAN.md` during this phase.

#### Selection guidance

- Choose `/build` when the plan grows complex, carries high risk, or
  spans many steps, and when step-by-step verification plus course
  correction matter most.
- Choose `/tdd` when the task changes observable behavior and a
  failing-then-passing test offers the clearest proof.
- Choose `/execute` for smaller, low-risk plans, routine refactoring, or
  well-defined features where manual step-by-step orchestration adds
  more overhead than value.
- Keep the choice stable for the whole `workstream`.

### Step 5: `/verify` (The arbiter)

- **Input**: `SPEC.md` + source code.
- **Action**: Compares implementation against `SPEC.md`. Inspects for
  gaps, regressions, and optimizations. Acts as the final arbiter of
  workstream completion.
- **Output (Fail)**: Creates `VERIFY.md` with detailed findings. Updates
  `STATE.json` with `status: revision_required` and `phase: spec`.
- **Output (Pass)**: Deletes `VERIFY.md`. Removes `.spae/current`.
  Updates `STATE.json` with `status: completed` and `phase: done`.
- **Write scope**: `VERIFY.md`, `STATE.json`, and `.spae/current`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, `PLAN.md`, and any other non-`SPAE` project file.

## Standardized output and feedback

Every SPAE skill must output a structured summary and status block upon
completion. This ensures consistent communication and clear next steps.

### 1. Execution summary

Provide a terse, three-point summary of the work performed.

```markdown
### Execution Summary

- **Actions**: [Terse description of actions taken]
- **Files**: [List of modified or created files]
- **Findings**: [Key technical findings, bugs, or blockers]
```

### 2. SPAE status blocks

Use Markdown blockquotes to display the current workstream state and the
required next command.

#### A. Task Execution Feedback (After `/build` or `/tdd`)

```markdown
> **SPAE Status** • `workstream-name` **Progress**: Task [X] of [Y] ([Z]
> remaining) **Completed**: `T-XXX` - [Task title] **Next Task**:
> `T-YYY` - [Next task title]
>
> _Run `/build` (or `/tdd`) to execute the next task._
```

#### B. Comprehensive Execution Feedback (After `/execute`)

```markdown
> **SPAE Status** • `workstream-name` **Progress**: All [X] tasks
> completed **Completed**: `T-001` through `T-XXX` **Next Phase**:
> `/verify`
>
> _Run `/verify` to validate the implementation against the
> specification._
```

#### C. Phase Transition Feedback (After `/spec`, `/plan`, or `/inspect`)

```markdown
> **SPAE Status** • `workstream-name` **Phase Complete**:
> `/[current-phase]` **Next Phase**: `/[next-phase]`
>
> _Run `/[next-phase]` to [brief description of next phase goal]._
```

#### D. Workstream completion feedback (After successful `/verify`)

```markdown
> **SPAE Status** • `workstream-name` **Phase Complete**: `/verify`
> (Pass) **Result**: Workstream completed successfully.
```
