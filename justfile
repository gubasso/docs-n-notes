# Justfile — task runner for this documentation SoT repo.
# .pre-commit-config.yaml is the source of truth for what lint/format runs;
# recipes delegate to `pre-commit run <hook>` rather than invoking tools directly.
# Tools (just, pre-commit, dprint) come from the Nix devShell (flake.nix); the
# direnv `.envrc` auto-loads it, so recipes assume you are in the devShell.

# List available recipes.
default:
    @just --list

# Enter an interactive dev shell (just, pre-commit, dprint).
dev:
    nix develop

# Format Markdown via the dprint hook (config owned by pre-commit).
fmt:
    pre-commit run dprint --all-files

# Style gate via the markdownlint hook (dprint owns formatting; this is lint-only).
lint:
    pre-commit run markdownlint-cli2 --all-files

# Run the full pre-commit hook suite across the repo.
hooks:
    pre-commit run --all-files

# Install pre-commit hooks into the local git repo.
install-hooks:
    pre-commit install --install-hooks

# Run the full hook suite (format, lint, TOC, spelling, links, ...).
check: hooks
