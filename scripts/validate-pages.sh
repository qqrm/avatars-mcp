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
check_path() {
  local relative_path="$1"
  local path="${OUTPUT_DIR}/${relative_path}"
  if [[ ! -s "${path}" ]]; then
    echo "Missing or empty artifact: ${relative_path}" >&2
    missing=1
  fi
}

required_paths=(
  scripts/BaseInitialization.sh
  scripts/FullInitialization.sh
  scripts/PretaskInitialization.sh
)

for relative_path in "${required_paths[@]}"; do
  check_path "${relative_path}"
done

legacy_paths=(
  scripts/split-initialization-cached-base.sh
  scripts/full-initialization.sh
  scripts/split-initialization-pretask.sh
  scripts/init-container.sh
  scripts/init-ephemeral-container.sh
  scripts/pre-task.sh
  scripts/lib/container-bootstrap-common.sh
  scripts/agent-sync.sh
  scripts/repo-setup.sh
)

for relative_path in "${legacy_paths[@]}"; do
  if [[ -e "${OUTPUT_DIR}/${relative_path}" ]]; then
    echo "Legacy artifact should not be published: ${relative_path}" >&2
    missing=1
  fi
done

if [[ ${missing} -ne 0 ]]; then
  echo "Pages artifact validation failed." >&2
  exit 1
fi

echo "Pages artifact validation passed." >&2
