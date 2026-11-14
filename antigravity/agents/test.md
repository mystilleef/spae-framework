---
# prettier-ignore
name: test
description: Address gaps in code coverage.
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

- Invoke the `test` skill immediately, regardless of input.
- Return its result unmodified.
