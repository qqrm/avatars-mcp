# Instructions

The avatar API is available at:

```text
https://qqrm.github.io/avatars-mcp/
```

- `GET /avatars.json` — retrieve the avatar catalog with the `base_uri` pointer to the shared instructions.
- `GET /AGENTS.md` — fetch the shared baseline instructions referenced by `base_uri`.
- `GET /avatars/{id}.md` — retrieve the complete descriptor for the avatar with the given `id`.

# Response Guidelines

- Share analytical findings and status updates directly in the conversation unless the task explicitly requires repository artifacts.
- Avoid committing ad-hoc reports or chat transcripts into the repository unless they are part of the deliverable specification.
