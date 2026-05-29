#!/usr/bin/env bash
# Apply the release-tags ruleset to a repository.
#
# Usage: OWNER_REPO=owner/repo ./apply-tag-ruleset.sh

set -euo pipefail

: "${OWNER_REPO:?set OWNER_REPO=owner/repo}"

here="$(cd "$(dirname "$0")" && pwd)"
payload="${here}/../rulesets/tags.json"

gh api -X POST "/repos/${OWNER_REPO}/rulesets" --input "$payload"
