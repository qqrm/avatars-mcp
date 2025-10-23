#!/usr/bin/env bash
# Entry point for bootstrapping non-cached containers. Always downloads
# the bootstrap helpers from the configured location and runs them from
# a temporary directory.

set -Eeuo pipefail

REMOTE_BASE_URL="${CODEX_TOOLS_BOOTSTRAP_BASE_URL:-https://qqrm.github.io/codex-tools}"

script_name="bootstrap-ephemeral-container.sh"
tmp_dir=""

cleanup_tmp() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

trap cleanup_tmp EXIT
tmp_dir="$(mktemp -d)"

curl -fsSL "${REMOTE_BASE_URL%/}/scripts/${script_name}" -o "$tmp_dir/${script_name}"
curl -fsSL "${REMOTE_BASE_URL%/}/scripts/lib/container-bootstrap-common.sh" \
  -o "$tmp_dir/container-bootstrap-common.sh"

chmod +x "$tmp_dir/${script_name}"

CODEX_TOOLS_BOOTSTRAP_LIB="$tmp_dir/container-bootstrap-common.sh" \
  bash "$tmp_dir/${script_name}" "$@"
