#!/usr/bin/env bash
# Wrapper for refreshing cached containers before each task. Always
# downloads the bootstrap helpers from the configured location and runs
# them from a temporary directory.

set -Eeuo pipefail

DEFAULT_REMOTE_BASE_URL="https://qqrm.github.io/codex-tools"
REMOTE_BASE_URL="${CODEX_TOOLS_BOOTSTRAP_BASE_URL:-$DEFAULT_REMOTE_BASE_URL}"

declare -a DOWNLOAD_BASES=("${REMOTE_BASE_URL%/}")
if [[ -z "${CODEX_TOOLS_BOOTSTRAP_BASE_URL:-}" && "${REMOTE_BASE_URL%/}" == "${DEFAULT_REMOTE_BASE_URL}" ]]; then
  DOWNLOAD_BASES+=("https://raw.githubusercontent.com/qqrm/codex-tools/main")
fi

script_name="refresh-cached-container.sh"
tmp_dir=""

cleanup_tmp() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

download_with_fallback() {
  local relative_path="$1"
  local destination="$2"
  local tmp_file
  tmp_file="$(mktemp)"

  for base in "${DOWNLOAD_BASES[@]}"; do
    local url="${base%/}/${relative_path}"
    if curl -fsSL "$url" -o "$tmp_file"; then
      mv "$tmp_file" "$destination"
      return 0
    fi
  done

  rm -f "$tmp_file"
  echo "Error: failed to download ${relative_path} from configured bootstrap mirrors." >&2
  return 1
}

trap cleanup_tmp EXIT
tmp_dir="$(mktemp -d)"

download_with_fallback "scripts/${script_name}" "$tmp_dir/${script_name}"
download_with_fallback "scripts/lib/container-bootstrap-common.sh" \
  "$tmp_dir/container-bootstrap-common.sh"

chmod +x "$tmp_dir/${script_name}"

CODEX_TOOLS_BOOTSTRAP_LIB="$tmp_dir/container-bootstrap-common.sh" \
  bash "$tmp_dir/${script_name}" "$@"
