#!/usr/bin/env bash
# init-container.sh
# Prepare the development container with one-time tooling installations and
# auth persistence.

set -Eeuo pipefail
trap 'rc=$?; echo -e "\n!! init-container failed at line $LINENO while running: $BASH_COMMAND (exit $rc)" >&2; exit $rc' ERR

SCRIPT_PATH="${BASH_SOURCE[0]-}"
SCRIPT_SOURCE_IS_STDIN=0
if [[ -n "$SCRIPT_PATH" && "$SCRIPT_PATH" != "-" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  cd "$SCRIPT_DIR"
else
  SCRIPT_DIR="$(pwd)"
  SCRIPT_SOURCE_IS_STDIN=1
fi

: "${GH_TOKEN:?GH_TOKEN is missing}"
GH_HOST="${GH_HOST:-github.com}"
CHECK_REPO="${CHECK_REPO:-}"

export HOME="${HOME:-/root}"
mkdir -p "$HOME" "$HOME/.local/bin" "$HOME/.cargo/bin"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export GH_NO_UPDATE_NOTIFIER=1
export GH_PAGER=cat
export PAGER=cat
export GIT_TERMINAL_PROMPT=0

log() { printf '>> %s\n' "$*"; }
die() { printf '❌ %s\n' "$*" >&2; exit 1; }

MCP_BASE_URL="${MCP_BASE_URL:-https://qqrm.github.io/avatars-mcp}"
export MCP_BASE_URL

gh_ok() { gh --version >/dev/null 2>&1; }
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

for mcp_pkg in crates-mcp; do
  if ! command -v "$mcp_pkg" >/dev/null 2>&1; then
    log "Installing $mcp_pkg via cargo-binstall"
    cargo binstall "$mcp_pkg" -y --quiet
  fi
  command -v "$mcp_pkg" >/dev/null 2>&1 || die "$mcp_pkg installation failed"
done

user_login="unknown"
if GH_TOKEN="$GH_TOKEN" gh api /user -q .login >/dev/null 2>&1; then
  user_login="$(GH_TOKEN="$GH_TOKEN" gh api /user -q .login)"
fi

cfg_root="${XDG_CONFIG_HOME:-$HOME/.config}"
cfg_dir="$cfg_root/gh"
hosts="$cfg_dir/hosts.yml"
mkdir -p "$cfg_dir"
umask 077

set +x
cat > "$hosts" <<EOF_INNER
$GH_HOST:
    user: $user_login
    oauth_token: $GH_TOKEN
    git_protocol: https
EOF_INNER
set -x

chmod 600 "$hosts" 2>/dev/null || true

if [[ "$(git config --global credential.helper || true)" != '!gh auth git-credential' ]]; then
  git config --global credential.helper '!gh auth git-credential'
fi
if ! git config --global --get-all url."https://github.com/".insteadof | grep -q '^git@github.com:$'; then
  git config --global url."https://github.com/".insteadOf git@github.com:
fi

unset GH_TOKEN

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

log "Auth persisted. Example checks without GH_TOKEN:"
log "  env -u GH_TOKEN gh repo view cli/cli --json name,description | jq"
log "  env -u GH_TOKEN gh run list -R ${CHECK_REPO:-owner/repo} -L 5 || true"

set +x
log "Container initialization complete. Run ./pre-task.sh before starting work on each task."
