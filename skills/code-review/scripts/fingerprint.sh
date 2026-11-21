#!/bin/sh
# Print a SHA-256 fingerprint of a code-review scope: the review argument
# plus the reviewed content, excluding the review report.
#
# Usage: fingerprint.sh ARGUMENT
#
# Inside a git work tree, hash the base commit (or empty tree), the
# working-tree diff against it, and every untracked, non-ignored file.
# Outside one, hash every file under the existing paths ARGUMENT names.
set -eu

REPORT=code-review-report.yaml
SCRIPT_NAME=${0##*/}
STATE=

die() {
  printf '%s: %s\n' "${SCRIPT_NAME}" "$1" >&2
  exit 1
}

cleanup() {
  if [ -n "${STATE}" ]; then
    rm -f -- "${STATE}"
  fi
}

digest() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum
  else
    shasum -a 256
  fi
}

git_state() {
  root=$(git rev-parse --show-toplevel)
  cd "${root}"
  base=$(git rev-parse --verify --quiet HEAD) ||
    base=$(git hash-object -t tree /dev/null)
  printf 'base %s\n' "${base}"
  git --no-pager diff --no-ext-diff --no-textconv --no-color --binary \
    "${base}" -- . ":(exclude)${REPORT}"
  untracked=$(git -c core.quotePath=false ls-files --others \
    --exclude-standard -- . ":(exclude)${REPORT}")
  while IFS= read -r path; do
    [ -n "${path}" ] || continue
    blob=$(git hash-object -- "${path}")
    printf 'untracked %s %s\n' "${blob}" "${path}"
  done <<EOF
${untracked}
EOF
}

plain_state() {
  set -f
  # shellcheck disable=SC2086 # split the argument into candidate paths
  set -- $1
  set +f
  for word in "$@"; do
    [ -e "${word}" ] || continue
    files=$(find "${word}" -type f ! -name "${REPORT}")
    files=$(printf '%s\n' "${files}" | LC_ALL=C sort)
    while IFS= read -r file; do
      [ -n "${file}" ] || continue
      sum=$(digest <"${file}")
      printf 'file %s %s\n' "${sum%% *}" "${file}"
    done <<EOF
${files}
EOF
  done
}

[ "$#" -eq 1 ] || die "usage: ${SCRIPT_NAME} ARGUMENT"
command -v sha256sum >/dev/null 2>&1 ||
  command -v shasum >/dev/null 2>&1 ||
  die 'sha256sum or shasum required'

trap cleanup EXIT
trap 'exit 130' INT
STATE=$(mktemp) || die 'mktemp failed'

{
  printf 'argument %s\n' "$1"
  if command -v git >/dev/null 2>&1 &&
    [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ]; then
    git_state
  else
    plain_state "$1"
  fi
} >"${STATE}"

sum=$(digest <"${STATE}")
printf '%s\n' "${sum%% *}"
