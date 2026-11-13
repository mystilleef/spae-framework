```md
# Diagnosis: [symptom title]

> **For agent consumption**: settled evidence for an independent fix.
>
> - Re-run `Reproduction` before any change; on divergence from
>   `Fails with`, halt and report drift against `Baseline`.
> - Fix each finding at its root cause per `Fix direction`; avoid every
>   `Rejected fixes` entry.
> - Treat `Ruled out` as settled; reopen a hypothesis only on new
>   contrary evidence.
> - `Inconclusive`: confirm each `Suspected` finding before fixing it.
> - `Not Reproduced`: change no code until a run reproduces the symptom.
> - Prove the fix through `Verification`.

## Status

- **Result**: [Diagnosed | Inconclusive | Not Reproduced]
- **Baseline**: [Commit SHA; dirty paths, or `clean`]
- **Environment**: [Runtime, OS, and tool versions bearing on the
  failure]

## Symptom

- **Observed**: [Actual behavior, error, or exit code]
- **Expected**: [Correct behavior and its source—test, spec, docs,
  contract]

## Reproduction

- **Command**: `[Unattended command from the repository root]`
- **Fails with**: [Distinguishing output excerpt and exit code]
- **Passes with**: [Output or exit code once fixed]
- **Determinism**: [Deterministic | Flaky—N of M runs]
- **Attempts**: [Not Reproduced only—every condition tried]

## Root cause

- **F1 [Title]**—`path:line` (`symbol`) · [critical | high | medium |
  low] · [Confirmed | Suspected]:
  - **Causal chain**: [Trigger to symptom, step by step]
  - **Proof**: [Check run and observed outcome]
  - **Missing evidence**: [Suspected only—confirming observation; why
    unreachable]

## Ruled out

- **H1 [Hypothesis]**: [Disproving check and outcome]

## Fix direction

- **F1**: [Corrected behavior at the root-cause site—never the edit;
  invariants kept; coupling with other findings]

## Rejected fixes

- **[Candidate fix]**: [Defect—masks the symptom, breaks a P item,
  weakens a contract]

## Scope

- **Touch**: [Surface the fix may change—modules, behaviors, contracts]
- **Exclude**: [Explicit boundaries; incidental defects outside the
  causal chain, with `path:line`]

## Preserved behavior

- **P1**: [Behavior the fix keeps]

## Accepted limits

- **L1**: [Residual risk or unreachable evidence—why accepted]

## Verification

| Outcome         | Evidence                                                           |
| --------------- | ------------------------------------------------------------------ |
| [F/P ID or aim] | [Existing test, tool, or seam—ladder rung]                         |
| F1 regression   | [New test: triggering input, asserted behavior—fails, then passes] |
```
