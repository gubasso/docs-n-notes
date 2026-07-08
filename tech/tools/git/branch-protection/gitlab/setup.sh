#!/usr/bin/env bash
# Branch-protection setup for a GitLab project: protect master/develop/tags,
# set develop as default, and verify. Run once per new project.
#
# Spec, strategy, prerequisites, caveats: ../workflow.md
#
# Usage:
#   PROJECT=group/project ./setup.sh                       # Free tier (default)
#   PROJECT=group/project TIER=premium BOT_USER_ID=456 ./setup.sh
#
# Environment:
#   PROJECT       group/project path (required)
#   TIER          free | premium (default: free)
#   BOT_USER_ID   premium only: user id of the CI push bot. If unset, resolved
#                 from project members matching BOT_PATTERN.
#   BOT_PATTERN   member-username regex (default: project_.*_bot|group_.*_bot)
#   MERGE_METHOD  ff | rebase_merge | merge (default: ff)
#   TAG_PATTERN   protected tag glob (default: v*)
#   DEFAULT_BRANCH  default branch to set (default: develop)
#
# Requires: glab (authenticated), jq. Premium per-user push allow-listing needs
# GitLab Premium/Ultimate; Free blocks all pushes and relies on the CI
# job-token toggle (see step printed at the end).

set -euo pipefail

: "${PROJECT:?set PROJECT=group/project}"
TIER="${TIER:-free}"
MERGE_METHOD="${MERGE_METHOD:-ff}"
TAG_PATTERN="${TAG_PATTERN:-v*}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-develop}"

encoded=$(printf %s "$PROJECT" | jq -sRr @uri)
PROJECT_ID=$(glab api "projects/${encoded}" --jq '.id')
echo "project id: ${PROJECT_ID}"

# --- master ----------------------------------------------------------------
echo "== master =="
# Remove GitLab's default auto-protection first (idempotent).
glab api -X DELETE "projects/${PROJECT_ID}/protected_branches/master" || true

if [[ "$TIER" == "premium" ]]; then
  if [[ -z "${BOT_USER_ID:-}" ]]; then
    pattern="${BOT_PATTERN:-project_.*_bot|group_.*_bot}"
    BOT_USER_ID=$(glab api "projects/${PROJECT_ID}/members/all" \
      --jq ".[] | select(.username|test(\"${pattern}\")) | .id" | head -n1)
    : "${BOT_USER_ID:?could not resolve bot user id; set BOT_USER_ID=<id>}"
    echo "bot user id: ${BOT_USER_ID}"
  fi
  glab api -X POST "projects/${PROJECT_ID}/protected_branches" \
    -H 'Content-Type: application/json' --input - <<EOF
{
  "name": "master",
  "allowed_to_push":      [{"user_id": ${BOT_USER_ID}}],
  "allowed_to_merge":     [{"user_id": ${BOT_USER_ID}}, {"access_level": 40}],
  "allowed_to_unprotect": [{"access_level": 40}],
  "allow_force_push": false,
  "code_owner_approval_required": true
}
EOF
  # Project push rules (Premium+): block unsigned commits, secrets, non-members.
  glab api -X POST "projects/${PROJECT_ID}/push_rule" \
    -f deny_delete_tag=true -f member_check=true \
    -f prevent_secrets=true -f reject_unsigned_commits=true || true
else
  # Free: no pushes, Maintainer-only merges. Pure CI promotion relies on the
  # job-token push toggle (printed at the end).
  glab api -X POST "projects/${PROJECT_ID}/protected_branches" \
    -f name=master -f push_access_level=0 -f merge_access_level=40 \
    -f unprotect_access_level=40 -f allow_force_push=false \
    -f code_owner_approval_required=true
fi

# --- develop ---------------------------------------------------------------
echo "== develop =="
glab api -X POST "projects/${PROJECT_ID}/protected_branches" \
  -f name=develop -f push_access_level=0 -f merge_access_level=30 \
  -f unprotect_access_level=40 -f allow_force_push=false \
  -f code_owner_approval_required=false

if [[ "$TIER" == "premium" ]]; then
  develop_branch_id=$(glab api "projects/${PROJECT_ID}/protected_branches/develop" --jq '.id')
  glab api -X PUT "projects/${PROJECT_ID}/approvals" \
    -f reset_approvals_on_push=true \
    -f disable_overriding_approvers_per_merge_request=true \
    -f merge_requests_author_approval=false \
    -f merge_requests_disable_committers_approval=true
  glab api -X POST "projects/${PROJECT_ID}/approval_rules" \
    -f name='dev-review' -f approvals_required=1 \
    -f applies_to_all_protected_branches=false \
    -f "protected_branch_ids[]=${develop_branch_id}"
fi

# Project-wide MR hygiene: green-pipeline-only, resolved discussions, ff merge.
glab api -X PUT "projects/${PROJECT_ID}" \
  -f only_allow_merge_if_pipeline_succeeds=true \
  -f only_allow_merge_if_all_discussions_are_resolved=true \
  -f "merge_method=${MERGE_METHOD}"

# --- tags ------------------------------------------------------------------
echo "== tags =="
glab api -X POST "projects/${PROJECT_ID}/protected_tags" \
  -f "name=${TAG_PATTERN}" -f create_access_level=40

# --- default branch --------------------------------------------------------
echo "== default branch -> ${DEFAULT_BRANCH} =="
glab api -X PUT "projects/${PROJECT_ID}" -f "default_branch=${DEFAULT_BRANCH}"

# --- verify ----------------------------------------------------------------
echo
echo "== protected branches =="
glab api "projects/${PROJECT_ID}/protected_branches"
echo "== protected tags =="
glab api "projects/${PROJECT_ID}/protected_tags"
echo "== push rules =="
glab api "projects/${PROJECT_ID}/push_rule" || echo '(none; requires Premium)'

cat <<EOF

Done. Manual steps this script cannot do via the API:
  1. Create a Project Access Token (Settings -> Access tokens, role Maintainer,
     scope write_repository) for the CI push bot. Premium: pass its user id as
     BOT_USER_ID and re-run, or add it to master's Allowed to push and merge.
  2. GitLab 17.2+: Settings -> CI/CD -> Job token permissions ->
     Allow Git push requests to the repository. No API equivalent yet
     (gitlab-org/gitlab#494324).
  3. Copy ci/release-promote.gitlab-ci.yml into the project's .gitlab-ci.yml
     (or include it). See ../first-run-enablement.md.
EOF
