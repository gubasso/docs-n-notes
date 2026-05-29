#!/usr/bin/env bash
# Set the repository default branch.
#
# Usage: OWNER_REPO=owner/repo BRANCH=develop ./set-default-branch.sh

set -euo pipefail

: "${OWNER_REPO:?set OWNER_REPO=owner/repo}"
: "${BRANCH:?set BRANCH=develop}"

gh repo edit "$OWNER_REPO" --default-branch "$BRANCH"
