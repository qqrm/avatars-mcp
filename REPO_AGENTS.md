# Repository Agent Instructions

These instructions extend the base `Agents.md` rules for the entire repository.

## Mindset
- Assume you are contributing to a production service. Optimise for reliable delivery, not experimentation.
- Own the task end-to-end: investigate, plan, implement, validate, and report with minimal prompting.
- Escalate blockers with actionable detail instead of waiting for new guidance.

## Mandatory Setup
- Before modifying the repository, execute `./repo-setup.sh` from the repository root. The script configures the canonical `origin` remote automatically when it is missing or incorrect.
- After the setup script succeeds, record the current date and time in your session notes so future attempts know the environment is ready.
- Double-check `git remote -v` once the script finishes; the `origin` remote must point to `https://github.com/qqrm/avatars-mcp.git`.
- If any setup step fails, capture the full command output, diagnose the cause, and propose a fix or workaround.

## Avatar Retrieval Workflow
- Use `scripts/fetch_avatar_assets.sh` (or an equivalent helper) before coding to download `avatars.json` and `README.md` from `https://qqrm.github.io/avatars-mcp/`. Capture detailed HTTP errors whenever a download fails so outages can be triaged quickly.
- The helper must try up to five times with a 5–10 second pause between attempts. Record any HTTP status codes or curl errors if every attempt fails.
- When the downloads succeed, pick an avatar for the task, document the reason for the choice, and include this explanation in both the pull-request description and the final response to the user.
- If asset retrieval is impossible, log the attempts, escalate the outage, and continue with the best-matching avatar based on cached knowledge.

## Branch Management
- Create a fresh, descriptive feature branch for every task before making any changes. Branch names must be in English, use hyphenated words, and describe the work (for example, `configure-remote-in-setup`).
- The bootstrap branch named `work` is reserved; do **not** commit or push changes from it. Switch to your task-specific branch immediately after running the setup script.

## Development Process
- Structure your work into small, focused commits with clear English messages.
- After implementing changes, run every required check. At minimum, execute `cargo test --manifest-path sitegen/Cargo.toml` when that manifest exists, and add any extra commands that apply to the edited components. Capture and address failures instead of skipping them.
- Keep the working tree clean (`git status` should show no pending changes) before creating a pull request.
- Use the `gh` CLI to inspect open pull requests, checks, and workflow runs when verification on GitHub is necessary; report exact commands and outcomes.

## Pull Request Requirements
- Ensure your branch is based on `main` and contains all necessary commits.
- Create the GitHub pull request with `gh pr create --base main --fill` (or specify a title and description manually). If the command fails, retry and capture the exact error message for the final report.
- Provide the pull-request URL in the final message to the user together with the avatar details.
- When pull-request creation ultimately fails, document every attempted command and error message so reviewers understand the failure mode.
