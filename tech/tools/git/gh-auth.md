# gh: Authentication Setup & Fixes

> TLDR runbook. Check `gh` auth, log in (token goes to the system keyring by default), wire the
> HTTPS git credential helper, and verify — top to bottom. This is the source of truth for `gh`
> authentication. For GitLab's `glab`, see [glab-auth.md](./glab-auth.md).

## TLDR

```bash
gh auth status                                    # 1. where do I stand?
env | grep -E '^(GH_TOKEN|GITHUB_TOKEN)='         # 2. stale overrides?
gh auth login                                     # 3. login (keyring is default)
gh auth setup-git                                 # 4. wire the git credential helper
printf 'protocol=https\nhost=github.com\n\n' | git credential fill  # 5. verify
```

## 1. Check auth

```bash
gh auth status
```

Expected when healthy:

```text
✓ Logged in to github.com account <user>
✓ Git operations for github.com configured to use https protocol
✓ Token: gho_************************
```

`You are not logged into any GitHub hosts` → continue below.

## 2. Clear stale env overrides

Environment variables **override** the stored token, so a stale one masks a good login. Check, then
unset for the current shell if present:

```bash
env | grep -E '^(GH_TOKEN|GITHUB_TOKEN|GH_HOST)='

unset GH_TOKEN GITHUB_TOKEN
```

> If one is set permanently (shell rc, CI secrets, secrets manager), remove it there too — otherwise
> it keeps shadowing the keyring token every session.

## 3. Log in (token → system keyring by default)

`gh` stores the token in your OS keyring (secure storage) **by default** — there is **no**
`--use-keyring` flag; keyring is automatic when a Secret Service backend is available.

```bash
gh auth login
```

When prompted, choose **GitHub.com** → **HTTPS** → authenticate via browser or a Personal Access
Token.

- **Opt out of the keyring** with `--insecure-storage`, which writes the token in cleartext to
  `~/.config/gh/hosts.yaml`:

  ```bash
  gh auth login --insecure-storage   # NOT recommended
  ```

- **Headless / container fallback.** When no keyring is reachable, `gh` falls back to writing the
  token to `~/.config/gh/hosts.yaml` — the same as `--insecure-storage`. Confirm where the token
  landed:

  ```bash
  grep -A3 'github.com' ~/.config/gh/hosts.yaml   # a token line here == plaintext fallback
  gh auth status
  ```

## 4. Wire the git credential helper

`gh` has a dedicated command for this (the equivalent `glab` lacks):

```bash
gh auth setup-git                       # all authenticated hosts
gh auth setup-git --hostname github.com # or scope to one host
```

Confirm exactly one helper is registered:

```bash
git config --global --get-all credential.https://github.com.helper
# Expected: a single line — !/usr/bin/gh auth git-credential
```

If more than one line appears, reset to a single entry:

```bash
git config --global --unset-all credential.https://github.com.helper
gh auth setup-git --hostname github.com
```

## 5. Verify end-to-end

```bash
# Helper resolves credentials with no prompt (do not paste the output anywhere)
printf 'protocol=https\nhost=github.com\n\n' | git credential fill
# Expected: prints protocol/host/username/password=<token>

# A real HTTPS git operation succeeds without prompting
git fetch
```

## Troubleshooting

**HTTPS clone still invokes an askpass helper** (e.g.
`unable to read askpass response from '.../ssh-askpass-rofi'`) — git isn't getting credentials from
`gh`. Clear any askpass override so git uses the credential helper:

```bash
git config --global --get core.askPass   # inspect
echo "$GIT_ASKPASS"; echo "$SSH_ASKPASS"

git config --global --unset core.askPass  # if set globally
unset GIT_ASKPASS SSH_ASKPASS             # for this session
```

Then re-check step 4 (single helper) and step 5.

## How it works

`gh auth setup-git` registers `gh auth git-credential` as a
[git credential helper](https://git-scm.com/docs/gitcredentials). When git needs to authenticate an
HTTPS remote, it calls the helper, which returns the token from `gh`'s store (keyring or
`~/.config/gh/hosts.yaml`) — no prompt, no askpass. GitLab's `glab` uses the same mechanism, minus
the `setup-git` convenience; see [glab-auth.md](./glab-auth.md).
