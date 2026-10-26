#!/bin/sh
# SPAE harness installer.
#
# Installs skills, agents, and command wiring from this clone into the
# per-harness configuration roots. The whole selection is validated
# before anything mutates.
set -eu

PROGRAM="${0##*/}"

usage() {
  printf '%s\n' \
    "usage: ${PROGRAM} [-n] [-f] [-u] [-v] <harness>... | all" \
    "       ${PROGRAM} -h" \
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
    '  antigravity is an alias for agy'
}

usage_error() {
  printf '%s: %s\n' "${PROGRAM}" "${1}" >&2
  usage >&2
  exit 2
}

die() {
  cleanup_temp
  printf '%s: %s\n' "${PROGRAM}" "${1}" >&2
  exit 1
}

# Copies run one at a time, so at most one owned temporary exists.
CURRENT_TEMP=""

cleanup_temp() {
  if [ -n "${CURRENT_TEMP}" ]; then
    rm -f "${CURRENT_TEMP}"
  fi
}

# ---- clone resolution ---------------------------------------------------

case "${0}" in
  */*) script_dir="${0%/*}" ;;
  *) script_dir=. ;;
esac
CLONE_DIR="$(cd "${script_dir}" && pwd -P)" || die "cannot resolve clone from ${0}"

# ---- argument parsing ---------------------------------------------------

NL='
'
DRY_RUN=0
FORCE=0
UNINSTALL=0
VERBOSE=0
SAW_ALL=0
SAW_NAME=0
SELECTED=""

add_selector() {
  _as_name="${1}"
  case "${_as_name}" in
    antigravity) _as_name=agy ;;
    *) : ;;
  esac
  case "${NL}${SELECTED}${NL}" in
    *"${NL}${_as_name}${NL}"*) return 0 ;;
    *) : ;;
  esac
  if [ -z "${SELECTED}" ]; then
    SELECTED="${_as_name}"
  else
    SELECTED="${SELECTED}${NL}${_as_name}"
  fi
}

while [ "${#}" -gt 0 ]; do
  case "${1}" in
    -h | --help)
      usage
      exit 0
      ;;
    -n | --dry-run) DRY_RUN=1 ;;
    -f | --force) FORCE=1 ;;
    -u | --uninstall) UNINSTALL=1 ;;
    -v | --verbose) VERBOSE=1 ;;
    -*) usage_error "unknown option: ${1}" ;;
    all) SAW_ALL=1 ;;
    pi | claude | agy | antigravity | opencode | codex | gemini)
      add_selector "${1}"
      SAW_NAME=1
      ;;
    *) usage_error "unknown harness: ${1}" ;;
  esac
  shift
done

if [ "${SAW_ALL}" = 1 ] && [ "${SAW_NAME}" = 1 ]; then
  usage_error "do not mix all with harness names"
fi
if [ "${SAW_ALL}" = 0 ] && [ "${SAW_NAME}" = 0 ]; then
  usage_error "no harness selected"
fi

# ---- environment validation ---------------------------------------------

validate_home() {
  case "${HOME-}" in
    "") die "HOME is unset or empty" ;;
    /*) : ;;
    *) die "HOME is not absolute: ${HOME}" ;;
  esac
}

check_override() {
  _co_name="${1}"
  _co_value="${2}"
  if [ -n "${_co_value}" ]; then
    case "${_co_value}" in
      /*) : ;;
      *) die "${_co_name} is not absolute: ${_co_value}" ;;
    esac
  fi
}

validate_home
check_override CLAUDE_CONFIG_DIR "${CLAUDE_CONFIG_DIR-}"
check_override PI_CODING_AGENT_DIR "${PI_CODING_AGENT_DIR-}"
check_override XDG_CONFIG_HOME "${XDG_CONFIG_HOME-}"
check_override CODEX_HOME "${CODEX_HOME-}"
check_override XDG_STATE_HOME "${XDG_STATE_HOME-}"

_uid="$(id -u)"
if [ "${_uid}" = 0 ] && [ "${SUDO_USER+set}" = set ]; then
  die "refusing to run as root with SUDO_USER set"
fi

# ---- destination bases --------------------------------------------------

C="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
P="${PI_CODING_AGENT_DIR:-${HOME}/.pi/agent}"
O="${XDG_CONFIG_HOME:-${HOME}/.config}/opencode"
X="${CODEX_HOME:-${HOME}/.codex}"
G="${HOME}/.gemini"
A="${HOME}/.agents/skills"

# ---- backup preservation state ----------------------------------------

STATE_BASE="${XDG_STATE_HOME:-${HOME}/.local/state}"
BACKUP_ROOT="${STATE_BASE}/spae/backups"
STAMP=""
BACKUP_BASE=""
BACKUP_PATH=""
BACKUP_CHECKED=0
BACKUPS=0

# ---- selection ----------------------------------------------------------

build_selection() {
  if [ "${SAW_ALL}" = 1 ]; then
    SELECTED=""
    if [ "${UNINSTALL}" = 1 ]; then
      for _bs_name in pi claude agy opencode codex gemini; do
        add_selector "${_bs_name}"
      done
      return 0
    fi
    for _bs_name in pi claude agy opencode codex; do
      if command -v "${_bs_name}" > /dev/null 2>&1; then
        add_selector "${_bs_name}"
      else
        printf '%s: skipping %s (not found in PATH)\n' "${PROGRAM}" "${_bs_name}" >&2
      fi
    done
    return 0
  fi
  while IFS= read -r _bs_name || [ -n "${_bs_name}" ]; do
    if [ "${_bs_name}" = gemini ]; then
      printf '%s: warning: gemini is deprecated\n' "${PROGRAM}" >&2
    fi
    if command -v "${_bs_name}" > /dev/null 2>&1; then
      :
    else
      printf '%s: warning: %s not found in PATH\n' "${PROGRAM}" "${_bs_name}" >&2
    fi
  done << EOF
${SELECTED}
EOF
}

build_selection

if [ -z "${SELECTED}" ]; then
  exit 0
fi

# ---- shared-root retention --------------------------------------------

# A serves pi, opencode, codex, and gemini; uninstalling some of them keeps
# it and names the rest. Selections without a sharing harness never touch A.
ACTION=apply
SHARED_RETAIN=0
if [ "${UNINSTALL}" = 1 ]; then
  ACTION=uninstall
  _sr_selected=""
  _sr_unselected=""
  for _sr_name in pi opencode codex gemini; do
    case "${NL}${SELECTED}${NL}" in
      *"${NL}${_sr_name}${NL}"*) _sr_selected=1 ;;
      *) _sr_unselected="${_sr_unselected:+${_sr_unselected}, }${_sr_name}" ;;
    esac
  done
  if [ -n "${_sr_selected}" ] && [ -n "${_sr_unselected}" ]; then
    SHARED_RETAIN=1
    printf '%s: note: preserving %s; shared with unselected harnesses: %s\n' \
      "${PROGRAM}" "${A}" "${_sr_unselected}" >&2
  fi
fi

# ---- deployment seam ----------------------------------------------------

deploy_pi() {
  deploy skills "${CLONE_DIR}/skills" "${A}"
  deploy files "${CLONE_DIR}/pi/agents" "${P}/agents"
}

deploy_claude() {
  deploy skills "${CLONE_DIR}/skills" "${C}/skills"
  deploy files "${CLONE_DIR}/claude/agents" "${C}/agents"
  deploy files "${CLONE_DIR}/claude/commands" "${C}/commands"
}

deploy_agy() {
  deploy skills "${CLONE_DIR}/skills" "${G}/config/skills"
  deploy skills "${CLONE_DIR}/antigravity/skills" "${G}/config/skills"
  deploy files "${CLONE_DIR}/antigravity/agents" "${G}/config/agents"
}

deploy_opencode() {
  deploy skills "${CLONE_DIR}/skills" "${A}"
  deploy files "${CLONE_DIR}/opencode/agents" "${O}/agents"
  deploy files "${CLONE_DIR}/opencode/commands" "${O}/commands"
}

deploy_codex() {
  deploy skills "${CLONE_DIR}/skills" "${A}"
  deploy files "${CLONE_DIR}/codex/agents" "${X}/agents"
  deploy skills "${CLONE_DIR}/codex/skills" "${X}/skills"
}

deploy_gemini() {
  deploy skills "${CLONE_DIR}/skills" "${A}"
  deploy files "${CLONE_DIR}/gemini/agents" "${G}/agents"
  deploy files "${CLONE_DIR}/gemini/commands" "${G}/commands"
}

preflight_source() {
  _ps_kind="${1}"
  _ps_src="${2}"
  if [ ! -d "${_ps_src}" ]; then
    die "preflight: missing source directory: ${_ps_src}"
  fi
  if [ "${_ps_kind}" = skills ]; then
    for _ps_entry in "${_ps_src}"/*; do
      if [ ! -d "${_ps_entry}" ]; then
        continue
      fi
      if [ ! -f "${_ps_entry}/SKILL.md" ]; then
        die "preflight: missing SKILL.md: ${_ps_entry}/SKILL.md"
      fi
    done
  fi
}

preflight_destination() {
  _pd_path="${1}"
  if [ -d "${_pd_path}" ]; then
    if [ -w "${_pd_path}" ]; then
      return 0
    fi
    die "preflight: destination is not writable: ${_pd_path}"
  fi
  if [ -e "${_pd_path}" ]; then
    die "preflight: destination is not a directory: ${_pd_path}"
  fi
  if [ -L "${_pd_path}" ]; then
    die "preflight: dangling link: ${_pd_path}"
  fi
  _pd_up="${_pd_path}"
  while :; do
    _pd_up="${_pd_up%/*}"
    if [ -z "${_pd_up}" ]; then
      _pd_up=/
    fi
    if [ -L "${_pd_up}" ] && [ ! -d "${_pd_up}" ]; then
      die "preflight: dangling link: ${_pd_up}"
    fi
    if [ -e "${_pd_up}" ]; then
      if [ -d "${_pd_up}" ]; then
        if [ -w "${_pd_up}" ]; then
          return 0
        fi
        die "preflight: destination is not writable: ${_pd_up}"
      fi
      die "preflight: destination ancestor is not a directory: ${_pd_up}"
    fi
    if [ "${_pd_up}" = / ]; then
      break
    fi
  done
  die "preflight: destination has no existing ancestor: ${_pd_path}"
}

# ---- install engine -----------------------------------------------------

ADDED=0
REPLACED=0
UNCHANGED=0
CONFLICTS=0
CONFLICT_REG=0
REMOVED=0
STALE=0
PATH_BLOCKED=0

count_conflict() {
  CONFLICTS="$((CONFLICTS + 1))"
}

count_regular_conflict() {
  CONFLICTS="$((CONFLICTS + 1))"
  CONFLICT_REG="$((CONFLICT_REG + 1))"
}

report() {
  _rpt_symbol="${1}"
  _rpt_path="${2}"
  if [ "${_rpt_symbol}" = = ] && [ "${VERBOSE}" != 1 ]; then
    return 0
  fi
  printf '%s %s\n' "${_rpt_symbol}" "${_rpt_path}"
}

execute() {
  # $1 holds the failure message; the remaining arguments run the mutation.
  _ex_failure="${1}"
  shift
  if [ "${DRY_RUN}" = 1 ]; then
    return 0
  fi
  "$@" || die "${_ex_failure}"
}

# Sets PATH_BLOCKED=1 when an existing path in the destination chain is not a
# directory, obstructing a shipped file path.
check_path_blocked() {
  PATH_BLOCKED=0
  _cpb_path="${1}"
  while :; do
    _cpb_path="${_cpb_path%/*}"
    if [ -z "${_cpb_path}" ]; then
      _cpb_path=/
    fi
    if [ -L "${_cpb_path}" ] || [ -e "${_cpb_path}" ]; then
      if [ -d "${_cpb_path}" ]; then
        return 0
      fi
      PATH_BLOCKED=1
      return 0
    fi
    if [ "${_cpb_path}" = / ]; then
      return 0
    fi
  done
}

# Sets CLASS=identical|different|missing|blocked|conflict-other for one
# shipped source/destination pair; comparison errors are fatal.
classify_file() {
  _cl_src="${1}"
  _cl_dst="${2}"
  if [ -L "${_cl_dst}" ] || [ -d "${_cl_dst}" ]; then
    CLASS=conflict-other
    return 0
  fi
  if [ -f "${_cl_dst}" ]; then
    if cmp -s "${_cl_src}" "${_cl_dst}"; then
      CLASS=identical
    else
      _cl_status="$?"
      if [ "${_cl_status}" -gt 1 ]; then
        die "${ACTION}: cannot compare ${_cl_dst}"
      fi
      CLASS=different
    fi
    return 0
  fi
  check_path_blocked "${_cl_dst}"
  if [ -e "${_cl_dst}" ] || [ "${PATH_BLOCKED}" = 1 ]; then
    CLASS=blocked
    return 0
  fi
  CLASS=missing
}

# One UTC stamp per invocation; backups mirror absolute destinations beneath
# it so preserved bytes stay outside every discovery root.
ensure_stamp() {
  if [ -z "${STAMP}" ]; then
    STAMP="$(date -u '+%Y%m%dT%H%M%SZ')" || die "preflight: cannot compute backup stamp"
    BACKUP_BASE="${BACKUP_ROOT}/${STAMP}"
  fi
}

# Resolve $1 physically through valid directory links and append any missing
# suffix literally; RESOLVED_PHYS stays empty when the existing prefix is not
# a directory.
resolve_physical() {
  _rph_path="${1}"
  _rph_suffix=""
  while [ ! -e "${_rph_path}" ] && [ ! -L "${_rph_path}" ]; do
    _rph_tail="${_rph_path##*/}"
    _rph_next="${_rph_path%/*}"
    if [ "${_rph_next}" = "${_rph_path}" ]; then
      _rph_next=.
    fi
    if [ -z "${_rph_next}" ]; then
      _rph_next=/
    fi
    _rph_suffix="/${_rph_tail}${_rph_suffix}"
    _rph_path="${_rph_next}"
  done
  RESOLVED_PHYS=""
  if [ ! -d "${_rph_path}" ]; then
    return 0
  fi
  RESOLVED_PHYS="$(cd "${_rph_path}" && pwd -P)" || die "preflight: cannot resolve ${1}"
  RESOLVED_PHYS="${RESOLVED_PHYS}${_rph_suffix}"
}

# Reject physical placement of backup path $1 at or beneath any
# install-matrix destination root, including unselected harness roots
# and aliases through valid directory links; containment compares whole
# path components after resolution and tolerates missing suffixes.
check_backup_placement() {
  _bp_path="${1}"
  resolve_physical "${_bp_path}"
  _bp_phys="${RESOLVED_PHYS}"
  if [ -z "${_bp_phys}" ]; then
    die "preflight: cannot resolve backup location: ${_bp_path}"
  fi
  for _bp_root in "${A}" "${C}" "${P}" "${O}" "${X}" "${G}"; do
    resolve_physical "${_bp_root}"
    if [ -z "${RESOLVED_PHYS}" ]; then
      continue
    fi
    case "${_bp_phys}" in
      "${RESOLVED_PHYS}" | "${RESOLVED_PHYS}"/*)
        die "preflight: backup location is inside an install destination root: ${_bp_path}"
        ;;
      *) : ;;
    esac
  done
}

# Validate $1's stamped backup pathname and its complete parent chain,
# including ancestors below the stamp, without creating anything.
# Recheck physical placement for every complete backup path so the
# stamp-base cache can never mask a mirrored-suffix escape.
# backup_file reuses this defense during apply.
check_backup_path() {
  if [ "${BACKUP_CHECKED}" = 0 ]; then
    BACKUP_CHECKED=1
    ensure_stamp
    check_backup_placement "${BACKUP_BASE}"
  fi
  ensure_stamp
  BACKUP_PATH="${BACKUP_BASE}${1}"
  preflight_destination "${BACKUP_PATH%/*}"
  if [ -e "${BACKUP_PATH}" ] || [ -L "${BACKUP_PATH}" ]; then
    die "preflight: refusing to overwrite existing backup: ${BACKUP_PATH}"
  fi
  check_backup_placement "${BACKUP_PATH}"
}

# Preserve $1's current bytes in the stamp-mirrored backup tree before any
# destructive change; forced uninstall reuses this helper.
backup_file() {
  _bk_path="${1}"
  check_backup_path "${_bk_path}"
  copy_shipped "${_bk_path}" "${BACKUP_PATH}"
  BACKUPS="$((BACKUPS + 1))"
}

copy_shipped() {
  _cp_src="${1}"
  _cp_dst="${2}"
  _cp_tmp="${_cp_dst}.spae-tmp.$$"
  if [ -e "${_cp_tmp}" ] || [ -L "${_cp_tmp}" ]; then
    die "${ACTION}: temporary path already exists: ${_cp_tmp}"
  fi
  execute "${ACTION}: cannot create directory ${_cp_dst%/*}" mkdir -p "${_cp_dst%/*}"
  if [ "${DRY_RUN}" = 1 ]; then
    return 0
  fi
  CURRENT_TEMP="${_cp_tmp}"
  execute "${ACTION}: cannot copy ${_cp_src}" cp "${_cp_src}" "${_cp_tmp}"
  execute "${ACTION}: cannot move ${_cp_tmp}" mv "${_cp_tmp}" "${_cp_dst}"
  CURRENT_TEMP=""
}

handle_file() {
  _hf_src="${1}"
  _hf_rel="${2}"
  _hf_root="${3}"
  _hf_file="${_hf_src}/${_hf_rel}"
  _hf_dst="${_hf_root}/${_hf_rel}"
  classify_file "${_hf_file}" "${_hf_dst}"
  case "${CLASS}" in
    identical)
      UNCHANGED="$((UNCHANGED + 1))"
      report '=' "${_hf_dst}"
      ;;
    different)
      if [ "${FORCE}" = 1 ]; then
        backup_file "${_hf_dst}"
        copy_shipped "${_hf_file}" "${_hf_dst}"
        REPLACED="$((REPLACED + 1))"
        report '~' "${_hf_dst}"
      else
        count_regular_conflict
        report '!' "${_hf_dst}"
      fi
      ;;
    missing)
      ADDED="$((ADDED + 1))"
      copy_shipped "${_hf_file}" "${_hf_dst}"
      report '+' "${_hf_dst}"
      ;;
    conflict-other | blocked)
      count_conflict
      report '!' "${_hf_dst}"
      ;;
    *)
      die "internal: unclassified file ${_hf_dst}"
      ;;
  esac
}

# Uninstall counterpart of handle_file: remove only shipped regular files
# matching the current source; keep edits without force and back up before
# any forced removal.
remove_file() {
  _rf_src="${1}"
  _rf_rel="${2}"
  _rf_root="${3}"
  _rf_file="${_rf_src}/${_rf_rel}"
  _rf_dst="${_rf_root}/${_rf_rel}"
  classify_file "${_rf_file}" "${_rf_dst}"
  case "${CLASS}" in
    identical)
      execute "uninstall: cannot remove ${_rf_dst}" rm -f "${_rf_dst}"
      REMOVED="$((REMOVED + 1))"
      report '-' "${_rf_dst}"
      ;;
    different)
      if [ "${FORCE}" = 1 ]; then
        backup_file "${_rf_dst}"
        execute "uninstall: cannot remove ${_rf_dst}" rm -f "${_rf_dst}"
        REMOVED="$((REMOVED + 1))"
        report '-' "${_rf_dst}"
      else
        count_regular_conflict
        report '!' "${_rf_dst}"
      fi
      ;;
    missing)
      UNCHANGED="$((UNCHANGED + 1))"
      report '=' "${_rf_dst}"
      ;;
    conflict-other | blocked)
      count_conflict
      report '!' "${_rf_dst}"
      ;;
    *)
      die "internal: unclassified file ${_rf_dst}"
      ;;
  esac
}

# Validate every needed backup destination before any selected harness
# applies; classification mirrors apply so no backup can slip past.
preflight_backups() {
  _pfb_src="${1}"
  _pfb_dst="${2}"
  _pfb_files="$(cd "${_pfb_src}" && find . -type f)" || die "preflight: cannot enumerate ${_pfb_src}"
  while IFS= read -r _pfb_rel || [ -n "${_pfb_rel}" ]; do
    if [ -z "${_pfb_rel}" ]; then
      continue
    fi
    _pfb_rel="${_pfb_rel#./}"
    classify_file "${_pfb_src}/${_pfb_rel}" "${_pfb_dst}/${_pfb_rel}"
    if [ "${CLASS}" = different ]; then
      check_backup_path "${_pfb_dst}/${_pfb_rel}"
    fi
  done << EOF
${_pfb_files}
EOF
}

# Report non-shipped files inside shipped skill directories.
scan_stale() {
  _ss_files="${1}"
  _ss_src="${2}"
  _ss_dst="${3}"
  for _ss_entry in "${_ss_src}"/*; do
    if [ ! -d "${_ss_entry}" ]; then
      continue
    fi
    _ss_name="${_ss_entry##*/}"
    _ss_dir="${_ss_dst}/${_ss_name}"
    if [ ! -d "${_ss_dir}" ]; then
      continue
    fi
    _ss_found="$(cd "${_ss_dir}" && find . -type f)" || die "${ACTION}: cannot enumerate ${_ss_dir}"
    while IFS= read -r _ss_rel || [ -n "${_ss_rel}" ]; do
      if [ -z "${_ss_rel}" ]; then
        continue
      fi
      _ss_rel="${_ss_rel#./}"
      _ss_key="${_ss_name}/${_ss_rel}"
      case "${NL}${_ss_files}${NL}" in
        *"${NL}./${_ss_key}${NL}"*) : ;;
        *)
          STALE="$((STALE + 1))"
          report '?' "${_ss_dir}/${_ss_rel}"
          ;;
      esac
    done << EOF
${_ss_found}
EOF
  done
}

# Prune emptied source-defined skill directories only, deepest first;
# destination roots, directory links, and foreign trees survive.
prune_skill_dirs() {
  for _psd_entry in "${1}"/*; do
    if [ -d "${_psd_entry}" ]; then
      prune_tree "${1}" "${2}" "${_psd_entry##*/}"
    fi
  done
}

prune_tree() {
  for _pt_entry in "${1}/${3}"/*; do
    if [ -d "${_pt_entry}" ]; then
      prune_tree "${1}" "${2}" "${3}/${_pt_entry##*/}"
    fi
  done
  _pt_target="${2}/${3}"
  if [ -L "${_pt_target}" ] || [ ! -d "${_pt_target}" ]; then
    return 0
  fi
  _pt_listing="$(cd "${_pt_target}" && find .)" || die "uninstall: cannot inspect ${_pt_target}"
  if [ "${_pt_listing}" != . ]; then
    return 0
  fi
  execute "uninstall: cannot prune ${_pt_target}" rmdir "${_pt_target}"
}

print_summary() {
  if [ "${DRY_RUN}" = 1 ]; then
    printf 'summary (planned): + %s ~ %s = %s ! %s - %s ? %s\n' \
      "${ADDED}" "${REPLACED}" "${UNCHANGED}" "${CONFLICTS}" "${REMOVED}" "${STALE}"
  else
    printf 'summary: + %s ~ %s = %s ! %s - %s ? %s\n' \
      "${ADDED}" "${REPLACED}" "${UNCHANGED}" "${CONFLICTS}" "${REMOVED}" "${STALE}"
  fi
  if [ "${BACKUPS}" -gt 0 ]; then
    if [ "${DRY_RUN}" = 1 ]; then
      printf 'note: planned backups: %s\n' "${BACKUP_BASE}"
    else
      printf 'note: backups: %s\n' "${BACKUP_BASE}"
    fi
  fi
  if [ "${CONFLICT_REG}" -gt 0 ]; then
    printf '%s\n' \
      'note: conflicting regular files are skipped; use --force to back up and replace regular files only (symlinks and directories are never replaced)'
  fi
  if [ "${UNINSTALL}" = 1 ]; then
    printf '%s\n' \
      'note: restart harness sessions after uninstallation to drop the removed files'
    return 0
  fi
  case "${NL}${SELECTED}${NL}" in
    *"${NL}pi${NL}"*)
      printf '%s\n' \
        'note: pi prerequisite: pi-subagent (https://github.com/mystilleef/pi-subagent)'
      ;;
    *) : ;;
  esac
  printf '%s\n' \
    'note: restart harness sessions after installation to pick up the new files'
}

# DEPLOYED keys are src|dst pairs, newline separated, reset per pass.
deploy() {
  _dp_kind="${1}"
  _dp_src="${2}"
  _dp_dst="${3}"
  if [ "${SHARED_RETAIN}" = 1 ] && [ "${_dp_dst}" = "${A}" ]; then
    if [ "${PHASE}" = preflight ]; then
      # Retention keeps shared content out of classification and backups,
      # but the shared root stays a selected destination: validate it like
      # any other root before returning.
      preflight_source "${_dp_kind}" "${_dp_src}"
      preflight_destination "${_dp_dst}"
    fi
    return 0
  fi
  _dp_key="${_dp_src}|${_dp_dst}"
  case "${NL}${DEPLOYED}${NL}" in
    *"${NL}${_dp_key}${NL}"*) return 0 ;;
    *) : ;;
  esac
  if [ -z "${DEPLOYED}" ]; then
    DEPLOYED="${_dp_key}"
  else
    DEPLOYED="${DEPLOYED}${NL}${_dp_key}"
  fi
  case "${PHASE}" in
    preflight)
      preflight_source "${_dp_kind}" "${_dp_src}"
      preflight_destination "${_dp_dst}"
      if [ "${FORCE}" = 1 ]; then
        preflight_backups "${_dp_src}" "${_dp_dst}"
      fi
      ;;
    apply)
      _dp_files="$(cd "${_dp_src}" && find . -type f)" || die "preflight: cannot enumerate ${_dp_src}"
      while IFS= read -r _dp_rel || [ -n "${_dp_rel}" ]; do
        if [ -z "${_dp_rel}" ]; then
          continue
        fi
        _dp_rel="${_dp_rel#./}"
        if [ "${UNINSTALL}" = 1 ]; then
          remove_file "${_dp_src}" "${_dp_rel}" "${_dp_dst}"
        else
          handle_file "${_dp_src}" "${_dp_rel}" "${_dp_dst}"
        fi
      done << EOF
${_dp_files}
EOF
      if [ "${_dp_kind}" = skills ]; then
        scan_stale "${_dp_files}" "${_dp_src}" "${_dp_dst}"
        if [ "${UNINSTALL}" = 1 ]; then
          prune_skill_dirs "${_dp_src}" "${_dp_dst}"
        fi
      fi
      ;;
    *) die "internal: unknown phase ${PHASE}" ;;
  esac
}

run_selection() {
  while IFS= read -r _rs_name || [ -n "${_rs_name}" ]; do
    case "${_rs_name}" in
      pi) deploy_pi ;;
      claude) deploy_claude ;;
      agy) deploy_agy ;;
      opencode) deploy_opencode ;;
      codex) deploy_codex ;;
      gemini) deploy_gemini ;;
      *) die "internal: unknown selection ${_rs_name}" ;;
    esac
  done << EOF
${SELECTED}
EOF
}

# ---- whole-selection preflight, then mutation dispatch ------------------

trap 'cleanup_temp' 0
trap 'exit 130' INT
trap 'exit 143' TERM

PHASE=preflight
DEPLOYED=""
run_selection

PHASE=apply
DEPLOYED=""
run_selection

print_summary
if [ "${CONFLICTS}" -gt 0 ]; then
  exit 3
fi
exit 0
