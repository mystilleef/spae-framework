# Proposal: `slug` CLI

Tiny command-line tool converting text to URL slugs. Smoke-test project
for the `SPAE` workflow; keep scope minimal.

## Goal

- Provide one command, `python3 slug.py`, printing a URL-safe slug for
  input text.

## Requirements

- **Runtime**: Python 3, standard library only.
- **Input**:
  - Positional arguments join with a single space.
  - With no arguments, read all of stdin.
  - Arguments take precedence; ignore stdin when present.
- **Transform**:
  - Lowercase the text.
  - Keep ASCII letters `a-z` and digits `0-9`.
  - Collapse every run of other characters (spaces, punctuation,
    non-ASCII) into one hyphen.
  - Strip leading and trailing hyphens.
- **Success**: print the slug and a newline to stdout; exit `0`.
- **Failure**: when the slug comes out empty, print `error: empty slug`
  to stderr, print nothing to stdout, and exit `1`.

| Input                | Stdout           | Exit |
| -------------------- | ---------------- | ---- |
| `Hello, World!`      | `hello-world`    | `0`  |
| `  Spae   Framework` | `spae-framework` | `0`  |
| `Café 2024`          | `caf-2024`       | `0`  |
| `!!!`                | _(empty)_        | `1`  |

## Layout

- `slug.py`—implementation.
- `test_slug.py`—tests.

## Testing

- Framework: `unittest`; run with `python3 -m unittest`.
- Invoke the CLI as a subprocess; assert stdout, stderr, and exit code.
- Cover each table row, the stdin path, and argument precedence over
  stdin.
- Run unattended; no network, no interactive input.

## Out of scope

- Unicode transliteration (`é` → `e`).
- Length limits, custom separators, or other options.
- Packaging, `README`, linting, `CI`.
