#!/usr/bin/env bash
# Branch-protection setup for a GitHub repo: apply the master/develop/tag
# rulesets, set develop as default, and verify. Run once per new project.
#
# Spec, strategy, prerequisites, caveats: ../workflow.md
#
# Usage:
#   OWNER_REPO=owner/repo ./setup.sh
#   OWNER_REPO=owner/repo REQUIRED_CHECKS="ci/build,ci/test" ./setup.sh
#   OWNER_REPO=owner/repo ./setup.sh --lookup     # just print bypass-actor ids
#
# Environment:
#   OWNER_REPO       owner/repo (required)
#   REQUIRED_CHECKS  comma-separated CI status-check contexts to require on
#                    master + develop. MUST match the job names your CI emits
#                    (see your language's release-workflow-spec). If unset, no
#                    status-check rule is added — nothing to block PRs on.
#   BYPASS_ACTOR_ID  master bypass actor id (default: github-actions app 15368).
#   DEFAULT_BRANCH   default branch to set (default: develop).
#
# Requires: gh (authenticated), jq.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
rulesets="${here}/rulesets"

: "${OWNER_REPO:?set OWNER_REPO=owner/repo}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-develop}"

# --- optional: list common bypass-actor ids and exit ------------------------
if [[ "${1:-}" == "--lookup" ]]; then
  # GitHub Actions app is a fixed global id.
  printf 'github-actions\t15368\tIntegration\n'
  if app_id=$(gh api "/repos/${OWNER_REPO}/installation" --jq '.app_id' 2>/dev/null); then
    printf 'installed-app\t%s\tIntegration\n' "$app_id"
  fi
  bot_id=$(gh api /users/github-actions%5Bbot%5D --jq '.id')
  printf 'github-actions[bot]-user\t%s\tUser\n' "$bot_id"
  exit 0
fi

# --- build the required_status_checks rule from REQUIRED_CHECKS -------------
# Emits a jq filter fragment; empty when no checks requested (rule omitted, so
# the ruleset never blocks on a check that never reports).
checks_filter='.'
if [[ -n "${REQUIRED_CHECKS:-}" ]]; then
  checks_json=$(printf '%s' "$REQUIRED_CHECKS" \
    | jq -Rc 'split(",") | map(gsub("^\\s+|\\s+$";"")) | map(select(length>0)) | map({context: .})')
  checks_filter='.rules += [{"type":"required_status_checks","parameters":{"required_status_checks":$checks,"strict_required_status_checks_policy":true}}]'
fi

apply_ruleset() {
  # $1 = payload file, $2 = "checks" to append status checks (branch rulesets only)
  local payload="$1" add_checks="${2:-}"
  local filter='.'
  local -a jq_args=()

  if [[ -n "${BYPASS_ACTOR_ID:-}" ]] && jq -e '.bypass_actors[0]' "$payload" >/dev/null 2>&1; then
    filter='(.bypass_actors[0].actor_id) = ($id | tonumber)'
    jq_args+=(--arg id "$BYPASS_ACTOR_ID")
  fi
  if [[ "$add_checks" == "checks" && -n "${REQUIRED_CHECKS:-}" ]]; then
    filter="${filter} | ${checks_filter}"
    jq_args+=(--argjson checks "$checks_json")
  fi

  jq "${jq_args[@]}" "$filter" "$payload" \
    | gh api -X POST "/repos/${OWNER_REPO}/rulesets" --input -
}

echo "== applying master-protection =="
apply_ruleset "${rulesets}/master.json" checks

echo "== applying develop-protection =="
apply_ruleset "${rulesets}/develop.json" checks

echo "== applying release-tags =="
apply_ruleset "${rulesets}/tags.json"

echo "== setting default branch -> ${DEFAULT_BRANCH} =="
gh repo edit "$OWNER_REPO" --default-branch "$DEFAULT_BRANCH"

echo
echo "== verify =="
gh ruleset list -R "$OWNER_REPO"
echo "-- applicable to master --"
gh ruleset check master -R "$OWNER_REPO" || true
echo "-- applicable to develop --"
gh ruleset check develop -R "$OWNER_REPO" || true

cat <<EOF

Done. Manual steps this script cannot do via the API:
  1. Copy workflows/release-promote.yml into the repo at
     .github/workflows/release-promote.yml (commit on a feature branch, PR into develop).
  2. Turn Actions on and grant write — see ../first-run-enablement.md
     (Settings -> Actions -> General: Read and write + allow Actions to create PRs).
EOF
