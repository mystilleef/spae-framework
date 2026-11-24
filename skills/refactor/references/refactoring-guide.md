# Refactoring guide

Language-agnostic violation catalog for detecting and fixing breaches of
the principles below. Self-contained, with no external references.

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

**YAGNI**—Exclude speculative features and delete unused code

**Idiomatic**—Write clean, language-idiomatic code following established
conventions

**Hygiene**—Self-documenting names, "why" comments only, and no debug
artifacts or commented-out code

**Structure**—Decouple business logic, I/O, and presentation—check
inputs at boundaries and handle failures explicitly

## Violation catalog

Format: numbered **Name** with **Signals**, **Fix**, and **Pitfall**

### `DRY`

1. **Duplicated logic blocks**
   - **Signals**—Same or near-identical logic in 2+ places
   - **Fix**—Extract Function/Method
   - **Pitfall**—Extracting before 3 occurrences (early abstraction)
2. **Duplicated constants/config**
   - **Signals**—Magic values repeated across modules
   - **Fix**—Introduce Named Constant
   - **Pitfall**—Centralizing unrelated values into one dumping module
3. **Structural duplication**
   - **Signals**—Parallel classes/modules with mirrored shape
   - **Fix**—Introduce shared abstraction or template
   - **Pitfall**—Over-abstracting superficial similarity
4. **Copy-paste inheritance**
   - **Signals**—Subclass duplicates parent logic instead of reusing it
   - **Fix**—Replace Inheritance with Composition
   - **Pitfall**—Creating deeper inheritance chains as the "fix"

### `SRP`

5. **God class**
   - **Signals**—Many unrelated public methods, high churn rate, large
     file size
   - **Fix**—Split into focused classes
   - **Pitfall**—Splitting by method count rather than responsibility
     boundary
6. **Mixed concerns**
   - **Signals**—Business logic co-located with I/O, UI, or data access
   - **Fix**—Move Logic to Correct Layer
   - **Pitfall**—Moving code without adjusting dependencies (hidden
     coupling remains)

### `OCP`

7. **Type-dispatch conditional**
   - **Signals**—Behavior selected by type tag in switch/if-else
   - **Fix**—Replace Conditional with Polymorphism
   - **Pitfall**—Applying polymorphism to ≤ 2 cases (a direct
     conditional suffices)
8. **Hard-coded behavior**
   - **Signals**—New variants require modifying existing code, not
     adding new code
   - **Fix**—Make extendable via interface or configuration
   - **Pitfall**—Building extension points for hypothetical cases

### `LSP`

9. **Contract-weakening override**
   - **Signals**—Override throws `NotImplemented`, narrows accepted
     input, or widens returned output
   - **Fix**—Redesign hierarchy or Replace Inheritance with Composition
   - **Pitfall**—Removing the override without reconsidering the
     hierarchy
10. **Silent no-op override**
    - **Signals**—Override body empty or silently no-ops
    - **Fix**—Same as #9, flagging the hierarchy as a design smell
    - **Pitfall**—Leaving the override with a comment as "documentation"

### `ISP`

11. **Fat interface**
    - **Signals**—Implementers forced to stub or leave methods
      unimplemented
    - **Fix**—Split into role-specific interfaces
    - **Pitfall**—Creating too many narrow interfaces (interface
      explosion)
12. **Oversize dependency surface**
    - **Signals**—Callers import or receive more than they use
    - **Fix**—Narrow the interface or introduce a façade
    - **Pitfall**—Conflating with #13 and #14, which target abstraction
      direction, not interface width

### `DIP`

13. **Concrete instantiation in high-level logic**
    - **Signals**—`new ConcreteService()` inside a domain class or
      business function
    - **Fix**—Inject abstraction via constructor or parameter
    - **Pitfall**—Injecting concretions (fixes the symptom, not the
      violation)
14. **High-level imports low-level directly**
    - **Signals**—Domain module imports infrastructure or data-access
      module
    - **Fix**—Invert Dependency and move binding to composition root
    - **Pitfall**—Inverting direction while leaving the dependency in
      the wrong layer

### `KISS`

15. **Unnecessary abstraction**
    - **Signals**—Indirection with a single caller, no variation, no
      testability gain
    - **Fix**—Inline Redundant Abstraction
    - **Pitfall**—Removing abstractions that provide testability or
      extension value
16. **Over-engineered control flow**
    - **Signals**—Nested ternaries, flag parameters, implicit `boolean`
      state
    - **Fix**—Rewrite with explicit, readable constructs
    - **Pitfall**—Replacing with equally opaque constructs (for example,
      complex lambda chains)

### `YAGNI`

17. **Speculative features**
    - **Signals**—Code paths with no callers and no tests
    - **Fix**—Verify no caller/test exists (static search + test suite),
      then delete
    - **Pitfall**—Deleting without verification (may remove implicitly
      used code)
18. **Dead code**
    - **Signals**—Unreachable branches, unused parameters, unused
      exports
    - **Fix**—Verify via test suite and static analysis, then remove
    - **Pitfall**—Removing code referenced only by non-running tests

### `Idiomatic`

19. **Non-idiomatic patterns**
    - **Signals**—Manual iteration in place of map/filter, or manual
      resource cleanup instead of language-native constructs
    - **Fix**—Rewrite to idiomatic form
    - **Pitfall**—Rewriting to an idiom that sacrifices readability for
      novelty

### `Hygiene`

20. **Cryptic identifiers**
    - **Signals**—Single-letter variables or opaque abbreviations
      outside math or loop contexts
    - **Fix**—Rename using domain language
    - **Pitfall**—Over-verbosifying loop variables (`i`, `x`
      conventional in tight loops)
21. **"What" comments**
    - **Signals**—Comments describe what code does, not why
    - **Fix**—Remove or rewrite as a "why" comment
    - **Pitfall**—Removing comments capturing subtle constraints or
      invariants
22. **Debug artifacts**
    - **Signals**—Commented-out code, debug log statements, temporary
      variables
    - **Fix**—Delete before commit
    - **Pitfall**—Removing production observability logging

### `Structure`

23. **Missing boundary validation**
    - **Signals**—Inputs lacking validation at API/interface entry
      points, with internal functions guarding instead
    - **Fix**—Add defensive checks at the boundary and remove redundant
      internal guards
    - **Pitfall**—Adding validation at every layer (over-defensiveness
      creates noise)
24. **Swallowed exceptions**
    - **Signals**—Empty catch blocks or catch-and-log-only without
      recovery or re-raise
    - **Fix**—Handle explicitly with recovery logic, or re-raise with
      added context
    - **Pitfall**—Converting all swallowed exceptions to hard crashes
      (some require graceful degradation)

## Fix playbook

- **Extract Function/Method**—Isolate a logic block into a named
  callable
- **Extract Class/Module**—Move cohesive responsibilities into a
  dedicated unit
- **Introduce Named Constant**—Replace magic values with a single named
  binding
- **Introduce Interface/Abstract Type**—Define a contract independent of
  implementation
- **Replace Conditional with Polymorphism**—Dispatch via type system
  instead of conditionals
- **Invert Dependency**—Make high-level code depend on an abstraction
  the low-level code implements
- **Replace Inheritance with Composition**—Delegate to a contained
  instance rather than extending
- **Rename Identifier**—Replace opaque names with descriptive,
  domain-specific ones
- **Move Logic to Correct Layer**—Move code to its correct architectural
  layer
- **Inline Redundant Abstraction**—Collapse indirection providing no
  value
- **Delete Dead Code**—Remove after verifying via test suite and
  dependency search

## Triage—compound violations

**SRP + OCP:** split responsibilities first, then assess extension
points per extracted class. Fixing extension points before the split
locks them to the wrong responsibility boundaries.

**DRY + SRP:** resist extracting shared logic before splitting concerns.
Extract after splitting—the correct abstraction boundary becomes visible
only once responsibilities separate.

**God class / Compound SRP:** isolate and extract one cohesive
responsibility boundary at a time, avoiding broad multi-entity splits in
a single unverified step.

## Guardrails

- Preserve exact behavior—refactoring changes structure, not semantics
- Introduce a design pattern only when it solves an actual, present
  problem
- Never merge distinct concerns to reduce line count
- Verify with existing test suites before and after each transformation,
  relying on baseline tests to confirm zero behavioral regressions
- Before deleting code (entries #17, #18): run the test suite and search
  for callers—delete only after confirming nothing depends on it
