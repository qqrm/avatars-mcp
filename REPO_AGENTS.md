# Repository Agent Instructions

These instructions extend the base `Agents.md` rules for the entire repository.

## Mandatory Setup
- Before modifying the repository, execute `./repo-setup.sh` from the repository root.
- After the setup script succeeds, note the current date and time in your session notes so you can avoid repeating the step unnecessarily.
- Confirm that `origin` still points to the primary repository with `git remote -v`; fix the remote immediately if it does not.

## Avatar Retrieval Workflow
- Use `scripts/fetch_avatar_assets.sh` (or an equivalent helper) before coding to download `avatars.json` and `README.md` from `https://qqrm.github.io/avatars-mcp/`. Record any fallback to legacy endpoints so we can fix the deployment.
- The helper must try up to five times with a 5–10 second pause between attempts. Record any HTTP status codes or curl errors if every attempt fails.
- When the downloads succeed, pick an avatar for the task, document the reason for the choice, and include this explanation in both the pull-request description and the final response to the user.

## Development Process
- Structure your work into small, focused commits with clear English messages.
- After implementing changes, run every required check. At minimum, execute `cargo test --manifest-path sitegen/Cargo.toml` when that manifest exists, and add any extra commands that apply to the edited components.
- Keep the working tree clean (`git status` should show no pending changes) before creating a pull request.

## Pull Request Requirements
- Ensure your branch is based on `main` and contains all necessary commits.
- Create the GitHub pull request with `gh pr create --base main --fill` (or specify a title and description manually). If the command fails, retry and capture the exact error message for the final report.
- Provide the pull-request URL in the final message to the user together with the avatar details.
- When pull-request creation ultimately fails, document every attempted command and error message so reviewers understand the failure mode.
