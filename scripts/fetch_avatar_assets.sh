#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="https://qqrm.github.io/avatars-mcp"
AVATAR_JSON="${1:-/tmp/avatars.json}"
GUIDELINES_MD="${2:-/tmp/avatar_guidelines.md}"
MAX_ATTEMPTS=5
SLEEP_SECONDS=10

PRIMARY_CATALOG_URL="${BASE_URL}/avatars.json"
LEGACY_CATALOG_URL="${BASE_URL}/avatars/index.json"
GUIDELINES_URL="${BASE_URL}/README.md"

FETCH_ERROR=""
CATALOG_SOURCE=""
CATALOG_WARNING=""

fetch() {
  local url="$1"
  local destination="$2"

  local http_code
  http_code=$(curl --silent --show-error --location --output "$destination" --write-out '%{http_code}' "$url" || true)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    rm -f "$destination"
    local code_msg=""
    if [[ $http_code =~ ^[0-9]{3}$ && $http_code != "000" ]]; then
      code_msg=" (HTTP ${http_code})"
    fi
    FETCH_ERROR="curl exit ${exit_code}${code_msg} (${url})"
    return 1
  fi

  if [[ ! $http_code =~ ^[0-9]{3}$ ]]; then
    FETCH_ERROR="Unexpected response code '${http_code}' (${url})"
    return 1
  fi

  if [[ $http_code -lt 200 || $http_code -ge 300 ]]; then
    rm -f "$destination"
    FETCH_ERROR="HTTP ${http_code} (${url})"
    return 1
  fi

  FETCH_ERROR=""
  return 0
}

download_catalog() {
  if fetch "$PRIMARY_CATALOG_URL" "$AVATAR_JSON"; then
    CATALOG_SOURCE="primary"
    CATALOG_WARNING=""
    return 0
  fi

  local primary_error="$FETCH_ERROR"

  if fetch "$LEGACY_CATALOG_URL" "$AVATAR_JSON"; then
    CATALOG_SOURCE="legacy"
    CATALOG_WARNING="Primary catalog unavailable: ${primary_error}"
    return 0
  fi

  local legacy_error="$FETCH_ERROR"
  FETCH_ERROR="Primary catalog unavailable: ${primary_error}; legacy catalog unavailable: ${legacy_error}"
  CATALOG_SOURCE=""
  CATALOG_WARNING=""
  return 1
}

download_guidelines() {
  if fetch "$GUIDELINES_URL" "$GUIDELINES_MD"; then
    return 0
  fi

  FETCH_ERROR="Guidelines download failed: ${FETCH_ERROR}"
  return 1
}

attempt=1
while (( attempt <= MAX_ATTEMPTS )); do
  if download_catalog && download_guidelines; then
    if [[ -n "$CATALOG_WARNING" ]]; then
      printf '%s\n' "$CATALOG_WARNING" >&2
    fi
    if [[ "$CATALOG_SOURCE" == "legacy" ]]; then
      printf 'Fetched avatar data on attempt %d using the legacy endpoint.\n' "$attempt"
    else
      printf 'Fetched avatar data on attempt %d.\n' "$attempt"
    fi
    exit 0
  fi

  if (( attempt < MAX_ATTEMPTS )); then
    printf 'Attempt %d failed: %s. Retrying in %d seconds...\n' "$attempt" "$FETCH_ERROR" "$SLEEP_SECONDS" >&2
  else
    printf 'Attempt %d failed: %s.\n' "$attempt" "$FETCH_ERROR" >&2
  fi
  attempt=$(( attempt + 1 ))
  if (( attempt <= MAX_ATTEMPTS )); then
    sleep "$SLEEP_SECONDS"
  fi
  FETCH_ERROR=""
  CATALOG_SOURCE=""
  CATALOG_WARNING=""
  rm -f "$AVATAR_JSON" "$GUIDELINES_MD"
done

printf 'Failed to download avatar resources after %d attempts.\n' "$MAX_ATTEMPTS" >&2
exit 1
