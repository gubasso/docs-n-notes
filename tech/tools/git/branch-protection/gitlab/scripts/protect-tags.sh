#!/usr/bin/env bash
# Protect semver release tags: only Maintainers (access_level 40) may create.
#
# Usage: PROJECT_ID=123 ./protect-tags.sh
#        PROJECT_ID=123 TAG_PATTERN='v*' ./protect-tags.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"
pattern="${TAG_PATTERN:-v*}"

glab api -X POST "projects/${PROJECT_ID}/protected_tags" \
  -f "name=${pattern}" \
  -f create_access_level=40
