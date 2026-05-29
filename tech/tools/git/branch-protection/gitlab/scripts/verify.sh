#!/usr/bin/env bash
# Dump current protection state for main, develop, and v* tags.
#
# Usage: PROJECT_ID=123 ./verify.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"

echo "== protected branches =="
glab api "projects/${PROJECT_ID}/protected_branches"

echo
echo "== protected tags =="
glab api "projects/${PROJECT_ID}/protected_tags"

echo
echo "== push rules =="
glab api "projects/${PROJECT_ID}/push_rule" || echo '(none; requires Premium)'
