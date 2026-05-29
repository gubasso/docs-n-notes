# glab: HTTPS Git Credential Helper Setup

Unlike `gh` (which has `gh auth setup-git`), `glab` has **no separate command** to configure the git
credential helper. It's done either during `glab auth login` or manually.

## Prerequisites

Before anything, confirm these are in place:

```bash
# 1. glab is installed and reachable
glab version

# 2. glab is authenticated against your GitLab instance
glab auth status

# Expected: "✓ Logged in to <hostname> as <user>"
# If not logged in, run: glab auth login --hostname gitlab.example.com

# 3. git is installed
git --version

# 4. Your remote is HTTPS (not SSH)
git remote -v
# Expected: https://gitlab.example.com/... (not git@gitlab.example.com:...)
```

If your remote is SSH and you want HTTPS, change it:

```bash
git remote set-url origin https://gitlab.example.com/group/project.git
```

## Option 1: During `glab auth login` (interactive)

Use this if you haven't logged in yet or want to redo the full flow.

**Before:** confirm no existing auth for the target host:

```bash
glab auth status
# Expected: no entry for gitlab.example.com, or you're fine overwriting it
```

**Run:**

```bash
glab auth login --hostname gitlab.example.com
```

When prompted:

1. Choose **HTTPS** as the git protocol.
2. Answer **Yes** to "Authenticate Git with your GitLab credentials?"

**After:** verify both auth and credential helper:

```bash
# Auth is active
glab auth status
# Expected: "✓ Logged in to gitlab.example.com as <user>"

# Credential helper was written to git config
git config --global --get-all credential.https://gitlab.example.com.helper
# Expected: exactly one line like: !/path/to/glab auth git-credential
```

## Option 2: Manual setup

Use this if you already ran `glab auth login` and skipped the credential helper prompt.

**Before:** confirm glab auth works but the credential helper is missing:

```bash
# Auth should be good
glab auth status
# Expected: "✓ Logged in to gitlab.example.com"

# Credential helper should be missing or wrong
git config --global --get-all credential.https://gitlab.example.com.helper
# Expected: empty output (not configured yet)

# Locate your glab binary
which glab
```

**Run:**

```bash
git config --global credential.https://gitlab.example.com.helper \
  '!/usr/bin/glab auth git-credential'
```

> Adjust the path to match your actual `glab` binary from `which glab`.

**After:**

```bash
git config --global --get-all credential.https://gitlab.example.com.helper
# Expected: single line: !/usr/bin/glab auth git-credential
```

## Fixing duplicate entries

Symptoms — you get this error on `git fetch`/`push` or when setting the config:

```text
error: cannot overwrite multiple values with a single value
```

**Before:** confirm duplicates exist:

```bash
git config --global --get-all credential.https://gitlab.example.com.helper
# Expected: multiple lines (that's the problem)
```

**Run:**

```bash
git config --global --unset-all credential.https://gitlab.example.com.helper
git config --global credential.https://gitlab.example.com.helper \
  '!/usr/bin/glab auth git-credential'
```

**After:**

```bash
git config --global --get-all credential.https://gitlab.example.com.helper
# Expected: exactly one line
```

## Final verification

Run all of these after any setup path to confirm everything works end-to-end:

```bash
# 1. Auth is active
glab auth status

# 2. Single credential helper entry
git config --global --get-all credential.https://gitlab.example.com.helper

# 3. Credential helper resolves credentials (no prompt)
printf 'protocol=https\nhost=gitlab.example.com\n' | git credential fill
# Expected: prints username + token without prompting

# 4. Actual git operation works
git fetch
# Expected: succeeds silently
```

## How it works

`glab auth git-credential` implements the
[git credential helper protocol](https://git-scm.com/docs/gitcredentials). When git needs to
authenticate against an HTTPS remote, it calls the configured helper, which reads the token from
glab's config (`~/.config/glab-cli/config.yml`) and returns it to git. Same mechanism
`gh auth git-credential` uses for GitHub.
