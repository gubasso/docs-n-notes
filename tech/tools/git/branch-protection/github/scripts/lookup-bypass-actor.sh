#!/usr/bin/env bash
# Print common bypass-actor IDs for a repo's rulesets.
#
# Usage: OWNER_REPO=owner/repo ./lookup-bypass-actor.sh
#
# Output: newline-separated "label\tactor_id\tactor_type" rows.
# Feed the chosen id/type into the bypass_actors[] of a ruleset JSON.

set -euo pipefail

: "${OWNER_REPO:?set OWNER_REPO=owner/repo}"

# GitHub Actions app is a fixed global id.
printf 'github-actions\t15368\tIntegration\n'

# App installation on this repo (if any).
if app_id=$(gh api "/repos/${OWNER_REPO}/installation" --jq '.app_id' 2>/dev/null); then
  printf 'installed-app\t%s\tIntegration\n' "$app_id"
fi

# github-actions[bot] user id (useful for some legacy lookups).
bot_id=$(gh api /users/github-actions%5Bbot%5D --jq '.id')
printf 'github-actions[bot]-user\t%s\tUser\n' "$bot_id"
