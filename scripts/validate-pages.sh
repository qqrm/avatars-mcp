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

check_file "scripts/split-initialization-cached-base.sh"
check_file "scripts/full-initialization.sh"
check_file "scripts/split-initialization-pretask.sh"
check_file "scripts/repo-setup.sh"
check_file "full-initialization.sh"
check_file "split-initialization-cached-base.sh"
check_file "split-initialization-pretask.sh"
check_file "scripts/bootstrap-split-initialization-cached-base.sh"
check_file "scripts/bootstrap-full-initialization.sh"
check_file "scripts/bootstrap-split-initialization-pretask.sh"
check_file "scripts/agent-sync.sh"
check_file "scripts/lib/container-bootstrap-common.sh"
check_file "workflows/codex-cleanup.yml"
check_file "AGENTS.md"
check_file "README.md"
check_file "docs/INSTRUCTIONS.md"
check_file "docs/SPECIFICATION.md"
check_file "static.json"
check_file "index.json"
check_file "avatars.json"
check_file "index.md"

if [[ ${missing} -ne 0 ]]; then
  echo "Pages artifact validation failed." >&2
  exit 1
fi

echo "Pages artifact validation passed." >&2
