# Refactoring guide

Language-agnostic violation catalog for detecting and fixing DRY, SOLID,
and coding directive violations. Self-contained; no external references.

## Principles

**SOLID**

- **SRP**—Single Responsibility: one reason to change per class/module
- **OCP**—Open/Closed: extend without modifying existing code
- **LSP**—`Liskov` Substitution: derived types substitute base types
  without breaking callers
- **ISP**—Interface Segregation: prefer specific interfaces over
  general-purpose ones
- **DIP**—Dependency Inversion: depend on abstractions, not concretions

**DRY**—Abstract common logic to a single source of truth

**KISS**—Prefer clear, readable solutions over complex abstractions

**YAGNI**—Exclude speculative features; delete unused code

**Idiomatic**—Write clean, language-idiomatic code following established
conventions

**Hygiene**—Self-documenting names; "why" comments only; no debug
artifacts or commented-out code

**Structure**—Decouple business logic, I/O, and presentation; check
inputs at boundaries; handle failures explicitly

## Violation catalog

Format: **Name | Signals | Fix | Pitfall**

### `DRY`

| #   | Name                        | Signals                                                | Fix                                      | Pitfall                                               |
| --- | --------------------------- | ------------------------------------------------------ | ---------------------------------------- | ----------------------------------------------------- |
| 1   | Duplicated logic blocks     | Same or near-identical logic in 2+ places              | Extract Function/Method                  | Extracting before 3 occurrences—early abstraction     |
| 2   | Duplicated constants/config | Magic values repeated across modules                   | Introduce Named Constant                 | Centralizing unrelated values into one dumping module |
| 3   | Structural duplication      | Parallel classes/modules with mirrored shape           | Introduce shared abstraction or template | Over-abstracting when similarity is superficial       |
| 4   | Copy-paste inheritance      | Subclass duplicates parent logic instead of reusing it | Replace Inheritance with Composition     | Creating deeper inheritance chains as the "fix"       |

### `SRP`

| #   | Name           | Signals                                                         | Fix                         | Pitfall                                                            |
| --- | -------------- | --------------------------------------------------------------- | --------------------------- | ------------------------------------------------------------------ |
| 5   | God class      | Many unrelated public methods; high churn rate; large file size | Split into focused classes  | Splitting by method count rather than responsibility boundary      |
| 6   | Mixed concerns | Business logic co-located with I/O, UI, or data access          | Move Logic to Correct Layer | Moving code without adjusting dependencies—hidden coupling remains |

### `OCP`

| #   | Name                      | Signals                                                           | Fix                                            | Pitfall                                                          |
| --- | ------------------------- | ----------------------------------------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------- |
| 7   | Type-dispatch conditional | Behavior selected by type tag in switch/if-else                   | Replace Conditional with Polymorphism          | Applying polymorphism to ≤ 2 cases—a direct conditional suffices |
| 8   | Hard-coded behavior       | New variants require modifying existing code, not adding new code | Make extendable via interface or configuration | Building extension points for hypothetical cases                 |

### `LSP`

| #   | Name                        | Signals                                                                             | Fix                                                        | Pitfall                                                   |
| --- | --------------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------- | --------------------------------------------------------- |
| 9   | Contract-weakening override | Override throws `NotImplemented`, narrows accepted input, or widens returned output | Redesign hierarchy or Replace Inheritance with Composition | Removing the override without reconsidering the hierarchy |
| 10  | Silent no-op override       | Override body empty or silently no-ops                                              | Same as #9; flag hierarchy as design smell                 | Leaving the override with a comment as "documentation"    |

### `ISP`

| #   | Name                        | Signals                                                    | Fix                                      | Pitfall                                                                            |
| --- | --------------------------- | ---------------------------------------------------------- | ---------------------------------------- | ---------------------------------------------------------------------------------- |
| 11  | Fat interface               | Implementers forced to stub or leave methods unimplemented | Split into role-specific interfaces      | Creating too many narrow interfaces—interface explosion                            |
| 12  | Oversize dependency surface | Callers import or receive more than they use               | Narrow the interface; introduce a façade | Confusing with DIP: ISP targets interface width; DIP targets abstraction direction |

### `DIP`

| #   | Name                                       | Signals                                                            | Fix                                                 | Pitfall                                                             |
| --- | ------------------------------------------ | ------------------------------------------------------------------ | --------------------------------------------------- | ------------------------------------------------------------------- |
| 13  | Concrete instantiation in high-level logic | `new ConcreteService()` inside a domain class or business function | Inject abstraction via constructor or parameter     | Injecting concretions—fixes the symptom, not the violation          |
| 14  | High-level imports low-level directly      | Domain module imports infrastructure or data-access module         | Invert Dependency; move binding to composition root | Inverting direction while leaving the dependency in the wrong layer |

### `KISS`

| #   | Name                         | Signals                                                             | Fix                                        | Pitfall                                                                       |
| --- | ---------------------------- | ------------------------------------------------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------- |
| 15  | Unnecessary abstraction      | Indirection with a single caller, no variation, no testability gain | Inline Redundant Abstraction               | Removing abstractions that provide testability or extension value             |
| 16  | Over-engineered control flow | Nested ternaries, flag parameters, implicit `boolean` state         | Rewrite with explicit, readable constructs | Replacing with equally opaque constructs (for example, complex lambda chains) |

### `YAGNI`

| #   | Name                 | Signals                                                 | Fix                                                                    | Pitfall                                                       |
| --- | -------------------- | ------------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------- |
| 17  | Speculative features | Code paths with no callers and no tests                 | Verify no caller/test exists (static search + test suite); then delete | Deleting without verification—may remove implicitly used code |
| 18  | Dead code            | Unreachable branches, unused parameters, unused exports | Verify via test suite and static analysis; then remove                 | Removing code referenced only by non-running tests            |

### `Idiomatic`

| #   | Name                   | Signals                                                                                         | Fix                       | Pitfall                                                       |
| --- | ---------------------- | ----------------------------------------------------------------------------------------------- | ------------------------- | ------------------------------------------------------------- |
| 19  | Non-idiomatic patterns | Manual iteration over map/filter; manual resource cleanup instead of language-native constructs | Rewrite to idiomatic form | Rewriting to an idiom that sacrifices readability for novelty |

### `Hygiene`

| #   | Name                | Signals                                                                     | Fix                                  | Pitfall                                                                 |
| --- | ------------------- | --------------------------------------------------------------------------- | ------------------------------------ | ----------------------------------------------------------------------- |
| 20  | Cryptic identifiers | Single-letter variables; opaque abbreviations outside math or loop contexts | Rename using domain language         | Over-verbosifying loop variables (`i`, `x` conventional in tight loops) |
| 21  | "What" comments     | Comments describe what code does, not why                                   | Remove or rewrite as a "why" comment | Removing comments capturing subtle constraints or invariants            |
| 22  | Debug artifacts     | Commented-out code; debug log statements; temporary variables               | Delete before commit                 | Removing production observability logging                               |

### `Structure`

| #   | Name                        | Signals                                                                                   | Fix                                                                    | Pitfall                                                                               |
| --- | --------------------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| 23  | Missing boundary validation | Inputs lacking validation at API/interface entry points; internal functions guard instead | Add defensive checks at the boundary; remove redundant internal guards | Adding validation at every layer—over-defensiveness creates noise                     |
| 24  | Swallowed exceptions        | Empty catch blocks or catch-and-log-only without recovery or re-raise                     | Handle explicitly with recovery logic, or re-raise with added context  | Converting all swallowed exceptions to hard crashes—some require graceful degradation |

## Fix playbook

| Move                                  | Description                                                                 |
| ------------------------------------- | --------------------------------------------------------------------------- |
| Extract Function/Method               | Isolate a logic block into a named callable                                 |
| Extract Class/Module                  | Move cohesive responsibilities into a dedicated unit                        |
| Introduce Named Constant              | Replace magic values with a single named binding                            |
| Introduce Interface/Abstract Type     | Define a contract independent of implementation                             |
| Replace Conditional with Polymorphism | Dispatch via type system instead of conditionals                            |
| Invert Dependency                     | Make high-level code depend on an abstraction the low-level code implements |
| Replace Inheritance with Composition  | Delegate to a contained instance rather than extending                      |
| Rename Identifier                     | Replace opaque names with descriptive, domain-specific ones                 |
| Move Logic to Correct Layer           | Move code to its correct architectural layer                                |
| Inline Redundant Abstraction          | Collapse indirection providing no value                                     |
| Delete Dead Code                      | Remove after verifying via test suite and dependency search                 |

## Triage—compound violations

**SRP + OCP:** resolve SRP first—split responsibilities, then assess OCP
per extracted class. Fixing OCP before SRP locks extension points to the
wrong responsibility boundaries.

**DRY + SRP:** resist extracting shared logic before splitting concerns.
Extract after splitting—the correct abstraction boundary becomes visible
only once responsibilities separate.

## Guardrails

- Preserve exact behavior—refactoring changes structure, not semantics
- Introduce a design pattern only when it solves an actual, present
  problem
- Never merge distinct concerns to reduce line count
- Verify with existing tests before and after each change; add tests if
  none exist
- Before deleting code (entries #17, #18): run the test suite and search
  for callers—delete only after confirming nothing depends on it
