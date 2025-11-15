# Instructions

The published persona site is available at:

```text
https://qqrm.github.io/codex-tools/
```

- `GET /personas.json` — retrieve the persona catalog with the `base_uri` pointer to the shared instructions. The deployment does **not** expose `/catalog.json`, so avoid requesting that legacy path.
- `GET /AGENTS.md` — fetch the shared baseline instructions referenced by `base_uri`.
- `GET /personas/{id}.md` — retrieve the complete descriptor for the persona with the given `id`.

# Response Guidelines

- Share analytical findings and status updates directly in the conversation unless the task explicitly requires repository artifacts.
- Avoid committing ad-hoc reports or chat transcripts into the repository unless they are part of the deliverable specification.
