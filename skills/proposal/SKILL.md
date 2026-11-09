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
- Hand any downstream reader, human or agent, a proposal whose every
  claim merits building or proving.

## Goal

- Settle design, decisions, and limits from confirmed findings; leave no
  open question.
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
- `references/prose-protocol.md`, `references/verification-guide.md`.

## Workflow

Select path by argument:

- **`Refine`**: argument names an existing file holding a proposal.
- **`Draft`**: otherwise; a file holding only a task statement supplies
  the task.

1. **GATE**—Make no writes:
   - Select `Draft` or `Refine`; set the target:
     - `Draft`: derive a kebab-case `<slug>` from the task; target
       `./<slug>-proposal.md`; confirm it doesn't exist.
     - `Refine`: target the supplied file; read it in full.
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
     settle; state the decision it informs.
4. **ACT**—Investigate, draft, refine:
   - Read codebase sections narrowly; widen only on uncertainty.
   - Run planned experiments per **Constraints**; delete their temporary
     directories afterward.
   - `Draft`: draft per `references/PROPOSAL.md` and **Directives**.
   - `Refine`: restructure the target per `references/PROPOSAL.md` and
     **Directives**.
   - Refine with confirmed findings; resolve every open question per
     **Directives**.
5. **VERIFY**—Loop over **Verification** criteria:
   - For each failure: return to `ACT`, fix, then re-enter `VERIFY`.
   - Exit only when every criterion passes.
6. **PERSIST**—Write the target—`Draft`: create; `Refine`: overwrite in
   place; re-read it to confirm the content.
7. **REPORT**—Emit result following result directives and using result
   template; then stop.

## Directives

- Optimize for agent, token, and context efficiency.
- Consult `references/prose-protocol.md` before drafting.
- **Self-contained**: readers, often agents, use the proposal for varied
  purposes, with no memory of this run or conversation; keep it
  self-contained, explicit, and token-dense:
  - Define non-standard terms on first use.
  - Never reference conversation context, prior runs, or paths absent
    from the repository, such as deleted experiment directories.
- **Claims become scope**: downstream readers turn every claim into a
  requirement, test, or exclusion; write only what merits building,
  preserving, or proving.
- **Condense, never drop** (`Refine`): tighten wording; keep every claim
  and its rationale; move a discarded claim to `Rejected` or
  `Accepted limits` with a one-line rationale, never silently.
- **Evidence versus verification**:
  - `Evidence`: how findings surfaced; downstream readers treat it as
    assumptions, never obligations.
  - `Verification`: outcomes the implementation must prove, each paired
    with its cheapest proving evidence.
- **YAGNI**: discard unrequested scope, speculative design, and
  theoretical complexity; log each discard under `Rejected` with a
  one-line rationale.
- **Codebase fit**: prefer existing patterns over new design.
- **Size**: scale detail to task size; write `None` under a section
  without content; keep headers intact.
- **Proportional verification**, per `references/verification-guide.md`:
  - Pair each outcome with the lowest evidence-ladder rung proving it.
  - Require only tooling the repository already declares or installs.
  - File outcomes only a real GUI, browser, or native input can prove
    under `Accepted limits`; require such evidence only when the task
    explicitly asks or the repository already declares the tooling.
  - Never prescribe rigs, recipes, pixel coordinates, key sequences, or
    tooling provisioning.
- **Open questions**: resolve each with prudent discretion—smallest
  scope meeting the goal; the conservative option when evidence stays
  insufficient:
  - Settle each into `Design`, `Decisions`, `Accepted limits`, or
    `Rejected`.
  - Never emit `Unverified`, open-question, TODO, or follow-up sections.
- **Plan boundary**: omit delivery ordering, task decomposition, and
  implementation sequencing; leave them to whoever plans the work.

## Constraints

- **Write scope**: write only the target; never edit any other file.
- **Experiments**:
  - Run one only when source and docs can't settle a decision.
  - Keep each minimal, unattended, timeout-bounded, and confined to a
    `mktemp -d` directory outside the repository; delete it before
    `PERSIST`.
  - Use installed tooling only; never provision tooling or build GUI or
    native-input rigs unless the task explicitly asks.
  - Isolate from the user's desktop, input devices, browser profiles,
    accounts, and live services.
- **Autonomy**: never ask the user for input mid-execution; never
  propose steps requiring human execution, an attended terminal, or
  human presence.
- **Version control and release**: never propose or run git mutations,
  package publishing, or deployments.
- **No further changes**: after `REPORT`, stop; never implement the
  proposal.
- **Halt conditions**: halt without writing; report `Failed` with a
  diagnostic under `Findings`:
  - `Draft`: no task supplied.
  - `Draft`: `./<slug>-proposal.md` already exists.
  - `Refine`: target unreadable or empty.

## Verification

- The target exists, follows `references/PROPOSAL.md` section order, and
  complies with `references/prose-protocol.md`.
- The target stays self-contained: no reference to conversation context,
  prior runs, or paths absent from the repository; non-standard terms
  carry definitions.
- `Refine`: every claim-ledger entry maps to a target section,
  `Rejected` and `Accepted limits` included; no claim or rationale
  vanishes.
- Every claim names something to build, preserve, decide, reject, or
  accept; no open question, `Unverified` item, TODO, or follow-up
  survives.
- Each `Verification` row names existing repository tooling and its
  ladder rung; no new tooling, rig, recipe, coordinate, or key sequence
  appears.
- GUI-, browser-, or native-input-only outcomes sit under
  `Accepted limits`, unless the task opted in.
- `Evidence` imposes no obligation; no delivery ordering or task
  decomposition appears.
- Section depth matches task size.
- No experiment directory remains.
- `git --no-pager status --porcelain` differs from the GATE baseline
  only in the target's entry.

## Result directives

- **Minimum** words. **Maximum** signal.
- Keep prose terse while ensuring clarity.
- Optimize prose for agent, token, and context efficiency.
- Split actions, findings, and summaries into terse bullet points.
- Use lists and sub-lists for long sentences and dense paragraphs.
- **Result contract**: orchestrating agents parse `Result`; a missing,
  altered, or inconsistent result breaks orchestration.
- End every run—completion, short-circuit, abort, or halt—with the
  result template as the final message; never end on progress narration.
- Set `Result` to exactly one template literal, verbatim; report an
  abort or halt lacking its own literal as `Failed`, with the reason
  under `Findings`.
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
