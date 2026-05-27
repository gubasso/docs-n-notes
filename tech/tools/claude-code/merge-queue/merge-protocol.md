# Merge Protocol Internals

Technical reference for the merge protocol implementation.

## Protocol Stages

The merge protocol processes a single queue entry through six stages:

```text
1. FETCH_BRANCH          → Fetch from remote, verify exists
2. PRE_MERGE_VALIDATION  → Check PR approval, run tests
3. CONFLICT_DETECTION    → Dry-run merge, detect conflicts
4. EXECUTE_MERGE         → Clean merge OR delegate conflict resolution
5. POST_MERGE_VALIDATION → Run tests, fix regressions if needed
6. FINALIZE              → Push, close PR, update metadata
```

## State Transitions

### Queue Entry States

```text
pending/
  │
  ├─ mv to processing/ (atomic claim)
  │
  ▼
processing/
  │
  ├─ Stage 1-6 execution
  │
  ├─ Success ──────────► completed/
  │
  └─ Failure ──────────► failed/
```

### Progress Tracking

Progress is tracked in `.claude-merge-queue/.progress.json` during processing:

```json
{
  "current_entry_id": "78-auth",
  "stage": "conflict_detection",
  "started_at": "2026-04-06T10:30:00Z",
  "entry_file": ".claude-merge-queue/processing/78-auth.json",
  "merge_commit": null,
  "conflict_resolution_delegated_at": null,
  "conflict_resolution_pre_dir": null,
  "regression_fix_delegated_at": null,
  "regression_fix_pre_dir": null
}
```

The `stage` field values:

- `fetch_branch`
- `pre_merge_validation`
- `conflict_detection`
- `execute_merge_clean`
- `conflict_resolution_delegating`
- `post_merge_validation`
- `finalize`

## Atomic Operations

### Entry Claiming

Atomicity via `mv`:

```bash
# Multiple processors may race to claim
NEXT=$(ls -1 "$QUEUE_DIR/pending/"*.json | sort | head -1)

# Winner claims atomically (loser's mv fails)
if ! mv "$NEXT" "$QUEUE_DIR/processing/$BASENAME" 2>/dev/null; then
  # Lost race, entry already claimed
  continue
fi

# Winner proceeds with merge
```

**Why this works:**

- POSIX guarantees `mv` is atomic on same filesystem
- Only one `mv` can succeed
- Failed `mv` returns non-zero exit code
- Test `if !` catches the loser

### Entry Creation

Atomic write via temp file:

```bash
# Write to temporary file
cat > "${ENTRY_FILE}.tmp" <<EOF
{ ... json ... }
EOF

# Atomic rename
mv "${ENTRY_FILE}.tmp" "$ENTRY_FILE"
```

**Why this works:**

- Partial writes go to `.tmp` file (invisible to queue)
- `mv` atomically replaces destination
- Readers never see partial JSON

## Delegation Protocol

### Conflict Resolution Delegation

**Trigger:** Stage 3 detects conflicts

**Protocol:**

1. Snapshot existing prex directories:

   ```bash
   ls -d /tmp/prex-*/ 2>/dev/null | sort > "$QUEUE_DIR/.pre-dirs-before"
   ```

2. Record delegation timestamp in progress.json:

   ```json
   "conflict_resolution_delegated_at": "2026-04-06T10:35:00Z"
   ```

3. Output delegation blockquote:

   ```text
   > DELEGATING: forking prex via the Agent tool for conflict resolution now.
   ```

4. Invoke the Agent tool (not the Skill tool — nested `Skill` calls load the child inline and break
   orchestration; see `_docs/development/claude-code/skills-and-orchestration.md` Dispatch vs
   Delegation):

   - `subagent_type`: `general-purpose`
   - `description`: `merge-queue conflict resolution`
   - `prompt`:

     ```text
     Read claude/.claude/skills/prex/SKILL.md and follow it
     end-to-end. Treat everything below "ARGS:" as $ARGUMENTS.

     ARGS:
     -ar <CONFLICT_PROMPT>
     ```

5. After delegation returns, find new directory:

   ```bash
   ls -d /tmp/prex-*/ 2>/dev/null | sort > "$QUEUE_DIR/.pre-dirs-after"
   NEW_PRE_DIR=$(comm -13 "$QUEUE_DIR/.pre-dirs-before" "$QUEUE_DIR/.pre-dirs-after" | tail -1)
   ```

6. Validate artifacts exist:

   ```bash
   [ -s "$NEW_PRE_DIR/stage3-impl-report.txt" ]
   [ -s "$NEW_PRE_DIR/stage4-review.md" ]
   ```

7. Record proof:

   ```json
   "conflict_resolution_pre_dir": "/tmp/prex-abc123"
   ```

8. Verify merge completed:

   ```bash
   git show -s --format=%s HEAD | grep -q "Merge branch"
   ```

**Failure modes:**

- No new directory found → Delegation failed, move to failed/
- Artifacts missing → Delegation incomplete, move to failed/
- Merge not completed → Delegation didn't finish merge, move to failed/

### Regression Fix Delegation

**Trigger:** Stage 5 post-merge tests fail

**Protocol:**

1. Capture test output:

   ```bash
   TEST_OUTPUT=$(eval "$POST_MERGE_CMD" 2>&1)
   ```

2. Snapshot (separate from conflict resolution):

   ```bash
   ls -d /tmp/prex-*/ 2>/dev/null | sort > "$QUEUE_DIR/.pre-dirs-before-regression"
   ```

3. Record timestamp:

   ```json
   "regression_fix_delegated_at": "2026-04-06T10:40:00Z"
   ```

4. Output blockquote:

   ```text
   > DELEGATING: forking prex via the Agent tool for regression fix now.
   ```

5. Invoke the Agent tool (not the Skill tool):

   - `subagent_type`: `general-purpose`
   - `description`: `merge-queue regression fix`
   - `prompt`:

     ```text
     Read claude/.claude/skills/prex/SKILL.md and follow it
     end-to-end. Treat everything below "ARGS:" as $ARGUMENTS.

     ARGS:
     -ar <REGRESSION_PROMPT>
     ```

6. Validate proof (same as conflict resolution)

7. Re-run tests to verify fix:

   ```bash
   if ! eval "$POST_MERGE_CMD"; then
     # Still failing - offer options
   fi
   ```

**Recovery options:**

- Retry: Re-delegate to /prex -ar
- Manual: Pause for user intervention
- Revert: `git revert -m 1 --no-edit <merge-commit>` (revert merge)

## Conflict Resolution Prompt

Template used when delegating conflict resolution:

```text
CONFLICT RESOLUTION TASK:

Branch: <branch-name> (PR #<pr-number>)
Target: <target-branch>

CRITICAL REQUIREMENTS:
1. Resolve all merge conflicts in the listed files
2. Preserve EVERY feature from branch '<branch-name>'
3. Preserve EVERY feature from target branch '<target-branch>'
4. If features conflict logically, integrate both (never drop either)
5. Complete the merge with a proper merge commit

Context:
- Incoming branch (<branch-name>) implements:
<incoming-commits>

- Target branch (<target-branch>) recent commits:
<target-commits>

- Files with changes in common:
<conflicted-files>

The merge must result in ALL features working together. No feature may be lost.

Instructions:
1. Start the merge: git merge --no-ff origin/<branch-name>
2. For each conflicted file, resolve conflicts preserving both features
3. Verify both features are present and functional
4. Complete merge: git add <resolved-files> && git commit
5. The merge commit message should be: Merge branch '<branch-name>'<pr-suffix>

DO NOT run any tests yet - that will happen in the next stage.
```

**Key elements:**

- Explicit preservation requirement for both branches
- Commit message format specified
- Clear instruction not to run tests (next stage handles that)
- Context about what each branch does

## Regression Fix Prompt

Template used when delegating regression fixes:

```text
REGRESSION FIX TASK:

Merge commit: <merge-commit>
Branch merged: <branch-name> (PR #<pr-number>)
Target branch: <target-branch>

CRITICAL REQUIREMENT:
Post-merge tests are failing. Fix the regression while preserving ALL features from both branches.

Test failures:

    <test-output>

Instructions:

1. Identify the root cause of test failures
2. Fix the issue WITHOUT removing features from either branch
3. Ensure all tests pass: <post-merge-command>
4. Do NOT revert the merge

The fix must maintain functionality from both '<branch-name>' and '<target-branch>'.
Create fix commits on top of the merge commit.
```

**Key elements:**

- Test output included for debugging
- Explicit no-revert instruction
- Fix must preserve both feature sets
- Creates commits on top (doesn't amend merge)

## Test Execution

### Pre-Merge Tests

**Purpose:** Verify integration branch is healthy before merging

**Command:** `config.pre_merge_command`

**Failure:** FATAL - aborts merge, moves to failed/

**Rationale:** Never merge onto a broken branch

### Post-Merge Tests

**Purpose:** Detect regressions introduced by merge

**Command:** `config.post_merge_command`

**Failure:** Delegates to /prex -ar for regression fix

**Rationale:** Merge may introduce integration issues

### Test Command Format

Commands run via `eval`:

```bash
# Simple
"npm test"

# Chained
"npm run lint && npm test"

# Complex
"npm run lint && npm run type-check && npm test && npm run test:e2e"

# With output suppression
"npm test 2>&1 | tee test.log"
```

**Exit codes:**

- 0 = success
- Non-zero = failure (triggers delegation or abort)

## Git Operations

### Merge Strategy

Always use `--no-ff`:

```bash
git merge --no-ff "origin/$BRANCH" -m "$MERGE_MSG"
```

**Why:**

- Preserves feature branch history
- Creates explicit merge commit
- Easier to revert if needed
- Matches forge merge behavior

### Conflict Detection

Dry-run merge to detect conflicts:

```bash
git merge --no-commit --no-ff "origin/$BRANCH" >/dev/null 2>&1
MERGE_STATUS=$?

if [ $MERGE_STATUS -eq 0 ] && ! git diff --cached --quiet; then
  # Clean merge
  CONFLICTS=false
  git merge --abort
else
  # Conflicts
  CONFLICTS=true
  git merge --abort
fi
```

**Why abort even on clean merge:**

- Dry-run shouldn't modify repo
- Real merge happens after validation
- Gives chance to run pre-merge tests

### Push Strategy

Push after successful merge:

```bash
git push origin "$TARGET_BRANCH"
```

**Why not push immediately:**

- Validates locally first
- Can batch multiple merges
- Reduces remote update frequency

**When to push:**

- After each merge (default: `auto_push: true`)
- After all merges (`--push-at-end` flag, future)
- Never (`--no-push` flag)

## Configuration

### Config File Format

`.claude-merge-queue/config.json`:

```json
{
  "auto_push": true,
  "auto_close_pr": true,
  "require_pr_approval": true,
  "require_ci_pass": false,
  "min_approvals": 1,
  "pre_merge_command": "npm test",
  "post_merge_command": "npm test",
  "max_retry_attempts": 3,
  "delegation": {
    "conflict_resolution": "/prex -ar",
    "regression_fix": "/prex -ar"
  }
}
```

### Config Loading

```bash
CONFIG_FILE="$QUEUE_DIR/config.json"
AUTO_PUSH=$(jq -r .auto_push "$CONFIG_FILE")
# ... load other fields ...
```

### Config Overrides

Command-line flags override config:

```bash
/merge-queue process-all --no-push --no-close-pr
```

Implementation:

```bash
[ "$NO_PUSH" = true ] && AUTO_PUSH=false
[ "$NO_CLOSE_PR" = true ] && AUTO_CLOSE_PR=false
```

## Entry Metadata

### Initial Format

Created by `/merge-queue add`:

```json
{
  "id": "78-auth",
  "work_clone_path": "/workspaces/my-project.78-auth",
  "branch": "78-add-auth-module",
  "pr_number": 123,
  "pr_url": "https://github.com/org/repo/pull/123",
  "enqueued_at": "2026-04-06T10:30:00Z",
  "enqueued_by": "user@hostname",
  "metadata": {
    "ci_status": "SUCCESS",
    "approvals": 2
  }
}
```

### Final Format

After successful merge:

```json
{
  "id": "78-auth",
  "work_clone_path": "/workspaces/my-project.78-auth",
  "branch": "78-add-auth-module",
  "pr_number": 123,
  "pr_url": "https://github.com/org/repo/pull/123",
  "enqueued_at": "2026-04-06T10:30:00Z",
  "enqueued_by": "user@hostname",
  "metadata": {
    "ci_status": "SUCCESS",
    "approvals": 2
  },
  "merged_at": "2026-04-06T10:35:00Z",
  "merge_commit": "abc123def456",
  "status": "completed",
  "pushed_at": "2026-04-06T10:35:05Z",
  "pr_closed_at": "2026-04-06T10:35:08Z"
}
```

### Failed Entry Format

```json
{
  "id": "78-auth",
  "branch": "78-add-auth-module",
  "pr_number": 123,
  "enqueued_at": "2026-04-06T10:30:00Z",
  "error": "Post-merge tests failed after 3 attempts",
  "failed_at": "2026-04-06T10:40:00Z"
}
```

## Error Recovery

### Recovery Matrix

| Stage | Error                    | Recovery                              |
| ----- | ------------------------ | ------------------------------------- |
| 1     | Branch not found         | Move to failed/, notify user          |
| 2     | PR not approved          | Move to failed/, retry after approval |
| 2     | Pre-merge tests fail     | ABORT, fix integration branch         |
| 3     | Conflicts detected       | Delegate to /prex -ar                 |
| 4     | Delegation proof missing | Move to failed/, retry                |
| 4     | Merge not completed      | Move to failed/, manual               |
| 5     | Post-merge tests fail    | Delegate to /prex -ar                 |
| 5     | Fix fails after retries  | Offer: retry/manual/revert            |
| 6     | Push fails               | Record failure, mark merge succeeded  |
| 6     | PR close fails           | Record failure, mark merge succeeded  |

### Manual Recovery

**Stuck in processing:**

```bash
# Check state
git status
cat .claude-merge-queue/.progress.json

# Abort if in merge
git merge --abort

# Move back to pending
mv .claude-merge-queue/processing/78-auth.json .claude-merge-queue/pending/

# Clean progress
rm -f .claude-merge-queue/.progress.json
```

**Clean up orphaned runs:**

```bash
# Find orphaned prex runs
find /tmp -name "prex-*" -type d -mtime +1

# Review and clean
rm -rf /tmp/prex-<old-id>
```

## Performance Considerations

### Sequential vs Parallel

**Current:** Sequential processing

**Rationale:**

- Ensures predictable merge order
- Each merge validates fully before next
- Prevents cascading conflicts
- Simpler state management

**Future optimization:** Parallel pre-validation

### Batch Operations

**Current:** Push after each merge (configurable)

**Future:** Batch push after N merges

```bash
/merge-queue process-all --batch-size 5 --push-at-end
```

**Benefits:**

- Reduces remote update frequency
- Faster overall processing
- Single CI trigger for multiple merges

### Test Caching

**Future:** Cache test results

```bash
# Before merge
PRE_HASH=$(run_tests_with_hash)

# After merge
POST_HASH=$(run_tests_with_hash)

# Compare
[ "$PRE_HASH" = "$POST_HASH" ] && SKIP_TESTS=true
```

## See Also

- Main skill: `merge-queue/SKILL.md`
- Usage: `merge-queue/references/usage-examples.md`
- Spec: `_docs/development/git/merge-queue-coordination.md`
