#!/usr/bin/env bash
# Entry point for performing the complete container initialization. Always
# downloads the bootstrap helpers from the configured GitHub Pages mirror
# and executes them from a temporary directory.

set -Eeuo pipefail

DEFAULT_REMOTE_BASE_URL="https://qqrm.github.io/codex-tools"
REMOTE_BASE_URL="${CODEX_TOOLS_BOOTSTRAP_BASE_URL:-$DEFAULT_REMOTE_BASE_URL}"
DOWNLOAD_BASE="${REMOTE_BASE_URL%/}"

script_name="bootstrap-full-initialization.sh"
tmp_dir=""

cleanup_tmp() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

download_from_pages() {
  local relative_path="$1"
  local destination="$2"
  local tmp_file
  tmp_file="$(mktemp)"

  local url="${DOWNLOAD_BASE}/${relative_path}"
  if curl -fsSL "$url" -o "$tmp_file"; then
    mv "$tmp_file" "$destination"
    return 0
  fi

  rm -f "$tmp_file"
  echo "Error: failed to download ${relative_path} from ${DOWNLOAD_BASE}." >&2
  return 1
}

trap cleanup_tmp EXIT
tmp_dir="$(mktemp -d)"

download_from_pages "scripts/${script_name}" "$tmp_dir/${script_name}"
download_from_pages "scripts/lib/container-bootstrap-common.sh" \
  "$tmp_dir/container-bootstrap-common.sh"

chmod +x "$tmp_dir/${script_name}"

CODEX_TOOLS_BOOTSTRAP_LIB="$tmp_dir/container-bootstrap-common.sh" \
  bash "$tmp_dir/${script_name}" "$@"
