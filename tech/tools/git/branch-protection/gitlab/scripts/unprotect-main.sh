#!/usr/bin/env bash
# Remove GitLab's default auto-protection on main (idempotent).
# Needed before applying our own main protection with custom push rules.
#
# Usage: PROJECT_ID=123 ./unprotect-main.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"

glab api -X DELETE "projects/${PROJECT_ID}/protected_branches/main" || true
