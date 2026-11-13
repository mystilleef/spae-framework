# Verification guide

## Purpose

Prove outcomes with automated evidence an agent produces unattended.
Never replicate manual human testing for its own sake.

## Principles

- **Evidence over ritual**: verify each outcome through the most direct
  automated evidence available.
- **Evidence ladder**: prefer, in order:
  1. Existing tests and harnesses.
  2. Programmatic seams in existing test tooling—call arguments, emitted
     output, file content.
  3. Available automated tools—headless browsers, emulators, snapshot or
     visual-diff tooling—already declared or installed.
  4. Residual risk, reported explicitly.
- **Proportionality**: prove each outcome once, on the first rung
  reaching it:
  - Reserve browser, GUI, emulator, and native-input evidence for
    outcomes no test or programmatic seam reaches.
  - Never re-prove logic unit or contract tests already cover.
- **Translate, don't transcribe**: convert a manual check into the
  outcome it protects, then climb the ladder; a literal GUI re-enactment
  rarely qualifies.
- **Feasibility before execution**: settle each step's tooling from
  concrete evidence—declared dependencies, configs, scripts, installed
  binaries—before execution starts.
  - Rely on tooling already declared or installed.
  - Admit new tooling only when the originating request explicitly
    demands evidence no existing rung reaches; schedule it as planned
    work, never an execution-time workaround. Otherwise record a
    residual risk.
  - Treat a step needing pixel coordinates, timing tuning, or
    machine-specific calibration as infeasible; record its outcome as a
    residual risk.
- **Isolation**: run apart from the user's live environment—desktop
  session, input devices, personal browser profiles, real accounts,
  production services.
  - Sufficient isolation: headless or private display, fresh temporary
    profile and data, mocked or intercepted external services.
  - Never add layers beyond it—network namespaces, capability drops,
    nested sandboxes—unless a requirement demands them.
  - Write run outputs—logs, reports, copies of a prior state—to scratch:
    a private temporary directory outside the project, removed when the
    run ends.
- **Self-contained runs**: steps finish unaided—non-interactive, no
  watch mode, no open-ended retries or exploratory probing—and yield a
  machine-decidable result.
  - A step needs only the project and its stated tooling, never state
    another run left behind outside the project.
  - Timeouts guard against hangs with generous headroom; never judge
    correctness by them.
- **Observation**: a step observes the state it judges and changes
  nothing in the project on purpose—never creates, regenerates, or
  overwrites what it judges—so every run against unchanged state yields
  the same verdict.
  - Byproducts of the project's own commands, such as formatter
    rewrites, stay incidental.
  - Prove a prior state—baselines, before-change measurements—from a
    recording of it, or from that state reproduced in scratch under
    isolation reached without changing the measured code; else record a
    residual risk.
- **Honest residuals**: record outcomes lacking practical automated
  evidence as residual risks; never fake a pass or write "attempt, else
  report unverified" fallbacks.
