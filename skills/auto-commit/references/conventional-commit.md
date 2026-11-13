# Conventional Commits 1.0.0

Reference for the Conventional Commits 1.0.0 specification
(conventionalcommits.org/en/v1.0.0):

- §1–§5 restate the standard, which binds no tool, framework, or
  environment.
- §6 adds readability conventions from git practice that serve any
  version control tool.
- §7 gives examples.

## 1. Structure

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## 2. Rules

Key words follow the specification: MUST, MAY, SHALL.

- **Prefix:** a type—a noun such as `feat` or `fix`—then an OPTIONAL
  scope, an OPTIONAL `!`, and a REQUIRED colon and space.
- **`feat`:** MUST mark a commit adding a feature.
- **`fix`:** MUST mark a commit fixing a bug.
- **Other types:** MAY appear; see §3.
- **Scope:** OPTIONAL; a noun naming a section of the codebase, in
  parentheses, such as `fix(parser):`; **Commit Vocabulary** in
  `SKILL.md` picks it.
- **Description:** MUST follow the colon and space; a short summary of
  the code changes.
- **Body:** OPTIONAL; begins one blank line after the description;
  free-form, any number of newline-separated paragraphs.
- **Footers:** OPTIONAL; begin one blank line after the body:
  - Each footer holds a word token, a `: ` or ` #` separator, and a
    value, after the git trailer format.
  - Tokens use `-` in place of spaces, such as `Acked-by` or
    `Reviewed-by`.
  - A value MAY span spaces and newlines; parsing ends at the next token
    and separator.
- **Breaking change:** MUST appear in the prefix, a footer, or both; any
  type MAY carry one:
  - Prefix: `!` immediately before the `:`, such as `feat!:` or
    `refactor(api)!:`; the description then SHALL describe the break,
    and the footer turns OPTIONAL.
  - Footer: uppercase `BREAKING CHANGE: <description>`;
    `BREAKING-CHANGE` works as a synonym token.
- **Case:** implementations treat every unit as case-insensitive except
  `BREAKING CHANGE`, which MUST stay uppercase; keep casing consistent
  within a project.

## 3. Types

- **Defined:** `feat` and `fix` alone carry meaning in the
  specification.
- **Others:** the specification mandates none; teams define types and
  evolve them over time; **Commit Vocabulary** in `SKILL.md` picks them
  from project evidence.
- **Common examples** (Angular convention, cited by the specification):
  - `build`: build system or dependencies.
  - `chore`: maintenance.
  - `ci`: continuous-integration configuration.
  - `docs`: documentation only.
  - `perf`: performance.
  - `refactor`: restructuring without behavior change.
  - `style`: formatting without logic change.
  - `test`: tests.
- **Revert:** the FAQ recommends a `revert` type plus a `Refs:` footer
  listing the reverted commit hashes.

## 4. Semantic Versioning

- `fix` → `PATCH`.
- `feat` → `MINOR`.
- A breaking change, regardless of type → `MAJOR`.
- Other types carry no implicit version effect unless they include a
  breaking change.

## 5. Practices from the FAQ

- **Mixed types:** a change fitting more than one type splits into
  separate commits whenever possible.
- **Early development:** write messages as if the product already
  shipped.

## 6. Readability conventions

These conventions originate in git practice and keep history readable
under any version control tool; they add to the standard, never override
it.

- **Subject:** the first line—type, scope, and description—aims for 50
  characters; hard limit 72.
- **Description:** imperative mood ("add," not "added"); no trailing
  period.
- **Body and footers:** wrap lines at 72 characters.

## 7. Examples

### Feature with scope

```
feat(auth): add OAuth2 login support
```

### Fix with body

```
fix(parser): resolve JSON parsing for nested arrays

Previously failed when arrays contained more than 3 levels of
nesting due to a recursion limit.

- Increase recursion depth limit from 3 to 10
- Add validation for maximum nesting depth
- Add regression tests
```

### Breaking change with `!` and footer

```
feat(config)!: change config file format to YAML

BREAKING CHANGE: configuration files now require YAML; JSON
configuration stops loading.
```

### Breaking change on another type

```
chore!: drop support for Node 6

BREAKING CHANGE: use JavaScript features not available in Node 6.
```

### Two footers

```
fix(security): patch XSS vulnerability

Refs: #456
Reviewed-by: Security Team <security@example.com>
```

### Revert

```
revert: let us never again speak of the noodle incident

Refs: 676104e, a215868
```

### Subject over the limit

Avoid—85 characters:

```
feat(auth): add new login system that supports google and facebook and handles errors
```

Prefer—36 characters, details moved to the body:

```
feat(auth): add social login support

Implements OAuth2 providers for Google and Facebook. Includes
error handling for network failures.
```
