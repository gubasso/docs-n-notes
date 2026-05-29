#!/usr/bin/env bash
# Require MR approvals project-wide (Premium).
# Adds a rule pinned to the develop protected-branch id.
#
# Usage:
#   PROJECT_ID=123 DEVELOP_BRANCH_ID=9 ./require-approvals.sh

set -euo pipefail

: "${PROJECT_ID:?set PROJECT_ID=<numeric project id>}"
: "${DEVELOP_BRANCH_ID:?set DEVELOP_BRANCH_ID=<protected_branches id for develop>}"

glab api -X PUT "projects/${PROJECT_ID}/approvals" \
  -f reset_approvals_on_push=true \
  -f disable_overriding_approvers_per_merge_request=true \
  -f merge_requests_author_approval=false \
  -f merge_requests_disable_committers_approval=true

glab api -X POST "projects/${PROJECT_ID}/approval_rules" \
  -f name='dev-review' \
  -f approvals_required=1 \
  -f applies_to_all_protected_branches=false \
  -f "protected_branch_ids[]=${DEVELOP_BRANCH_ID}"
