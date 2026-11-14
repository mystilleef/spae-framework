---
# prettier-ignore
name: commit
description: Runs the auto-commit skill
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

- Invoke the `auto-commit` skill immediately, regardless of input.
- Return its result unmodified.
