#!/usr/bin/env bash
# Set the project default branch.
#
# Usage: PROJECT_ID=123 BRANCH=develop ./set-default-branch.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"
: "${BRANCH:?set BRANCH=develop}"

glab api -X PUT "projects/${PROJECT_ID}" -f "default_branch=${BRANCH}"
