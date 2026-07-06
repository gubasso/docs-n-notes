# 06 — Helper scripts

A small set of project-local scripts makes the manual paths repeatable: a token-free readiness
check, an auth-gated publish, and a dispatcher for local release chores. They are the escape hatch
for the [first publish](03-first-publish-manual.md) and for when CI is down; the everyday path is
still [release-plz](05-release-plz-automation.md).

## Design principles

- **Keep the auth check in the project script.** It is a _configuration_ check — "is crates.io auth
  set up?" — never a validity check. It must never echo, log, or inspect a token value. Do not push
  this logic into a shared CLI or a CI action; it belongs next to the publish it guards.
- **Dry runs need no auth.** The readiness script must run for anyone, so it never touches
  credentials.
- **Fail with remediation.** When auth is missing, print how to fix it (local `cargo login`, CI
  OIDC, or the token secret), then exit non-zero.

## `publish-dry` — readiness check (no token)

```bash
#!/usr/bin/env bash
# Dry-run readiness check; needs no crates.io token.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

echo "==> cargo publish --dry-run"
cargo publish --dry-run "$@"

echo "==> cargo package --list"
cargo package --list

echo "==> Dry-run readiness complete. No crates.io token was required."
```

## `publish` — auth-gated real publish

```bash
#!/usr/bin/env bash
# Publish to crates.io. Auth-gated: checks that auth is CONFIGURED (never that a
# token is valid) and prints remediation if it is not. Never echoes a token value.
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

cargo_publish_auth_configured() {
  local cred_home="${CARGO_HOME:-$HOME/.cargo}"
  if [ -n "${CARGO_REGISTRY_TOKEN:-}" ] || [ -n "${CARGO_REGISTRIES_CRATES_IO_TOKEN:-}" ]; then
    return 0
  fi
  if [ -f "$cred_home/credentials.toml" ] && grep -q 'token[[:space:]]*=' "$cred_home/credentials.toml"; then
    return 0
  fi
  if [ -f "$cred_home/credentials" ] && grep -q 'token[[:space:]]*=' "$cred_home/credentials"; then
    return 0
  fi
  return 1
}

if ! cargo_publish_auth_configured; then
  printf '%s\n' \
    "No crates.io auth configured." \
    "" \
    "Local publishing:" \
    "  run 'cargo login' and paste an API token from https://crates.io/settings/tokens." \
    "" \
    "CI with release-plz (recommended):" \
    "  grant 'permissions: id-token: write' and do NOT set CARGO_REGISTRY_TOKEN." \
    "" \
    "Dry runs need no auth: run ./scripts/publish-dry to validate." >&2
  exit 1
fi

echo "==> cargo publish"
cargo publish "$@"
```

The check passes if any of these is present: `CARGO_REGISTRY_TOKEN` /
`CARGO_REGISTRIES_CRATES_IO_TOKEN` in the environment, or a `token = ...` line in
`$CARGO_HOME/credentials.toml` (or the legacy `credentials`). `CARGO_HOME` defaults to `~/.cargo`.

## `release` — local operator dispatcher

A thin wrapper over the release tools, so operators do not memorize flags. None of these publish to
crates.io — they prepare a release:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

case "${1:-}" in
  release-plz-update)  exec release-plz update ;;
  release-plz-pr)      exec release-plz release-pr ;;
  cargo-release-dry)   shift; exec cargo release "$@" ;;           # dry-run by default; add --execute to publish
  semver-check)        exec cargo semver-checks check-release ;;   # library crates
  *) echo "usage: release {release-plz-update|release-plz-pr|cargo-release-dry LEVEL|semver-check}" >&2; exit 1 ;;
esac
```

## Usage

```bash
./scripts/publish-dry          # anyone, anytime — validates the package
./scripts/publish              # gated; requires cargo login (or a token env var)
./scripts/release semver-check # check public-API compatibility (lib crates)
```

Pass `--allow-dirty` through to `publish-dry` when validating uncommitted metadata changes; commit
before a real publish so the tarball matches git.
