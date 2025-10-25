#!/usr/bin/env bash
# Validate that the generated GitHub Pages artifact contains the required files.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR%/scripts}"
OUTPUT_DIR="${1:-${REPO_ROOT}/public}"
OUTPUT_DIR="${OUTPUT_DIR%/}"

if [[ ! -d "${OUTPUT_DIR}" ]]; then
  echo "Error: output directory ${OUTPUT_DIR} does not exist." >&2
  exit 1
fi

missing=0
check_script() {
  local script_name="$1"
  local relative_path="scripts/${script_name}"
  local path="${OUTPUT_DIR}/${relative_path}"
  if [[ ! -s "${path}" ]]; then
    echo "Missing or empty artifact: ${relative_path}" >&2
    missing=1
  fi
}

check_script "split-initialization-cached-base.sh"
check_script "full-initialization.sh"
check_script "split-initialization-pretask.sh"

if [[ ${missing} -ne 0 ]]; then
  echo "Pages artifact validation failed." >&2
  exit 1
fi

echo "Pages artifact validation passed." >&2
