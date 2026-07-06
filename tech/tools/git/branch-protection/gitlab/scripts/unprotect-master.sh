#!/usr/bin/env bash
# Remove GitLab's default auto-protection on master (idempotent).
# Needed before applying our own master protection with custom push rules.
#
# Usage: PROJECT_ID=123 ./unprotect-master.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"

glab api -X DELETE "projects/${PROJECT_ID}/protected_branches/master" || true
