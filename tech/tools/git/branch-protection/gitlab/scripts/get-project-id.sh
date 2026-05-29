#!/usr/bin/env bash
# Resolve a GitLab project path to its numeric ID.
#
# Usage: PROJECT=group/project ./get-project-id.sh
# Output: the numeric project id on stdout.

set -euo pipefail

: "${PROJECT:?set PROJECT=group/project}"

encoded=$(printf %s "$PROJECT" | jq -sRr @uri)
glab api "projects/${encoded}" --jq '.id'
