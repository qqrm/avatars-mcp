# Repository Agent Instructions

These instructions extend the base `AGENTS.md` rules for the entire repository.

## Mandatory Setup
- Before modifying the repository, execute `./repo-setup.sh` from the repository root. The script configures the canonical `origin` remote automatically when it is missing or incorrect.
- After the setup script succeeds, record the current date and time in your session notes so future attempts know the environment is ready.
- Double-check `git remote -v` once the script finishes; the `origin` remote must point to `https://github.com/qqrm/avatars-mcp.git`.
- Run `gh auth status` immediately after setup to confirm credentials are valid; capture the full output when authentication fails.
- If any setup step fails, capture the full command output, diagnose the cause, and propose a fix or workaround.

## Avatar Retrieval Workflow
- Use `scripts/fetch_avatar_assets.sh` (or an equivalent helper) before coding to download `avatars.json` and `README.md` from `https://qqrm.github.io/avatars-mcp/`. Capture detailed HTTP errors whenever a download fails so outages can be triaged quickly.
- The helper must try up to five times with a 5–10 second pause between attempts. Record any HTTP status codes or curl errors if every attempt fails.
- When the downloads succeed, pick an avatar for the task, document the reason for the choice, and include this explanation in both the pull-request description and the final response to the user.
- If asset retrieval is impossible, log the attempts, escalate the outage, and continue with the best-matching avatar based on cached knowledge.

## Repository Validation
- Run the Rust test suite from the repository root (`cargo test`) before opening a pull request so the CLI that publishes the avatar catalog remains healthy.
- Capture the output of any failing command and address the problem before proceeding. If a failure is outside your control, document the exact logs and escalate it.

## Branch Management and Pull Requests
This repository relies on the global branching, pull-request, and conflict-resolution process defined in `AGENTS.md` (including `AUTO_CONFLICT_STRATEGY.md`). Follow those universal rules here, then apply the repository-specific setup and automation practices described above.
