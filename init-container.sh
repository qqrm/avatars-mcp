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
with_privilege() {
  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

CANONICAL_CLEANUP_PATH=".github/workflows/codex-cleanup.yml"

gh_ok() { gh --version >/dev/null 2>&1; }
cargo_binstall_ok() { command -v cargo-binstall >/dev/null 2>&1; }
docker_ok() { command -v docker >/dev/null 2>&1; }
rustup_ok() { command -v rustup >/dev/null 2>&1; }

install_rustup() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile minimal --default-toolchain stable
}

ensure_rust_toolchain() {
  if ! rustup_ok; then
    log "Installing rustup and the latest stable Rust toolchain"
    install_rustup
  fi

  rustup_ok || die "rustup installation failed"

  log "Updating Rust toolchain to the latest stable release"
  rustup update stable >/dev/null
  rustup default stable >/dev/null
  rustup component add --toolchain stable rustfmt clippy >/dev/null
  log "rustc version: $(rustc --version | head -n1)"
}

ensure_codex_cleanup_workflow() {
  local repo_root dest canonical_url tmp
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    log "Skipping Codex cleanup bootstrap: not inside a Git repository."
    return
  fi

  repo_root="$(git rev-parse --show-toplevel)"
  dest="${repo_root}/${CANONICAL_CLEANUP_PATH}"

  if [[ -f "$dest" ]]; then
    log "Codex Branch Cleanup workflow already present at ${CANONICAL_CLEANUP_PATH}."
    return
  fi

  canonical_url="https://qqrm.github.io/avatars-mcp/workflows/codex-cleanup.yml"
  tmp="${dest}.tmp"
  mkdir -p "$(dirname "$dest")"

  if curl -fsSL "$canonical_url" -o "$tmp"; then
    mv "$tmp" "$dest"
    log "Installed Codex Branch Cleanup workflow from ${canonical_url}."
  else
    rm -f "$tmp"
    log "Unable to install Codex Branch Cleanup workflow from ${canonical_url}."
  fi
}

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

ensure_rust_toolchain

install_docker() {
  local pkg_manager=""
  if docker_ok; then
    log "docker version: $(docker --version | head -n1)"
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    pkg_manager="apt-get"
    log "Installing Docker via apt-get"
    with_privilege env DEBIAN_FRONTEND=noninteractive apt-get update
    with_privilege env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends docker.io
  elif command -v dnf >/dev/null 2>&1; then
    pkg_manager="dnf"
    log "Installing Docker via dnf"
    with_privilege dnf install -y docker
  elif command -v yum >/dev/null 2>&1; then
    pkg_manager="yum"
    log "Installing Docker via yum"
    with_privilege yum install -y docker
  elif command -v zypper >/dev/null 2>&1; then
    pkg_manager="zypper"
    log "Installing Docker via zypper"
    with_privilege zypper install -y docker
  else
    log "Skipping Docker installation: no supported package manager found"
  fi

  if docker_ok; then
    log "docker version: $(docker --version | head -n1)"
  elif [[ -n "$pkg_manager" ]]; then
    die "Docker installation via $pkg_manager reported success but docker command is missing"
  fi
}

install_docker

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

ensure_codex_cleanup_workflow

log "Auth persisted. Example checks without GH_TOKEN:"
log "  env -u GH_TOKEN gh repo view cli/cli --json name,description | jq"
log "  env -u GH_TOKEN gh run list -R ${CHECK_REPO:-owner/repo} -L 5 || true"

set +x
log "Container initialization complete. Run ./pre-task.sh before starting work on each task."
