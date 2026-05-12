# Git staging reference

**Goal:** Stage the smallest complete atomic unit forming a single
logical change.

## 1. Atomic grouping heuristics

**Core Rule:** Group files that _must_ exist together as valid and
reversible.

<!-- prettier-ignore -->
| Rel. | Pattern | Action |
| :--- | :--- | :--- |
| **Impl.** | `file.ext` + `file.test.ext` | **ALWAYS** stage together. |
| **Module** | Same feature dir | Stage together if part<br>of same feature. |
| **Dep.** | Code + `package.json` | Stage together. |
| **Assets** | Component + CSS/Icons | Stage together. |
| **Refactor** | Renames / Cross-file | Stage `ALL` affected. |
| **Docs** | `README.md`, `docs/` | Stage **separately**<br>unless related. |

**Priority:**

1. **Smallest Complete Unit:** `OAuth` login (`impl` + test) > `OAuth`
   login + User Profile.
2. **Feature > Cleanup:** Stage feature code before formatting/typo
   fixes.

## 2. Ignore patterns (`DO NOT STAGE`)

**CRITICAL: HARD BLOCK** (Stop & Warn User)

- **Secrets:** `.env*` (except `.example`), `*.key`, `*.pem`, `*.p12`,
  `*.pfx`, `*_rsa`, `*_dsa`, `id_*`, `secrets.*`, `credentials.*`,
  `.aws/`, `.ssh/`, `.gnupg/`.

**Standard Ignores** (Add to `.gitignore` if missing)

- **Dependencies:** `node_modules/`, `vendor/`, `venv/`, `.venv/`,
  `target/` (Rust/Cargo).
- **Build/Dist:** `dist/`, `build/`, `out/`, `bin/`, `obj/`, `*.class`,
  `*.jar`, `*.exe`, `*.dll`, `*.so`, `*.pyc`, `__pycache__/`.
- **Logs/`Tmp`:** `*.log`, `logs/`, `tmp/`, `temp/`, `*.swp`,
  `.DS_Store`, `Thumbs.db`.
- **IDE/Tools:** `.vscode/` (except settings/launch if shared),
  `.idea/`, `.vs/`, `.cache/`, `.next/`, `.nuxt/`, `coverage/`.

## 3. Decision logic

1. **Analyze `Unstaged`:** Identify distinct logical groups (Feature A,
   `Bugfix` B, Docs C).
2. **Check Dependencies:** Do files in A depend on B? If yes, merge.
3. **Isolate:** Pick the most critical/foundational group.
4. **Verify:** Does this group pass tests independently?
5. **Stage.**
