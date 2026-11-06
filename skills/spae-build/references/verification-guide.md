# Verification guide

## Purpose

Prove outcomes with automated evidence an agent produces unattended.
Never replicate manual human testing for its own sake.

## Principles

- **Evidence over ritual**: verify each outcome through the most direct
  automated evidence available.
- **Evidence ladder**: prefer, in order:
  1. Existing tests and harnesses.
  2. Available automated tools—headless browsers, emulators, snapshot or
     visual-diff tooling—already declared or installed.
  3. Programmatic seams—call arguments, emitted output, file content.
  4. Residual risk, reported explicitly.
- **Translate, don't transcribe**: convert a manual check into the
  outcome it protects, then climb the ladder; a literal GUI re-enactment
  rarely qualifies.
- **Feasibility before execution**: settle each step's tooling from
  concrete evidence—declared dependencies, configs, scripts, installed
  binaries—before execution starts.
  - New tooling counts as planned work with its own task, never an
    execution-time workaround.
- **Isolation**: run apart from the user's live environment—desktop
  session, input devices, personal browser profiles, real accounts,
  production services; prefer headless or sandboxed modes.
- **Self-contained runs**: steps finish unaided—non-interactive, no
  watch mode, no open-ended retries or exploratory probing—and yield a
  machine-decidable result.
  - Timeouts guard against hangs with generous headroom; never judge
    correctness by them.
- **Honest residuals**: record outcomes lacking practical automated
  evidence as residual risks; never fake a pass or write "attempt, else
  report unverified" fallbacks.

## `SPAE` phase roles

| Phase            | Role                                                                                                                        |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `/spec`          | Decide what evidence proves each requirement; record outcomes lacking practical evidence under `Out of scope`.              |
| `/plan`          | Bind each step to tooling confirmed available now; schedule new tooling as a task; carry residual risks to `Risk notes`.    |
| `/inspect`       | Challenge each step's feasibility and isolation; rewrite failing steps or demote them to `Risk notes`.                      |
| `/build`, `/fix` | Execute steps as planned; never discover, install, or calibrate tooling ad hoc; fail fast on an unrunnable step.            |
| `/check`         | Run planned steps; fail an unrunnable planned step as a plan defect; flag a task-written test breaking this guide as a gap. |
| `/verify`        | Judge from automated evidence; treat residual risks as observations, never verdict inputs.                                  |
