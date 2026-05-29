#!/usr/bin/env bash
# Protect develop: no direct pushes, Developer-level merge via MR.
#
# Usage: PROJECT_ID=123 ./protect-develop.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"

glab api -X POST "projects/${PROJECT_ID}/protected_branches" \
  -f name=develop \
  -f push_access_level=0 \
  -f merge_access_level=30 \
  -f unprotect_access_level=40 \
  -f allow_force_push=false \
  -f code_owner_approval_required=false
