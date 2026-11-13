# Staging evidence

Evidence catalogs for `SKILL.md`: coupling evidence decides which
changes share a commit; ignore evidence decides which `untracked` paths
join `.gitignore`. Examples illustrate each family, never limit it.

## 1. Coupling evidence

Weigh per **Atomic Grouping** in `SKILL.md`. Group changes that _must_
exist together as valid and reversible, in the smallest complete
unit—`OAuth` login with its test, not login plus a user-profile change.

- **Breaking:** splitting yields a commit that fails to build, resolve,
  or install, or loses file history.
  - **Rename pair:** a deleted tracked path whose HEAD content closely
    matches an `untracked` path; piping `git --no-pager show HEAD:<old>`
    into `git --no-pager diff --no-index --numstat -- - <new>` measures
    the difference; once both halves stage,
    `git --no-pager diff --cached --find-renames --summary` confirms
    `rename`.
  - **Symbol rename or removal:** a change renames or removes an
    identifier other changes reference, as in a cross-file refactor;
    `git --no-pager grep -n -w -F <identifier>` across changed files
    confirms.
  - **Manifest and lockfile:** `package.json` with `package-lock.json`,
    `Cargo.toml` with `Cargo.lock`, `pyproject.toml` with its lockfile.
  - **Generated output and source:** a tracked generated file
    regenerated from a changed source, such as test snapshots beside
    their test.
- **Ordering:** the definition lands at or before its use.
  - **Definition and use:** a change adds an identifier, file, or config
    key another change uses, such as a function in `file.ext` that
    `file.test.ext` exercises, or a dependency in `package.json` that
    code imports.
- **Supporting:**
  - **Co-change:** the paths recur together in recent commits touching
    either, per
    `git --no-pager log --format= --name-only -n <N> -- <path>`.
  - **Stem:** a shared base name, such as `file.ext` with
    `file.test.ext`, or a component with its CSS or icons.
  - **Locality:** the same directory or feature module.
- **Counter:**
  - **Distinct intent:** the changes need different subjects or types,
    such as a `fix` beside a `style` sweep.
  - **Mechanical sweep:** formatting, typo, or rename-only churn beside
    feature work.
  - **Unrelated documentation:** `README.md` or `docs/` changes
    describing nothing the accompanying code changes.

## 2. Ignore evidence

Weigh per **Ignore Verdict** in `SKILL.md`; sensitive paths follow
**Ignore Rules** there instead.

- **Decisive:**
  - **Companion:** the path equals an ignored path plus a runtime
    suffix—lock, journal, WAL, shared-memory, PID, temp, backup;
    `git --no-pager check-ignore -v --no-index -- <base>` confirms the
    base. Example: `auth.json.lock` beside ignored `auth.json`.
  - **Self-identification:** `CACHEDIR.TAG`, a tool-written `.gitignore`
    inside the directory, or a generated-file header.
  - **Declared output:** a tracked manifest or config names the path as
    build output, cache, or virtual environment—`outDir`, `target-dir`,
    `cacheDir`.
  - **Ecosystem convention:** the generating tool documents the path as
    ignorable. Examples:
    - Dependencies: `node_modules/`, `vendor/`, `venv/`, `.venv/`,
      `target/` (Rust/Cargo), `.tox/`.
    - Build/Dist: `dist/`, `build/`, `out/`, `bin/` and `obj/` (.NET),
      `*.class`, `*.jar`, `*.exe`, `*.dll`, `*.so`, `*.pyc`,
      `__pycache__/`, `*.egg-info/`.
    - Logs/`Tmp`: `*.log`, `logs/`, `tmp/`, `temp/`, `*.swp`,
      `.DS_Store`, `Thumbs.db`.
    - IDE/Tools: `.vscode/` (except settings/launch if shared),
      `.idea/`, `.vs/`, `.cache/`, `.next/`, `.nuxt/`, `coverage/`,
      `.pytest_cache/`.
- **Supporting, path-specific:**
  - **Stem:** the path shares a stem with one specific ignored
    entry—`auth.lock` beside ignored `auth.json`.
  - **Content:** empty or opaque.
    `git --no-pager diff --no-index --numstat -- /dev/null <path>`
    prints `0 0` for empty and `- -` for binary; opaque text holds
    hashes, UUIDs, PIDs, serialized state, or absolute machine paths;
    recognized asset formats—images, fonts, documents—carry no signal.
  - **Naming:** lock, PID, swap, temp, or backup suffixes; hash- or
    timestamp-shaped names.
  - **Metadata:** owner-only permissions; size far beyond repository
    norms.
- **Supporting, ambient:**
  - **Repository role:** existing ignore sections show a tool writing
    state into the repository; counts only alongside a path-specific
    signal.
- **Counter:**
  - **Input reference:** tracked files reference the path as an
    input—import, include, source, config load; output declarations,
    such as a manifest `main` field pointing into `dist/`, carry no
    counter weight.
  - **Authored content:** comments, prose, hand-written code or scripts,
    such as shell scripts under `bin/`.
  - **Versioned by convention:** lockfiles beside a tracked manifest,
    such as `Cargo.lock` or `package-lock.json`; package markers such as
    an empty `__init__.py`; `.gitkeep` placeholders.
  - **Guard failure:** per **Ignore Guards** in `SKILL.md`.
