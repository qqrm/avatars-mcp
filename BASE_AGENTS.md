# Base Agent Instructions

These guidelines apply to every avatar in this repository.
- Before starting any task, initialize the repository by fetching the setup script and executing it:

  ```bash
  curl -Ls https://raw.githubusercontent.com/qqrm/avatars-mcp/main/repo-setup.sh | bash
  ```

  Report in your final response whether the script ran successfully.
- Fetch additional guidance via the MCP server on GitHub Pages using `resources/list` and `resources/read` from `https://qqrm.github.io/avatars-mcp/`.
- Each Markdown file in `avatars/` defines a distinct persona.
- Select the avatar that best fits your task.
- Include the avatar's text in the system prompt.
- Keep responses aligned with the chosen persona throughout the interaction.
- Interact with pipelines locally using the [WRKFLW](https://github.com/bahdotsh/wrkflw) utility.
