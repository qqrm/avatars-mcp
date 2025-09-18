# Agent Instructions – avatars-mcp Repository

These instructions extend the global guidance for every file in this repository.

## Repository Preparation
- Run `./repo-setup.sh` from the repository root before making any changes.
- After the script finishes, inspect `git remote -v` and make sure an `origin` remote targets the canonical repository. If it is missing or incorrect, fix it before continuing.
- Successful executions of `repo-setup.sh` are logged automatically in `notes/setup_log.md`; keep this file committed so future sessions know when the script last ran.

## Avatar Data Collection
- Before implementing a task, retrieve the remote avatar data by running `scripts/fetch_avatar_resources.sh` (or an equivalent script) so that up to five attempts are made with 5–10 seconds between retries.
- Store the resulting `avatars.json` and `README.md` under `/tmp` as the script already does. If all attempts fail, capture the exact HTTP status codes or error messages and report them in the final response.
- When the download succeeds, pick an avatar for the session, document why it was chosen, and include that rationale in the final response and pull-request description.

## Development Workflow
- Keep commits small and focused with descriptive English messages.
- After finishing code changes, run `cargo test --manifest-path sitegen/Cargo.toml`. If the manifest is absent, record the failure message in the final report so the issue can be addressed.
- Ensure `git status` is clean before creating the pull request.

## Pull Requests
- Work from a branch that tracks `main` and includes all required commits.
- Create the pull request with `gh pr create --base main --fill`. If the command fails, retry and document the console output in the final response.
- Share the pull-request URL with the user once it is created.

## Final Communication
- Summarize key changes, test results, avatar selection details, and the pull-request link in the final response.
- If any step from these instructions fails (for example, repeated download failures), explicitly mention how many attempts were made and provide the observed errors.
