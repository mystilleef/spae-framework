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
- **Full autonomy**: No phase, task, or verification step may require
  human execution, an attended or interactive terminal, or a human
  physically present to observe or respond. Deterministic, unattended
  automated waits—polling, `backoff`, timeouts—don't count as human
  intervention. An unverifiable-without-a-human requirement classifies
  as a spec defect, not a valid testing or verification path.

## Execution guardrails

The framework prioritizes forward motion over workflow theater. To
prevent process inflation, agents maintaining or extending this
framework must enforce these constraints:

- **Protect the artifact limit**: Reject any proposal to add new files
  beyond the core three and the ephemeral `VERIFY.md` and `FIX.md`
  signals.
- **Scale detail to task size**: don't force large-process behavior
  (heavy documentation) onto small tasks.
- **Prefer codebase fit**: Reject speculative, new design in favor of
  existing patterns.
- **Reject process bloat**: Reject any new phase or approval gate that
  doesn't materially improve execution reliability.
- **Prohibit `.spae` commits**: Never stage or commit the `.spae/`
  directory. These artifacts maintain local execution state and don't
  belong in version control. Always ensure the project's `.gitignore`
  includes `.spae/`.
- **Enforce phase write boundaries**: `/spec`, `/plan`, `/inspect`, and
  `/check` may read repository code for context, but they may only
  write their designated `SPAE` artifacts. Only `/build` and `/fix`
  may edit source code, tests, configuration files, docs, or any other
  non-`SPAE` project file.
- **Fail forward, not sideways**: A task or phase failure in `/build`,
  `/check`, or `/fix` halts orchestration immediately; it never
  reroutes to `/spec` or any other phase. Only `/verify`'s no-pass
  verdict returns a workstream to `/spec`.

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
   `/inspect`, `/build`, `/check`, or `/fix`, the agent resolves the
   `current` symlink to locate the artifacts.

## The canonical artifacts

The framework restricts all state to three core files and two
ephemeral signals per `workstream`.

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
    "active_task_id": "T-003"
  },
  "tasks": {
    "T-001": "done",
    "T-002": "done",
    "T-003": "in_progress",
    "T-004": "todo"
  }
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
during the execution phase (`/build`, `/check`, or `/fix`).

- **Dependencies**: Prerequisite task IDs that form the `DAG` edges.
- **Satisfies**: `SPEC.md` requirement IDs the task implements, or
  `none` for an enabling task.
- **Intent**: One-line goal the task serves, so execution stays
  goal-aware.
- **Context**: Least setup needed for execution.
- **Scope**: Atomic changes the task makes.
- **Acceptance**: Outcomes, not implementation steps.
- **Verification**: Concrete commands or steps to prove success.

### 4. `VERIFY.md` (The ephemeral revision signal)

Created only when `/verify` detects gaps between implementation and
specification. Contains technical findings, bugs, and optimizations.
`/spec` consumes this file to trigger a revision cycle. `/verify`
deletes this file upon a successful pass.

### 5. `FIX.md` (The ephemeral gap signal)

Created only when `/check` detects gaps between the active task's
implementation and its `PLAN.md` entry. Contains the task `Intent`,
the specific gaps found, and pointers to the affected files—full
context for a `/fix` agent to close them without re-reading the whole
plan. `/fix` consumes this file to scope its edits, then deletes it
upon completion.

## The execution loop

Users orchestrate the workflow by manually invoking these skills in
sequence. After `/inspect`, `/build` executes one atomic task, `/check`
gates it against the plan, and `/fix` closes any gaps `/check` finds.
The `build`-`check`-`fix` cycle repeats per task until `/check` clears
it clean, then routes to `/build` for the next task or to `/verify`
once the plan concludes.

### Step 1: `/spec` (Smart entry & requirements)

- **Input**: New `workstream`: raw user prompt + codebase context.
  Revision: `STATE.json` + `VERIFY.md` + codebase context.
- **Action**: Resolve `workstream` using explicit argument or
  `.spae/current` target. For new workstreams, create the directory,
  update the symlink, and initialize state. For existing workstreams,
  abort if `STATE.json` status lacks `revision_required` or `VERIFY.md`
  doesn't exist; otherwise, delete `SPEC.md` and write a new one from
  scratch using `VERIFY.md` findings and source inspection.
- **Output**: Writes `SPEC.md`. Resets `STATE.json` (`phase: plan`,
  `status: active`, `cursor: {}`, `tasks: {}`). Updates `.spae/current`.
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
- **Output**: Overwrites `PLAN.md`. Initializes `tasks` to `todo`, resets
  `cursor: {}`, and updates `STATE.json` phase to `inspect`.
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
  `tasks` registry to match. Updates `STATE.json` phase to `build`,
  which signals execution readiness for `/build`.
- **Write scope**: `PLAN.md` and `STATE.json`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, and any other non-`SPAE` project file.

### Step 4: `/build` (Atomic execution)

- **Input**: `STATE.json` (cursor) + `PLAN.md` (plan `Goal` + active
  task
  - `Intent`) + source code.
- **Action**: Executes exactly one atomic task. Halts on state drift at entry.
  Writes exhaustive tests first—expected behavior, failure modes, and edge
  cases—then writes the minimal code that satisfies them. Runs project checks.
  Reads forward tasks to avoid foreclosing them but never implements beyond
  the active task. Holds exclusive authority to edit source code and other
  non-`SPAE` project files. Drives task verification to green by iterating
  test→implement, treating a failing check as ordinary work rather than a stop
  signal. Fails the task only when it can't pass within its scope—an
  infeasible acceptance criterion, a plan or spec defect, or a broken external
  dependency—never by gaming a test or editing the plan. When a task
  legitimately changes a contract, updates the tests it invalidates to match;
  never weakens, skips, or deletes a test to force a pass.
- **Output**: Mutates source code. Leaves the active task `in_progress`
  in the `tasks` registry—`/check` owns the `done` transition and
  cursor advance. Updates `STATE.json` phase to `check`. The agent
  never edits `PLAN.md` during this phase.

### Step 5: `/check` (Task verification gate)

- **Input**: `STATE.json` (cursor) + `PLAN.md` (active task
  `Acceptance` + `Verification`) + source code + tests.
- **Action**: Self-heals state drift at entry (`tasks[active_task_id]`
  reading `todo`, corrected to `in_progress`); halts if it reads `done`.
  Verifies the active task's
  implementation against its `PLAN.md` entry. Runs project checks and the
  task's own tests. Confirms every `Acceptance` outcome and `Verification`
  step passes, with no gap against the task `Intent`. Reads source code for
  analysis only.
- **Output (Gaps found)**: Writes `FIX.md` with the findings. Updates
  `STATE.json` phase to `fix`. The active task stays `in_progress`.
- **Output (Clean)**: Marks the active task `done` in the `tasks`
  registry and advances the cursor. Updates `STATE.json` phase to
  `build` if tasks remain, or `verify` if the plan concludes.
- **Write scope**: `FIX.md` and `STATE.json`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, `PLAN.md`, and any other non-`SPAE` project file.

### Step 6: `/fix` (Gap remediation)

- **Input**: `STATE.json` (cursor) + `FIX.md` (gaps) + `PLAN.md`
  (active task `Intent`) + source code.
- **Action**: Addresses exactly the gaps `FIX.md` lists—nothing beyond
  their scope. Holds the same source-editing authority as `/build`.
  Self-heals state drift at entry (`todo` → `in_progress`); halts if
  the active task reads `done`. Iterates test→implement until the task's
  tests pass, treating a failing check as ordinary work rather than a stop
  signal. Fails the task only when a gap can't close within scope—an
  infeasible finding, a plan or spec defect, or a broken external dependency.
- **Output**: Mutates source code. Deletes `FIX.md`. Updates
  `STATE.json` phase to `check`. The active task stays `in_progress`;
  the agent never marks it `done` or edits `PLAN.md`.

### Step 7: `/verify` (The arbiter)

- **Input**: `SPEC.md` + source code.
- **Action**: Compares implementation strictly against explicit `SPEC.md`
  requirements. Restricts fail verdicts exclusively to hard block
  requirement failures, regressions, or check breaks; relegates
  theoretical edge cases to observations. Acts as the final arbiter of
  `workstream` completion.
- **Output (Fail)**: Creates `VERIFY.md` with detailed findings. Updates
  `STATE.json` with `status: revision_required`, `phase: spec`, `cursor: {}`,
  and `tasks: {}`.
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
- **Findings**: [Key technical findings, bugs, or failures]
```

### 2. SPAE status blocks

Use Markdown `blockquotes` to display the current `workstream` state and
the required next command.

#### A. Task Implementation Feedback (After `/build`)

```markdown
> **SPAE Status** • `workstream-name` **Active Task**: `T-XXX` - [Task
> title] **Status**: Implemented, pending check
>
> _Run `/check` to verify the completed task._
```

#### B. Gap Found Feedback (After `/check`, gaps found)

```markdown
> **SPAE Status** • `workstream-name` **Active Task**: `T-XXX` - [Task
> title] **Result**: Gaps found, `FIX.md` written
>
> _Run `/fix` to close the gaps._
```

#### C. Fix Applied Feedback (After `/fix`)

```markdown
> **SPAE Status** • `workstream-name` **Active Task**: `T-XXX` - [Task
> title] **Result**: Gaps addressed, `FIX.md` removed
>
> _Run `/check` to re-verify the task._
```

#### D. Task Clear Feedback (After `/check`, clean, tasks remain)

```markdown
> **SPAE Status** • `workstream-name` **Progress**: Task [X] of [Y] ([Z]
> remaining) **Completed**: `T-XXX` - [Task title] **Next Task**:
> `T-YYY` - [Next task title]
>
> _Run `/build` to execute the next task._
```

#### E. Plan Completion Feedback (After `/check` clears the final task)

```markdown
> **SPAE Status** • `workstream-name` **Progress**: All [X] tasks
> completed **Completed**: `T-001` through `T-XXX` **Next Phase**:
> `/verify`
>
> _Run `/verify` to validate the implementation against the
> specification._
```

#### F. Phase Transition Feedback (After `/spec`, `/plan`, or `/inspect`)

```markdown
> **SPAE Status** • `workstream-name` **Phase Complete**:
> `/[current-phase]` **Next Phase**: `/[next-phase]`
>
> _Run `/[next-phase]` to [brief description of next phase goal]._
```

#### G. Workstream completion feedback (After successful `/verify`)

```markdown
> **SPAE Status** • `workstream-name` **Phase Complete**: `/verify`
> (Pass) **Result**: Workstream completed successfully.
```
