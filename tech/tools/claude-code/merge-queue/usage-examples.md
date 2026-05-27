# Merge Queue Usage Examples

Quick reference for common merge queue workflows.

## Basic Workflow

### From Work-Clone

```bash
# 1. Implement feature
cd /workspaces/my-project.78-auth
# ... development work ...

# 2. Push and create PR
git push origin 78-add-auth-module
gh pr create --base devel --title "Add authentication module"

# 3. Wait for approval and CI
# (happens on GitHub/GitLab)

# 4. Enqueue for merge
/merge-queue add --pr 123
```

### From Main Repository

```bash
# 1. Check queue status
cd /workspaces/my-project
/merge-queue list

# 2. Process queue
/merge-queue process-all

# Or process one at a time
/merge-queue next

# Or run in watch mode (continuous)
/merge-queue watch
```

## Concurrent Development

### Scenario: Three Features in Parallel

**Terminal 1 (Work-Clone A):**

```bash
cd /workspaces/my-project.78-auth
# Implement auth
git push && gh pr create --base devel
# After approval:
/merge-queue add --pr 123
```

**Terminal 2 (Work-Clone B):**

```bash
cd /workspaces/my-project.92-api
# Implement API
git push && gh pr create --base devel
# After approval:
/merge-queue add --pr 124
```

**Terminal 3 (Work-Clone C):**

```bash
cd /workspaces/my-project.105-ui
# Implement UI
git push && gh pr create --base devel
# After approval:
/merge-queue add --pr 125
```

**Terminal 4 (Main Repository):**

```bash
cd /workspaces/my-project
/merge-queue watch
# Automatically processes 123, 124, 125 in order
```

## Advanced Usage

### Manual Queue Entry

```bash
# Add specific branch without PR
cd /workspaces/my-project
/merge-queue add --branch 78-add-auth-module --work-clone /workspaces/my-project.78-auth
```

### Handle Failed Merge

```bash
# Check failed merges
/merge-queue list

# Retry failed merge
/merge-queue retry 78-auth

# Or cancel it
/merge-queue cancel 78-auth
```

### Batch Processing

```bash
# Process all pending, don't push automatically
/merge-queue process-all --no-push

# Later, push accumulated merges
git push origin devel

# Close PRs manually
gh pr close 123 124 125
```

### Archive Completed

```bash
# Archive old completed entries
/merge-queue clear-completed
```

## Delegation Flow

### Conflict Resolution

When conflicts are detected:

```text
▶ Processing: 92-api.json
📥 Fetching branch: 92-add-api-endpoints
✓ Fetched: origin/92-add-api-endpoints
🔍 Verifying PR approval...
✓ PR approved: #124 (2 approvals)
🧪 Running pre-merge tests...
✓ Pre-merge tests passed
🔍 Detecting conflicts...
⚠ Conflicts detected in:
    src/routes.js
    src/index.js
⚠ Conflicts require resolution. Delegating to /prex -ar...

> DELEGATING: Invoking /prex -ar via the Skill tool for conflict resolution now.

[/prex -ar runs - plan, review, implement conflict resolution, review]

✓ Conflict resolution delegated successfully: /tmp/prex-abc123
✓ Conflict resolution complete: def456abc789
🧪 Running post-merge tests...
✓ Post-merge tests passed
⬆️  Pushing to remote...
✓ Pushed to remote: origin/devel
📝 Closing PR...
✓ Closed PR: #124

═══════════════════════════════════════════════
✓ Merge complete: 92-add-api-endpoints → devel
  Commit: def456abc789
  PR: #124
  Pushed: origin/devel
  PR closed: #124
═══════════════════════════════════════════════
```

### Regression Fix

When post-merge tests fail:

```text
▶ Processing: 105-ui.json
📥 Fetching branch: 105-add-ui-components
✓ Fetched: origin/105-add-ui-components
✓ Clean merge detected
🔀 Executing merge...
✓ Merged: abc123def456
🧪 Running post-merge tests...
⚠ Post-merge tests failed (regression detected)
⚠ Regression detected. Delegating fix to /prex -ar...

> DELEGATING: Invoking /prex -ar via the Skill tool for regression fix now.

[/prex -ar runs - plan, review, implement fix, review]

✓ Regression fix delegated successfully: /tmp/prex-xyz789
✓ Regression fixed - all tests passing
⬆️  Pushing to remote...
✓ Pushed to remote: origin/devel
📝 Closing PR...
✓ Closed PR: #125

═══════════════════════════════════════════════
✓ Merge complete: 105-add-ui-components → devel
  Commit: abc123def456
  PR: #125
  Pushed: origin/devel
  PR closed: #125
═══════════════════════════════════════════════
```

## Queue Inspection

### Check Status

```bash
/merge-queue list
```

Output:

```text
Merge Queue Status:

Pending (2):
  1. 92-api (PR #124) - Enqueued 15m ago
  2. 105-ui (PR #125) - Enqueued 5m ago

Processing (1):
  • 78-auth (PR #123) - Stage: post_merge_validation

Completed (3):
  ✓ 42-bug-fix (PR #115) - 60m ago
  ✓ 51-refactor (PR #118) - 45m ago
  ✓ 58-docs (PR #119) - 30m ago

Failed (0):
```

### Inspect Queue Files

```bash
# View entry details
cat .claude-merge-queue/pending/92-api.json | jq .

# View progress
cat .claude-merge-queue/.progress.json | jq .

# List all pending
ls -1 .claude-merge-queue/pending/
```

## Configuration

### Customize Behavior

Edit `.claude-merge-queue/config.json`:

```json
{
  "auto_push": false,
  "auto_close_pr": false,
  "require_pr_approval": true,
  "min_approvals": 2,
  "pre_merge_command": "npm run lint && npm test",
  "post_merge_command": "npm run test:integration",
  "max_retry_attempts": 3
}
```

### Test Commands

Example test configurations:

**Node.js project:**

```json
{
  "pre_merge_command": "npm test",
  "post_merge_command": "npm test"
}
```

**Rust project:**

```json
{
  "pre_merge_command": "cargo test",
  "post_merge_command": "cargo test --all-features"
}
```

**Python project:**

```json
{
  "pre_merge_command": "pytest",
  "post_merge_command": "pytest --cov"
}
```

**Multiple commands:**

```json
{
  "pre_merge_command": "npm run lint && npm run type-check && npm test",
  "post_merge_command": "npm run lint && npm run type-check && npm test && npm run test:e2e"
}
```

## Troubleshooting

### Queue Stuck

```bash
# Check if something is stuck in processing
ls -la .claude-merge-queue/processing/

# If stuck, move back to pending
mv .claude-merge-queue/processing/78-auth.json .claude-merge-queue/pending/

# Clear progress file
rm -f .claude-merge-queue/.progress.json
```

### Failed Delegation

```bash
# Check for orphaned prex runs
ls -d /tmp/prex-*/

# Inspect failed entry
cat .claude-merge-queue/failed/78-auth.json | jq .error

# Retry
/merge-queue retry 78-auth
```

### Manual Intervention

```bash
# If merge is stuck in processing
cd /workspaces/my-project

# Check current state
git status

# If in middle of merge, abort it
git merge --abort

# Move entry back to pending for retry
mv .claude-merge-queue/processing/78-auth.json .claude-merge-queue/pending/

# Clean up progress
rm -f .claude-merge-queue/.progress.json

# Retry
/merge-queue next
```

## Integration with Existing Workflow

### Before Queue (Traditional)

```bash
# Work-clone
git push
gh pr create
# Wait for review
gh pr merge  # Merges remotely

# Main repo
git pull  # Pull remote merge
```

### With Queue (Coordinated)

```bash
# Work-clone
git push
gh pr create
# Wait for review
/merge-queue add --pr 123  # Enqueue

# Main repo
/merge-queue process-all  # Merge locally with validation
```

Benefits:

- Conflict resolution with AI assistance
- Regression prevention
- Coordinated multi-feature merges
- Local validation before pushing

## See Also

- [[development/git/merge-queue-coordination]] — Full specification
- [[development/git/feature-lifecycle]] — Work-clone lifecycle
- Main skill: `claude/.claude/skills/merge-queue/SKILL.md`
