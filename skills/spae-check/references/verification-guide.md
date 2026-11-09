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
- **Self-contained runs**: steps finish unaided—non-interactive, no
  watch mode, no open-ended retries or exploratory probing—and yield a
  machine-decidable result.
  - Timeouts guard against hangs with generous headroom; never judge
    correctness by them.
- **Honest residuals**: record outcomes lacking practical automated
  evidence as residual risks; never fake a pass or write "attempt, else
  report unverified" fallbacks.
