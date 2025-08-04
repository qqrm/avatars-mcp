# Universal Agent Instructions

## Communication
- Final responses, code comments, commit messages, and documentation must be in **English**.
- The user may speak Russian; you may interpret Russian requests but always answer in English.

## Documentation and Design
- Every feature or fix must start with an explicit specification in `SPECIFICATION.md` (or another dedicated Markdown file).
- Keep the system architecture documented in `ARCHITECTURE.md` and update it whenever the design changes.
- Maintain a clear `README.md` for getting started and usage.
- All Markdown should follow common conventions: use `#` for headers and specify languages for code blocks.

## Development Workflow
- Treat user requests as complete tasks and prefer delivering full pull‑request solutions.
- Remove dead code instead of suppressing warnings.
- Branch names, file names, and commit messages must be in English.
- Do not mention build commands in commit messages.

### Rust Projects
For Rust codebases, ensure the required tools are installed:
```bash
rustup component add clippy rustfmt
```
Run the following before committing:
```bash
cargo fmt --all
cargo clippy --all-targets --all-features -- -D warnings
cargo test
cargo machete    # if available
```
Fix all issues reported by these commands.

### Other Languages
Run equivalent formatting, linting, testing, and dependency checks.

## Testing and CI
- Write tests for new functionality.
- Keep CI pipelines (e.g., `.github/workflows`) up to date so formatting, linting, tests, and other checks run automatically.
- Reference changed files in summaries using `F:path#Lx-Ly` and include test output.

## Releases
- Applications must have automated release pipelines; each change to application code should produce a new release artifact.
- Use the application from published releases when demonstrating or testing behavior.

## Additional Notes
- Consult existing documentation in `DOCS/` before making changes.
- Investigate and resolve any reported problems before finishing a task.
