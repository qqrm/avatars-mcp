# Repository Agent Instructions

These instructions extend the base `AGENTS.md` rules for the entire repository.

## Critical Checklist
- Run `./repo-setup.sh` before making changes so the canonical `origin` remote is configured automatically.
- After setup, verify `git remote -v` and `gh auth status`, then continue only if both confirm a working GitHub connection.
- Leave the bootstrap `work` branch immediately, create a descriptive feature branch, and avoid any branch named `WORK`.
- Use the `gh` CLI to open the pull request for this repository and wait for GitHub Actions checks to turn green before reporting completion.

## Mandatory Setup
- Before modifying the repository, execute `./repo-setup.sh` from the repository root. The script configures the canonical `origin` remote automatically when it is missing or incorrect.
- After the setup script succeeds, record the current date and time in your session notes so future attempts know the environment is ready.
- Double-check `git remote -v` once the script finishes; the `origin` remote must point to `https://github.com/qqrm/avatars-mcp.git`.
- Run `gh auth status` immediately after setup to confirm credentials are valid; capture the full output when authentication fails.
- If any setup step fails, capture the full command output, diagnose the cause, and propose a fix or workaround.

## Branch Management and Pull Requests
This repository relies on the global branching, pull-request, and conflict-resolution process defined in `AGENTS.md` (including `AUTO_CONFLICT_STRATEGY.md`). Follow those universal rules here, then apply the repository-specific setup and automation practices described above.
