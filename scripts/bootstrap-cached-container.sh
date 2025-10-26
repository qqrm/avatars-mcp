#!/usr/bin/env bash
# Initialize a cached development container with persisted GitHub CLI auth.
#
# The script is self-contained and installs every dependency without sourcing
# auxiliary libraries.

set -Eeuo pipefail
trap 'rc=$?; echo -e "\n!! bootstrap-cached-container failed at line $LINENO while running: $BASH_COMMAND (exit $rc)" >&2; exit $rc' ERR

bootstrap_log() {
  printf '>> %s\n' "$*"
}

bootstrap_die() {
  printf '❌ %s\n' "$*" >&2
  exit 1
}

bootstrap_require_env() {
  local missing=0
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      printf 'Missing required environment variable: %s\n' "$var" >&2
      missing=1
    fi
  done
  if [[ "$missing" -eq 1 ]]; then
    exit 1
  fi
}

bootstrap_prepare_paths() {
  export HOME="${HOME:-/root}"
  mkdir -p "$HOME" "$HOME/.local/bin" "$HOME/.cargo/bin"
  export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
  export GH_NO_UPDATE_NOTIFIER=1
  export GH_PAGER=cat
  export PAGER=cat
  export GIT_TERMINAL_PROMPT=0
}

bootstrap_install_gh_tarball() {
  local arch tarch ver url tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64) tarch="amd64" ;;
    aarch64) tarch="arm64" ;;
    *) bootstrap_die "Unsupported arch: $arch" ;;
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

bootstrap_ensure_gh_cli() {
  if ! command -v gh >/dev/null 2>&1; then
    bootstrap_log "Installing gh via tarball"
    bootstrap_install_gh_tarball
  fi

  command -v gh >/dev/null 2>&1 || bootstrap_die "gh is not operational"
  bootstrap_log "gh version: $(gh --version | head -n1)"
}

bootstrap_install_rustup() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile minimal --default-toolchain stable
}

bootstrap_ensure_rust_toolchain() {
  if ! command -v rustup >/dev/null 2>&1; then
    bootstrap_log "Installing rustup and the latest stable Rust toolchain"
    bootstrap_install_rustup
  fi

  command -v rustup >/dev/null 2>&1 || bootstrap_die "rustup installation failed"

  bootstrap_log "Updating Rust toolchain to the latest stable release"
  rustup update stable >/dev/null
  rustup default stable >/dev/null
  rustup component add --toolchain stable rustfmt clippy >/dev/null
  bootstrap_log "rustc version: $(rustc --version | head -n1)"
}

bootstrap_install_cargo_binstall() {
  local arch target url tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64) target="x86_64-unknown-linux-gnu" ;;
    aarch64) target="aarch64-unknown-linux-gnu" ;;
    *) bootstrap_die "Unsupported arch: $arch" ;;
  esac

  url="https://github.com/cargo-bins/cargo-binstall/releases/latest/download/cargo-binstall-${target}.tgz"
  tmp="$(mktemp -t cargo-binstall.tgz.XXXXXX)"
  curl -fsSL "$url" -o "$tmp"
  tar -C "$HOME/.cargo/bin" -xzf "$tmp" cargo-binstall
  rm -f "$tmp"
}

bootstrap_ensure_cargo_binstall() {
  if ! command -v cargo-binstall >/dev/null 2>&1; then
    bootstrap_log "Installing cargo-binstall"
    bootstrap_install_cargo_binstall
  fi

  command -v cargo-binstall >/dev/null 2>&1 || bootstrap_die "cargo-binstall is not operational"
}

bootstrap_install_wrkflw_tarball() {
  local arch tarch tmp
  arch="$(uname -m)"
  case "$arch" in
    x86_64) tarch="x86_64" ;;
    *) bootstrap_die "Unsupported arch for wrkflw tarball: $arch" ;;
  esac

  tmp="$(mktemp -d)"
  curl -fsSL "https://github.com/bahdotsh/wrkflw/releases/download/v0.7.0/wrkflw-v0.7.0-linux-${tarch}.tar.gz" \
    | tar -xz -C "$tmp"
  install -m 755 "$tmp/wrkflw" "$HOME/.cargo/bin/"
  rm -rf "$tmp"
}

bootstrap_ensure_dev_tools() {
  if ! command -v cargo-machete >/dev/null 2>&1; then
    bootstrap_log "Installing cargo-machete via cargo-binstall"
    cargo binstall cargo-machete -y --quiet --disable-strategies compile
  fi
  command -v cargo-machete >/dev/null 2>&1 || bootstrap_die "cargo-machete installation failed"

  if ! command -v wrkflw >/dev/null 2>&1; then
    bootstrap_log "Installing wrkflw via cargo-binstall"
    if ! cargo binstall wrkflw@0.7.0 -y --quiet --disable-strategies compile; then
      bootstrap_log "Falling back to wrkflw tarball"
      bootstrap_install_wrkflw_tarball
    fi
  fi
  command -v wrkflw >/dev/null 2>&1 || bootstrap_die "wrkflw installation failed"
}

bootstrap_persist_gh_auth() {
  bootstrap_require_env GH_TOKEN

  local gh_host user_login cfg_root cfg_dir hosts
  gh_host="${GH_HOST:-github.com}"
  user_login="unknown"
  if GH_TOKEN="$GH_TOKEN" gh api /user -q .login >/dev/null 2>&1; then
    user_login="$(GH_TOKEN="$GH_TOKEN" gh api /user -q .login)"
  fi

  cfg_root="${XDG_CONFIG_HOME:-$HOME/.config}"
  cfg_dir="$cfg_root/gh"
  hosts="$cfg_dir/hosts.yml"
  mkdir -p "$cfg_dir"
  umask 077

  cat >"$hosts" <<EOF_AUTH
$gh_host:
  user: $user_login
  oauth_token: $GH_TOKEN
  git_protocol: https
EOF_AUTH

  chmod 600 "$hosts" 2>/dev/null || true

  if [[ "$(git config --global credential.helper || true)" != '!gh auth git-credential' ]]; then
    git config --global credential.helper '!gh auth git-credential'
  fi

  if ! git config --global --get-all url."https://github.com/".insteadOf | grep -q '^git@github.com:$'; then
    git config --global url."https://github.com/".insteadOf git@github.com:
  fi
}

bootstrap_validate_saved_auth() {
  local gh_host cfg_root hosts_file
  gh_host="${GH_HOST:-github.com}"
  cfg_root="${XDG_CONFIG_HOME:-$HOME/.config}"
  hosts_file="$cfg_root/gh/hosts.yml"

  if [[ ! -f "$hosts_file" ]]; then
    bootstrap_die "saved auth failed: ${hosts_file} is missing"
  fi

  if ! env -u GH_TOKEN gh auth status -h "$gh_host"; then
    bootstrap_die "GitHub CLI could not use the persisted token; provide a valid GH_TOKEN"
  fi

  if env -u GH_TOKEN gh api -H "Accept: application/vnd.github+json" /rate_limit >/dev/null 2>&1; then
    bootstrap_log "rate_limit ok"
  else
    bootstrap_die "GitHub API validation failed after persisting auth; verify network access and GH_TOKEN scopes"
  fi
}

bootstrap_validate_repo_access() {
  local repo="$1"
  if [[ -z "$repo" ]]; then
    return
  fi

  if env -u GH_TOKEN gh api "/repos/${repo}" -q .full_name >/dev/null 2>&1; then
    bootstrap_log "repo access ok: $repo"
  else
    bootstrap_die "no access to $repo with saved token"
  fi
}

bootstrap_ensure_codex_cleanup_workflow() {
  if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    bootstrap_log "Skipping Codex cleanup bootstrap: not inside a Git repository."
    return
  fi

  local repo_root dest canonical_url tmp
  repo_root="$(git rev-parse --show-toplevel)"
  dest="${repo_root}/.github/workflows/codex-cleanup.yml"

  if [[ -f "$dest" ]]; then
    bootstrap_log "Codex Branch Cleanup workflow already present at .github/workflows/codex-cleanup.yml."
    return
  fi

  canonical_url="https://qqrm.github.io/codex-tools/workflows/codex-cleanup.yml"
  tmp="${dest}.tmp"
  mkdir -p "$(dirname "$dest")"

  if curl -fsSL "$canonical_url" -o "$tmp"; then
    mv "$tmp" "$dest"
    bootstrap_log "Installed Codex Branch Cleanup workflow from ${canonical_url}."
  else
    rm -f "$tmp"
    bootstrap_log "Unable to install Codex Branch Cleanup workflow from ${canonical_url}."
  fi
}

bootstrap_refresh_pages_asset() {
  local url="$1"
  local dest="$2"
  local tmp

  tmp="${dest}.tmp"
  if curl -fsSL "$url" -o "$tmp"; then
    mv "$tmp" "$dest"
    bootstrap_log "Updated $(basename "$dest") from $url"
  else
    rm -f "$tmp"
    bootstrap_log "Unable to refresh $(basename "$dest") from $url"
  fi
}

bootstrap_run_repo_setup() {
  local script_path="scripts/repo-setup.sh"

  if [[ -f "$script_path" ]]; then
    bootstrap_log "Executing ${script_path}"
    bash "$script_path"
  else
    bootstrap_log "Skipping repository setup (scripts/repo-setup.sh not found)"
  fi
}

bootstrap_log "Performing cached container bootstrap"
bootstrap_require_env GH_TOKEN
: "${GH_HOST:=github.com}"
CHECK_REPO="${CHECK_REPO:-}"
PAGES_BASE_URL="${PAGES_BASE_URL:-https://qqrm.github.io/codex-tools}"
AGENTS_URL="${PAGES_BASE_URL%/}/AGENTS.md"

bootstrap_prepare_paths
bootstrap_ensure_gh_cli
bootstrap_ensure_rust_toolchain
bootstrap_ensure_cargo_binstall
bootstrap_ensure_dev_tools
bootstrap_persist_gh_auth
bootstrap_validate_saved_auth
bootstrap_validate_repo_access "$CHECK_REPO"
unset GH_TOKEN

bootstrap_ensure_codex_cleanup_workflow
bootstrap_refresh_pages_asset "$AGENTS_URL" "AGENTS.md"
bootstrap_run_repo_setup

bootstrap_log "Cached container bootstrap complete."
