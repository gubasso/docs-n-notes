#!/usr/bin/env bash
# Protect main on GitLab Free: no pushes, Maintainer-only merges.
# Pure CI-only promotion requires the CI job-token push toggle (Settings →
# CI/CD → Job token permissions) or a Deploy Token allow-listed below.
#
# Usage: PROJECT_ID=123 ./protect-main-free.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"

glab api -X POST "projects/${PROJECT_ID}/protected_branches" \
  -f name=main \
  -f push_access_level=0 \
  -f merge_access_level=40 \
  -f unprotect_access_level=40 \
  -f allow_force_push=false \
  -f code_owner_approval_required=true
