#!/bin/sh
# Test runner for install.sh.
#
# Every case runs the installer inside an isolated fixture: private HOME,
# controlled PATH, cloned source tree, captured streams, and filesystem
# snapshots. The installer interpreter is selected through
# INSTALL_TEST_SHELL=dash|busybox|bash-posix (default: dash).
set -eu

PROGRAM=${0##*/}
case "${0}" in
  */*) TESTS_DIR=${0%/*} ;;
  *) TESTS_DIR=. ;;
esac
TESTS_DIR="$(cd "${TESTS_DIR}" && pwd -P)"
REPO_DIR="$(cd "${TESTS_DIR}/.." && pwd -P)"
INSTALLER="${REPO_DIR}/install.sh"
RUNNER="${TESTS_DIR}/test-install.sh"

# ---- installer interpreter selection ------------------------------------

INSTALL_TEST_SHELL=${INSTALL_TEST_SHELL:-dash}
export INSTALL_TEST_SHELL
case "${INSTALL_TEST_SHELL}" in
  dash) SHELL_NAME=dash ;;
  busybox) SHELL_NAME=busybox ;;
  bash-posix) SHELL_NAME=bash ;;
  *)
    printf '%s: unsupported INSTALL_TEST_SHELL %s (expected dash, busybox, or bash-posix)\n' \
      "${PROGRAM}" "${INSTALL_TEST_SHELL}" >&2
    exit 2
    ;;
esac
if command -v "${SHELL_NAME}" > /dev/null 2>&1; then
  SHELL_BIN="$(command -v "${SHELL_NAME}")"
else
  printf '%s: required installer shell not found in PATH: %s (INSTALL_TEST_SHELL=%s)\n' \
    "${PROGRAM}" "${SHELL_NAME}" "${INSTALL_TEST_SHELL}" >&2
  exit 2
fi
if command -v stat > /dev/null 2>&1; then
  :
else
  printf '%s: required snapshot utility not found in PATH: stat\n' "${PROGRAM}" >&2
  exit 2
fi

SYS_PATH=${PATH}
REAL_CP="$(command -v cp)"
REAL_CMP="$(command -v cmp)"
REAL_MKDIR="$(command -v mkdir)"
REAL_MV="$(command -v mv)"
REAL_RM="$(command -v rm)"
REAL_RMDIR="$(command -v rmdir)"
RUNNER_UMASK=$(umask)
# Fixed backup stamp for deterministic backup path assertions.
FIXED_STAMP=20250101T000000Z
RUN_TMP="$(mktemp -d "${TMPDIR:-/tmp}/spae-test-install.XXXXXX")"
trap 'rm -rf "${RUN_TMP}"' EXIT INT TERM

# Installer allowlist plus the interpreter, for restricted-PATH cases.
TOOL_BIN="${RUN_TMP}/tools"
mkdir -p "${TOOL_BIN}"
for _tool in cmp cp mv mkdir rm rmdir find date id; do
  _tool_bin="$(command -v "${_tool}")"
  ln -s "${_tool_bin}" "${TOOL_BIN}/${_tool}"
done
ln -s "${SHELL_BIN}" "${TOOL_BIN}/${SHELL_NAME}"

# Clear inherited overrides; every case sets its own values explicitly.
unset CLAUDE_CONFIG_DIR PI_CODING_AGENT_DIR XDG_CONFIG_HOME CODEX_HOME \
  XDG_STATE_HOME OPENCODE_CONFIG_DIR SUDO_USER

TESTS_RUN=0
TESTS_FAILED=0
CASE_NO=0
CASE_FAILED=0

# ---- fixture helpers ----------------------------------------------------

make_fake_id() {
  cat > "${CASE_BIN}/id" << 'EOF'
#!/bin/sh
# Fixture id: controls privilege probes without real sudo.
case "${1-}" in
  -u) printf '%s\n' "${FAKE_ID_UID-1000}" ;;
  *)
    printf 'fixture id: unexpected invocation\n' >&2
    exit 99
    ;;
esac
EOF
  chmod 755 "${CASE_BIN}/id"
}

make_harness_fake() {
  _mf_name=${1}
  cat > "${CASE_BIN}/${_mf_name}" << EOF
#!/bin/sh
# Fixture harness binary: its execution is a test failure.
printf '%s\n' "${_mf_name}" >> "\${HARNESS_MARK_DIR}/executed"
exit 99
EOF
  chmod 755 "${CASE_BIN}/${_mf_name}"
}

make_clone() {
  _mc_dir=${1}
  mkdir -p "${_mc_dir}"
  cp "${INSTALLER}" "${_mc_dir}/install.sh"
  chmod 755 "${_mc_dir}/install.sh"
  mkdir -p "${_mc_dir}/skills/alpha/references" "${_mc_dir}/skills/beta"
  printf 'alpha skill\n' > "${_mc_dir}/skills/alpha/SKILL.md"
  printf 'alpha reference\n' > "${_mc_dir}/skills/alpha/references/ref.md"
  printf 'beta skill\n' > "${_mc_dir}/skills/beta/SKILL.md"
  mkdir -p "${_mc_dir}/pi/agents"
  printf 'pi agent\n' > "${_mc_dir}/pi/agents/pi-agent.md"
  mkdir -p "${_mc_dir}/claude/agents" "${_mc_dir}/claude/commands"
  printf 'claude agent\n' > "${_mc_dir}/claude/agents/claude-agent.md"
  printf 'claude command\n' > "${_mc_dir}/claude/commands/claude-command.md"
  mkdir -p "${_mc_dir}/antigravity/skills/run" "${_mc_dir}/antigravity/agents"
  printf 'agy run skill\n' > "${_mc_dir}/antigravity/skills/run/SKILL.md"
  printf 'agy agent\n' > "${_mc_dir}/antigravity/agents/agy-agent.md"
  mkdir -p "${_mc_dir}/opencode/agents" "${_mc_dir}/opencode/commands"
  printf 'opencode agent\n' > "${_mc_dir}/opencode/agents/oc-agent.md"
  printf 'opencode command\n' > "${_mc_dir}/opencode/commands/oc-command.md"
  mkdir -p "${_mc_dir}/codex/skills/run/agents" "${_mc_dir}/codex/agents"
  printf 'codex run skill\n' > "${_mc_dir}/codex/skills/run/SKILL.md"
  printf 'codex run agent spec\n' > "${_mc_dir}/codex/skills/run/agents/openai.yaml"
  printf 'codex agent\n' > "${_mc_dir}/codex/agents/codex-agent.md"
  mkdir -p "${_mc_dir}/gemini/agents" "${_mc_dir}/gemini/commands"
  printf 'gemini agent\n' > "${_mc_dir}/gemini/agents/gemini-agent.md"
  printf 'gemini run\n' > "${_mc_dir}/gemini/commands/run.toml"
  printf 'gemini syd\n' > "${_mc_dir}/gemini/commands/syd.toml"
}

make_failing_cp() {
  # Fixture cp: fails for destinations containing $1, delegates otherwise.
  cat > "${CASE_BIN}/cp" << EOF
#!/bin/sh
# Fixture cp: injected copy failure.
case "\${2-}" in
  *"${1}"*)
    printf 'fixture cp failure\n' >&2
    exit 1
    ;;
esac
exec "${REAL_CP}" "\$@"
EOF
  chmod 755 "${CASE_BIN}/cp"
}

make_partial_cp() {
  # Fixture cp: leaves a partial temporary behind for matching destinations,
  # then fails.
  cat > "${CASE_BIN}/cp" << EOF
#!/bin/sh
# Fixture cp: injected partial copy failure.
case "\${2-}" in
  *"${1}"*)
    printf 'partial\n' > "\${2}"
    printf 'fixture cp failure\n' >&2
    exit 1
    ;;
esac
exec "${REAL_CP}" "\$@"
EOF
  chmod 755 "${CASE_BIN}/cp"
}

make_blocking_cp() {
  # Fixture cp: parks mid-copy for destinations containing $1 behind a
  # readiness/acknowledgment FIFO handshake, leaving the partial
  # temporary in place after acknowledgment so signal cases can prove
  # its cleanup.
  mkfifo "${CASE_MARK}/cp-ready" "${CASE_MARK}/cp-ack"
  cat > "${CASE_BIN}/cp" << EOF
#!/bin/sh
# Fixture cp: synchronized pause for signal injection.
case "\${2-}" in
  *"${1}"*)
    printf 'partial\n' > "\${2}"
    printf '%s\n' "\${2}" > "${CASE_MARK}/cp-ready"
    IFS= read -r _bc_line < "${CASE_MARK}/cp-ack"
    exit 0
    ;;
esac
exec "${REAL_CP}" "\$@"
EOF
  chmod 755 "${CASE_BIN}/cp"
}

make_signal_injector() {
  # Fixture injector: rendezvouses with the parked fixture copy, creates
  # a true collision temporary from the reported PID suffix, delivers $1
  # to the installer, then acknowledges the fixture. The installer runs
  # synchronously so its signal traps are live; only this injector is a
  # background job.
  cat > "${CASE_DIR}/injector" << EOF
#!/bin/sh
# Fixture signal injector: readiness/acknowledgment handshake.
IFS= read -r _si_tmp < "${CASE_MARK}/cp-ready"
_si_pid=\${_si_tmp##*.spae-tmp.}
printf 'keep me\n' > "${2}.spae-tmp.\${_si_pid}"
printf '%s\n' "${2}.spae-tmp.\${_si_pid}" > "${CASE_MARK}/collision-path"
kill -${1} "\${_si_pid}"
printf 'ack\n' > "${CASE_MARK}/cp-ack"
EOF
  chmod 755 "${CASE_DIR}/injector"
}

make_failing_cmp() {
  # Fixture cmp: injects a comparison error for arguments containing $1.
  cat > "${CASE_BIN}/cmp" << EOF
#!/bin/sh
# Fixture cmp: injected comparison error.
case "\$*" in
  *"${1}"*)
    printf 'fixture cmp error\n' >&2
    exit 2
    ;;
esac
exec "${REAL_CMP}" "\$@"
EOF
  chmod 755 "${CASE_BIN}/cmp"
}

make_failing_mv() {
  # Fixture mv: fails for destinations containing $1 unless they also
  # contain $2, delegating otherwise.
  cat > "${CASE_BIN}/mv" << EOF
#!/bin/sh
# Fixture mv: injected rename failure.
case "\${2-}" in
  *"${1}"*)
    if [ -n "${2-}" ]; then
      case "\${2-}" in
        *"${2-}"*) exec "${REAL_MV}" "\$@" ;;
      esac
    fi
    printf 'fixture mv failure\n' >&2
    exit 1
    ;;
esac
exec "${REAL_MV}" "\$@"
EOF
  chmod 755 "${CASE_BIN}/mv"
}

make_fake_date() {
  rm -f "${CASE_MARK}/date-calls"
  cat > "${CASE_BIN}/date" << EOF
#!/bin/sh
# Fixture date: fixed UTC stamp for deterministic backup paths.
printf '%s\n' "\$*" >> "${CASE_MARK}/date-calls"
case "\${1-} \${2-}" in
  '-u +%Y%m%dT%H%M%SZ')
    printf '%s\n' '${FIXED_STAMP}'
    ;;
  *)
    printf 'fixture date: unexpected invocation\n' >&2
    exit 99
    ;;
esac
EOF
  chmod 755 "${CASE_BIN}/date"
}

make_mutation_log() {
  # Fixture mutators: append every mkdir/cp/mv/rm/rmdir invocation to a
  # mutation log before delegating, so cases can prove exactly which
  # writes a run attempted.
  rm -f "${CASE_MARK}/mutations"
  for _mml_tool in mkdir cp mv rm rmdir; do
    case "${_mml_tool}" in
      mkdir) _mml_bin=${REAL_MKDIR} ;;
      cp) _mml_bin=${REAL_CP} ;;
      mv) _mml_bin=${REAL_MV} ;;
      rm) _mml_bin=${REAL_RM} ;;
      rmdir) _mml_bin=${REAL_RMDIR} ;;
      *) continue ;;
    esac
    cat > "${CASE_BIN}/${_mml_tool}" << EOF
#!/bin/sh
# Fixture ${_mml_tool}: mutation logger.
printf '%s\n' "${_mml_tool} \$*" >> "${CASE_MARK}/mutations"
exec "${_mml_bin}" "\$@"
EOF
    chmod 755 "${CASE_BIN}/${_mml_tool}"
  done
}

fake_backup_root() {
  _fbr_state=${XDG_STATE_HOME:-${CASE_HOME}/.local/state}
  printf '%s\n' "${_fbr_state}/spae/backups/${FIXED_STAMP}"
}

make_collision_wrapper() {
  # Fixture wrapper: pre-creates the installer's temporary pathname, then
  # execs the installer through the selected interpreter in this very
  # process so the $$ suffix matches.
  cat > "${CASE_CLONE}/collision-install" << EOF
#!/bin/sh
mkdir -p "${1%/*}"
printf 'keep me\n' > "${1}.spae-tmp.\$\$"
case "${SHELL_NAME}" in
  dash) exec "${SHELL_BIN}" "${CASE_CLONE}/install.sh" "\$@" ;;
  busybox) exec "${SHELL_BIN}" sh "${CASE_CLONE}/install.sh" "\$@" ;;
  bash) exec "${SHELL_BIN}" --posix "${CASE_CLONE}/install.sh" "\$@" ;;
  *) exit 2 ;;
esac
EOF
  chmod 755 "${CASE_CLONE}/collision-install"
}

begin_case() {
  CASE_NAME=${1}
  CASE_FAILED=0
  CASE_NO=$((CASE_NO + 1))
  CASE_DIR="${RUN_TMP}/case-${CASE_NO}"
  CASE_HOME="${CASE_DIR}/home"
  CASE_BIN="${CASE_DIR}/bin"
  CASE_MARK="${CASE_DIR}/harness-marks"
  CASE_CLONE="${CASE_DIR}/clone"
  CASE_CWD="${CASE_DIR}"
  CASE_INSTALLER_ARG="${CASE_CLONE}/install.sh"
  CASE_UID=1000
  MEASURED_ROOTS=""
  # Isolated PATH: fixture bin plus the installer utility allowlist.
  CASE_PATH="${CASE_BIN}:${TOOL_BIN}"
  CASE_HOME_SET=1
  mkdir -p "${CASE_HOME}" "${CASE_BIN}" "${CASE_MARK}"
  make_fake_id
  make_clone "${CASE_CLONE}"
  unset CLAUDE_CONFIG_DIR PI_CODING_AGENT_DIR XDG_CONFIG_HOME CODEX_HOME \
    XDG_STATE_HOME OPENCODE_CONFIG_DIR SUDO_USER
}

end_case() {
  assert_no_harness_exec
  if [ "${CASE_FAILED}" = 0 ]; then
    printf 'ok: %s\n' "${CASE_NAME}"
  else
    printf 'FAIL: %s\n' "${CASE_NAME}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  set -e
}

# Opens one counted case on a fresh fixture; errexit stays off until
# end_case so failed assertions record instead of aborting the runner.
start_case() {
  TESTS_RUN=$((TESTS_RUN + 1))
  set +e
  begin_case "${1}"
}

# ---- installer and runner invocation ------------------------------------

run_installer() {
  _ri_home=${HOME}
  _ri_path=${PATH}
  STATUS=0
  HOME=${CASE_HOME}
  PATH=${CASE_PATH}
  export HOME PATH
  if [ "${CASE_HOME_SET}" = 0 ]; then
    unset HOME
  fi
  export FAKE_ID_UID="${CASE_UID}"
  export HARNESS_MARK_DIR="${CASE_MARK}"
  (
    cd "${CASE_CWD}" || exit 1
    _ri_bin=$(command -v "${SHELL_NAME}") || exit 2
    case "${SHELL_NAME}" in
      dash) "${_ri_bin}" "${CASE_INSTALLER_ARG}" "$@" ;;
      busybox) "${_ri_bin}" sh "${CASE_INSTALLER_ARG}" "$@" ;;
      bash) "${_ri_bin}" --posix "${CASE_INSTALLER_ARG}" "$@" ;;
      *) exit 2 ;;
    esac
  ) > "${CASE_DIR}/out" 2> "${CASE_DIR}/err" || STATUS=$?
  HOME=${_ri_home}
  PATH=${_ri_path}
  export HOME PATH
}

# ---- assertions ---------------------------------------------------------

case_fail() {
  printf 'FAIL: %s: %s\n' "${CASE_NAME}" "${1}" >&2
  CASE_FAILED=1
}

assert_status() {
  if [ "${STATUS}" -ne "${1}" ]; then
    case_fail "status ${STATUS}, expected ${1}"
  fi
}

assert_file_empty() {
  if [ -s "${1}" ]; then
    _afe_text=$(cat "${1}")
    case_fail "${2} not empty: ${_afe_text}"
  fi
}

assert_stdout_empty() {
  assert_file_empty "${CASE_DIR}/out" stdout
}

assert_stderr_empty() {
  assert_file_empty "${CASE_DIR}/err" stderr
}

assert_file_eq() {
  if cmp -s "${1}" "${2}"; then
    :
  else
    _afe_text=$(cat "${2}")
    case_fail "${3} mismatch: got ${_afe_text}"
  fi
}

assert_stderr_contains() {
  if grep -q -F -- "${1}" "${CASE_DIR}/err"; then
    :
  else
    _asc_text=$(cat "${CASE_DIR}/err")
    case_fail "stderr misses ${1}: ${_asc_text}"
  fi
}

assert_no_harness_exec() {
  if [ -f "${CASE_MARK}/executed" ]; then
    _anh_text=$(cat "${CASE_MARK}/executed")
    case_fail "fixture harness executed: ${_anh_text}"
  fi
}

write_usage_file() {
  printf '%s\n' \
    'usage: install.sh [-n] [-f] [-u] [-v] <harness>... | all' \
    '       install.sh -h' \
    '' \
    'Install SPAE harness files from this clone.' \
    '' \
    'Options:' \
    '  -n, --dry-run    report planned actions without writing' \
    '  -f, --force      back up, then replace or remove conflicting regular files' \
    '  -u, --uninstall  remove installed files' \
    '  -v, --verbose    report unchanged files' \
    '  -h, --help       show this help and exit' \
    '' \
    'Harnesses:' \
    '  pi claude agy opencode codex gemini' \
    '  antigravity is an alias for agy' > "${1}"
}

write_usage_error_file() {
  printf '%s\n' "${2}" > "${1}"
  write_usage_file "${CASE_DIR}/usage-tmp"
  cat "${CASE_DIR}/usage-tmp" >> "${1}"
}

write_lines_file() {
  _wlf_path=${1}
  shift
  : > "${_wlf_path}"
  for _wlf_line in "$@"; do
    printf '%s\n' "${_wlf_line}" >> "${_wlf_path}"
  done
}

assert_stderr_lines() {
  _asl_path="${CASE_DIR}/expected-err"
  write_lines_file "${_asl_path}" "$@"
  assert_file_eq "${_asl_path}" "${CASE_DIR}/err" stderr
}

assert_stdout_contains() {
  if grep -q -F -- "${1}" "${CASE_DIR}/out"; then
    :
  else
    _asoc_text=$(cat "${CASE_DIR}/out")
    case_fail "stdout misses ${1}: ${_asoc_text}"
  fi
}

assert_stdout_lacks() {
  if grep -q -F -- "${1}" "${CASE_DIR}/out"; then
    case_fail "stdout unexpectedly contains ${1}"
  fi
}

assert_stdout_count() {
  _asc_n=$(grep -c -F -x -- "${1}" "${CASE_DIR}/out" 2> /dev/null || true)
  if [ "${_asc_n}" = "${2}" ]; then
    :
  else
    case_fail "stdout count ${_asc_n} for '${1}', expected ${2}"
  fi
}

assert_stdout_lines() {
  _asol_path="${CASE_DIR}/expected-out"
  write_lines_file "${_asol_path}" "$@"
  assert_file_eq "${_asol_path}" "${CASE_DIR}/out" stdout
}

assert_installed() {
  if [ -f "${CASE_CLONE}/${1}" ] && cmp -s "${CASE_CLONE}/${1}" "${2}"; then
    :
  else
    case_fail "missing or mismatched install: ${2}"
  fi
}

assert_absent() {
  if [ -e "${1}" ] || [ -L "${1}" ]; then
    case_fail "unexpected path: ${1}"
  fi
}

assert_dir_present() {
  if [ -d "${1}" ]; then
    :
  else
    case_fail "missing directory: ${1}"
  fi
}

assert_link_present() {
  if [ -L "${1}" ]; then
    :
  else
    case_fail "missing link: ${1}"
  fi
}

assert_mode() {
  ls -ldn "${1}" > "${CASE_DIR}/mode-out" 2> /dev/null
  _am_mode=$(awk '{print substr($1, 1, 10)}' "${CASE_DIR}/mode-out")
  if [ "${_am_mode}" = "${2}" ]; then
    :
  else
    case_fail "mode ${_am_mode} for ${1}, expected ${2}"
  fi
}

assert_no_temporaries() {
  _ant_hits=$(find "${CASE_HOME}" -name '*.spae-tmp.*' 2> /dev/null || true)
  if [ -n "${_ant_hits}" ]; then
    case_fail "leftover temporaries: ${_ant_hits}"
  fi
}

assert_mutations_empty() {
  if [ -s "${CASE_MARK}/mutations" ]; then
    _ame_hits=$(cat "${CASE_MARK}/mutations")
    case_fail "unexpected mutation commands: ${_ame_hits}"
  fi
}

assert_date_calls() {
  _adc_count=0
  if [ -f "${CASE_MARK}/date-calls" ]; then
    _adc_count=$(awk 'END {print NR}' "${CASE_MARK}/date-calls")
  fi
  if [ "${_adc_count}" = "${1}" ]; then
    :
  else
    case_fail "date calls ${_adc_count}, expected ${1}"
  fi
}

# ---- snapshots ----------------------------------------------------------

NL='
'

# Registers an external state tree or directory-link referent so snapshot
# comparisons cover it alongside the HOME/clone contract.
measure_root() {
  if [ -z "${MEASURED_ROOTS}" ]; then
    MEASURED_ROOTS=${1}
  else
    MEASURED_ROOTS="${MEASURED_ROOTS}${NL}${1}"
  fi
}

# Captures root metadata, inventory, modes, link targets, bytes, and full
# modification-time precision for $2; access times stay unmeasured so read
# activity never registers as a change.
capture_snapshot() {
  if [ ! -d "${2}" ]; then
    printf 'absent: %s\n' "${2}" > "${1}"
    return 0
  fi
  (
    cd "${2}" || exit 1
    ls -ldn .
    _cs_mtime=$(stat -c '%y' .)
    printf '. mtime %s\n' "${_cs_mtime}"
    find . -mindepth 1 | LC_ALL=C sort | while IFS= read -r _cs_path; do
      ls -ldn "${_cs_path}"
      _cs_mtime=$(stat -c '%y' "${_cs_path}")
      printf '%s mtime %s\n' "${_cs_path}" "${_cs_mtime}"
      if [ -f "${_cs_path}" ] && [ ! -L "${_cs_path}" ]; then
        cksum < "${_cs_path}" | awk -v p="${_cs_path}" '{print p, $1, $2}'
      fi
    done
  ) > "${1}"
}

snapshot_all() {
  capture_snapshot "${CASE_DIR}/${1}-home" "${CASE_HOME}"
  capture_snapshot "${CASE_DIR}/${1}-clone" "${CASE_CLONE}"
  _sa_no=0
  while IFS= read -r _sa_root || [ -n "${_sa_root}" ]; do
    if [ -z "${_sa_root}" ]; then
      continue
    fi
    _sa_no=$((_sa_no + 1))
    capture_snapshot "${CASE_DIR}/${1}-extra-${_sa_no}" "${_sa_root}"
  done << EOF
${MEASURED_ROOTS}
EOF
}

# Sets CHANGED_TREES to the measured captures whose before/after snapshots
# differ; empty means every measured tree survived unchanged.
compare_snapshots() {
  CHANGED_TREES=""
  for _cps_label in home clone; do
    if cmp -s "${CASE_DIR}/before-${_cps_label}" "${CASE_DIR}/after-${_cps_label}"; then
      :
    else
      CHANGED_TREES="${CHANGED_TREES} ${_cps_label}"
    fi
  done
  _cps_no=0
  while IFS= read -r _cps_root || [ -n "${_cps_root}" ]; do
    if [ -z "${_cps_root}" ]; then
      continue
    fi
    _cps_no=$((_cps_no + 1))
    if cmp -s "${CASE_DIR}/before-extra-${_cps_no}" "${CASE_DIR}/after-extra-${_cps_no}"; then
      :
    else
      CHANGED_TREES="${CHANGED_TREES} extra-${_cps_no}"
    fi
  done << EOF
${MEASURED_ROOTS}
EOF
}

assert_tree_unchanged() {
  snapshot_all after
  compare_snapshots
  if [ -n "${CHANGED_TREES}" ]; then
    case_fail "measured trees changed:${CHANGED_TREES}"
  fi
}

# Captures root $2 under slot $1 so later assert_root_unchanged calls prove
# the root survived an operation that legitimately changes other trees.
capture_root() {
  capture_snapshot "${CASE_DIR}/root-${1}" "${2}"
}

# Asserts root $2 still matches its capture_root snapshot for slot $1,
# covering bytes, links, modes, and full modification-time precision.
assert_root_unchanged() {
  capture_snapshot "${CASE_DIR}/root-after-${1}" "${2}"
  if cmp -s "${CASE_DIR}/root-${1}" "${CASE_DIR}/root-after-${1}"; then
    :
  else
    case_fail "measured root changed: ${2}"
  fi
}

# Runs the installer with $2...; expects exit 1, the single stderr line
# "install.sh: $1", empty stdout, and no write to any measured tree.
assert_preflight_failure() {
  _apf_message=${1}
  shift
  snapshot_all before
  run_installer "$@"
  assert_status 1
  assert_stderr_lines "install.sh: ${_apf_message}"
  assert_stdout_empty
  assert_tree_unchanged
}

# ---- structural contract cases ------------------------------------------

test_scripts_carry_mode_755() {
  _tcm_hit=$(find "${INSTALLER}" -prune -perm 755)
  if [ -n "${_tcm_hit}" ]; then
    :
  else
    case_fail "install.sh is not mode 755"
  fi
  _tcm_hit=$(find "${RUNNER}" -prune -perm 755)
  if [ -n "${_tcm_hit}" ]; then
    :
  else
    case_fail "test-install.sh is not mode 755"
  fi
}

test_installer_behaves_identically_without_extra_utilities() {
  make_harness_fake pi
  CASE_PATH="${CASE_BIN}:${SYS_PATH}"
  run_installer pi
  assert_status 0
  _tbi_first=${CASE_DIR}
  sed "s|${_tbi_first}|CASE|g" "${CASE_DIR}/out" > "${RUN_TMP}/out-host-path"
  sed "s|${_tbi_first}|CASE|g" "${CASE_DIR}/err" > "${RUN_TMP}/err-host-path"
  begin_case "${CASE_NAME}"
  make_harness_fake pi
  CASE_PATH="${CASE_BIN}:${TOOL_BIN}"
  run_installer pi
  assert_status 0
  sed "s|${CASE_DIR}|CASE|g" "${CASE_DIR}/out" > "${RUN_TMP}/out-restricted"
  sed "s|${CASE_DIR}|CASE|g" "${CASE_DIR}/err" > "${RUN_TMP}/err-restricted"
  assert_file_eq "${RUN_TMP}/out-host-path" "${RUN_TMP}/out-restricted" "restricted stdout"
  assert_file_eq "${RUN_TMP}/err-host-path" "${RUN_TMP}/err-restricted" "restricted stderr"
}

test_scripts_pass_shellcheck_with_all_checks() {
  if command -v shellcheck > /dev/null 2>&1; then
    :
  else
    case_fail "missing tool: shellcheck"
    return
  fi
  if timeout -k 5 60 shellcheck -s sh -o all "${INSTALLER}" "${RUNNER}" \
    > "${CASE_DIR}/out" 2>&1; then
    :
  else
    _tps_text=$(cat "${CASE_DIR}/out")
    case_fail "shellcheck findings: ${_tps_text}"
  fi
}

test_scripts_pass_shfmt_format_check() {
  if command -v shfmt > /dev/null 2>&1; then
    :
  else
    case_fail "missing tool: shfmt"
    return
  fi
  if timeout -k 5 60 shfmt -d -p -i 2 -ci -sr "${INSTALLER}" "${RUNNER}" \
    > "${CASE_DIR}/out" 2>&1; then
    :
  else
    _pss_text=$(cat "${CASE_DIR}/out")
    case_fail "shfmt findings: ${_pss_text}"
  fi
}

# ---- CLI contract cases -------------------------------------------------

assert_help() {
  run_installer "$@"
  assert_status 0
  assert_file_eq "${CASE_DIR}/expected-out" "${CASE_DIR}/out" "help stdout: $*"
  assert_stderr_empty
}

test_help_prints_usage_and_exits_zero() {
  write_usage_file "${CASE_DIR}/expected-out"
  snapshot_all before
  assert_help -h
  assert_help --help
  assert_help -h bogus --bogus all pi
  assert_tree_unchanged
}

# $1 holds the expected message; the remaining arguments run the installer.
assert_usage_error() {
  write_usage_error_file "${CASE_DIR}/expected-err" "install.sh: ${1}"
  shift
  run_installer "$@"
  assert_status 2
  assert_file_eq "${CASE_DIR}/expected-err" "${CASE_DIR}/err" "usage stderr: $*"
  assert_stdout_empty
}

test_invalid_arguments_print_usage_and_exit_two() {
  snapshot_all before
  assert_usage_error 'no harness selected'
  assert_usage_error 'unknown option: -x' -x pi
  assert_usage_error 'unknown option: --bogus' --bogus pi
  assert_usage_error 'unknown harness: bogus' bogus
  assert_usage_error 'do not mix all with harness names' all pi
  assert_usage_error 'do not mix all with harness names' pi all
  assert_tree_unchanged
}

# ---- selection cases ----------------------------------------------------

test_duplicate_and_alias_selectors_collapse() {
  run_installer pi pi pi
  assert_status 0
  assert_stderr_lines \
    "install.sh: warning: pi not found in PATH"
  assert_stdout_count "+ ${CASE_HOME}/.pi/agent/agents/pi-agent.md" 1
  run_installer antigravity agy antigravity
  assert_status 0
  assert_stderr_lines \
    "install.sh: warning: agy not found in PATH"
  assert_stdout_count "+ ${CASE_HOME}/.gemini/config/agents/agy-agent.md" 1
  make_harness_fake gemini
  run_installer gemini gemini
  assert_status 0
  assert_stderr_lines \
    "install.sh: warning: gemini is deprecated"
  assert_stdout_count "+ ${CASE_HOME}/.gemini/commands/run.toml" 1
}

test_detection_selects_only_available_candidates() {
  make_harness_fake pi
  make_harness_fake codex
  run_installer all
  assert_status 0
  assert_stderr_lines \
    "install.sh: skipping claude (not found in PATH)" \
    "install.sh: skipping agy (not found in PATH)" \
    "install.sh: skipping opencode (not found in PATH)"
  assert_stdout_count "+ ${CASE_HOME}/.agents/skills/alpha/SKILL.md" 1
}

test_detection_excludes_gemini() {
  make_harness_fake gemini
  snapshot_all before
  run_installer all
  assert_status 0
  assert_stderr_lines \
    "install.sh: skipping pi (not found in PATH)" \
    "install.sh: skipping claude (not found in PATH)" \
    "install.sh: skipping agy (not found in PATH)" \
    "install.sh: skipping opencode (not found in PATH)" \
    "install.sh: skipping codex (not found in PATH)"
  assert_stdout_empty
  assert_tree_unchanged
}

test_explicit_missing_binary_warns_and_stays_selected() {
  run_installer codex
  assert_status 0
  assert_stderr_lines \
    "install.sh: warning: codex not found in PATH"
  assert_installed "codex/agents/codex-agent.md" "${CASE_HOME}/.codex/agents/codex-agent.md"
}

# ---- mutation boundary cases --------------------------------------------

# Install, dry-run, force, and verbose install run the real engine; see the
# install apply cases below. Uninstall cases live in their own section.
test_force_flag_backs_up_and_replaces_conflicting_regular_files() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha" "${CASE_HOME}/.agents/skills/beta"
  printf 'user edit alpha\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'user edit beta\n' > "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  run_installer -f pi
  assert_status 0
  assert_stderr_empty
  assert_stdout_contains "~ ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "~ ${CASE_HOME}/.agents/skills/beta/SKILL.md"
  _tfb_alpha="$(fake_backup_root)${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  _tfb_beta="$(fake_backup_root)${CASE_HOME}/.agents/skills/beta/SKILL.md"
  printf 'user edit alpha\n' > "${CASE_DIR}/expected-alpha"
  printf 'user edit beta\n' > "${CASE_DIR}/expected-beta"
  assert_file_eq "${CASE_DIR}/expected-alpha" "${_tfb_alpha}" "alpha backup bytes"
  assert_file_eq "${CASE_DIR}/expected-beta" "${_tfb_beta}" "beta backup bytes"
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_installed "skills/beta/SKILL.md" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_stdout_contains "summary: + 2 ~ 2 = 0 ! 0 - 0 ? 0"
  _tfb_root="$(fake_backup_root)"
  assert_stdout_contains "note: backups: ${_tfb_root}"
  assert_stdout_lacks "force"
  assert_no_temporaries
}

test_combined_force_flags_plan_verbose_forced_dry_run() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha/references" \
    "${CASE_HOME}/.agents/skills/beta"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'stale\n' > "${CASE_HOME}/.agents/skills/alpha/stale.txt"
  ln -s "${CASE_DIR}/missing-referent" \
    "${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  cp "${CASE_CLONE}/skills/beta/SKILL.md" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  snapshot_all before
  run_installer -n -f -v pi
  assert_status 3
  assert_tree_unchanged
  assert_stdout_contains "~ ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/alpha/stale.txt"
  assert_stdout_contains "= ${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_stdout_contains "+ ${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  assert_stdout_contains "summary (planned): + 1 ~ 1 = 1 ! 1 - 0 ? 1"
  _tcv_root="$(fake_backup_root)"
  assert_stdout_contains "note: planned backups: ${_tcv_root}"
  assert_stdout_lacks "note: backups: "
  assert_absent "${CASE_HOME}/.local/state"
  assert_no_temporaries
}

test_forced_install_relocates_backups_with_xdg_state_home() {
  make_harness_fake pi
  make_fake_date
  export XDG_STATE_HOME="${CASE_DIR}/state"
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  run_installer -f pi
  unset XDG_STATE_HOME
  assert_status 0
  _tfr_path="${CASE_DIR}/state/spae/backups/${FIXED_STAMP}"
  _tfr_path="${_tfr_path}${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'user edit\n' > "${CASE_DIR}/expected-edit"
  assert_file_eq "${CASE_DIR}/expected-edit" "${_tfr_path}" "relocated backup bytes"
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "note: backups: ${CASE_DIR}/state/spae/backups/${FIXED_STAMP}"
}

test_forced_rerun_refuses_existing_backup_before_any_apply() {
  make_harness_fake pi
  make_harness_fake claude
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit v1\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  run_installer -f pi
  assert_status 0
  _trr_path="$(fake_backup_root)${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'user edit v1\n' > "${CASE_DIR}/expected-v1"
  assert_file_eq "${CASE_DIR}/expected-v1" "${_trr_path}" "first backup bytes"
  printf 'user edit v2\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  snapshot_all before
  run_installer -f pi claude
  assert_status 1
  assert_stderr_contains "refusing to overwrite existing backup"
  assert_stdout_empty
  assert_tree_unchanged
  assert_file_eq "${CASE_DIR}/expected-v1" "${_trr_path}" "preserved backup bytes"
  assert_absent "${CASE_HOME}/.claude"
}

test_forced_run_without_conflicts_creates_no_backup_directories() {
  make_harness_fake pi
  make_fake_date
  run_installer -f pi
  assert_status 0
  assert_stdout_contains "summary: + 4 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stdout_lacks "backup"
  assert_absent "${CASE_HOME}/.local/state"
  snapshot_all before
  run_installer -f pi
  assert_status 0
  assert_tree_unchanged
  assert_stdout_contains "summary: + 0 ~ 0 = 4 ! 0 - 0 ? 0"
  assert_stdout_lacks "backup"
  assert_absent "${CASE_HOME}/.local/state"
}

test_backup_placement_inside_discovery_root_fails_before_any_change() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  snapshot_all before
  export XDG_STATE_HOME="${CASE_HOME}/.agents/skills"
  run_installer -f pi
  assert_status 1
  assert_stderr_contains "backup location is inside an install destination root"
  assert_stdout_empty
  export XDG_STATE_HOME="${CASE_HOME}/.agents/skills/nested/state"
  run_installer -f pi
  assert_status 1
  assert_stderr_contains "backup location is inside an install destination root"
  assert_stdout_empty
  unset XDG_STATE_HOME
  assert_tree_unchanged
}

test_backup_placement_via_state_link_alias_fails_before_any_change() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  ln -s "${CASE_HOME}/.agents/skills" "${CASE_HOME}/.local"
  snapshot_all before
  run_installer -f pi
  assert_status 1
  assert_stderr_contains "backup location is inside an install destination root"
  assert_stdout_empty
  assert_tree_unchanged
}

test_backup_placement_via_destination_link_alias_fails_before_any_change() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_DIR}/agents-real/skills/alpha"
  printf 'user edit\n' > "${CASE_DIR}/agents-real/skills/alpha/SKILL.md"
  ln -s "${CASE_DIR}/agents-real" "${CASE_HOME}/.agents"
  export XDG_STATE_HOME="${CASE_DIR}/agents-real/skills/state"
  snapshot_all before
  run_installer -f pi
  unset XDG_STATE_HOME
  assert_status 1
  assert_stderr_contains "backup location is inside an install destination root"
  assert_stdout_empty
  assert_tree_unchanged
}

test_forced_symlink_and_directory_conflicts_survive_force() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha/references"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'referent\n' > "${CASE_DIR}/referent"
  ln -s "${CASE_DIR}/referent" \
    "${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  mkdir -p "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  printf 'inner\n' > "${CASE_HOME}/.pi/agent/agents/pi-agent.md/inner.txt"
  run_installer -f pi
  assert_status 3
  assert_stdout_contains "~ ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  assert_stdout_contains "! ${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  if [ -L "${CASE_HOME}/.agents/skills/alpha/references/ref.md" ]; then
    :
  else
    case_fail "file symlink replaced"
  fi
  printf 'referent\n' > "${CASE_DIR}/expected-referent"
  assert_file_eq "${CASE_DIR}/expected-referent" "${CASE_DIR}/referent" "symlink referent"
  if [ -d "${CASE_HOME}/.pi/agent/agents/pi-agent.md" ]; then
    :
  else
    case_fail "directory obstruction removed"
  fi
  printf 'inner\n' > "${CASE_DIR}/expected-inner"
  assert_file_eq "${CASE_DIR}/expected-inner" \
    "${CASE_HOME}/.pi/agent/agents/pi-agent.md/inner.txt" "obstruction content"
  printf 'user edit\n' > "${CASE_DIR}/expected-edit"
  _tsd_backup="$(fake_backup_root)${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_file_eq "${CASE_DIR}/expected-edit" "${_tsd_backup}" "backup bytes"
  assert_stdout_lacks "force"
  assert_stdout_contains "summary: + 1 ~ 1 = 0 ! 2 - 0 ? 0"
  assert_no_temporaries
}

test_injected_backup_failure_preserves_destination_and_overrides_conflicts() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  ln -s "${CASE_DIR}/missing-referent" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  mkdir -p "${CASE_HOME}/.pi/agent/agents"
  printf 'user edit\n' > "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  make_failing_cp "spae/backups"
  run_installer -f pi
  assert_status 1
  assert_stderr_contains "apply: cannot copy"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'user edit\n' > "${CASE_DIR}/expected-edit"
  assert_file_eq "${CASE_DIR}/expected-edit" \
    "${CASE_HOME}/.pi/agent/agents/pi-agent.md" "edited file"
  assert_no_temporaries
}

test_forced_dry_run_collision_fails_without_writes() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  _tfc_path="$(fake_backup_root)${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  mkdir -p "${_tfc_path%/*}"
  printf 'keep me\n' > "${_tfc_path}"
  snapshot_all before
  run_installer -n -f pi
  assert_status 1
  assert_stderr_contains "refusing to overwrite existing backup"
  assert_stdout_empty
  assert_tree_unchanged
}

# Seeds an edited Claude agent for backup preflight cases: fixed stamp,
# external state root, and the state tree registered for snapshots.
backup_chain_seed() {
  make_harness_fake claude
  make_fake_date
  export XDG_STATE_HOME="${CASE_DIR}/state"
  mkdir -p "${CASE_HOME}/.claude/agents"
  printf 'user edit agent\n' > "${CASE_HOME}/.claude/agents/claude-agent.md"
  measure_root "${CASE_DIR}/state"
}

# Asserts one rejected backup preflight run: exit 1 with "$@" as the
# complete stderr lines, no file-action output, no mutation command, and
# untouched measured destinations, external state, and link referents.
assert_backup_preflight_rejected() {
  assert_status 1
  assert_stderr_lines "$@"
  assert_stdout_empty
  assert_tree_unchanged
  assert_mutations_empty
}

test_backup_ancestor_obstruction_rejects_forced_install_preflight() {
  backup_chain_seed
  _tbam_mirror="$(fake_backup_root)${CASE_HOME}/.claude/agents"
  mkdir -p "${_tbam_mirror%/*}"
  printf 'obstruction\n' > "${_tbam_mirror}"
  for _tbam_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tbam_row}" in
      apply) run_installer -f claude ;;
      dry-run) run_installer -n -f claude ;;
      *) case_fail "${_tbam_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: destination is not a directory: ${_tbam_mirror}"
    printf 'user edit agent\n' > "${CASE_DIR}/expected-agent"
    assert_file_eq "${CASE_DIR}/expected-agent" \
      "${CASE_HOME}/.claude/agents/claude-agent.md" "edited agent"
    assert_absent "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  done
  unset XDG_STATE_HOME
}

test_backup_ancestor_obstruction_rejects_forced_uninstall_preflight() {
  make_harness_fake claude
  run_installer claude
  assert_status 0
  make_fake_date
  export XDG_STATE_HOME="${CASE_DIR}/state"
  printf 'user edit agent\n' > "${CASE_HOME}/.claude/agents/claude-agent.md"
  measure_root "${CASE_DIR}/state"
  _tbap_mirror="$(fake_backup_root)${CASE_HOME}/.claude/agents"
  mkdir -p "${_tbap_mirror%/*}"
  printf 'obstruction\n' > "${_tbap_mirror}"
  for _tbap_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tbap_row}" in
      apply) run_installer -f -u claude ;;
      dry-run) run_installer -n -f -u claude ;;
      *) case_fail "${_tbap_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: destination is not a directory: ${_tbap_mirror}"
    printf 'user edit agent\n' > "${CASE_DIR}/expected-agent"
    assert_file_eq "${CASE_DIR}/expected-agent" \
      "${CASE_HOME}/.claude/agents/claude-agent.md" "edited agent"
    assert_installed "skills/alpha/SKILL.md" \
      "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  done
  unset XDG_STATE_HOME
}

test_backup_ancestor_dangling_link_rejects_forced_preflight() {
  backup_chain_seed
  _tbal_mirror="$(fake_backup_root)${CASE_HOME}/.claude/agents"
  mkdir -p "${_tbal_mirror%/*}"
  ln -s "${CASE_DIR}/missing-target" "${_tbal_mirror}"
  for _tbal_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tbal_row}" in
      apply) run_installer -f claude ;;
      dry-run) run_installer -n -f claude ;;
      *) case_fail "${_tbal_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: dangling link: ${_tbal_mirror}"
  done
  unset XDG_STATE_HOME
}

test_backup_ancestor_file_link_rejects_forced_preflight() {
  backup_chain_seed
  mkdir -p "${CASE_DIR}/referent-dir"
  printf 'referent target\n' > "${CASE_DIR}/referent-dir/target"
  measure_root "${CASE_DIR}/referent-dir"
  _tbfl_mirror="$(fake_backup_root)${CASE_HOME}/.claude/agents"
  mkdir -p "${_tbfl_mirror%/*}"
  ln -s "${CASE_DIR}/referent-dir/target" "${_tbfl_mirror}"
  for _tbfl_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tbfl_row}" in
      apply) run_installer -f claude ;;
      dry-run) run_installer -n -f claude ;;
      *) case_fail "${_tbfl_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: destination is not a directory: ${_tbfl_mirror}"
  done
  unset XDG_STATE_HOME
}

test_backup_final_symlink_collision_rejects_forced_preflight() {
  backup_chain_seed
  _tbfs_final="$(fake_backup_root)${CASE_HOME}/.claude/agents/claude-agent.md"
  mkdir -p "${_tbfs_final%/*}"
  ln -s "${CASE_DIR}/missing-target" "${_tbfs_final}"
  for _tbfs_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tbfs_row}" in
      apply) run_installer -f claude ;;
      dry-run) run_installer -n -f claude ;;
      *) case_fail "${_tbfs_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: refusing to overwrite existing backup: ${_tbfs_final}"
  done
  unset XDG_STATE_HOME
}

test_missing_backup_suffix_preserves_exact_edited_bytes() {
  backup_chain_seed
  _tmbm_root="$(fake_backup_root)"
  mkdir -p "${_tmbm_root}${CASE_HOME}/.claude"
  run_installer -f claude
  assert_status 0
  printf 'user edit agent\n' > "${CASE_DIR}/expected-agent"
  _tmbm_backup="${_tmbm_root}${CASE_HOME}/.claude/agents/claude-agent.md"
  assert_file_eq "${CASE_DIR}/expected-agent" "${_tmbm_backup}" "backup bytes"
  assert_installed "claude/agents/claude-agent.md" \
    "${CASE_HOME}/.claude/agents/claude-agent.md"
  assert_stdout_contains "note: backups: ${_tmbm_root}"
  unset XDG_STATE_HOME
}

test_missing_backup_suffix_dry_run_plans_without_writes() {
  backup_chain_seed
  _tmbd_root="$(fake_backup_root)"
  mkdir -p "${_tmbd_root}${CASE_HOME}/.claude"
  make_mutation_log
  snapshot_all before
  run_installer -n -f claude
  assert_status 0
  assert_tree_unchanged
  assert_mutations_empty
  assert_stdout_contains "~ ${CASE_HOME}/.claude/agents/claude-agent.md"
  assert_stdout_contains "+ ${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  assert_stdout_contains "note: planned backups: ${_tmbd_root}"
  assert_stdout_lacks "note: backups: "
  unset XDG_STATE_HOME
}

test_forced_backups_share_one_stamp_per_invocation() {
  make_harness_fake claude
  export XDG_STATE_HOME="${CASE_DIR}/state"
  measure_root "${CASE_DIR}/state"
  for _tbs_row in install-apply install-dry-run uninstall-apply \
    uninstall-dry-run; do
    rm -rf "${CASE_HOME}/.claude" "${CASE_DIR}/state"
    mkdir -p "${CASE_HOME}/.claude/agents" "${CASE_HOME}/.claude/commands"
    printf 'user edit agent\n' > "${CASE_HOME}/.claude/agents/claude-agent.md"
    printf 'user edit command\n' > "${CASE_HOME}/.claude/commands/claude-command.md"
    make_fake_date
    _tbs_root="$(fake_backup_root)"
    make_mutation_log
    snapshot_all before
    case "${_tbs_row}" in
      install-apply) run_installer -f claude ;;
      install-dry-run) run_installer -n -f claude ;;
      uninstall-apply) run_installer -f -u claude ;;
      uninstall-dry-run) run_installer -n -f -u claude ;;
      *) case_fail "${_tbs_row}: unknown row" ;;
    esac
    assert_status 0
    assert_date_calls 1
    printf 'user edit agent\n' > "${CASE_DIR}/expected-agent"
    printf 'user edit command\n' > "${CASE_DIR}/expected-command"
    case "${_tbs_row}" in
      *-apply)
        assert_file_eq "${CASE_DIR}/expected-agent" \
          "${_tbs_root}${CASE_HOME}/.claude/agents/claude-agent.md" \
          "agent backup bytes"
        assert_file_eq "${CASE_DIR}/expected-command" \
          "${_tbs_root}${CASE_HOME}/.claude/commands/claude-command.md" \
          "command backup bytes"
        assert_stdout_contains "note: backups: ${_tbs_root}"
        ;;
      *-dry-run)
        assert_stdout_contains "note: planned backups: ${_tbs_root}"
        assert_absent "${_tbs_root}"
        assert_tree_unchanged
        assert_mutations_empty
        ;;
      *) case_fail "${_tbs_row}: unknown row" ;;
    esac
  done
  unset XDG_STATE_HOME
}

test_unchanged_forced_rerun_requests_no_stamp() {
  make_harness_fake claude
  export XDG_STATE_HOME="${CASE_DIR}/state"
  measure_root "${CASE_DIR}/state"
  for _tuc_row in install uninstall; do
    rm -rf "${CASE_HOME}/.claude" "${CASE_DIR}/state"
    run_installer claude
    assert_status 0
    if [ "${_tuc_row}" = uninstall ]; then
      run_installer -u claude
      assert_status 0
    fi
    make_fake_date
    make_mutation_log
    snapshot_all before
    case "${_tuc_row}" in
      install) run_installer -f claude ;;
      uninstall) run_installer -f -u claude ;;
      *) case_fail "${_tuc_row}: unknown row" ;;
    esac
    assert_status 0
    assert_date_calls 0
    assert_absent "${CASE_DIR}/state"
    assert_tree_unchanged
    assert_mutations_empty
    assert_stdout_lacks "backup"
  done
  unset XDG_STATE_HOME
}

# Seeds the mirrored-suffix escape fixture: fixed stamp, external state
# tree, an edited Claude agent, and a directory link from the stamped
# mirror of .claude/agents to $1, so a required backup would physically
# escape through the mirrored suffix.
backup_escape_seed() {
  backup_chain_seed
  _bes_mirror="$(fake_backup_root)${CASE_HOME}/.claude/agents"
  mkdir -p "${_bes_mirror%/*}"
  ln -s "${1}" "${_bes_mirror}"
}

test_backup_suffix_escape_after_safe_backup_rejects_forced_install_preflight() {
  mkdir -p "${CASE_HOME}/.codex/agents"
  backup_escape_seed "${CASE_HOME}/.codex/agents"
  mkdir -p "${CASE_HOME}/.claude/skills/alpha"
  printf 'user edit skill\n' > "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  _tsea_mirror="$(fake_backup_root)${CASE_HOME}/.claude/agents"
  _tsea_final="${_tsea_mirror}/claude-agent.md"
  for _tsea_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tsea_row}" in
      apply) run_installer -f claude ;;
      dry-run) run_installer -n -f claude ;;
      *) case_fail "${_tsea_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: backup location is inside an install destination root: ${_tsea_final}"
    printf 'user edit agent\n' > "${CASE_DIR}/expected-agent"
    assert_file_eq "${CASE_DIR}/expected-agent" \
      "${CASE_HOME}/.claude/agents/claude-agent.md" "edited agent"
    assert_absent "${_tsea_final}"
    assert_absent "${CASE_HOME}/.claude/skills/beta/SKILL.md"
    assert_link_present "${_tsea_mirror}"
  done
  unset XDG_STATE_HOME
}

test_backup_suffix_escape_after_safe_backup_rejects_forced_uninstall_preflight() {
  make_harness_fake claude
  run_installer claude
  assert_status 0
  make_fake_date
  export XDG_STATE_HOME="${CASE_DIR}/state"
  printf 'user edit agent\n' > "${CASE_HOME}/.claude/agents/claude-agent.md"
  printf 'user edit skill\n' > "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  measure_root "${CASE_DIR}/state"
  mkdir -p "${CASE_HOME}/.codex/agents"
  backup_escape_seed "${CASE_HOME}/.codex/agents"
  _tseu_mirror="$(fake_backup_root)${CASE_HOME}/.claude/agents"
  _tseu_final="${_tseu_mirror}/claude-agent.md"
  for _tseu_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tseu_row}" in
      apply) run_installer -f -u claude ;;
      dry-run) run_installer -n -f -u claude ;;
      *) case_fail "${_tseu_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: backup location is inside an install destination root: ${_tseu_final}"
    printf 'user edit agent\n' > "${CASE_DIR}/expected-agent"
    assert_file_eq "${CASE_DIR}/expected-agent" \
      "${CASE_HOME}/.claude/agents/claude-agent.md" "edited agent"
    assert_absent "${_tseu_final}"
    assert_installed "skills/beta/SKILL.md" \
      "${CASE_HOME}/.claude/skills/beta/SKILL.md"
    assert_link_present "${_tseu_mirror}"
  done
  unset XDG_STATE_HOME
}

test_backup_suffix_escape_through_protected_alias_rejects_preflight() {
  for _tspa_shape in direct aliased; do
    for _tspa_row in apply dry-run; do
      rm -rf "${CASE_HOME}" "${CASE_DIR}/aliases" "${CASE_DIR}/state"
      mkdir -p "${CASE_HOME}" "${CASE_DIR}/aliases"
      MEASURED_ROOTS=""
      case "${_tspa_shape}" in
        direct) _tspa_target="${CASE_HOME}/.codex" ;;
        aliased)
          mkdir -p "${CASE_HOME}/.codex"
          ln -s "${CASE_HOME}/.codex" "${CASE_DIR}/aliases/codex-alias"
          _tspa_target="${CASE_DIR}/aliases/codex-alias"
          ;;
        *) case_fail "${_tspa_shape}: unknown shape" ;;
      esac
      mkdir -p "${_tspa_target}"
      measure_root "${CASE_DIR}/aliases"
      backup_escape_seed "${_tspa_target}"
      _tspa_final="$(fake_backup_root)${CASE_HOME}/.claude/agents/claude-agent.md"
      make_mutation_log
      snapshot_all before
      case "${_tspa_row}" in
        apply) run_installer -f claude ;;
        dry-run) run_installer -n -f claude ;;
        *) case_fail "${_tspa_row}: unknown row" ;;
      esac
      assert_backup_preflight_rejected \
        "install.sh: preflight: backup location is inside an install destination root: ${_tspa_final}"
    done
  done
  unset XDG_STATE_HOME
}

test_backup_suffix_escape_with_missing_suffix_rejects_preflight() {
  backup_chain_seed
  mkdir -p "${CASE_HOME}/.codex"
  _tsms_link="$(fake_backup_root)${CASE_HOME}/.claude"
  mkdir -p "${_tsms_link%/*}"
  ln -s "${CASE_HOME}/.codex" "${_tsms_link}"
  _tsms_final="${_tsms_link}/agents/claude-agent.md"
  for _tsms_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tsms_row}" in
      apply) run_installer -f claude ;;
      dry-run) run_installer -n -f claude ;;
      *) case_fail "${_tsms_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: backup location is inside an install destination root: ${_tsms_final}"
  done
  unset XDG_STATE_HOME
}

test_backup_suffix_deeper_link_into_every_root_rejects_preflight() {
  for _tsdr_root in A C P O X G; do
    for _tsdr_row in apply dry-run; do
      rm -rf "${CASE_HOME}" "${CASE_DIR}/state"
      mkdir -p "${CASE_HOME}"
      MEASURED_ROOTS=""
      backup_chain_seed
      mkdir -p "${CASE_HOME}/.claude/skills/alpha"
      printf 'user edit skill\n' > "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
      case "${_tsdr_root}" in
        A) _tsdr_target="${CASE_HOME}/.agents/skills" ;;
        C) _tsdr_target="${CASE_HOME}/.claude" ;;
        P) _tsdr_target="${CASE_HOME}/.pi/agent" ;;
        O) _tsdr_target="${CASE_HOME}/.config/opencode" ;;
        X) _tsdr_target="${CASE_HOME}/.codex" ;;
        G) _tsdr_target="${CASE_HOME}/.gemini" ;;
        *) case_fail "${_tsdr_root}: unknown root" ;;
      esac
      mkdir -p "${_tsdr_target}"
      _tsdr_mirror="$(fake_backup_root)${CASE_HOME}/.claude/skills/alpha"
      mkdir -p "${_tsdr_mirror%/*}"
      ln -s "${_tsdr_target}" "${_tsdr_mirror}"
      _tsdr_final="${_tsdr_mirror}/SKILL.md"
      make_mutation_log
      snapshot_all before
      case "${_tsdr_row}" in
        apply) run_installer -f claude ;;
        dry-run) run_installer -n -f claude ;;
        *) case_fail "${_tsdr_row}: unknown row" ;;
      esac
      assert_backup_preflight_rejected \
        "install.sh: preflight: backup location is inside an install destination root: ${_tsdr_final}"
      assert_absent "${_tsdr_final}"
    done
  done
  unset XDG_STATE_HOME
}

test_backup_suffix_escape_with_spaced_paths_rejects_preflight() {
  make_harness_fake claude
  rm -rf "${CASE_HOME}" "${CASE_CLONE}"
  CASE_HOME="${CASE_DIR}/ho me"
  CASE_CLONE="${CASE_DIR}/cl one"
  CASE_INSTALLER_ARG="${CASE_CLONE}/install.sh"
  mkdir -p "${CASE_HOME}/.codex/agents"
  make_clone "${CASE_CLONE}"
  backup_escape_seed "${CASE_HOME}/.codex/agents"
  _tssp_final="$(fake_backup_root)${CASE_HOME}/.claude/agents/claude-agent.md"
  for _tssp_row in apply dry-run; do
    make_mutation_log
    snapshot_all before
    case "${_tssp_row}" in
      apply) run_installer -f claude ;;
      dry-run) run_installer -n -f claude ;;
      *) case_fail "${_tssp_row}: unknown row" ;;
    esac
    assert_backup_preflight_rejected \
      "install.sh: preflight: backup location is inside an install destination root: ${_tssp_final}"
  done
  unset XDG_STATE_HOME
}

test_backup_suffix_safe_link_and_sibling_placement_permits_backups() {
  for _tssl_shape in sibling external; do
    for _tssl_row in apply dry-run; do
      rm -rf "${CASE_HOME}" "${CASE_DIR}/state" "${CASE_DIR}/external-store"
      mkdir -p "${CASE_HOME}"
      MEASURED_ROOTS=""
      case "${_tssl_shape}" in
        sibling) _tssl_target="${CASE_HOME}/.codex-old/agents" ;;
        external) _tssl_target="${CASE_DIR}/external-store" ;;
        *) case_fail "${_tssl_shape}: unknown shape" ;;
      esac
      mkdir -p "${_tssl_target}"
      measure_root "${_tssl_target}"
      backup_escape_seed "${_tssl_target}"
      _tssl_mirror="$(fake_backup_root)${CASE_HOME}/.claude/agents"
      _tssl_backup="${_tssl_target}/claude-agent.md"
      make_mutation_log
      snapshot_all before
      case "${_tssl_row}" in
        apply) run_installer -f claude ;;
        dry-run) run_installer -n -f claude ;;
        *) case_fail "${_tssl_row}: unknown row" ;;
      esac
      _tssl_root="$(fake_backup_root)"
      assert_status 0
      assert_link_present "${_tssl_mirror}"
      printf 'user edit agent\n' > "${CASE_DIR}/expected-agent"
      case "${_tssl_row}" in
        apply)
          assert_file_eq "${CASE_DIR}/expected-agent" "${_tssl_backup}" \
            "backup bytes"
          assert_installed "claude/agents/claude-agent.md" \
            "${CASE_HOME}/.claude/agents/claude-agent.md"
          assert_stdout_contains "note: backups: ${_tssl_root}"
          ;;
        dry-run)
          assert_absent "${_tssl_backup}"
          assert_tree_unchanged
          assert_mutations_empty
          assert_stdout_contains \
            "~ ${CASE_HOME}/.claude/agents/claude-agent.md"
          assert_stdout_contains "note: planned backups: ${_tssl_root}"
          ;;
        *) case_fail "${_tssl_row}: unknown row" ;;
      esac
    done
  done
  unset XDG_STATE_HOME
}

test_failed_rename_removes_owned_temporary_and_exits_one() {
  make_harness_fake pi
  make_failing_mv "beta/SKILL.md"
  run_installer pi
  assert_status 1
  assert_stderr_contains "apply: cannot move"
  assert_no_temporaries
  assert_absent "${CASE_HOME}/.agents/skills/beta/SKILL.md"
}

test_forced_rename_failure_preserves_destination_bytes() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/beta"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  make_failing_mv "beta/SKILL.md" "spae/backups"
  run_installer -f pi
  assert_status 1
  assert_stderr_contains "apply: cannot move"
  printf 'user edit\n' > "${CASE_DIR}/expected-edit"
  assert_file_eq "${CASE_DIR}/expected-edit" \
    "${CASE_HOME}/.agents/skills/beta/SKILL.md" "edited file"
  _tfrf_backup="$(fake_backup_root)${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_file_eq "${CASE_DIR}/expected-edit" "${_tfrf_backup}" "backup bytes"
  assert_no_temporaries
}

test_failed_backup_rename_preserves_destination_and_removes_temporary() {
  make_harness_fake pi
  make_fake_date
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  make_failing_mv "spae/backups"
  run_installer -f pi
  assert_status 1
  assert_stderr_contains "apply: cannot move"
  printf 'user edit\n' > "${CASE_DIR}/expected-edit"
  assert_file_eq "${CASE_DIR}/expected-edit" \
    "${CASE_HOME}/.agents/skills/alpha/SKILL.md" "edited file"
  _tfbr_backup="$(fake_backup_root)${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_absent "${_tfbr_backup}"
  assert_no_temporaries
}

test_dry_runs_issue_no_mutation_commands() {
  # Table-driven zero-write proof: each dry-run shape must attempt no
  # filesystem mutation command at all.
  make_harness_fake pi
  run_installer pi opencode codex gemini
  assert_status 0
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'stale\n' > "${CASE_HOME}/.agents/skills/alpha/stale.txt"
  for _tdd_row in install install-force uninstall uninstall-force \
    preflight-reject; do
    case "${_tdd_row}" in
      preflight-reject)
        mv "${CASE_CLONE}/pi/agents" "${CASE_DIR}/stashed-agents"
        ;;
      *) : ;;
    esac
    make_mutation_log
    snapshot_all before
    case "${_tdd_row}" in
      install) run_installer -n pi ;;
      install-force) run_installer -n -f pi ;;
      uninstall) run_installer -n -u pi opencode codex gemini ;;
      uninstall-force) run_installer -n -f -u pi opencode codex gemini ;;
      preflight-reject) run_installer -n pi ;;
      *) case_fail "${_tdd_row}: unknown row" ;;
    esac
    case "${_tdd_row}" in
      install | uninstall) assert_status 3 ;;
      install-force | uninstall-force) assert_status 0 ;;
      preflight-reject) assert_status 1 ;;
      *) case_fail "${_tdd_row}: unknown row" ;;
    esac
    assert_tree_unchanged
    assert_mutations_empty
    if [ -e "${CASE_HOME}/.local/state" ]; then
      case_fail "${_tdd_row}: backup state created"
    fi
    case "${_tdd_row}" in
      preflight-reject)
        mv "${CASE_DIR}/stashed-agents" "${CASE_CLONE}/pi/agents"
        ;;
      *) : ;;
    esac
  done
}

# ---- cancellation cases ------------------------------------------------

signal_cleanup_scenario() {
  # $1 = signal name, $2 = expected status. The fixture copy parks
  # mid-flight with its owned temporary on disk; the injector creates a
  # true collision temporary from the reported PID suffix, delivers $1
  # to the synchronous installer, then acknowledges the fixture, so
  # cleanup must remove only the owned temporary and spare the collision.
  make_harness_fake pi
  make_harness_fake claude
  mkdir -p "${CASE_HOME}/.claude/commands"
  make_blocking_cp "alpha/SKILL.md"
  make_signal_injector "${1}" "${CASE_HOME}/.claude/commands/claude-command.md"
  "${CASE_DIR}/injector" &
  INJECTOR_JOB=$!
  run_installer pi claude
  wait "${INJECTOR_JOB}" || true
  assert_status "${2}"
  assert_absent "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  _scs_collide=$(cat "${CASE_MARK}/collision-path")
  printf 'keep me\n' > "${CASE_DIR}/expected-keep"
  assert_file_eq "${CASE_DIR}/expected-keep" "${_scs_collide}" "collision file"
  _scs_hits=$(find "${CASE_HOME}" -name '*.spae-tmp.*' 2> /dev/null || true)
  if [ "${_scs_hits}" = "${_scs_collide}" ]; then
    :
  else
    case_fail "unexpected temporaries: ${_scs_hits}"
  fi
}

test_int_cleanup_preserves_preexisting_collision() {
  signal_cleanup_scenario INT 130
}

test_term_cleanup_preserves_preexisting_collision() {
  signal_cleanup_scenario TERM 143
}

# ---- preflight failure cases --------------------------------------------

# A later harness's preflight failure blocks writes for earlier harnesses.
test_missing_source_directory_fails_whole_selection_preflight() {
  make_harness_fake pi
  make_harness_fake claude
  rm -rf "${CASE_CLONE}/claude/agents"
  assert_preflight_failure \
    "preflight: missing source directory: ${CASE_CLONE}/claude/agents" pi claude
}

# $1 selects the harness; $2 names the clone-relative SKILL.md to hide.
assert_missing_skill_md_fails() {
  mv "${CASE_CLONE}/${2}" "${CASE_DIR}/aside"
  assert_preflight_failure "preflight: missing SKILL.md: ${CASE_CLONE}/${2}" "${1}"
  mv "${CASE_DIR}/aside" "${CASE_CLONE}/${2}"
}

test_missing_skill_md_fails_preflight() {
  make_harness_fake pi
  make_harness_fake agy
  make_harness_fake codex
  assert_missing_skill_md_fails pi skills/alpha/SKILL.md
  assert_missing_skill_md_fails agy antigravity/skills/run/SKILL.md
  assert_missing_skill_md_fails codex codex/skills/run/SKILL.md
}

test_invalid_home_fails_preflight() {
  _tih_home=${CASE_HOME}
  CASE_HOME_SET=0
  assert_preflight_failure "HOME is unset or empty" pi
  CASE_HOME_SET=1
  CASE_HOME=
  assert_preflight_failure "HOME is unset or empty" pi
  CASE_HOME=relative-home
  assert_preflight_failure "HOME is not absolute: relative-home" pi
  CASE_HOME=${_tih_home}
}

test_relative_overrides_fail_preflight() {
  for _tro_name in CLAUDE_CONFIG_DIR PI_CODING_AGENT_DIR XDG_CONFIG_HOME \
    CODEX_HOME XDG_STATE_HOME; do
    export "${_tro_name}=relative-value"
    assert_preflight_failure "${_tro_name} is not absolute: relative-value" pi
    unset "${_tro_name}"
  done
}

test_empty_overrides_fall_back_to_defaults() {
  make_harness_fake claude
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  mkdir -p "${CASE_HOME}/.claude" "${CASE_HOME}/.pi/agent" \
    "${CASE_HOME}/.config/opencode" "${CASE_HOME}/.codex"
  printf 'block\n' > "${CASE_HOME}/.claude/skills"
  printf 'block\n' > "${CASE_HOME}/.pi/agent/agents"
  printf 'block\n' > "${CASE_HOME}/.config/opencode/agents"
  printf 'block\n' > "${CASE_HOME}/.codex/agents"
  snapshot_all before
  export CLAUDE_CONFIG_DIR=
  run_installer claude
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_HOME}/.claude/skills"
  unset CLAUDE_CONFIG_DIR

  export PI_CODING_AGENT_DIR=
  run_installer pi
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_HOME}/.pi/agent/agents"
  unset PI_CODING_AGENT_DIR

  export XDG_CONFIG_HOME=
  run_installer opencode
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_HOME}/.config/opencode/agents"
  unset XDG_CONFIG_HOME

  export CODEX_HOME=
  run_installer codex
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_HOME}/.codex/agents"
  unset CODEX_HOME
  assert_stdout_empty
  assert_tree_unchanged
}

test_empty_state_override_is_accepted() {
  make_harness_fake pi
  export XDG_STATE_HOME=
  run_installer pi
  assert_status 0
  assert_stdout_contains "summary: + 4 ~ 0 = 0 ! 0 - 0 ? 0"
  unset XDG_STATE_HOME
}

test_documented_overrides_redirect_destinations() {
  make_harness_fake claude
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  snapshot_all before
  export CLAUDE_CONFIG_DIR="${CASE_DIR}/alt/claude"
  mkdir -p "${CASE_DIR}/alt/claude"
  printf 'block\n' > "${CASE_DIR}/alt/claude/skills"
  run_installer claude
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_DIR}/alt/claude/skills"
  unset CLAUDE_CONFIG_DIR

  export PI_CODING_AGENT_DIR="${CASE_DIR}/alt/pi-agent"
  mkdir -p "${CASE_DIR}/alt/pi-agent"
  printf 'block\n' > "${CASE_DIR}/alt/pi-agent/agents"
  run_installer pi
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_DIR}/alt/pi-agent/agents"
  unset PI_CODING_AGENT_DIR

  export XDG_CONFIG_HOME="${CASE_DIR}/alt/xdg"
  mkdir -p "${CASE_DIR}/alt/xdg/opencode"
  printf 'block\n' > "${CASE_DIR}/alt/xdg/opencode/agents"
  run_installer opencode
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_DIR}/alt/xdg/opencode/agents"
  unset XDG_CONFIG_HOME

  export CODEX_HOME="${CASE_DIR}/alt/codex"
  mkdir -p "${CASE_DIR}/alt/codex"
  printf 'block\n' > "${CASE_DIR}/alt/codex/agents"
  run_installer codex
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_DIR}/alt/codex/agents"
  unset CODEX_HOME
  assert_stdout_empty
  assert_tree_unchanged
}

test_opencode_config_dir_is_ignored() {
  make_harness_fake opencode
  export OPENCODE_CONFIG_DIR="${CASE_DIR}/elsewhere"
  mkdir -p "${CASE_DIR}/elsewhere" "${CASE_HOME}/.config/opencode"
  printf 'block\n' > "${CASE_HOME}/.config/opencode/agents"
  snapshot_all before
  run_installer opencode
  assert_status 1
  assert_stderr_lines \
    "install.sh: preflight: destination is not a directory: ${CASE_HOME}/.config/opencode/agents"
  assert_stdout_empty
  assert_tree_unchanged
}

test_sudo_root_is_rejected() {
  CASE_UID=0
  for _tsr_user in '' someone; do
    export SUDO_USER="${_tsr_user}"
    assert_preflight_failure "refusing to run as root with SUDO_USER set" pi
  done
  unset SUDO_USER
}

# Only root and SUDO_USER together signal sudo; either alone proceeds.
test_root_or_sudo_user_alone_passes_environment_checks() {
  make_harness_fake pi
  CASE_UID=0
  run_installer pi
  assert_status 0
  assert_installed "pi/agents/pi-agent.md" "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  CASE_UID=1000
  export SUDO_USER=someone
  run_installer pi
  assert_status 0
  unset SUDO_USER
}

test_destination_obstructions_fail_preflight() {
  make_harness_fake pi
  make_harness_fake claude
  make_harness_fake opencode
  mkdir -p "${CASE_HOME}/.agents"
  printf 'block\n' > "${CASE_HOME}/.agents/skills"
  assert_preflight_failure \
    "preflight: destination is not a directory: ${CASE_HOME}/.agents/skills" pi
  rm -rf "${CASE_HOME}/.agents"
  printf 'block\n' > "${CASE_HOME}/.pi"
  assert_preflight_failure \
    "preflight: destination ancestor is not a directory: ${CASE_HOME}/.pi" pi
  ln -s "${CASE_DIR}/missing-target" "${CASE_HOME}/.claude"
  assert_preflight_failure "preflight: dangling link: ${CASE_HOME}/.claude" claude
  ln -s "${CASE_DIR}/missing-target" "${CASE_HOME}/.config"
  assert_preflight_failure "preflight: dangling link: ${CASE_HOME}/.config" opencode
}

test_valid_directory_links_pass_preflight() {
  make_harness_fake claude
  make_harness_fake opencode
  mkdir -p "${CASE_DIR}/real-claude" "${CASE_DIR}/real-config"
  ln -s "${CASE_DIR}/real-claude" "${CASE_HOME}/.claude"
  ln -s "${CASE_DIR}/real-config" "${CASE_HOME}/.config"
  run_installer claude opencode
  assert_status 0
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  assert_installed "opencode/agents/oc-agent.md" \
    "${CASE_HOME}/.config/opencode/agents/oc-agent.md"
}

test_invocation_from_any_directory_resolves_clone() {
  make_harness_fake pi
  CASE_CWD="${CASE_DIR}/elsewhere"
  mkdir -p "${CASE_CWD}"
  run_installer pi
  assert_status 0
  assert_installed "pi/agents/pi-agent.md" "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  CASE_CWD="${CASE_DIR}"
  CASE_INSTALLER_ARG=./clone/install.sh
  run_installer pi
  assert_status 0
}

test_paths_with_spaces_pass_preflight() {
  make_harness_fake pi
  rm -rf "${CASE_HOME}" "${CASE_CLONE}"
  CASE_HOME="${CASE_DIR}/ho me"
  CASE_CLONE="${CASE_DIR}/cl one"
  CASE_INSTALLER_ARG="${CASE_CLONE}/install.sh"
  mkdir -p "${CASE_HOME}"
  make_clone "${CASE_CLONE}"
  run_installer pi
  assert_status 0
  assert_installed "pi/agents/pi-agent.md" "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
}

# ---- install apply cases ------------------------------------------------

test_pi_install_deploys_shared_skills_and_agents_without_run_wiring() {
  make_harness_fake pi
  run_installer pi
  assert_status 0
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_installed "skills/alpha/references/ref.md" \
    "${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  assert_installed "skills/beta/SKILL.md" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_installed "pi/agents/pi-agent.md" "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  assert_absent "${CASE_HOME}/.agents/skills/run"
  assert_absent "${CASE_HOME}/.pi/agent/skills"
  assert_absent "${CASE_HOME}/.pi/agent/commands"
  assert_stdout_contains \
    "note: pi prerequisite: pi-subagent (https://github.com/mystilleef/pi-subagent)"
  assert_stdout_contains "summary: + 4 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stderr_empty
}

test_claude_install_deploys_native_roots_without_shared_root() {
  make_harness_fake claude
  run_installer claude
  assert_status 0
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  assert_installed "skills/alpha/references/ref.md" \
    "${CASE_HOME}/.claude/skills/alpha/references/ref.md"
  assert_installed "skills/beta/SKILL.md" "${CASE_HOME}/.claude/skills/beta/SKILL.md"
  assert_installed "claude/agents/claude-agent.md" \
    "${CASE_HOME}/.claude/agents/claude-agent.md"
  assert_installed "claude/commands/claude-command.md" \
    "${CASE_HOME}/.claude/commands/claude-command.md"
  assert_absent "${CASE_HOME}/.agents"
  assert_absent "${CASE_HOME}/.claude/skills/run"
  assert_stdout_contains "summary: + 5 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stderr_empty
}

test_agy_install_merges_shared_and_run_skills_into_config_root() {
  make_harness_fake agy
  run_installer agy
  assert_status 0
  assert_installed "skills/alpha/SKILL.md" \
    "${CASE_HOME}/.gemini/config/skills/alpha/SKILL.md"
  assert_installed "skills/alpha/references/ref.md" \
    "${CASE_HOME}/.gemini/config/skills/alpha/references/ref.md"
  assert_installed "skills/beta/SKILL.md" \
    "${CASE_HOME}/.gemini/config/skills/beta/SKILL.md"
  assert_installed "antigravity/skills/run/SKILL.md" \
    "${CASE_HOME}/.gemini/config/skills/run/SKILL.md"
  assert_installed "antigravity/agents/agy-agent.md" \
    "${CASE_HOME}/.gemini/config/agents/agy-agent.md"
  assert_absent "${CASE_HOME}/.agents"
  assert_absent "${CASE_HOME}/.gemini/agents"
  assert_stdout_contains "summary: + 5 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stderr_empty
}

test_opencode_install_deploys_shared_agents_and_commands() {
  make_harness_fake opencode
  run_installer opencode
  assert_status 0
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_installed "skills/alpha/references/ref.md" \
    "${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  assert_installed "skills/beta/SKILL.md" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_installed "opencode/agents/oc-agent.md" \
    "${CASE_HOME}/.config/opencode/agents/oc-agent.md"
  assert_installed "opencode/commands/oc-command.md" \
    "${CASE_HOME}/.config/opencode/commands/oc-command.md"
  assert_absent "${CASE_HOME}/.agents/skills/run"
  assert_stdout_contains "summary: + 5 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stderr_empty
}

test_codex_install_deploys_run_skill_with_nested_reference() {
  make_harness_fake codex
  run_installer codex
  assert_status 0
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_installed "skills/alpha/references/ref.md" \
    "${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  assert_installed "skills/beta/SKILL.md" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_installed "codex/agents/codex-agent.md" "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_installed "codex/skills/run/SKILL.md" "${CASE_HOME}/.codex/skills/run/SKILL.md"
  assert_installed "codex/skills/run/agents/openai.yaml" \
    "${CASE_HOME}/.codex/skills/run/agents/openai.yaml"
  assert_absent "${CASE_HOME}/.agents/skills/run"
  assert_stdout_contains "summary: + 6 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stderr_empty
}

test_gemini_install_deploys_both_command_files() {
  make_harness_fake gemini
  run_installer gemini
  assert_status 0
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_installed "gemini/agents/gemini-agent.md" \
    "${CASE_HOME}/.gemini/agents/gemini-agent.md"
  assert_installed "gemini/commands/run.toml" "${CASE_HOME}/.gemini/commands/run.toml"
  assert_installed "gemini/commands/syd.toml" "${CASE_HOME}/.gemini/commands/syd.toml"
  assert_stdout_contains "summary: + 6 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stderr_lines \
    "install.sh: warning: gemini is deprecated"
}

test_additional_source_files_deploy_without_code_changes() {
  make_harness_fake opencode
  mkdir -p "${CASE_CLONE}/skills/alpha/extra"
  printf 'extra reference\n' > "${CASE_CLONE}/skills/alpha/extra/notes.md"
  printf 'extra command\n' > "${CASE_CLONE}/opencode/commands/extra-command.md"
  run_installer opencode
  assert_status 0
  assert_installed "skills/alpha/extra/notes.md" \
    "${CASE_HOME}/.agents/skills/alpha/extra/notes.md"
  assert_installed "opencode/commands/extra-command.md" \
    "${CASE_HOME}/.config/opencode/commands/extra-command.md"
  assert_stdout_contains "summary: + 7 ~ 0 = 0 ! 0 - 0 ? 0"
}

test_identical_rerun_reports_unchanged_and_performs_no_writes() {
  make_harness_fake pi
  run_installer pi
  assert_status 0
  assert_no_temporaries
  make_mutation_log
  snapshot_all before
  run_installer pi
  assert_status 0
  assert_stdout_lines \
    "summary: + 0 ~ 0 = 4 ! 0 - 0 ? 0" \
    "note: pi prerequisite: pi-subagent (https://github.com/mystilleef/pi-subagent)" \
    "note: restart harness sessions after installation to pick up the new files"
  run_installer -v pi
  assert_status 0
  assert_stdout_count "= ${CASE_HOME}/.agents/skills/alpha/SKILL.md" 1
  assert_stdout_count "= ${CASE_HOME}/.agents/skills/alpha/references/ref.md" 1
  assert_stdout_count "= ${CASE_HOME}/.agents/skills/beta/SKILL.md" 1
  assert_stdout_count "= ${CASE_HOME}/.pi/agent/agents/pi-agent.md" 1
  assert_stdout_contains "summary: + 0 ~ 0 = 4 ! 0 - 0 ? 0"
  assert_mutations_empty
  assert_tree_unchanged
}

test_claude_codex_selection_visits_native_and_shared_roots_once() {
  make_harness_fake claude
  make_harness_fake codex
  run_installer claude codex
  assert_status 0
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  assert_installed "claude/commands/claude-command.md" \
    "${CASE_HOME}/.claude/commands/claude-command.md"
  assert_installed "codex/agents/codex-agent.md" "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_installed "codex/skills/run/agents/openai.yaml" \
    "${CASE_HOME}/.codex/skills/run/agents/openai.yaml"
  assert_stdout_count "+ ${CASE_HOME}/.claude/skills/alpha/SKILL.md" 1
  assert_stdout_count "+ ${CASE_HOME}/.agents/skills/alpha/SKILL.md" 1
  assert_stdout_contains "summary: + 11 ~ 0 = 0 ! 0 - 0 ? 0"
}

test_repeated_and_aliased_selectors_never_duplicate_action_lines() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake agy
  run_installer pi antigravity opencode codex agy opencode
  assert_status 0
  assert_stdout_count "+ ${CASE_HOME}/.agents/skills/alpha/SKILL.md" 1
  assert_stdout_count "+ ${CASE_HOME}/.gemini/config/skills/run/SKILL.md" 1
  if sort "${CASE_DIR}/out" | uniq -d | grep -q .; then
    case_fail "duplicate stdout lines"
  fi
  assert_stdout_contains "summary: + 14 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stderr_empty
}

test_edited_regular_file_conflict_preserves_bytes_and_exits_three() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  run_installer pi
  assert_status 3
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'user edit\n' > "${CASE_DIR}/expected-edit"
  assert_file_eq "${CASE_DIR}/expected-edit" \
    "${CASE_HOME}/.agents/skills/alpha/SKILL.md" "edited file"
  assert_installed "skills/beta/SKILL.md" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_stdout_contains \
    "note: conflicting regular files are skipped; use --force to back up and replace regular files only (symlinks and directories are never replaced)"
  assert_stdout_contains "summary: + 3 ~ 0 = 0 ! 1 - 0 ? 0"
}

test_file_symlink_conflict_preserves_link_and_omits_force_hint() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  cp "${CASE_CLONE}/skills/alpha/SKILL.md" "${CASE_DIR}/referent"
  ln -s "${CASE_DIR}/referent" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  run_installer pi
  assert_status 3
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  if [ -L "${CASE_HOME}/.agents/skills/alpha/SKILL.md" ]; then
    :
  else
    case_fail "file symlink replaced"
  fi
  assert_file_eq "${CASE_CLONE}/skills/alpha/SKILL.md" "${CASE_DIR}/referent" \
    "symlink referent"
  assert_stdout_lacks "force"
  assert_stdout_contains "summary: + 3 ~ 0 = 0 ! 1 - 0 ? 0"
}

test_dangling_symlink_conflict_preserves_link() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  ln -s "${CASE_DIR}/missing-referent" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  run_installer pi
  assert_status 3
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  if [ -L "${CASE_HOME}/.agents/skills/alpha/SKILL.md" ]; then
    :
  else
    case_fail "dangling file symlink replaced"
  fi
  assert_stdout_lacks "force"
}

test_directory_obstruction_conflict_preserves_contents_and_omits_force_hint() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'inner\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md/inner.txt"
  run_installer pi
  assert_status 3
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  if [ -d "${CASE_HOME}/.agents/skills/alpha/SKILL.md" ]; then
    :
  else
    case_fail "directory obstruction removed"
  fi
  printf 'inner\n' > "${CASE_DIR}/expected-inner"
  assert_file_eq "${CASE_DIR}/expected-inner" \
    "${CASE_HOME}/.agents/skills/alpha/SKILL.md/inner.txt" "obstruction content"
  assert_stdout_lacks "force"
  assert_stdout_contains "summary: + 3 ~ 0 = 0 ! 1 - 0 ? 1"
}

test_skill_directory_obstruction_blocks_shipped_files_as_conflicts() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills"
  printf 'block\n' > "${CASE_HOME}/.agents/skills/alpha"
  run_installer pi
  assert_status 3
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  printf 'block\n' > "${CASE_DIR}/expected-block"
  assert_file_eq "${CASE_DIR}/expected-block" "${CASE_HOME}/.agents/skills/alpha" \
    "obstruction file"
  assert_stdout_lacks "force"
  assert_stdout_contains "summary: + 2 ~ 0 = 0 ! 2 - 0 ? 0"
}

test_stale_files_report_question_only_in_shipped_skill_directories() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha/references" \
    "${CASE_HOME}/.agents/skills/foreign"
  printf 'stale\n' > "${CASE_HOME}/.agents/skills/alpha/stale.txt"
  printf 'orphan\n' > "${CASE_HOME}/.agents/skills/alpha/references/orphan.md"
  printf 'foreign\n' > "${CASE_HOME}/.agents/skills/foreign/SKILL.md"
  printf 'root foreign\n' > "${CASE_HOME}/.agents/skills/root-file.md"
  run_installer pi
  assert_status 0
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/alpha/stale.txt"
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/alpha/references/orphan.md"
  assert_stdout_lacks "foreign"
  assert_stdout_lacks "root-file"
  assert_stdout_contains "summary: + 4 ~ 0 = 0 ! 0 - 0 ? 2"
  printf 'stale\n' > "${CASE_DIR}/expected-stale"
  assert_file_eq "${CASE_DIR}/expected-stale" \
    "${CASE_HOME}/.agents/skills/alpha/stale.txt" "stale file"
}

test_summary_reports_all_six_symbol_counts_with_notes() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha/references" "${CASE_HOME}/.agents/skills/beta"
  cp "${CASE_CLONE}/skills/beta/SKILL.md" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'referent\n' > "${CASE_DIR}/referent"
  ln -s "${CASE_DIR}/referent" \
    "${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  printf 'stale\n' > "${CASE_HOME}/.agents/skills/beta/stale.txt"
  run_installer -v pi
  assert_status 3
  assert_stdout_contains "= ${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/references/ref.md"
  assert_stdout_contains "+ ${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/beta/stale.txt"
  assert_stdout_contains "summary: + 1 ~ 0 = 1 ! 2 - 0 ? 1"
  assert_stdout_contains \
    "note: conflicting regular files are skipped; use --force to back up and replace regular files only (symlinks and directories are never replaced)"
  assert_stdout_contains \
    "note: pi prerequisite: pi-subagent (https://github.com/mystilleef/pi-subagent)"
  assert_stdout_count \
    "note: restart harness sessions after installation to pick up the new files" 1
}

test_install_dry_run_reports_planned_actions_and_preserves_tree() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'stale\n' > "${CASE_HOME}/.agents/skills/alpha/stale.txt"
  snapshot_all before
  run_installer -n -v pi
  assert_status 3
  assert_tree_unchanged
  assert_stdout_contains "+ ${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/alpha/stale.txt"
  assert_stdout_contains "summary (planned): + 3 ~ 0 = 0 ! 1 - 0 ? 1"
  assert_stdout_contains \
    "note: conflicting regular files are skipped; use --force to back up and replace regular files only (symlinks and directories are never replaced)"
  assert_stdout_contains \
    "note: pi prerequisite: pi-subagent (https://github.com/mystilleef/pi-subagent)"
  assert_stdout_contains \
    "note: restart harness sessions after installation to pick up the new files"
  assert_no_temporaries
}

test_clean_install_dry_run_plans_additions_without_writes() {
  make_harness_fake pi
  snapshot_all before
  run_installer -n pi
  assert_status 0
  assert_tree_unchanged
  assert_stdout_contains "summary (planned): + 4 ~ 0 = 0 ! 0 - 0 ? 0"
  assert_stdout_lacks "backup"
  assert_no_temporaries
}

test_new_file_modes_reflect_current_umask() {
  make_harness_fake pi
  chmod 666 "${CASE_CLONE}/pi/agents/pi-agent.md"
  umask 022
  run_installer pi
  assert_status 0
  assert_mode "${CASE_HOME}/.pi/agent/agents/pi-agent.md" "-rw-r--r--"
  rm -f "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  umask 077
  run_installer pi
  assert_status 0
  umask "${RUNNER_UMASK}"
  assert_mode "${CASE_HOME}/.pi/agent/agents/pi-agent.md" "-rw-------"
}

test_preexisting_temporary_collision_preserves_bytes() {
  make_harness_fake pi
  make_collision_wrapper "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  CASE_INSTALLER_ARG="${CASE_CLONE}/collision-install"
  run_installer pi
  assert_status 1
  assert_stderr_contains "apply: temporary path already exists"
  _tpc_hit=$(find "${CASE_HOME}" -name 'pi-agent.md.spae-tmp.*')
  if [ -n "${_tpc_hit}" ]; then
    :
  else
    case_fail "collision file missing"
  fi
  printf 'keep me\n' > "${CASE_DIR}/expected-keep"
  assert_file_eq "${CASE_DIR}/expected-keep" "${_tpc_hit}" "collision file"
  assert_absent "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
}

test_failed_copy_removes_owned_temporary_and_exits_one() {
  make_harness_fake pi
  make_partial_cp "beta/SKILL.md"
  run_installer pi
  assert_status 1
  assert_stderr_contains "apply: cannot copy"
  assert_no_temporaries
  assert_absent "${CASE_HOME}/.agents/skills/beta/SKILL.md"
}

test_comparison_error_exits_one_without_classifying_conflict() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  make_failing_cmp "alpha/SKILL.md"
  run_installer pi
  assert_status 1
  assert_stderr_contains "apply: cannot compare"
  assert_stdout_lacks "summary"
}

test_runtime_failure_overrides_conflicts_with_exit_one() {
  make_harness_fake pi
  mkdir -p "${CASE_HOME}/.agents/skills/alpha"
  printf 'user edit\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  make_failing_cp "SKILL.md"
  run_installer pi
  assert_status 1
  assert_stderr_contains "apply: cannot copy"
}

# ---- uninstall cases ---------------------------------------------------

test_uninstall_removes_identical_files_and_prunes_empty_skill_dirs() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  run_installer pi opencode codex gemini
  assert_status 0
  run_installer -u pi opencode codex gemini
  assert_status 0
  assert_stderr_lines "install.sh: warning: gemini is deprecated"
  assert_stdout_count "- ${CASE_HOME}/.agents/skills/alpha/SKILL.md" 1
  assert_stdout_count "- ${CASE_HOME}/.agents/skills/alpha/references/ref.md" 1
  assert_stdout_count "- ${CASE_HOME}/.agents/skills/beta/SKILL.md" 1
  assert_stdout_count "- ${CASE_HOME}/.pi/agent/agents/pi-agent.md" 1
  assert_stdout_count "- ${CASE_HOME}/.codex/skills/run/agents/openai.yaml" 1
  assert_stdout_count "- ${CASE_HOME}/.gemini/commands/syd.toml" 1
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 12 ? 0"
  assert_absent "${CASE_HOME}/.agents/skills/alpha"
  assert_absent "${CASE_HOME}/.agents/skills/beta"
  assert_absent "${CASE_HOME}/.codex/skills/run"
  assert_absent "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  assert_absent "${CASE_HOME}/.config/opencode/agents/oc-agent.md"
  assert_absent "${CASE_HOME}/.gemini/commands/run.toml"
  assert_dir_present "${CASE_HOME}/.agents/skills"
  assert_dir_present "${CASE_HOME}/.pi/agent/agents"
  assert_dir_present "${CASE_HOME}/.config/opencode/agents"
  assert_dir_present "${CASE_HOME}/.codex/skills"
  assert_dir_present "${CASE_HOME}/.gemini/agents"
  assert_stdout_lacks "pi prerequisite"
  assert_stdout_contains \
    "note: restart harness sessions after uninstallation to drop the removed files"
}

test_uninstall_rerun_reports_unchanged_and_writes_nothing() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  run_installer pi opencode codex gemini
  assert_status 0
  run_installer -u pi opencode codex gemini
  assert_status 0
  snapshot_all before
  run_installer -v -u pi opencode codex gemini
  assert_status 0
  assert_tree_unchanged
  assert_stderr_lines "install.sh: warning: gemini is deprecated"
  assert_stdout_contains "= ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "= ${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  assert_stdout_contains "summary: + 0 ~ 0 = 12 ! 0 - 0 ? 0"
  assert_stdout_lacks "backup"
  assert_absent "${CASE_HOME}/.local/state"
  assert_no_temporaries
}

test_uninstall_preserves_edits_and_exits_three_without_force() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  run_installer pi opencode codex gemini
  assert_status 0
  printf 'user edit alpha\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  run_installer -u pi opencode codex gemini
  assert_status 3
  assert_stderr_lines "install.sh: warning: gemini is deprecated"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'user edit alpha\n' > "${CASE_DIR}/expected-edit"
  assert_file_eq "${CASE_DIR}/expected-edit" \
    "${CASE_HOME}/.agents/skills/alpha/SKILL.md" "edited file"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 1 - 11 ? 0"
  assert_stdout_contains \
    "note: conflicting regular files are skipped; use --force to back up and replace regular files only (symlinks and directories are never replaced)"
  assert_absent "${CASE_HOME}/.agents/skills/beta"
  assert_absent "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
}

test_forced_uninstall_backs_up_and_removes_edits() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  make_fake_date
  run_installer pi opencode codex gemini
  assert_status 0
  printf 'user edit alpha\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  run_installer -f -u pi opencode codex gemini
  assert_status 0
  assert_stderr_lines "install.sh: warning: gemini is deprecated"
  assert_stdout_contains "- ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  _tfu_root="$(fake_backup_root)"
  _tfu_path="${_tfu_root}${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'user edit alpha\n' > "${CASE_DIR}/expected-edit"
  assert_file_eq "${CASE_DIR}/expected-edit" "${_tfu_path}" "backup bytes"
  assert_absent "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 12 ? 0"
  assert_stdout_contains "note: backups: ${_tfu_root}"
  assert_stdout_lacks "force"
}

test_forced_uninstall_refuses_existing_backup_before_removal() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  make_fake_date
  run_installer pi opencode codex gemini
  assert_status 0
  printf 'user edit alpha\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  _trb_path="$(fake_backup_root)${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  mkdir -p "${_trb_path%/*}"
  printf 'keep me\n' > "${_trb_path}"
  snapshot_all before
  run_installer -f -u pi opencode codex gemini
  assert_status 1
  assert_stderr_contains "refusing to overwrite existing backup"
  assert_stdout_empty
  assert_tree_unchanged
}

test_uninstall_codex_retains_shared_root_and_names_remaining_consumers() {
  make_harness_fake codex
  run_installer codex
  assert_status 0
  run_installer -u codex
  assert_status 0
  assert_stderr_lines \
    "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, gemini"
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_installed "skills/beta/SKILL.md" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_absent "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_absent "${CASE_HOME}/.codex/skills/run"
  assert_dir_present "${CASE_HOME}/.codex/agents"
  assert_dir_present "${CASE_HOME}/.codex/skills"
  assert_stdout_count "- ${CASE_HOME}/.codex/agents/codex-agent.md" 1
  assert_stdout_count "- ${CASE_HOME}/.codex/skills/run/SKILL.md" 1
  assert_stdout_count "- ${CASE_HOME}/.codex/skills/run/agents/openai.yaml" 1
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 3 ? 0"
  assert_stdout_lacks "pi-subagent"
}

test_uninstall_force_still_retains_shared_root_for_unselected_consumers() {
  make_harness_fake gemini
  run_installer gemini
  assert_status 0
  run_installer -f -u gemini
  assert_status 0
  assert_stderr_lines \
    "install.sh: warning: gemini is deprecated" \
    "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, codex"
  assert_installed "skills/alpha/SKILL.md" "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_absent "${CASE_HOME}/.gemini/agents/gemini-agent.md"
  assert_absent "${CASE_HOME}/.gemini/commands/run.toml"
  assert_absent "${CASE_HOME}/.gemini/commands/syd.toml"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 3 ? 0"
}

test_uninstall_all_without_binaries_visits_shared_root_once() {
  for _uan_name in pi claude agy opencode codex gemini; do
    make_harness_fake "${_uan_name}"
  done
  run_installer pi claude agy opencode codex gemini
  assert_status 0
  rm -f "${CASE_BIN}/pi" "${CASE_BIN}/claude" "${CASE_BIN}/agy" \
    "${CASE_BIN}/opencode" "${CASE_BIN}/codex" "${CASE_BIN}/gemini"
  run_installer -u all
  assert_status 0
  assert_stderr_empty
  assert_stdout_count "- ${CASE_HOME}/.agents/skills/alpha/SKILL.md" 1
  assert_stdout_count "- ${CASE_HOME}/.claude/skills/alpha/SKILL.md" 1
  assert_stdout_count "- ${CASE_HOME}/.gemini/config/skills/run/SKILL.md" 1
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 22 ? 0"
  assert_absent "${CASE_HOME}/.agents/skills/alpha"
  assert_absent "${CASE_HOME}/.claude/skills/alpha"
  assert_absent "${CASE_HOME}/.gemini/config/skills/run"
  assert_dir_present "${CASE_HOME}/.agents/skills"
  assert_dir_present "${CASE_HOME}/.claude/skills"
  assert_dir_present "${CASE_HOME}/.gemini/config/skills"
}

test_uninstall_retains_file_symlinks_and_directory_obstructions() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  run_installer pi opencode codex gemini
  assert_status 0
  printf 'referent\n' > "${CASE_DIR}/referent"
  rm -f "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  ln -s "${CASE_DIR}/referent" "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  rm -f "${CASE_HOME}/.codex/agents/codex-agent.md"
  ln -s "${CASE_DIR}/missing-referent" "${CASE_HOME}/.codex/agents/codex-agent.md"
  rm -f "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  mkdir -p "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  printf 'inner keep\n' > "${CASE_HOME}/.pi/agent/agents/pi-agent.md/inner.txt"
  run_installer -f -u pi opencode codex gemini
  assert_status 3
  assert_stderr_lines "install.sh: warning: gemini is deprecated"
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_stdout_contains "! ${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_stdout_contains "! ${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 3 - 9 ? 0"
  assert_stdout_lacks "force"
  assert_link_present "${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_link_present "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_dir_present "${CASE_HOME}/.pi/agent/agents/pi-agent.md"
  printf 'referent\n' > "${CASE_DIR}/expected-referent"
  assert_file_eq "${CASE_DIR}/expected-referent" "${CASE_DIR}/referent" \
    "referent bytes"
  printf 'inner keep\n' > "${CASE_DIR}/expected-inner"
  assert_file_eq "${CASE_DIR}/expected-inner" \
    "${CASE_HOME}/.pi/agent/agents/pi-agent.md/inner.txt" "obstruction contents"
}

test_uninstall_prunes_only_empty_source_defined_dirs() {
  make_harness_fake claude
  mkdir -p "${CASE_CLONE}/skills/gamma"
  printf 'gamma skill\n' > "${CASE_CLONE}/skills/gamma/SKILL.md"
  run_installer claude
  assert_status 0
  mkdir -p "${CASE_HOME}/.claude/skills/alpha/user-empty"
  rm -rf "${CASE_HOME}/.claude/skills/beta"
  mkdir -p "${CASE_DIR}/beta-external"
  cp "${CASE_CLONE}/skills/beta/SKILL.md" "${CASE_DIR}/beta-external/SKILL.md"
  ln -s "${CASE_DIR}/beta-external" "${CASE_HOME}/.claude/skills/beta"
  printf 'user edit gamma\n' > "${CASE_HOME}/.claude/skills/gamma/SKILL.md"
  mkdir -p "${CASE_HOME}/.claude/skills/other-skill"
  printf 'keep\n' > "${CASE_HOME}/.claude/skills/other-skill/SKILL.md"
  printf 'keep root\n' > "${CASE_HOME}/.claude/skills/root-keep.md"
  run_installer -u claude
  assert_status 3
  assert_stdout_contains "! ${CASE_HOME}/.claude/skills/gamma/SKILL.md"
  assert_absent "${CASE_HOME}/.claude/skills/alpha/references"
  assert_absent "${CASE_HOME}/.claude/skills/alpha/SKILL.md"
  assert_absent "${CASE_HOME}/.claude/agents/claude-agent.md"
  assert_absent "${CASE_HOME}/.claude/commands/claude-command.md"
  assert_absent "${CASE_DIR}/beta-external/SKILL.md"
  assert_dir_present "${CASE_HOME}/.claude/skills/alpha"
  assert_dir_present "${CASE_HOME}/.claude/skills/alpha/user-empty"
  assert_dir_present "${CASE_HOME}/.claude/skills/other-skill"
  assert_dir_present "${CASE_HOME}/.claude/skills/gamma"
  assert_dir_present "${CASE_HOME}/.claude/skills"
  assert_dir_present "${CASE_HOME}/.claude/agents"
  assert_dir_present "${CASE_HOME}/.claude/commands"
  assert_link_present "${CASE_HOME}/.claude/skills/beta"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 1 - 5 ? 0"
  assert_stderr_empty
}

test_uninstall_reports_stale_files_inside_shipped_skill_directories() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  run_installer pi opencode codex gemini
  assert_status 0
  printf 'stale\n' > "${CASE_HOME}/.agents/skills/alpha/stale.txt"
  printf 'orphan\n' > "${CASE_HOME}/.agents/skills/alpha/references/orphan.md"
  mkdir -p "${CASE_HOME}/.agents/skills/old-skill"
  printf 'old\n' > "${CASE_HOME}/.agents/skills/old-skill/SKILL.md"
  printf 'root\n' > "${CASE_HOME}/.agents/skills/root-file.md"
  run_installer -u pi opencode codex gemini
  assert_status 0
  assert_stderr_lines "install.sh: warning: gemini is deprecated"
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/alpha/stale.txt"
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/alpha/references/orphan.md"
  assert_stdout_lacks "old-skill"
  assert_stdout_lacks "root-file"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 12 ? 2"
  printf 'stale\n' > "${CASE_DIR}/expected-stale"
  assert_file_eq "${CASE_DIR}/expected-stale" \
    "${CASE_HOME}/.agents/skills/alpha/stale.txt" "stale file"
  assert_dir_present "${CASE_HOME}/.agents/skills/alpha/references"
  assert_dir_present "${CASE_HOME}/.agents/skills/old-skill"
  assert_absent "${CASE_HOME}/.agents/skills/beta"
}

test_uninstall_preflight_failures_leave_destinations_unchanged() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  run_installer pi opencode codex gemini
  assert_status 0
  rm -f "${CASE_CLONE}/codex/skills/run/SKILL.md"
  snapshot_all before
  run_installer -u pi opencode codex gemini
  assert_status 1
  assert_stderr_contains "missing SKILL.md"
  assert_stdout_empty
  assert_tree_unchanged
  printf 'codex run skill\n' > "${CASE_CLONE}/codex/skills/run/SKILL.md"
  rm -rf "${CASE_HOME}/.pi/agent/agents"
  printf 'block\n' > "${CASE_HOME}/.pi/agent/agents"
  snapshot_all before
  run_installer -u pi opencode codex gemini
  assert_status 1
  assert_stderr_contains "preflight: destination is not a directory"
  assert_stdout_empty
  assert_tree_unchanged
}

test_uninstall_retained_shared_root_still_preflights_selected_sources() {
  make_harness_fake codex
  make_harness_fake gemini
  run_installer codex gemini
  assert_status 0
  rm -f "${CASE_CLONE}/skills/alpha/SKILL.md"
  snapshot_all before
  run_installer -u codex gemini
  assert_status 1
  assert_stderr_contains "note: preserving ${CASE_HOME}/.agents/skills"
  assert_stderr_contains \
    "preflight: missing SKILL.md: ${CASE_CLONE}/skills/alpha/SKILL.md"
  assert_stdout_empty
  assert_tree_unchanged
  printf 'alpha skill\n' > "${CASE_CLONE}/skills/alpha/SKILL.md"
  rm -rf "${CASE_CLONE}/skills"
  snapshot_all before
  run_installer -u codex gemini
  assert_status 1
  assert_stderr_contains \
    "preflight: missing source directory: ${CASE_CLONE}/skills"
  assert_stdout_empty
  assert_tree_unchanged
}

# Seeds matching Codex agent and run destinations plus the shared skills
# tree so uninstall cases exercise retained shared-root handling.
retained_root_seed() {
  make_harness_fake codex
  run_installer codex
  assert_status 0
}

# Runs the installer for one retained-root uninstall variant: $1 selects
# plain, dry-run, force, or force-dry-run over the remaining selectors.
run_uninstall_variant() {
  _ruv_mode=${1}
  shift
  case "${_ruv_mode}" in
    plain) run_installer -u "$@" ;;
    dry-run) run_installer -n -u "$@" ;;
    force) run_installer -f -u "$@" ;;
    force-dry-run) run_installer -n -f -u "$@" ;;
    *) case_fail "${_ruv_mode}: unknown uninstall variant" ;;
  esac
}

# Asserts one rejected retained-root preflight run over "$@": the generic
# rejected-preflight contract plus surviving matching Codex destinations.
assert_retained_preflight_rejected() {
  assert_backup_preflight_rejected "$@"
  assert_installed "codex/agents/codex-agent.md" \
    "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_installed "codex/skills/run/SKILL.md" \
    "${CASE_HOME}/.codex/skills/run/SKILL.md"
}

# Asserts retained uninstall survival through the valid directory link $2
# pointing at measured directory $1: dry-run writes nothing and apply keeps
# the link, its referent, and every shared byte untouched.
assert_retained_link_survival() {
  measure_root "${1}"
  capture_root shared "${1}"
  make_mutation_log
  snapshot_all before
  run_uninstall_variant dry-run codex
  assert_status 0
  assert_tree_unchanged
  assert_mutations_empty
  assert_stdout_contains "summary (planned): + 0 ~ 0 = 0 ! 0 - 3 ? 0"
  run_uninstall_variant plain codex
  assert_status 0
  assert_root_unchanged shared "${1}"
  assert_link_present "${2}"
  assert_absent "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_absent "${CASE_HOME}/.codex/skills/run"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 3 ? 0"
}

test_uninstall_retained_shared_root_obstruction_rejects_before_removals() {
  retained_root_seed
  rm -rf "${CASE_HOME}/.agents/skills"
  printf 'obstruction\n' > "${CASE_HOME}/.agents/skills"
  for _trso_row in plain dry-run force force-dry-run; do
    make_fake_date
    make_mutation_log
    snapshot_all before
    run_uninstall_variant "${_trso_row}" codex
    assert_retained_preflight_rejected \
      "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, gemini" \
      "install.sh: preflight: destination is not a directory: ${CASE_HOME}/.agents/skills"
    assert_date_calls 0
    assert_absent "${CASE_HOME}/.local/state"
  done
}

test_uninstall_retained_shared_ancestor_obstruction_rejects_before_other_actions() {
  retained_root_seed
  make_harness_fake claude
  run_installer claude
  assert_status 0
  rm -rf "${CASE_HOME}/.agents"
  printf 'obstruction\n' > "${CASE_HOME}/.agents"
  for _trsa_row in plain dry-run force force-dry-run; do
    make_fake_date
    make_mutation_log
    snapshot_all before
    run_uninstall_variant "${_trsa_row}" claude codex
    assert_retained_preflight_rejected \
      "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, gemini" \
      "install.sh: preflight: destination ancestor is not a directory: ${CASE_HOME}/.agents"
    assert_installed "claude/agents/claude-agent.md" \
      "${CASE_HOME}/.claude/agents/claude-agent.md"
    assert_installed "claude/commands/claude-command.md" \
      "${CASE_HOME}/.claude/commands/claude-command.md"
  done
}

test_uninstall_retained_shared_root_invalid_links_reject_preflight() {
  retained_root_seed
  printf 'target\n' > "${CASE_DIR}/file-target"
  for _tril_row in dangling-root file-root dangling-ancestor; do
    rm -rf "${CASE_HOME}/.agents"
    case "${_tril_row}" in
      dangling-root)
        mkdir -p "${CASE_HOME}/.agents"
        ln -s "${CASE_DIR}/missing-target" "${CASE_HOME}/.agents/skills"
        _tril_err="install.sh: preflight: dangling link: ${CASE_HOME}/.agents/skills"
        ;;
      file-root)
        mkdir -p "${CASE_HOME}/.agents"
        ln -s "${CASE_DIR}/file-target" "${CASE_HOME}/.agents/skills"
        _tril_err="install.sh: preflight: destination is not a directory: ${CASE_HOME}/.agents/skills"
        ;;
      dangling-ancestor)
        ln -s "${CASE_DIR}/missing-target" "${CASE_HOME}/.agents"
        _tril_err="install.sh: preflight: dangling link: ${CASE_HOME}/.agents"
        ;;
      *) case_fail "${_tril_row}: unknown link row" ;;
    esac
    for _tril_mode in plain dry-run force force-dry-run; do
      make_fake_date
      make_mutation_log
      snapshot_all before
      run_uninstall_variant "${_tril_mode}" codex
      assert_retained_preflight_rejected \
        "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, gemini" \
        "${_tril_err}"
      assert_date_calls 0
    done
  done
}

test_uninstall_retained_shared_root_source_failure_precedes_destination_checks() {
  retained_root_seed
  rm -f "${CASE_CLONE}/skills/alpha/SKILL.md"
  rm -rf "${CASE_HOME}/.agents/skills"
  printf 'obstruction\n' > "${CASE_HOME}/.agents/skills"
  make_mutation_log
  snapshot_all before
  run_uninstall_variant plain codex
  assert_retained_preflight_rejected \
    "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, gemini" \
    "install.sh: preflight: missing SKILL.md: ${CASE_CLONE}/skills/alpha/SKILL.md"
}

test_uninstall_retained_absent_shared_root_stays_absent() {
  retained_root_seed
  rm -rf "${CASE_HOME}/.agents"
  make_mutation_log
  snapshot_all before
  run_uninstall_variant dry-run codex
  assert_status 0
  assert_tree_unchanged
  assert_mutations_empty
  assert_stderr_lines \
    "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, gemini"
  assert_stdout_contains "summary (planned): + 0 ~ 0 = 0 ! 0 - 3 ? 0"
  run_uninstall_variant plain codex
  assert_status 0
  assert_absent "${CASE_HOME}/.agents"
  assert_absent "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_absent "${CASE_HOME}/.codex/skills/run"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 3 ? 0"
  assert_no_temporaries
}

test_uninstall_retained_shared_root_survives_removals_unchanged() {
  retained_root_seed
  capture_root shared "${CASE_HOME}/.agents/skills"
  make_mutation_log
  snapshot_all before
  run_uninstall_variant dry-run codex
  assert_status 0
  assert_tree_unchanged
  assert_mutations_empty
  assert_stdout_contains "- ${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_stdout_contains "summary (planned): + 0 ~ 0 = 0 ! 0 - 3 ? 0"
  run_uninstall_variant plain codex
  assert_status 0
  assert_stderr_lines \
    "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, gemini"
  assert_root_unchanged shared "${CASE_HOME}/.agents/skills"
  assert_absent "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_absent "${CASE_HOME}/.codex/skills/run"
  assert_dir_present "${CASE_HOME}/.codex/agents"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 3 ? 0"
  assert_no_temporaries
}

test_uninstall_retained_shared_root_link_survives_removals() {
  retained_root_seed
  mv "${CASE_HOME}/.agents/skills" "${CASE_DIR}/shared-real"
  ln -s "${CASE_DIR}/shared-real" "${CASE_HOME}/.agents/skills"
  assert_retained_link_survival "${CASE_DIR}/shared-real" \
    "${CASE_HOME}/.agents/skills"
}

test_uninstall_retained_shared_ancestor_link_survives_removals() {
  retained_root_seed
  mv "${CASE_HOME}/.agents" "${CASE_DIR}/agents-real"
  ln -s "${CASE_DIR}/agents-real" "${CASE_HOME}/.agents"
  assert_retained_link_survival "${CASE_DIR}/agents-real" "${CASE_HOME}/.agents"
}

test_uninstall_retained_shared_edits_trigger_no_conflicts_or_backups() {
  retained_root_seed
  make_fake_date
  printf 'user edit alpha\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'foreign\n' > "${CASE_HOME}/.agents/skills/alpha/foreign.txt"
  capture_root shared "${CASE_HOME}/.agents/skills"
  make_mutation_log
  snapshot_all before
  run_uninstall_variant force-dry-run codex
  assert_status 0
  assert_tree_unchanged
  assert_mutations_empty
  assert_stdout_contains "summary (planned): + 0 ~ 0 = 0 ! 0 - 3 ? 0"
  assert_stdout_lacks "backup"
  assert_stdout_lacks "force"
  assert_date_calls 0
  run_uninstall_variant force codex
  assert_status 0
  assert_stderr_lines \
    "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, gemini"
  assert_root_unchanged shared "${CASE_HOME}/.agents/skills"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 3 ? 0"
  assert_stdout_lacks "backup"
  assert_stdout_lacks "force"
  assert_date_calls 0
  assert_absent "${CASE_HOME}/.local/state"
  assert_absent "${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_absent "${CASE_HOME}/.codex/skills/run"
  assert_no_temporaries
}

test_uninstall_dry_run_plans_removals_and_preserves_tree() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  make_fake_date
  run_installer pi opencode codex gemini
  assert_status 0
  printf 'user edit alpha\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'stale\n' > "${CASE_HOME}/.agents/skills/alpha/stale.txt"
  snapshot_all before
  run_installer -n -v -u pi opencode codex gemini
  assert_status 3
  assert_tree_unchanged
  assert_stdout_contains "! ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/alpha/stale.txt"
  assert_stdout_contains "- ${CASE_HOME}/.agents/skills/beta/SKILL.md"
  assert_stdout_contains "summary (planned): + 0 ~ 0 = 0 ! 1 - 11 ? 1"
  assert_absent "${CASE_HOME}/.local/state"
  assert_no_temporaries
  run_installer -n -f -v -u pi opencode codex gemini
  assert_status 0
  assert_tree_unchanged
  assert_stdout_count "- ${CASE_HOME}/.agents/skills/alpha/SKILL.md" 1
  assert_stdout_contains "summary (planned): + 0 ~ 0 = 0 ! 0 - 12 ? 1"
  _tud_root="$(fake_backup_root)"
  assert_stdout_contains "note: planned backups: ${_tud_root}"
  assert_stdout_lacks "note: backups: "
  assert_absent "${CASE_HOME}/.local/state"
  assert_no_temporaries
}

test_uninstall_alias_and_duplicate_selectors_remove_once() {
  make_harness_fake agy
  run_installer agy
  assert_status 0
  run_installer -u antigravity agy agy antigravity
  assert_status 0
  assert_stdout_count "- ${CASE_HOME}/.gemini/config/skills/alpha/SKILL.md" 1
  assert_stdout_count "- ${CASE_HOME}/.gemini/config/skills/run/SKILL.md" 1
  assert_stdout_count "- ${CASE_HOME}/.gemini/config/agents/agy-agent.md" 1
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 5 ? 0"
  assert_absent "${CASE_HOME}/.gemini/config/skills/alpha"
  assert_absent "${CASE_HOME}/.gemini/config/skills/run"
  assert_dir_present "${CASE_HOME}/.gemini/config/skills"
  assert_stderr_empty
}

test_uninstall_combined_flags_plan_verbose_forced_actions() {
  make_harness_fake pi
  make_harness_fake opencode
  make_harness_fake codex
  make_harness_fake gemini
  make_fake_date
  run_installer pi opencode codex gemini
  assert_status 0
  printf 'user edit alpha\n' > "${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  printf 'stale\n' > "${CASE_HOME}/.agents/skills/alpha/stale.txt"
  rm -f "${CASE_HOME}/.codex/agents/codex-agent.md"
  ln -s "${CASE_DIR}/missing-referent" "${CASE_HOME}/.codex/agents/codex-agent.md"
  snapshot_all before
  run_installer -n -f -v -u pi opencode codex gemini
  assert_status 3
  assert_tree_unchanged
  assert_stdout_contains "- ${CASE_HOME}/.agents/skills/alpha/SKILL.md"
  assert_stdout_contains "! ${CASE_HOME}/.codex/agents/codex-agent.md"
  assert_stdout_contains "? ${CASE_HOME}/.agents/skills/alpha/stale.txt"
  assert_stdout_count "= ${CASE_HOME}/.agents/skills/beta/SKILL.md" 0
  assert_stdout_contains "summary (planned): + 0 ~ 0 = 0 ! 1 - 11 ? 1"
  _tuc_root="$(fake_backup_root)"
  assert_stdout_contains "note: planned backups: ${_tuc_root}"
  assert_stdout_lacks "force"
  assert_stderr_lines "install.sh: warning: gemini is deprecated"
}

test_uninstall_explicit_missing_binary_warns_and_proceeds() {
  make_harness_fake gemini
  run_installer gemini
  assert_status 0
  rm -f "${CASE_BIN}/gemini"
  run_installer -u gemini
  assert_status 0
  assert_stderr_lines \
    "install.sh: warning: gemini is deprecated" \
    "install.sh: warning: gemini not found in PATH" \
    "install.sh: note: preserving ${CASE_HOME}/.agents/skills; shared with unselected harnesses: pi, opencode, codex"
  assert_absent "${CASE_HOME}/.gemini/agents/gemini-agent.md"
  assert_absent "${CASE_HOME}/.gemini/commands/run.toml"
  assert_absent "${CASE_HOME}/.gemini/commands/syd.toml"
  assert_stdout_contains "summary: + 0 ~ 0 = 0 ! 0 - 3 ? 0"
}

# ---- case registry ------------------------------------------------------

start_case test_scripts_carry_mode_755
test_scripts_carry_mode_755
end_case
start_case test_installer_behaves_identically_without_extra_utilities
test_installer_behaves_identically_without_extra_utilities
end_case
start_case test_scripts_pass_shellcheck_with_all_checks
test_scripts_pass_shellcheck_with_all_checks
end_case
start_case test_scripts_pass_shfmt_format_check
test_scripts_pass_shfmt_format_check
end_case
start_case test_help_prints_usage_and_exits_zero
test_help_prints_usage_and_exits_zero
end_case
start_case test_invalid_arguments_print_usage_and_exit_two
test_invalid_arguments_print_usage_and_exit_two
end_case
start_case test_duplicate_and_alias_selectors_collapse
test_duplicate_and_alias_selectors_collapse
end_case
start_case test_detection_selects_only_available_candidates
test_detection_selects_only_available_candidates
end_case
start_case test_detection_excludes_gemini
test_detection_excludes_gemini
end_case
start_case test_explicit_missing_binary_warns_and_stays_selected
test_explicit_missing_binary_warns_and_stays_selected
end_case
start_case test_force_flag_backs_up_and_replaces_conflicting_regular_files
test_force_flag_backs_up_and_replaces_conflicting_regular_files
end_case
start_case test_combined_force_flags_plan_verbose_forced_dry_run
test_combined_force_flags_plan_verbose_forced_dry_run
end_case
start_case test_forced_install_relocates_backups_with_xdg_state_home
test_forced_install_relocates_backups_with_xdg_state_home
end_case
start_case test_forced_rerun_refuses_existing_backup_before_any_apply
test_forced_rerun_refuses_existing_backup_before_any_apply
end_case
start_case test_forced_run_without_conflicts_creates_no_backup_directories
test_forced_run_without_conflicts_creates_no_backup_directories
end_case
start_case test_backup_placement_inside_discovery_root_fails_before_any_change
test_backup_placement_inside_discovery_root_fails_before_any_change
end_case
start_case test_backup_placement_via_state_link_alias_fails_before_any_change
test_backup_placement_via_state_link_alias_fails_before_any_change
end_case
start_case test_backup_placement_via_destination_link_alias_fails_before_any_change
test_backup_placement_via_destination_link_alias_fails_before_any_change
end_case
start_case test_forced_symlink_and_directory_conflicts_survive_force
test_forced_symlink_and_directory_conflicts_survive_force
end_case
start_case test_injected_backup_failure_preserves_destination_and_overrides_conflicts
test_injected_backup_failure_preserves_destination_and_overrides_conflicts
end_case
start_case test_forced_dry_run_collision_fails_without_writes
test_forced_dry_run_collision_fails_without_writes
end_case
start_case test_backup_ancestor_obstruction_rejects_forced_install_preflight
test_backup_ancestor_obstruction_rejects_forced_install_preflight
end_case
start_case test_backup_ancestor_obstruction_rejects_forced_uninstall_preflight
test_backup_ancestor_obstruction_rejects_forced_uninstall_preflight
end_case
start_case test_backup_ancestor_dangling_link_rejects_forced_preflight
test_backup_ancestor_dangling_link_rejects_forced_preflight
end_case
start_case test_backup_ancestor_file_link_rejects_forced_preflight
test_backup_ancestor_file_link_rejects_forced_preflight
end_case
start_case test_backup_final_symlink_collision_rejects_forced_preflight
test_backup_final_symlink_collision_rejects_forced_preflight
end_case
start_case test_missing_backup_suffix_preserves_exact_edited_bytes
test_missing_backup_suffix_preserves_exact_edited_bytes
end_case
start_case test_missing_backup_suffix_dry_run_plans_without_writes
test_missing_backup_suffix_dry_run_plans_without_writes
end_case
start_case test_forced_backups_share_one_stamp_per_invocation
test_forced_backups_share_one_stamp_per_invocation
end_case
start_case test_unchanged_forced_rerun_requests_no_stamp
test_unchanged_forced_rerun_requests_no_stamp
end_case
start_case test_backup_suffix_escape_after_safe_backup_rejects_forced_install_preflight
test_backup_suffix_escape_after_safe_backup_rejects_forced_install_preflight
end_case
start_case test_backup_suffix_escape_after_safe_backup_rejects_forced_uninstall_preflight
test_backup_suffix_escape_after_safe_backup_rejects_forced_uninstall_preflight
end_case
start_case test_backup_suffix_escape_through_protected_alias_rejects_preflight
test_backup_suffix_escape_through_protected_alias_rejects_preflight
end_case
start_case test_backup_suffix_escape_with_missing_suffix_rejects_preflight
test_backup_suffix_escape_with_missing_suffix_rejects_preflight
end_case
start_case test_backup_suffix_deeper_link_into_every_root_rejects_preflight
test_backup_suffix_deeper_link_into_every_root_rejects_preflight
end_case
start_case test_backup_suffix_escape_with_spaced_paths_rejects_preflight
test_backup_suffix_escape_with_spaced_paths_rejects_preflight
end_case
start_case test_backup_suffix_safe_link_and_sibling_placement_permits_backups
test_backup_suffix_safe_link_and_sibling_placement_permits_backups
end_case
start_case test_pi_install_deploys_shared_skills_and_agents_without_run_wiring
test_pi_install_deploys_shared_skills_and_agents_without_run_wiring
end_case
start_case test_claude_install_deploys_native_roots_without_shared_root
test_claude_install_deploys_native_roots_without_shared_root
end_case
start_case test_agy_install_merges_shared_and_run_skills_into_config_root
test_agy_install_merges_shared_and_run_skills_into_config_root
end_case
start_case test_opencode_install_deploys_shared_agents_and_commands
test_opencode_install_deploys_shared_agents_and_commands
end_case
start_case test_codex_install_deploys_run_skill_with_nested_reference
test_codex_install_deploys_run_skill_with_nested_reference
end_case
start_case test_gemini_install_deploys_both_command_files
test_gemini_install_deploys_both_command_files
end_case
start_case test_additional_source_files_deploy_without_code_changes
test_additional_source_files_deploy_without_code_changes
end_case
start_case test_identical_rerun_reports_unchanged_and_performs_no_writes
test_identical_rerun_reports_unchanged_and_performs_no_writes
end_case
start_case test_claude_codex_selection_visits_native_and_shared_roots_once
test_claude_codex_selection_visits_native_and_shared_roots_once
end_case
start_case test_repeated_and_aliased_selectors_never_duplicate_action_lines
test_repeated_and_aliased_selectors_never_duplicate_action_lines
end_case
start_case test_edited_regular_file_conflict_preserves_bytes_and_exits_three
test_edited_regular_file_conflict_preserves_bytes_and_exits_three
end_case
start_case test_file_symlink_conflict_preserves_link_and_omits_force_hint
test_file_symlink_conflict_preserves_link_and_omits_force_hint
end_case
start_case test_dangling_symlink_conflict_preserves_link
test_dangling_symlink_conflict_preserves_link
end_case
start_case test_directory_obstruction_conflict_preserves_contents_and_omits_force_hint
test_directory_obstruction_conflict_preserves_contents_and_omits_force_hint
end_case
start_case test_skill_directory_obstruction_blocks_shipped_files_as_conflicts
test_skill_directory_obstruction_blocks_shipped_files_as_conflicts
end_case
start_case test_stale_files_report_question_only_in_shipped_skill_directories
test_stale_files_report_question_only_in_shipped_skill_directories
end_case
start_case test_summary_reports_all_six_symbol_counts_with_notes
test_summary_reports_all_six_symbol_counts_with_notes
end_case
start_case test_install_dry_run_reports_planned_actions_and_preserves_tree
test_install_dry_run_reports_planned_actions_and_preserves_tree
end_case
start_case test_clean_install_dry_run_plans_additions_without_writes
test_clean_install_dry_run_plans_additions_without_writes
end_case
start_case test_new_file_modes_reflect_current_umask
test_new_file_modes_reflect_current_umask
end_case
start_case test_preexisting_temporary_collision_preserves_bytes
test_preexisting_temporary_collision_preserves_bytes
end_case
start_case test_failed_copy_removes_owned_temporary_and_exits_one
test_failed_copy_removes_owned_temporary_and_exits_one
end_case
start_case test_comparison_error_exits_one_without_classifying_conflict
test_comparison_error_exits_one_without_classifying_conflict
end_case
start_case test_runtime_failure_overrides_conflicts_with_exit_one
test_runtime_failure_overrides_conflicts_with_exit_one
end_case
start_case test_failed_rename_removes_owned_temporary_and_exits_one
test_failed_rename_removes_owned_temporary_and_exits_one
end_case
start_case test_forced_rename_failure_preserves_destination_bytes
test_forced_rename_failure_preserves_destination_bytes
end_case
start_case test_failed_backup_rename_preserves_destination_and_removes_temporary
test_failed_backup_rename_preserves_destination_and_removes_temporary
end_case
start_case test_dry_runs_issue_no_mutation_commands
test_dry_runs_issue_no_mutation_commands
end_case
start_case test_int_cleanup_preserves_preexisting_collision
test_int_cleanup_preserves_preexisting_collision
end_case
start_case test_term_cleanup_preserves_preexisting_collision
test_term_cleanup_preserves_preexisting_collision
end_case
start_case test_missing_source_directory_fails_whole_selection_preflight
test_missing_source_directory_fails_whole_selection_preflight
end_case
start_case test_missing_skill_md_fails_preflight
test_missing_skill_md_fails_preflight
end_case
start_case test_invalid_home_fails_preflight
test_invalid_home_fails_preflight
end_case
start_case test_relative_overrides_fail_preflight
test_relative_overrides_fail_preflight
end_case
start_case test_empty_overrides_fall_back_to_defaults
test_empty_overrides_fall_back_to_defaults
end_case
start_case test_empty_state_override_is_accepted
test_empty_state_override_is_accepted
end_case
start_case test_documented_overrides_redirect_destinations
test_documented_overrides_redirect_destinations
end_case
start_case test_opencode_config_dir_is_ignored
test_opencode_config_dir_is_ignored
end_case
start_case test_sudo_root_is_rejected
test_sudo_root_is_rejected
end_case
start_case test_root_or_sudo_user_alone_passes_environment_checks
test_root_or_sudo_user_alone_passes_environment_checks
end_case
start_case test_destination_obstructions_fail_preflight
test_destination_obstructions_fail_preflight
end_case
start_case test_valid_directory_links_pass_preflight
test_valid_directory_links_pass_preflight
end_case
start_case test_invocation_from_any_directory_resolves_clone
test_invocation_from_any_directory_resolves_clone
end_case
start_case test_paths_with_spaces_pass_preflight
test_paths_with_spaces_pass_preflight
end_case
start_case test_uninstall_removes_identical_files_and_prunes_empty_skill_dirs
test_uninstall_removes_identical_files_and_prunes_empty_skill_dirs
end_case
start_case test_uninstall_rerun_reports_unchanged_and_writes_nothing
test_uninstall_rerun_reports_unchanged_and_writes_nothing
end_case
start_case test_uninstall_preserves_edits_and_exits_three_without_force
test_uninstall_preserves_edits_and_exits_three_without_force
end_case
start_case test_forced_uninstall_backs_up_and_removes_edits
test_forced_uninstall_backs_up_and_removes_edits
end_case
start_case test_forced_uninstall_refuses_existing_backup_before_removal
test_forced_uninstall_refuses_existing_backup_before_removal
end_case
start_case test_uninstall_codex_retains_shared_root_and_names_remaining_consumers
test_uninstall_codex_retains_shared_root_and_names_remaining_consumers
end_case
start_case test_uninstall_force_still_retains_shared_root_for_unselected_consumers
test_uninstall_force_still_retains_shared_root_for_unselected_consumers
end_case
start_case test_uninstall_all_without_binaries_visits_shared_root_once
test_uninstall_all_without_binaries_visits_shared_root_once
end_case
start_case test_uninstall_retains_file_symlinks_and_directory_obstructions
test_uninstall_retains_file_symlinks_and_directory_obstructions
end_case
start_case test_uninstall_prunes_only_empty_source_defined_dirs
test_uninstall_prunes_only_empty_source_defined_dirs
end_case
start_case test_uninstall_reports_stale_files_inside_shipped_skill_directories
test_uninstall_reports_stale_files_inside_shipped_skill_directories
end_case
start_case test_uninstall_preflight_failures_leave_destinations_unchanged
test_uninstall_preflight_failures_leave_destinations_unchanged
end_case
start_case test_uninstall_retained_shared_root_still_preflights_selected_sources
test_uninstall_retained_shared_root_still_preflights_selected_sources
end_case
start_case test_uninstall_retained_shared_root_obstruction_rejects_before_removals
test_uninstall_retained_shared_root_obstruction_rejects_before_removals
end_case
start_case test_uninstall_retained_shared_ancestor_obstruction_rejects_before_other_actions
test_uninstall_retained_shared_ancestor_obstruction_rejects_before_other_actions
end_case
start_case test_uninstall_retained_shared_root_invalid_links_reject_preflight
test_uninstall_retained_shared_root_invalid_links_reject_preflight
end_case
start_case test_uninstall_retained_shared_root_source_failure_precedes_destination_checks
test_uninstall_retained_shared_root_source_failure_precedes_destination_checks
end_case
start_case test_uninstall_retained_absent_shared_root_stays_absent
test_uninstall_retained_absent_shared_root_stays_absent
end_case
start_case test_uninstall_retained_shared_root_survives_removals_unchanged
test_uninstall_retained_shared_root_survives_removals_unchanged
end_case
start_case test_uninstall_retained_shared_root_link_survives_removals
test_uninstall_retained_shared_root_link_survives_removals
end_case
start_case test_uninstall_retained_shared_ancestor_link_survives_removals
test_uninstall_retained_shared_ancestor_link_survives_removals
end_case
start_case test_uninstall_retained_shared_edits_trigger_no_conflicts_or_backups
test_uninstall_retained_shared_edits_trigger_no_conflicts_or_backups
end_case
start_case test_uninstall_dry_run_plans_removals_and_preserves_tree
test_uninstall_dry_run_plans_removals_and_preserves_tree
end_case
start_case test_uninstall_alias_and_duplicate_selectors_remove_once
test_uninstall_alias_and_duplicate_selectors_remove_once
end_case
start_case test_uninstall_combined_flags_plan_verbose_forced_actions
test_uninstall_combined_flags_plan_verbose_forced_actions
end_case
start_case test_uninstall_explicit_missing_binary_warns_and_proceeds
test_uninstall_explicit_missing_binary_warns_and_proceeds
end_case

printf '%s: %s run, %s passed, %s failed\n' "${PROGRAM}" "${TESTS_RUN}" \
  "$((TESTS_RUN - TESTS_FAILED))" "${TESTS_FAILED}"
if [ "${TESTS_FAILED}" -eq 0 ]; then
  exit 0
fi
exit 1
