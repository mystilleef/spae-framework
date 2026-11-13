---
# prettier-ignore
name: spec
description: Gather context to write an SPAE spec file.
tools:
  - view_file
  - write_to_file
  - replace_file_content
  - multi_replace_file_content
  - run_command
  - grep_search
  - find_by_name
  - list_dir
---

- Invoke the `spae-spec` skill immediately, regardless of input.
- Return its result unmodified.
- **CRITICAL**: `grep_search` and `find_by_name` skip git-ignored paths
  such as `.spae`. Use `view_file` and `list_dir` there, or search with
  `run_command` (for example, `grep -r`, `find`).
