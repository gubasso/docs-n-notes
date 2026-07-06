#!/usr/bin/env bash
# Apply the master-protection ruleset to a repository.
#
# Usage: OWNER_REPO=owner/repo ./apply-master-ruleset.sh

set -euo pipefail

: "${OWNER_REPO:?set OWNER_REPO=owner/repo}"

here="$(cd "$(dirname "$0")" && pwd)"
payload="${here}/../rulesets/master.json"

gh api -X POST "/repos/${OWNER_REPO}/rulesets" --input "$payload"
