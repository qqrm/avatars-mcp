# Instructions

The published persona site is available at:

```text
https://qqrm.github.io/codex-tools/
```

- `GET /personas.json` — retrieve the persona catalog with the `base_uri` pointer to the shared instructions. The deployment does **not** expose `/catalog.json`, so avoid requesting that legacy path.
- `GET /AGENTS.md` — fetch the shared baseline instructions referenced by `base_uri`.
- `GET /personas/{id}.md` — retrieve the complete descriptor for the persona with the given `id`.
- `GET /scenarios.json` — retrieve the scenario catalog for reusable execution playbooks. Each entry links to Markdown prompts stored alongside personas.
- `GET /scenarios/{id}.md` — retrieve the scenario Markdown requested by the catalog entry.

# Response Guidelines

- Share analytical findings and status updates directly in the conversation unless the task explicitly requires repository artifacts.
- Avoid committing ad-hoc reports or chat transcripts into the repository unless they are part of the deliverable specification.
- When a user explicitly asks to run a scenario (e.g., architecture audit, dependency refresh), fetch it from the published catalog and follow the instructions alongside the selected persona.
