# State-persistent atomic execution (`SPAE`) framework

The `SPAE` framework provides a high-bandwidth, state-persistent
protocol for large language model (`LLM`) agents. Agents drive every
phase: they author, consume, and act on every artifact; humans supply
intent and receive verified outcomes. It enables complex technical
execution across many sessions, models, and harnesses without relying on
conversational memory. It enforces rigorous engineering practices:
reading before writing, slicing work vertically, and proving outcomes
before advancing.

## Core principles

- **Agent-first artifacts**: Agents author and consume every artifact,
  for varied purposes, with no memory of the authoring run. Refine and
  optimize each artifact for agent consumption: self-contained,
  explicit, and token-dense. Human readers come second.
- **Outcome-first artifacts**: Artifacts state _what_ to achieve and
  _why_; consumers choose _how_. Acceptance and verification hold every
  consumer accountable. `outcome-guide.md` defines the rule.
- **Fault-tolerant resumption**: Agents keep no internal state. Every
  invocation begins fresh, reading only external artifacts to determine
  the execution cursor. The `STATE.json` phase advances only on phase
  completion, so dropped connections, agent errors, or halted
  orchestration lose no finished work. Any harness resumes by rerunning
  the interrupted phase.
- **Harness agnosticism**: The protocol requires only file `I/O` and
  large language model prompting. It functions independently of specific
  tool wrappers or proprietary memory systems.
- **Maximum token density**: The system aggressively prunes context.
  Phases load only specific file sections required for the immediate
  task.
- **Atomic execution**: The framework decomposes all work into
  single-cycle tasks that leave the system in a working state. Each task
  stands alone, as each skill does: fresh, isolated agents build, test,
  and verify it in separate runs, needing only its text and the
  repository, and its lines stay jointly satisfiable. `/spec` audits the
  requirement set and `/inspect` audits tasks against `outcome-guide.md`
  **Self-contained units**.
- **Full autonomy**: No phase, task, or verification step may require
  human execution, an attended or interactive terminal, or a human
  physically present to observe or respond. Deterministic, unattended
  automated waits—polling, `backoff`, timeouts—don't count as human
  intervention. An unverifiable-without-a-human requirement classifies
  as a spec defect, not a valid testing or verification path.
- **Practical verification**: Prove outcomes with automated evidence an
  agent produces unattended; never replicate manual human testing for
  its own sake. Settle feasibility before execution, isolate runs from
  the user's live environment, and record outcomes lacking practical
  evidence as residual risks. Verification observes: `/check` and
  `/verify` rerun planned evidence on finished work, so no step creates,
  regenerates, or overwrites what it judges. `verification-guide.md`
  defines the evidence ladder and these rules; **Verification roles**
  assigns each phase its part.

## Verification roles

Each phase skill states its own role; skills never carry this table.

| Phase            | Role                                                                                                                                                                                       |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `/spec`          | Decide the cheapest evidence proving each requirement; record outcomes lacking practical evidence under `Out of scope`.                                                                    |
| `/plan`          | Bind each step to tooling confirmed available now; schedule admitted new tooling as a task; carry residual risks to `Risk notes`.                                                          |
| `/inspect`       | Challenge each step's feasibility, isolation, observation, and proportionality; rewrite failing steps or demote them to `Risk notes`.                                                      |
| `/build`, `/fix` | Execute steps as planned; never discover, install, or calibrate tooling ad hoc; fail fast on an unrunnable step.                                                                           |
| `/check`         | Run planned steps; halt on a step unrunnable for a cause outside the task diff; flag a step the diff leaves unrunnable, or a task-written test breaking `verification-guide.md`, as a gap. |
| `/verify`        | Judge from automated evidence; treat residual risks as observations, never verdict inputs.                                                                                                 |

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
  belong in version control.
- **Enforce phase write boundaries**: `/spec`, `/plan`, `/inspect`,
  `/check`, and `/verify` may read repository code for context, but they
  may only write their designated `SPAE` artifacts. Only `/build` and
  `/fix` may edit source code, tests, configuration files, docs, or any
  other non-`SPAE` project file. Every phase writes incidental run
  outputs to scratch: a private temporary directory outside the project,
  removed when the run ends. Scratch writes and byproducts of a command
  run for evidence, such as a formatter's rewrites, never count as a
  phase's writes; no phase runs a command for its write effect outside
  its boundary.
- **Fail forward, not sideways**: A task or phase failure in `/build`,
  `/check`, or `/fix` halts orchestration immediately; it never reroutes
  to `/spec` or any other phase. Only `/verify`'s no-pass verdict
  returns a workstream to `/spec`.

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

The framework restricts all state to three core files and two ephemeral
signals per `workstream`.

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

The framework distinguishes **Critical Execution State** (`phase`,
`cursor.active_task_id`, `tasks`) from **Derivable Metadata**
(`version`, `workstream`, `status`):

- **Critical Execution State**: Dictates lifecycle dispatch and task
  progress. Missing or contradictory values halt orchestration.
- **Derivable Metadata**: Enriches tracking. Skills self-heal missing
  metadata automatically upon reading (injecting `version: "1.0"`,
  inferring `workstream` from the symlink target or working directory,
  and defaulting `status: "active"`).
- **Hard Halt Boundaries**: Every halt leaves `phase` unchanged, writes
  no further `STATE.json` change, and reports `Result: Failed`.
  Execution halts only on:
  - `.spae/current` missing or dangling; `STATE.json` missing or holding
    unparseable JSON syntax; a `phase` other than the running phase.
  - A missing or malformed input: `SPEC.md`, `PLAN.md`, `VERIFY.md` (at
    `/spec` revision), `cursor.active_task_id`, the active task's
    `PLAN.md` entry, or `FIX.md` (absent, naming another task, or
    listing no gap).
  - Completed-task re-entry (`"done"` task at entry to build/check/fix),
    or a task not `"done"` at entry to `/verify`.
  - Unmet task dependencies.
  - A defect no source edit closes: an infeasible criterion, an
    unrunnable planned step, or a need for human presence.
  - Unresolvable environment blockers.
  - A `SPEC.md`-internal conflict no `PLAN.md` edit can resolve (at
    `/inspect`).

### 2. `SPEC.md` (The normalized truth)

Contains distilled requirements and boundaries. Agents must read the
codebase first to ensure the spec fits existing patterns.

- **What**: Core goal.
- **Requirements**: Specific, testable outcomes, contracts, constraints,
  or sourced decisions; never unsourced mechanism.
- **Testing strategy**: Global validation plan.
- **Out of scope**: Explicit boundaries and residual risks.
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
- **Context**: Entry-point paths plus facts a fresh agent can't derive.
- **Scope**: The surface the task may change—modules, behaviors,
  contracts—plus non-obvious off-limits areas; never an edit list.
- **Acceptance**: Observable outcomes, contracts, and preserved
  behaviors at risk; never implementation steps.
- **Verification**: Project commands or existing test targets, each
  mapped to the outcomes it proves.

### 4. `VERIFY.md` (The ephemeral revision signal)

Created only when `/verify` detects gaps between implementation and
specification. Contains evidence-backed findings—bugs and
optimizations—stating unmet outcomes, never remedies. `/spec` consumes
this file to trigger a revision cycle. `/verify` deletes this file upon
a successful pass.

### 5. `FIX.md` (The ephemeral gap signal)

Created only when `/check` detects gaps between the active task's
implementation and its `PLAN.md` entry. Contains the task `Intent`; any
task constraints, decisions, and non-derivable facts the closures depend
on; and each gap as the unmet outcome with evidence—never the edit
closing it—with pointers to the affected files: full context to close
them without re-reading the whole plan. `/fix` consumes this file to
scope its edits, then deletes it upon completion.

## The execution loop

Users or orchestrating agents invoke these skills in sequence. After
`/inspect`, `/build` executes one atomic task, `/check` gates it against
the plan, and `/fix` closes any gaps `/check` finds. The
`build`-`check`-`fix` cycle repeats per task until `/check` clears it
clean, then routes to `/build` for the next task or to `/verify` once
the plan concludes.

### Step 1: `/spec` (Smart entry & requirements)

- **Input**: New `workstream`: raw user prompt + codebase context.
  Revision: `STATE.json` + `VERIFY.md` + codebase context.
- **Action**: Resolve `workstream` using explicit argument or
  `.spae/current` target. For new workstreams, create the directory,
  update the symlink, and initialize state. For existing workstreams,
  resume an interrupted draft (`phase: spec`, `status: active`), or, on
  `status: revision_required` with `VERIFY.md` present, write a new
  `SPEC.md` from scratch using `VERIFY.md` findings and source
  inspection; halt otherwise. Audits the draft for joint satisfiability
  and self-heals conflicts by precedence; never halts on them.
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
  each task stands alone and leaves the system in a working state.
  Treats repository code as read-only.
- **Output**: Overwrites `PLAN.md`. Initializes `tasks` to `todo`,
  resets `cursor: {}`, and updates `STATE.json` phase to `inspect`.
- **Write scope**: `PLAN.md` and `STATE.json`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, and any other non-`SPAE` project file.

### Step 3: `/inspect` (Optimization and verification)

- **Input**: `SPEC.md` + `PLAN.md` + optional source-code context.
- **Action**: Performs gap analysis. Prioritizes concrete bugs,
  regressions, contract breaks, and verification strength. It must not
  evolve into a heavyweight governance stage. Reports findings as
  `Must fix`, `Should fix`, or `Observations`. Rewrites plan lines and
  tasks that contradict `SPEC.md`, source code, each other, or
  themselves—`SPEC.md` arbitrates requirements, source code facts. Halts
  without writing on a `SPEC.md`-internal conflict no `PLAN.md` edit can
  resolve. Reads source code for analysis only.
- **Output**: Overwrites `PLAN.md` with the optimized version. When
  refinement resizes the task set, renumbers to contiguous `T-NNN` IDs,
  updates every in-plan reference, and re-derives the `STATE.json`
  `tasks` registry to match. Sets `cursor.active_task_id: T-001` and
  updates `STATE.json` phase to `build`, which signals execution
  readiness for `/build`.
- **Write scope**: `PLAN.md` and `STATE.json`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, and any other non-`SPAE` project file.

### Step 4: `/build` (Atomic execution)

- **Input**: `STATE.json` (cursor), `PLAN.md` (plan `Goal`, active task,
  its `Intent`), and source code.
- **Action**: Executes exactly one atomic task. Halts on state drift at
  entry. Writes exhaustive tests first—expected behavior, failure modes,
  and edge cases—then writes the minimal code that satisfies them. Runs
  project checks. Reads forward tasks to avoid foreclosing them but
  never implements beyond the active task. Drives task verification to
  green by iterating test→implement, treating a failing check as
  ordinary work rather than a stop signal. Fails the task only when it
  can't pass within its scope—an infeasible acceptance criterion, a plan
  or spec defect, or a broken external dependency—never by gaming a test
  or editing the plan. When a task legitimately changes a contract,
  updates the tests it invalidates to match; never weakens, skips, or
  deletes a test to force a pass.
- **Output**: Mutates source code. Leaves the active task `in_progress`
  in the `tasks` registry—`/check` owns the `done` transition and cursor
  advance. Updates `STATE.json` phase to `check`. The agent never edits
  `PLAN.md` during this phase.

### Step 5: `/check` (Task verification gate)

- **Input**: `STATE.json` (cursor) + `PLAN.md` (active task
  `Acceptance` + `Verification`) + source code + tests.
- **Action**: Self-heals metadata (injects missing `version`,
  `workstream`, `status`) and state drift at entry
  (`tasks[active_task_id]` reading `todo` or missing, corrected to
  `in_progress`); halts if it reads `done`. Verifies the active task's
  implementation against its `PLAN.md` entry. Runs project checks and
  the task's own tests. Confirms every `Acceptance` outcome and
  `Verification` step passes, with no gap against the task `Intent`.
  Reads source code for analysis only. Evaluates gaps strictly within
  the active task's declared scope and ignores pre-existing uncommitted
  files outside task scope.
- **Output (Gaps found)**: Writes `FIX.md` with the findings. Updates
  `STATE.json` phase to `fix`. The active task stays `in_progress`.
- **Output (Clean)**: Marks the active task `done` in the `tasks`
  registry. With tasks remaining, advances the cursor to the next `todo`
  task and updates `STATE.json` phase to `build`; on the final task,
  keeps the cursor and updates phase to `verify`.
- **Write scope**: `FIX.md` and `STATE.json`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, `PLAN.md`, and any other non-`SPAE` project file.

### Step 6: `/fix` (Gap remediation)

- **Input**: `STATE.json` (cursor), `FIX.md` (task, `Intent`, `Context`,
  and gaps), and source code; `FIX.md` carries all task context.
- **Action**: Addresses exactly the gaps `FIX.md` lists—nothing beyond
  their scope. Holds the same source-editing authority as `/build`.
  Self-heals metadata (injects missing `version`, `workstream`,
  `status`) and state drift at entry (`todo` → `in_progress`); halts if
  the active task reads `done`. Iterates test→implement until the task's
  tests pass, treating a failing check as ordinary work rather than a
  stop signal. Fails the task only when a gap can't close within
  scope—an infeasible finding, a plan or spec defect, or a broken
  external dependency.
- **Output**: Mutates source code. Updates `STATE.json` phase to
  `check`, then deletes `FIX.md`. The active task stays `in_progress`;
  the agent never marks it `done` or edits `PLAN.md`.

### Step 7: `/verify` (The arbiter)

- **Input**: `STATE.json`, `SPEC.md`, `PLAN.md` (task IDs and `Scope`),
  and source code.
- **Action**: Compares implementation strictly against explicit
  `SPEC.md` requirements. Restricts `Revision required` verdicts to hard
  blocks—requirement failures, regressions, or check breaks; relegates
  theoretical edge cases to observations. Acts as the final arbiter of
  `workstream` completion.
- **Output (Revision required)**: Creates `VERIFY.md` with detailed
  findings. Updates `STATE.json` with `status: revision_required`,
  `phase: spec`, `cursor: {}`, and `tasks: {}`.
- **Output (Pass)**: Updates `STATE.json` with `status: completed` and
  `phase: done`, then deletes `VERIFY.md` and removes `.spae/current`.
- **Output (Failed)**: Writes nothing; `phase` stays `verify`. Covers
  missing inputs, unfinished tasks, and environment failures.
- **Write scope**: `VERIFY.md`, `STATE.json`, and `.spae/current`.
- **Forbidden writes**: Source code, tests, configuration files, docs,
  `SPEC.md`, `PLAN.md`, and any other non-`SPAE` project file.

## Standardized output and feedback

Every SPAE skill must output a structured summary and status block upon
completion. This ensures consistent communication and clear next steps.

### 1. Execution summary

Provide a terse summary of the work performed; omit inapplicable fields.

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Terse list of affected files]
- **Findings**:
  - [Terse list of notable findings]
- **Summary**:
  - [Terse list of summary of changes]
```
<!-- prettier-ignore-end -->

### 2. SPAE status blocks

Use Markdown `blockquotes` to display the current `workstream` state and
the required next command:

- Put `Result` directly after the status line.
- On `Failed`, omit `Next Phase` and the next-step line; report the
  diagnostic under `Findings`.

#### A. Task Implementation Feedback (After `/build`)

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Implemented, pending check
> **Active Task**: `T-XXX` - [Task title]
>
> _Run `/check` to verify the completed task._
```
<!-- prettier-ignore-end -->

#### B. Gap Found Feedback (After `/check`, gaps found)

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Gaps found, `FIX.md` written
> **Active Task**: `T-XXX` - [Task title]
>
> _Run `/fix` to close the gaps._
```
<!-- prettier-ignore-end -->

#### C. Fix Applied Feedback (After `/fix`)

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Gaps addressed, `FIX.md` removed
> **Active Task**: `T-XXX` - [Task title]
>
> _Run `/check` to re-verify the task._
```
<!-- prettier-ignore-end -->

#### D. Task Clear Feedback (After `/check`, clean, tasks remain)

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Clear, tasks remain
> **Progress**: Task [X] of [Y] ([Z] remaining)
> **Completed**: `T-XXX` - [Task title]
> **Next Task**: `T-YYY` - [Next task title]
>
> _Run `/build` to execute the next task._
```
<!-- prettier-ignore-end -->

#### E. Plan Completion Feedback (After `/check` clears the final task)

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Clear, final task
> **Progress**: All [X] tasks completed
> **Completed**: `T-001` through `T-XXX`
> **Next Phase**: `/verify`
>
> _Run `/verify` to validate the implementation against the specification._
```
<!-- prettier-ignore-end -->

#### F. Phase Transition Feedback (After `/spec`, `/plan`, or `/inspect`)

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Phase outcome]
> **Next Phase**: `/[next-phase]`
> **Impact**: [Terse impact statement]
>
> _Run `/[next-phase]` to [brief description of next phase goal]._
```
<!-- prettier-ignore-end -->

#### G. Verdict Feedback (After `/verify`)

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: [Pass | Revision required]
> **Next Phase**: `/spec`  _(if revision required)_
```
<!-- prettier-ignore-end -->

#### H. Failed Feedback (Any phase halt)

<!-- prettier-ignore-start -->
```md
> **`SPAE` Status** • `[workstream-name]`
> **Result**: Failed
> **Active Task**: `T-XXX` - [Task title]  _(build, check, fix)_
```
<!-- prettier-ignore-end -->
