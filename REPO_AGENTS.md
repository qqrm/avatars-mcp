# Repository Agent Instructions

These instructions extend the base `AGENTS.md` rules for the entire repository.

## Critical Checklist
- Run `./repo-setup.sh` before making changes so the canonical `origin` remote is configured automatically.
- After setup, verify `git remote -v` and `gh auth status`, then continue only if both confirm a working GitHub connection.
- Leave the bootstrap `work` branch immediately, create a descriptive feature branch, and avoid any branch named `WORK`.
- Use the `gh` CLI to inspect branch protection, required status checks, and the latest workflow runs. Mirror those checks locally before reporting completion.
- Whenever you modify an `AGENTS.md` file, regenerate the avatar catalog (for example with `cargo run -p avatars-cli --release`) and confirm `avatars/catalog.json` reflects the change before handing off the branch.

## Mandatory Setup
- Before modifying the repository, execute `./repo-setup.sh` from the repository root. The script configures the canonical `origin` remote automatically when it is missing or incorrect.
- After the setup script succeeds, record the current date and time in your session notes so future attempts know the environment is ready.
- Double-check `git remote -v` once the script finishes; the `origin` remote must point to `https://github.com/qqrm/avatars-mcp.git`.
- Run `gh auth status` immediately after setup to confirm credentials are valid; capture the full output when authentication fails.
- If any setup step fails, capture the full command output, diagnose the cause, and propose a fix or workaround.

## Branch Management and Handoff
This repository follows the global branching guidance in `AGENTS.md`. Push every commit to the same feature branch, reproduce the required checks locally, and hand the branch to maintainers so they can open the pull request manually via Codex.
