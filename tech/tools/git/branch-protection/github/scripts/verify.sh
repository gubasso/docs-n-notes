#!/usr/bin/env bash
# List rulesets on the repo and dry-run which rules apply to main/develop.
#
# Usage: OWNER_REPO=owner/repo ./verify.sh

set -euo pipefail

: "${OWNER_REPO:?set OWNER_REPO=owner/repo}"

echo "== rulesets =="
gh ruleset list -R "$OWNER_REPO"

echo
echo "== applicable to main =="
gh ruleset check main -R "$OWNER_REPO"

echo
echo "== applicable to develop =="
gh ruleset check develop -R "$OWNER_REPO"
