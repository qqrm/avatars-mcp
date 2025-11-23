#!/usr/bin/env bash
# Build the GitHub Pages artifact into the provided output directory.
# Mirrors the packaging performed during CI deployments so local builds
# and validation remain consistent.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR%/scripts}"
if [[ ! -d "${REPO_ROOT}/.git" ]]; then
  echo "Error: build-pages.sh must run from within the repository." >&2
  exit 1
fi

OUTPUT_DIR="${1:-${REPO_ROOT}/public}"
OUTPUT_DIR="${OUTPUT_DIR%/}"
if [[ -z "${OUTPUT_DIR}" || "${OUTPUT_DIR}" == "/" ]]; then
  echo "Error: refusing to operate on empty or root output directory." >&2
  exit 1
fi

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

copy_file() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "${src}" ]]; then
    echo "Error: expected file ${src} missing." >&2
    exit 1
  fi
  install -m 0644 "${src}" "${dest}"
}

copy_executable() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "${src}" ]]; then
    echo "Error: expected executable ${src} missing." >&2
    exit 1
  fi
  install -m 0755 "${src}" "${dest}"
}

refresh_personas_catalog() {
  local catalog_target="${REPO_ROOT}/personas/catalog.json"
  if [[ -n "${PERSONAS_CATALOG_SOURCE:-}" ]]; then
    if [[ ! -f "${PERSONAS_CATALOG_SOURCE}" ]]; then
      echo "Error: PERSONAS_CATALOG_SOURCE (${PERSONAS_CATALOG_SOURCE}) not found." >&2
      exit 1
    fi
    install -m 0644 "${PERSONAS_CATALOG_SOURCE}" "${catalog_target}"
    return
  fi

  if ! command -v cargo >/dev/null 2>&1; then
    echo "Error: cargo is required to regenerate personas/catalog.json." >&2
    exit 1
  fi

  (cd "${REPO_ROOT}" && cargo run --release -p personas-core)
}

# Personas and catalogs
refresh_personas_catalog
mkdir -p "${OUTPUT_DIR}/personas"
cp -a "${REPO_ROOT}/personas/." "${OUTPUT_DIR}/personas/"

# Scenarios
mkdir -p "${OUTPUT_DIR}/scenarios"
cp -a "${REPO_ROOT}/scenarios/." "${OUTPUT_DIR}/scenarios/"

# Shared markdown artifacts
copy_file "${REPO_ROOT}/AGENTS.md" "${OUTPUT_DIR}/AGENTS.md"
copy_file "${REPO_ROOT}/README.md" "${OUTPUT_DIR}/README.md"

mkdir -p "${OUTPUT_DIR}/docs"
copy_file "${REPO_ROOT}/docs/INSTRUCTIONS.md" "${OUTPUT_DIR}/docs/INSTRUCTIONS.md"
copy_file "${REPO_ROOT}/docs/SPECIFICATION.md" "${OUTPUT_DIR}/docs/SPECIFICATION.md"

# Pages configuration
copy_file "${REPO_ROOT}/static.json" "${OUTPUT_DIR}/static.json"

# Bootstrap entry points
mkdir -p "${OUTPUT_DIR}/scripts"
bootstrap_scripts=(
  BaseInitialization.sh
  FullInitialization.sh
  PretaskInitialization.sh
)

for script in "${bootstrap_scripts[@]}"; do
  copy_executable "${REPO_ROOT}/scripts/${script}" "${OUTPUT_DIR}/scripts/${script}"
done

# Workflows
mkdir -p "${OUTPUT_DIR}/workflows"
copy_file "${REPO_ROOT}/.github/workflows/codex-cleanup.yml" "${OUTPUT_DIR}/workflows/codex-cleanup.yml"

# Catalog copies
copy_file "${OUTPUT_DIR}/personas/catalog.json" "${OUTPUT_DIR}/index.json"
copy_file "${OUTPUT_DIR}/personas/catalog.json" "${OUTPUT_DIR}/personas.json"
copy_file "${OUTPUT_DIR}/scenarios/catalog.json" "${OUTPUT_DIR}/scenarios/index.json"
copy_file "${OUTPUT_DIR}/scenarios/catalog.json" "${OUTPUT_DIR}/scenarios.json"

# Landing page markdown
{
  cat "${REPO_ROOT}/AGENTS.md"
  echo
  echo "## Personas"
  for persona_path in "${REPO_ROOT}"/personas/*.md; do
    persona_name="$(basename "${persona_path}")"
    echo "- [${persona_name%.*}](personas/${persona_name})"
  done
  echo
  echo "## Scenarios"
  for scenario_path in "${REPO_ROOT}"/scenarios/*.md; do
    scenario_name="$(basename "${scenario_path}")"
    echo "- [${scenario_name%.*}](scenarios/${scenario_name})"
  done
  echo
  cat "${REPO_ROOT}/docs/INSTRUCTIONS.md"
} > "${OUTPUT_DIR}/index.md"

# Disable Jekyll processing
: > "${OUTPUT_DIR}/.nojekyll"
