# Dockerfile — Review Guide

## When to load

`Dockerfile`/`Containerfile`, `*.dockerfile`, `docker-compose.yml`.

## Top review heuristics

### Image hygiene

- `FROM image:latest` → `[blocking]` "Pin to a specific tag/digest; latest drifts."
- `FROM image` without tag → `[blocking]`.
- Tag without digest in production → `[important]` "Tags can be re-pointed; pin digest for
  reproducibility."

### Layer / size

- `apt-get update && apt-get install ...` without `rm -rf /var/lib/apt/lists/*` in the same `RUN` →
  `[important]` "Bloats image."
- `RUN pip install` then no cleanup of `~/.cache/pip` → `[important]`.
- Multiple `RUN` commands that should be one (each creates a layer) → `[suggestion]`.
- COPY before dependency install (busts cache) → `[important]` "Copy lockfile first, install, then
  copy source."

### User / permissions

- No `USER` directive (running as root) → `[important]`.
- `USER root` after a non-root USER → `[important]` "Defeats the protection."
- `chmod 777` on files → `[blocking]`.

### Secrets

- `ENV` containing a secret value → `[blocking]`.
- `ARG` for a secret without `--secret` mount → `[important]` "ARGs persist in image history."
- COPY of a `.env` file → `[blocking]`.

### Multi-stage

- Build artifacts copied between stages without explicit selection → `[important]`
  "`COPY --from=builder /app/bin /usr/local/bin/` is explicit."
- Final stage carrying the full builder toolchain → `[important]` "Use minimal runtime base."

### Common bugs

- `WORKDIR` set with relative path after a `cd` (cd doesn't persist) → `[blocking]` "Use `WORKDIR`
  directive."
- `CMD` and `ENTRYPOINT` mixed forms (exec vs shell) → `[important]`.
- `HEALTHCHECK` missing on a service container → `[suggestion]`.
- `EXPOSE` lying about the actual port the app binds to → `[important]`.

### docker-compose specifics

- Service without `restart` policy → `[suggestion]`.
- Volume mount of host path that varies by user → `[important]` "Use named volumes."
- `version: '2'` in new compose files → `[important]` "Use the schemaless form (v3.8+ doesn't need
  version)."

## See also

- hadolint rules: <https://github.com/hadolint/hadolint/wiki>.
- Docker best practices:
  <https://docs.docker.com/develop/develop-images/dockerfile_best-practices/>.
