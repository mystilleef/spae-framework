# Shell command guide

## Directives

- Redirect `stderr` with `2>&1` only; see redirect syntax table.
- Capture output to a file; **never** pipe through `head`, `tail`, or
  `grep`—in non-`TTY` mode, both sides block waiting for `EOF` that
  never arrives.
- Wrap all commands that spawn processes or produce output with
  `timeout -k 5 N`; see timeout defaults table.
  - `timeout` moves the command into its own process group; harnesses
    that kill only their shell's group miss it until `N` expires.
  - `-k 5`—escalates to `SIGKILL` when the command survives `SIGTERM`
    for 5 seconds.
  - Never pass `--foreground`—on expiry it signals only the direct
    child, orphaning grandchildren (for example, the real `bun` behind a
    Volta shim).
- Redirect `stdin` from `/dev/null` (`< /dev/null`) on all
  non-interactive commands.
- Some tools open `/dev/tty` for credentials, bypassing `< /dev/null`—
  suppress with the tool's non-interactive flag or credential env var.
- Set `CI=true NO_COLOR=1 PAGER=cat TERM=dumb` before invoking test
  runners, build tools, and installers.
- Pass flags per tool docs to exit cleanly: kill descendants, disable
  watch mode, set per-step timeouts.
- Never run watch modes (`--watch`) or dev servers in non-interactive
  shells—they never exit, and `CI=true` doesn't disable them (for
  example, `bun --watch`, `bun test --watch`).
- Write every command self-contained—no environment variables, shell
  options, or state carry over from prior invocations.

## Reference

### Redirect syntax

| Correct           | Wrong           |
| :---------------- | :-------------- |
| `cmd > file 2>&1` | `cmd 2&>1`      |
| `cmd 2>&1`        | `cmd &> file`   |
| `cmd 2>/dev/null` | `cmd \|& other` |

### Timeout defaults

| Type     | Seconds |
| :------- | :------ |
| Tests    | 60      |
| Builds   | 120     |
| Installs | 120     |

`timeout` exits with code `124` on expiry, or `137` when `-k` escalates
to `SIGKILL`—distinguishes a timeout from a real process failure.

### Non-interactive environment variables

| Variable     | Effect                                            |
| :----------- | :------------------------------------------------ |
| `CI=true`    | Disables prompts, progress bars, some watch modes |
| `NO_COLOR=1` | Strips `ANSI` codes                               |
| `TERM=dumb`  | Signals non-interactive terminal                  |
| `PAGER=cat`  | Suppresses pager (for example, `less`) on output  |

## Output capture pattern

```sh
out=$(mktemp)
trap 'rm -f "${out}"' EXIT INT TERM
CI=true NO_COLOR=1 PAGER=cat TERM=dumb timeout -k 5 60 cmd < /dev/null > "${out}" 2>&1
status=$?
tail -n 40 "${out}"
exit "${status}"
```

- `< /dev/null`—prevents tools from blocking on `stdin`
- `trap`—cleans up on any exit, including `SIGINT` and `SIGTERM`
- `tail -n 40` reads from a file—safe; pipes block, files don't

## Pipelines (unavoidable only)

Disable buffering so consumers receive lines as they arrive:

```sh
CI=true NO_COLOR=1 PAGER=cat timeout -k 5 60 stdbuf -oL cmd < /dev/null 2>&1 | grep -m 10 -E 'error|fail'
```

- `stdbuf -oL`—`GNU/Linux` coreutils; use `unbuffer` on macOS/BSD
- `2>&1` before the pipe—`stdbuf -oL` covers both streams
- `grep -m N`—exits after N matches; prevents consumer from blocking
