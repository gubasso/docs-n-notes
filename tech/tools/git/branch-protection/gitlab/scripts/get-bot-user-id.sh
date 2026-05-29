#!/usr/bin/env bash
# Find the user id of a project/group access token bot.
#
# GitLab names these users `project_<id>_bot*` or `group_<id>_bot*`.
#
# Usage: PROJECT_ID=123 ./get-bot-user-id.sh
#        PROJECT_ID=123 BOT_PATTERN='project_.*_bot' ./get-bot-user-id.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"
pattern="${BOT_PATTERN:-project_.*_bot|group_.*_bot}"

glab api "projects/${PROJECT_ID}/members/all" \
  --jq ".[] | select(.username|test(\"${pattern}\")) | .id"
