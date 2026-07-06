#!/usr/bin/env bash
# Protect master on GitLab Premium/Ultimate: only $BOT_USER_ID can push.
#
# Usage:
#   PROJECT_ID=123 BOT_USER_ID=456 ./protect-master-premium.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"
: "${BOT_USER_ID:?set BOT_USER_ID=<numeric user id of CI bot>}"

glab api -X POST "projects/${PROJECT_ID}/protected_branches" \
  -H 'Content-Type: application/json' \
  --input - <<EOF
{
  "name": "master",
  "allowed_to_push":      [{"user_id": ${BOT_USER_ID}}],
  "allowed_to_merge":     [{"user_id": ${BOT_USER_ID}}, {"access_level": 40}],
  "allowed_to_unprotect": [{"access_level": 40}],
  "allow_force_push": false,
  "code_owner_approval_required": true
}
EOF
