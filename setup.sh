#!/usr/bin/env bash
# scripts/setup.sh
# Persistent auth для GitHub CLI в init-окне с секретом. Не зависит от gh auth status.
# Делает:
# - ставит gh при необходимости
# - сохраняет токен в ~/.config/gh/hosts.yml
# - настраивает git на использование gh auth git-credential
# - проверяет, что gh видит токен уже без GH_TOKEN в окружении

set -Eeuo pipefail
trap 'rc=$?; echo -e "\n!! setup failed at line $LINENO while running: $BASH_COMMAND (exit $rc)" >&2; exit $rc' ERR

SCRIPT_PATH="${BASH_SOURCE[0]-}"
SCRIPT_SOURCE_IS_STDIN=0
if [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" != "-" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  cd "$SCRIPT_DIR"
else
  SCRIPT_DIR="$(pwd)"
  SCRIPT_SOURCE_IS_STDIN=1
fi

# вход
: "${GH_TOKEN:?GH_TOKEN is missing}"
GH_HOST="${GH_HOST:-github.com}"
CHECK_REPO="${CHECK_REPO:-}"   # optional owner/repo to verify access

# basic environment
export HOME="${HOME:-/root}"
mkdir -p "$HOME" "$HOME/.local/bin" "$HOME/.cargo/bin"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export GH_NO_UPDATE_NOTIFIER=1
export GH_PAGER=cat
export PAGER=cat
export GIT_TERMINAL_PROMPT=0

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
  dest_abs="$SCRIPT_DIR/$dest_path"
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

MCP_BASE_URL="${MCP_BASE_URL:-https://qqrm.github.io/avatars-mcp}"
AVATAR_DIR="${AVATAR_DIR:-avatars}"
BASE_FILE="${BASE_FILE:-BASE_AGENTS.md}"
INDEX_PATH="${INDEX_PATH:-$AVATAR_DIR/index.json}"
export MCP_BASE_URL AVATAR_DIR BASE_FILE INDEX_PATH

sync_mcp_resources() {
  command -v curl >/dev/null 2>&1 || die "curl is required"
  command -v python3 >/dev/null 2>&1 || die "python3 is required"
  command -v cmp >/dev/null 2>&1 || die "cmp is required"

  validate_relative "$AVATAR_DIR"
  validate_relative "$BASE_FILE"
  validate_relative "$INDEX_PATH"

  local total=0
  local updated=0

  if [[ "$(download_file "$BASE_FILE" "$BASE_FILE")" == "1" ]]; then
    updated=$((updated + 1))
  fi
  total=$((total + 1))

  if [[ "$(download_file "$INDEX_PATH" "$INDEX_PATH")" == "1" ]]; then
    updated=$((updated + 1))
  fi
  total=$((total + 1))

  mapfile -t avatar_paths < <(list_avatar_paths "$SCRIPT_DIR/$INDEX_PATH")

  local avatar_path
  for avatar_path in "${avatar_paths[@]}"; do
    validate_relative "$avatar_path"
    if [[ "$(download_file "$avatar_path" "$avatar_path")" == "1" ]]; then
      updated=$((updated + 1))
    fi
    total=$((total + 1))
  done

  log "Synced ${total} files (${updated} updated, $((total - updated)) unchanged) from ${MCP_BASE_URL%/}"
}

# ensure mcp.json exists
if [ ! -f mcp.json ]; then
  if curl -fsSL https://qqrm.github.io/avatars-mcp/mcp.json -o mcp.json; then
    log "mcp.json created"
  else
    log "mcp.json unavailable"
  fi
else
  log "mcp.json already exists"
fi

sync_mcp_resources

if [ ! -f AGENTS.md ]; then
  if [ -f "$BASE_FILE" ]; then
    cp "$BASE_FILE" AGENTS.md
    log "AGENTS.md created from ${BASE_FILE}"
  else
    log "${BASE_FILE} missing; skipping AGENTS.md creation"
  fi
else
  log "AGENTS.md already exists"
fi

# gh installation if missing
gh_ok() { gh --version >/dev/null 2>&1; }

# cargo-binstall installation if missing
cargo_binstall_ok() { command -v cargo-binstall >/dev/null 2>&1; }

install_cargo_binstall() {
  local arch target url tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64) target="x86_64-unknown-linux-gnu" ;;
    aarch64) target="aarch64-unknown-linux-gnu" ;;
    *) die "Unsupported arch: $arch" ;;
  esac
  url="https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-${target}.tgz"
  tmp="$(mktemp -t cargo-binstall.tgz.XXXXXX)"
  curl -fsSL "$url" -o "$tmp"
  tar -C "$HOME/.cargo/bin" -xzf "$tmp" cargo-binstall
  rm -f "$tmp"
}

install_gh_tarball() {
  local arch tarch ver url tmp sudo_cmd
  arch="$(uname -m)"
  case "$arch" in
    x86_64) tarch="amd64" ;;
    aarch64) tarch="arm64" ;;
    *) die "Unsupported arch: $arch" ;;
  esac
  ver="2.56.0"
  url="https://github.com/cli/cli/releases/download/v${ver}/gh_${ver}_linux_${tarch}.tar.gz"
  tmp="$(mktemp -t gh.tgz.XXXXXX)"
  curl -fsSL "$url" -o "$tmp"
  if command -v sudo >/dev/null 2>&1; then
    sudo tar -C /usr/local -xzf "$tmp"
    sudo ln -sf "/usr/local/gh_${ver}_linux_${tarch}/bin/gh" /usr/local/bin/gh
  else
    tar -C "$HOME/.local" -xzf "$tmp"
    ln -sf "$HOME/.local/gh_${ver}_linux_${tarch}/bin/gh" "$HOME/.local/bin/gh"
  fi
  rm -f "$tmp"
}

if ! gh_ok; then
  log "Installing gh via tarball"
  install_gh_tarball
fi
gh_ok || die "gh is not operational"

log "gh version: $(gh --version | head -n1)"

# install cargo-machete using cargo-binstall
if ! cargo_binstall_ok; then
  log "Installing cargo-binstall"
  install_cargo_binstall
fi
cargo_binstall_ok || die "cargo-binstall is not operational"

if ! command -v cargo-machete >/dev/null 2>&1; then
  log "Installing cargo-machete via cargo-binstall"
  cargo binstall cargo-machete -y --quiet --disable-strategies compile
fi
command -v cargo-machete >/dev/null 2>&1 || die "cargo-machete installation failed"

# install wrkflw using cargo-binstall with tarball fallback
if ! command -v wrkflw >/dev/null 2>&1; then
  log "Installing wrkflw via cargo-binstall"
  if ! cargo binstall wrkflw@0.7.0 -y --quiet --disable-strategies compile; then
    log "Falling back to wrkflw tarball"
    arch="$(uname -m)"
    case "$arch" in
      x86_64) tarch="x86_64" ;;
      *) die "Unsupported arch for wrkflw tarball: $arch" ;;
    esac
    tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/bahdotsh/wrkflw/releases/download/v0.7.0/wrkflw-v0.7.0-linux-${tarch}.tar.gz" \
      | tar -xz -C "$tmp"
    install -m 755 "$tmp/wrkflw" "$HOME/.cargo/bin/"
    rm -rf "$tmp"
  fi
fi
command -v wrkflw >/dev/null 2>&1 || die "wrkflw installation failed"

# install Rust documentation MCP servers
for mcp_pkg in crates-mcp; do
  if ! command -v "$mcp_pkg" >/dev/null 2>&1; then
    log "Installing $mcp_pkg via cargo-binstall"
    cargo binstall "$mcp_pkg" -y --quiet
  fi
  command -v "$mcp_pkg" >/dev/null 2>&1 || die "$mcp_pkg installation failed"
done

# пробуем узнать login, если токен разрешает, иначе оставим unknown
user_login="unknown"
if GH_TOKEN="$GH_TOKEN" gh api /user -q .login >/dev/null 2>&1; then
  user_login="$(GH_TOKEN="$GH_TOKEN" gh api /user -q .login)"
fi

# записываем hosts.yml напрямую, не полагаясь на gh auth login
cfg_root="${XDG_CONFIG_HOME:-$HOME/.config}"
cfg_dir="$cfg_root/gh"
hosts="$cfg_dir/hosts.yml"
mkdir -p "$cfg_dir"
umask 077

# важно: не светим токен в трассировке
set +x
cat > "$hosts" <<EOF
$GH_HOST:
    user: $user_login
    oauth_token: $GH_TOKEN
    git_protocol: https
EOF
set -x

chmod 600 "$hosts" 2>/dev/null || true

# настраиваем git под gh helper
if [[ "$(git config --global credential.helper || true)" != '!gh auth git-credential' ]]; then
  git config --global credential.helper '!gh auth git-credential'
fi
if ! git config --global --get-all url."https://github.com/".insteadof | grep -q '^git@github.com:$'; then
  git config --global url."https://github.com/".insteadOf git@github.com:
fi

# очищаем следы секрета из окружения
unset GH_TOKEN

# проверка что gh теперь использует сохраненный токен без GH_TOKEN
log "Validating saved auth using hosts.yml"
if env -u GH_TOKEN gh api -H "Accept: application/vnd.github+json" /rate_limit >/dev/null 2>&1; then
  log "rate_limit ok"
else
  die "saved auth failed, hosts.yml not picked up"
fi

if [[ -n "$CHECK_REPO" ]]; then
  if env -u GH_TOKEN gh api "/repos/${CHECK_REPO}" -q .full_name >/dev/null 2>&1; then
    log "repo access ok: $CHECK_REPO"
  else
    die "no access to $CHECK_REPO with saved token"
  fi
fi

# краткая подсказка
log "Auth persisted. Example checks without GH_TOKEN:"
log "  env -u GH_TOKEN gh repo view cli/cli --json name,description | jq"
log "  env -u GH_TOKEN gh run list -R ${CHECK_REPO:-owner/repo} -L 5 || true"

# run repository-specific setup if available
if [ -f repo-setup.sh ]; then
  log "Executing repo-setup.sh"
  bash repo-setup.sh
fi

log "setup completed"
