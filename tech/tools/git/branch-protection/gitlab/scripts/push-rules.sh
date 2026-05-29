#!/usr/bin/env bash
# Configure project push rules (Premium+): block unsigned commits, secrets,
# non-member authors, and tag deletion.
#
# Usage: PROJECT_ID=123 ./push-rules.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"

glab api -X POST "projects/${PROJECT_ID}/push_rule" \
  -f deny_delete_tag=true \
  -f member_check=true \
  -f prevent_secrets=true \
  -f reject_unsigned_commits=true
