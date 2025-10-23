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
check_file() {
  local relative="$1"
  local path="${OUTPUT_DIR}/${relative}"
  if [[ ! -s "${path}" ]]; then
    echo "Missing or empty artifact: ${relative}" >&2
    missing=1
  fi
}

check_file "init-container.sh"
check_file "init-ephemeral-container.sh"
check_file "pre-task.sh"
check_file "repo-setup.sh"
check_file "scripts/bootstrap-cached-container.sh"
check_file "scripts/bootstrap-ephemeral-container.sh"
check_file "scripts/refresh-cached-container.sh"
check_file "scripts/lib/container-bootstrap-common.sh"
check_file "workflows/codex-cleanup.yml"
check_file "AGENTS.md"
check_file "INSTRUCTIONS.md"
check_file "README.md"
check_file "SPECIFICATION.md"
check_file "index.json"
check_file "avatars.json"
check_file "index.md"

if [[ ${missing} -ne 0 ]]; then
  echo "Pages artifact validation failed." >&2
  exit 1
fi

echo "Pages artifact validation passed." >&2
