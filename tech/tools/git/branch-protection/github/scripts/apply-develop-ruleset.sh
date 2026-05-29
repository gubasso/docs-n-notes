#!/usr/bin/env bash
# Apply the develop-protection ruleset to a repository.
#
# Usage: OWNER_REPO=owner/repo ./apply-develop-ruleset.sh

set -euo pipefail

: "${OWNER_REPO:?set OWNER_REPO=owner/repo}"

here="$(cd "$(dirname "$0")" && pwd)"
payload="${here}/../rulesets/develop.json"

gh api -X POST "/repos/${OWNER_REPO}/rulesets" --input "$payload"
