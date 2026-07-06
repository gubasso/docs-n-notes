#!/usr/bin/env bash
# List rulesets on the repo and dry-run which rules apply to master/develop.
#
# Usage: OWNER_REPO=owner/repo ./verify.sh

set -euo pipefail

: "${OWNER_REPO:?set OWNER_REPO=owner/repo}"

echo "== rulesets =="
gh ruleset list -R "$OWNER_REPO"

echo
echo "== applicable to master =="
gh ruleset check master -R "$OWNER_REPO"

echo
echo "== applicable to develop =="
gh ruleset check develop -R "$OWNER_REPO"
