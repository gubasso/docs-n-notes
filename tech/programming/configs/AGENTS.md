---
digest-of: tech/programming/configs
last-synced: 2026-05-27
source-files:
  - README.md
  - dockerfile-review.md
  - github-actions-review.md
  - markdown-review.md
  - yaml-toml-review.md
token-estimate: 700
---

# AGENTS

## Scope

Review heuristics for configuration file formats: Dockerfiles, GitHub Actions workflows, Markdown,
YAML, and TOML.

## Key Points

### Dockerfile

- `FROM` without pinned tag/digest -> `[blocking]`. No `USER` directive -> `[important]`.
- COPY before dependency install busts cache. Secrets in `ENV`/`ARG` -> `[blocking]`.
- Multi-stage: explicit `COPY --from=builder`, minimal runtime base.

### GitHub Actions

- `pull_request_target` + untrusted checkout -> `[blocking]` (script injection).
- Actions pinned by branch instead of SHA -> `[blocking]`. Missing `permissions:` -> `[important]`.
- `if: github.ref == 'main'` (should be `refs/heads/main`) -> `[blocking]`.
- No cache for package managers -> `[important]`. No `timeout-minutes` -> `[important]`.

### Markdown

- Code block without language specifier -> `[blocking]` (MD040). Use `text` when none applies.
- Multiple H1 -> `[important]`. Skipped heading levels -> `[important]`.
- Broken relative links -> `[blocking]`. Table column mismatch -> `[blocking]`.

### YAML/TOML

- YAML: unquoted `0.10` parses as float -> `[blocking]`. `yes`/`no` boolean ambiguity ->
  `[important]`.
- TOML: table-of-tables vs array-of-tables confusion -> `[blocking]`.
- Both: secrets committed -> `[blocking]`. Orphan config -> `[suggestion]`.

## Source Map

| Topic                                   | File                       |
| --------------------------------------- | -------------------------- |
| Dockerfile/Containerfile/docker-compose | `dockerfile-review.md`     |
| GitHub Actions workflows                | `github-actions-review.md` |
| Markdown files                          | `markdown-review.md`       |
| YAML and TOML files                     | `yaml-toml-review.md`      |

## Maintenance Notes

- Each file is a standalone review guide loadable on demand by the code-review skill.
- Regenerate when underlying linter rules change (hadolint, actionlint, markdownlint).
