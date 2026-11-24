---
name: proposal
description:
  Investigates a task and writes a decision-complete, minimally scoped
  proposal to `<slug>-proposal.md` in the current folder, or refines an
  existing proposal in place, for review. Use before planning or
  implementation when a task needs its design, decisions, rejected
  alternatives, accepted limits, and proportional verification settled
  first.
user-invocable: true
argument-hint: "<task statement | path/to/proposal.md>"
---

# Proposal

## When to use

- Turn a task or problem into a reviewable proposal before
  implementation.
- Refine a hand-edited or external proposal before planning or
  implementation.
- Hand any downstream reader—human or agent—a proposal whose every claim
  merits building or proving.

## Goal

- Settle design, decisions, and limits from confirmed findings, leaving
  no open question.
- Write the target proposal, present it for review, and change nothing
  else:
  - `Draft`: a new `./<slug>-proposal.md`.
  - `Refine`: the supplied proposal, in place.

## Input

- `Draft`: task statement from the argument, the conversation, or a
  task-only file.
- `Refine`: path to an existing proposal file.
- Project instruction and architecture docs, when present—for example
  `AGENTS.md`, `CONTRIBUTING.md`, `README.md`.
- Codebase sections the proposal touches.
- `references/PROPOSAL.md`: section template.
- `references/prose-protocol.md`, `references/outcome-guide.md`,
  `references/verification-guide.md`.

## Workflow

Select path by argument:

- **`Refine`**: argument names an existing file holding a proposal.
- **`Draft`**: otherwise. A file holding only a task statement supplies
  the task.

1. **GATE**—Make no writes:
   - Select `Draft` or `Refine`, then set the target:
     - `Draft`: derive a kebab-case `<slug>` from the task, target
       `./<slug>-proposal.md`, and confirm it doesn't exist.
     - `Refine`: target the supplied file and read it in full.
   - Inside a git repository, record `git --no-pager status --porcelain`
     as baseline.
   - Halt on any **Halt conditions** entry.
2. **ORIENT**—State goal and path in one sentence:
   - Every file except the target stays unmodified.
   - Read project instruction and architecture docs in full when
     present.
3. **PLAN**—Declare the work:
   - `Refine`: build a claim ledger—every claim in the target, with its
     rationale and section.
   - List investigation questions:
     - `Draft`: the task's unknowns.
     - `Refine`: open questions and claims needing source confirmation.
   - Name the codebase sections each question needs.
   - Name an experiment only for a question source and docs can't
     settle, stating the decision it informs.
4. **ACT**—Investigate, draft, refine:
   - Read codebase sections narrowly, widening only on uncertainty.
   - Run planned experiments per **Constraints**, then delete their
     temporary directories.
   - `Draft`: draft per `references/PROPOSAL.md` and **Directives**.
   - `Refine`: restructure the target per `references/PROPOSAL.md` and
     **Directives**.
   - Refine with confirmed findings, resolving every open question per
     **Directives**.
5. **VERIFY**—Loop over **Verification** criteria:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when every criterion passes.
6. **PERSIST**—Write the target, then re-read it to confirm the content:
   - `Draft`: create it.
   - `Refine`: overwrite it in place.
7. **REPORT**—Emit result following result directives and using result
   template, then stop.

## Directives

- Optimize all operations for agent, token, and context efficiency.
- Consult `references/prose-protocol.md` and
  `references/outcome-guide.md` before drafting.
- **Self-contained**: readers, often agents, use the proposal for varied
  purposes with no memory of this run or conversation, so keep it
  self-contained, explicit, and token-dense:
  - Define non-standard terms on first use.
  - Never reference conversation context, prior runs, or paths absent
    from the repository, such as deleted experiment directories.
- **Claims become scope**: downstream readers turn every claim outside
  `Guidance` into a _requirement_, test, or exclusion, so write only what
  merits building, preserving, or proving. State `Design` as components,
  interfaces, and contracts. Bind an internal choice through `Decisions`
  with its rationale, else offer it under `Guidance`.
- **`Guidance`**: advisory hints per `references/outcome-guide.md`
  `## Guidance`, keyed by `B` or `C` ID—never scope. Settle tempting
  wrong approaches under `Rejected`, never as `Avoid` hints.
- **Condense, never drop** (`Refine`): tighten wording while keeping
  every claim and its rationale. Move a discarded claim to `Rejected` or
  `Accepted limits` with a one-line rationale, never silently.
- **Evidence versus verification**:
  - `Evidence`: how findings surfaced. Downstream readers treat it as
    assumptions, never obligations.
  - `Verification`: outcomes the implementation must prove, each paired
    with its cheapest proving evidence.
- **YAGNI**: discard _unrequested_ scope, speculative design, and
  theoretical complexity, logging each discard under `Rejected` with a
  one-line rationale.
- **Codebase fit**: prefer existing patterns over new design.
- **Size**: scale detail to task size, write `None` under a section
  without content, and keep headers intact.
- **Proportional verification**, per `references/verification-guide.md`:
  - Pair each outcome with the lowest evidence-ladder rung proving it,
    or prose with reading.
  - Require only tooling the repository already declares or installs.
  - File outcomes only a real GUI, browser, or native input can prove
    under `Accepted limits`. Require such evidence only when the task
    explicitly asks or the repository already declares the tooling.
  - Never prescribe rigs, recipes, pixel coordinates, key sequences, or
    tooling provisioning.
- **Open questions**: resolve each with prudent discretion—the smallest
  scope meeting the goal, and the conservative option when evidence
  stays insufficient:
  - Settle each into `Design`, `Decisions`, `Accepted limits`, or
    `Rejected`.
  - Never emit `Unverified`, open-question, _TODO_, or follow-up
    sections.
- **Plan boundary**: omit delivery ordering, task decomposition, and
  implementation sequencing, leaving them to whoever plans the work. A
  `Guidance` approach sketches one component's solution, never delivery
  order.
- **IMPORTANT:** Return the result to the caller.

## Constraints

- **Write scope**: write only the target, never editing any other file.
- **Experiments**:
  - Run one only when source and docs can't settle a decision.
  - Keep each minimal, unattended, timeout-bounded, and confined to a
    `mktemp -d` directory outside the repository. Delete it before
    `PERSIST`.
  - Use installed tooling only. Never provision tooling or build GUI or
    native-input rigs unless the task explicitly asks.
  - Isolate from the user's desktop, input devices, browser profiles,
    accounts, and live services.
- **Autonomy**: never ask the user for input mid-execution, and never
  propose steps requiring human execution, an attended terminal, or
  human presence.
- **Version control and release**: never propose or run git mutations,
  package publishing, or deployments.
- **No further changes**: after `REPORT`, stop. Never carry out the
  proposal.
- **Halt conditions**: halt without writing and report `Failed` with a
  diagnostic under `Findings`:
  - `Draft`: no task supplied.
  - `Draft`: `./<slug>-proposal.md` already exists.
  - `Refine`: target unreadable or empty.

## Verification

- The target exists, follows `references/PROPOSAL.md` section order, and
  complies with `references/prose-protocol.md`.
- The target stays self-contained: no reference to conversation context,
  prior runs, or paths absent from the repository. Non-standard terms
  carry definitions.
- `Refine`: every claim-ledger entry maps to a target section,
  `Rejected` and `Accepted limits` included. No claim or rationale
  vanishes.
- Every claim names something to build, preserve, decide, reject,
  accept, or advise. No open question, `Unverified` item, _TODO_, or follow-up
  survives.
- Every `Design` claim passes the `references/outcome-guide.md`
  substitution test. Every bound internal choice sits under `Decisions`
  with its rationale.
- Every `Guidance` entry follows the `references/outcome-guide.md`
  `## Guidance` rules and keys a defined `B` or `C` ID.
- Each `Verification` row names existing repository tooling and its
  ladder rung, or reading for prose. No new tooling, rig, recipe,
  coordinate, or key sequence appears.
- GUI-, browser-, or native-input-only outcomes sit under
  `Accepted limits`, unless the task opted in.
- `Evidence` imposes no obligation. No delivery ordering or task
  decomposition appears.
- Section depth matches task size.
- No experiment directory remains.
- `git --no-pager status --porcelain` differs from the **GATE** baseline
  only in the target's entry.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`, so a
  missing, altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, early stop, or halt—with the
  result template as the final message, never on progress narration.
- Set `Result` to exactly one template literal, verbatim. Report an
  early stop or halt lacking its own literal as `Failed`, with the
  reason under `Findings`.
- Emit the result template as live markdown—never in a code fence.
- Output nothing outside the template.

### Result template

<!-- prettier-ignore-start -->
```md
### Execution Summary

- **Actions**:
  - [Terse list of actions taken]
- **Files**:
  - [Proposal path]
- **Findings**:
  - [Terse list of notable findings, risks, or halt diagnostics]
- **Summary**:
  - **Decisions**: [Terse list of key decisions]
  - **Accepted limits**: [Terse list of accepted limits and residual risks]

> **Proposal Status** • `[slug]`
> **Result**: [Drafted | Refined | Failed]
> **Impact**: [Terse impact statement]
> **Path**: `[target path]`
>
> _Review the proposal before planning or implementation._  _(unless failed)_
```
<!-- prettier-ignore-end -->
