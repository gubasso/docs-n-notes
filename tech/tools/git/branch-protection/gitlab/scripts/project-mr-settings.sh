#!/usr/bin/env bash
# Project-wide MR hygiene: green-pipeline-only merges, fast-forward method,
# resolved-discussions gate.
#
# Usage: PROJECT_ID=123 ./project-mr-settings.sh
#        PROJECT_ID=123 MERGE_METHOD=rebase_merge ./project-mr-settings.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"
merge_method="${MERGE_METHOD:-ff}" # ff | rebase_merge | merge

glab api -X PUT "projects/${PROJECT_ID}" \
  -f only_allow_merge_if_pipeline_succeeds=true \
  -f only_allow_merge_if_all_discussions_are_resolved=true \
  -f "merge_method=${merge_method}"
