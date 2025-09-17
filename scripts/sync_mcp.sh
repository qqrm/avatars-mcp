#!/usr/bin/env bash
# Synchronize published MCP assets locally using only shell tooling.
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

log() { printf '>> %s\n' "$*"; }
die() { printf '❌ %s\n' "$*" >&2; exit 1; }

validate_relative() {
  local path="$1"
  if [[ -z "$path" ]]; then
    die "Path must not be empty"
  fi
  if [[ "$path" == /* ]]; then
    die "Path '$path' must be relative"
  fi
  local IFS='/'
  read -ra segments <<<"$path"
  for segment in "${segments[@]}"; do
    case "$segment" in
      ''|'.') continue ;;
      '..') die "Path '$path' must not contain parent directory segments" ;;
    esac
  done
}

build_url() {
  local base="$1" rel="$2"
  local trimmed_base="${base%/}"
  local cleaned_rel="${rel#./}"
  if [[ -z "$cleaned_rel" ]]; then
    printf '%s' "$trimmed_base"
  else
    printf '%s/%s' "$trimmed_base" "$cleaned_rel"
  fi
}

download_file() {
  local remote_path="$1" dest_path="$2"
  validate_relative "$remote_path"
  validate_relative "$dest_path"

  local url tmp dest_abs dest_dir
  url="$(build_url "$MCP_BASE_URL" "$remote_path")"
  dest_abs="$REPO_ROOT/$dest_path"
  dest_dir="$(dirname "$dest_abs")"
  mkdir -p "$dest_dir"

  tmp="$(mktemp -p "${TMPDIR:-/tmp}" sync_mcp.XXXXXX)"
  if ! curl -fsSL "$url" -o "$tmp"; then
    rm -f "$tmp"
    die "Failed to download $url"
  fi

  local changed=0
  if [[ -f "$dest_abs" ]] && cmp -s "$tmp" "$dest_abs"; then
    rm -f "$tmp"
  else
    mv "$tmp" "$dest_abs"
    changed=1
  fi

  printf '%s' "$changed"
}

list_avatar_paths() {
  local index_file="$1"
  python3 - "$index_file" <<'PY'
import json
import sys
from pathlib import Path

index_path = Path(sys.argv[1])
with index_path.open('r', encoding='utf-8') as handle:
    data = json.load(handle)
for entry in data.get('avatars', []):
    uri = entry.get('uri')
    if isinstance(uri, str):
        value = uri.strip()
        if value:
            print(value)
PY
}

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v python3 >/dev/null 2>&1 || die "python3 is required"
command -v cmp >/dev/null 2>&1 || die "cmp is required"

MCP_BASE_URL="${MCP_BASE_URL:-https://qqrm.github.io/avatars-mcp}"
AVATAR_DIR="${AVATAR_DIR:-avatars}"
BASE_FILE="${BASE_FILE:-BASE_AGENTS.md}"
INDEX_PATH="${INDEX_PATH:-$AVATAR_DIR/index.json}"

validate_relative "$AVATAR_DIR"
validate_relative "$BASE_FILE"
validate_relative "$INDEX_PATH"

total=0
updated=0

if [[ "$(download_file "$BASE_FILE" "$BASE_FILE")" == "1" ]]; then
  updated=$((updated + 1))
fi
total=$((total + 1))

if [[ "$(download_file "$INDEX_PATH" "$INDEX_PATH")" == "1" ]]; then
  updated=$((updated + 1))
fi
total=$((total + 1))

mapfile -t avatar_paths < <(list_avatar_paths "$INDEX_PATH")

for avatar_path in "${avatar_paths[@]}"; do
  validate_relative "$avatar_path"
  if [[ "$(download_file "$avatar_path" "$avatar_path")" == "1" ]]; then
    updated=$((updated + 1))
  fi
  total=$((total + 1))
done

log "Synced ${total} files (${updated} updated, $((total - updated)) unchanged) from ${MCP_BASE_URL%/}"
