# glab: Authentication Setup & Fixes

> TLDR runbook. Check `glab` auth, store the token in the system keyring, wire the HTTPS git
> credential helper, and verify — top to bottom. This is the source of truth for `glab`
> authentication. For GitHub's `gh`, see [gh-auth.md](./gh-auth.md).

## TLDR

```bash
glab auth status                                  # 1. where do I stand?
env | grep -E '^(GITLAB_TOKEN|GITLAB_ACCESS_TOKEN|OAUTH_TOKEN)='  # 2. stale overrides?
glab auth login --hostname gitlab.com --web --git-protocol https --use-keyring  # 3. login
printf 'protocol=https\nhost=gitlab.com\n\n' | git credential fill  # 4. verify
```

Answer **Yes** to "Authenticate Git with your GitLab credentials?" during step 3 so the git
credential helper is wired for you.

## 1. Check auth

```bash
glab auth status
```

Expected when healthy:

```text
✓ Logged in to gitlab.com as <user>
✓ Git operations for gitlab.com configured to use https protocol
✓ API calls for gitlab.com are made over https protocol
```

`401 Unauthorized` / `No token found` → token is missing or expired; continue below.

## 2. Clear stale env overrides

Environment variables **override** the stored token, so a stale one masks a good login. Check, then
unset for the current shell if present:

```bash
env | grep -E '^(GITLAB_TOKEN|GITLAB_ACCESS_TOKEN|OAUTH_TOKEN|GITLAB_HOST)='

unset GITLAB_TOKEN GITLAB_ACCESS_TOKEN OAUTH_TOKEN
```

> If one of these is set permanently (shell rc, secrets manager), remove it there too — otherwise it
> keeps shadowing the keyring/config token every session.

## 3. Log in (token → system keyring)

`--use-keyring` stores the token in your OS keyring (GNOME Keyring / KWallet / any libsecret Secret
Service backend) instead of the default plaintext `~/.config/glab-cli/config.yml`.

```bash
glab auth logout --hostname gitlab.com          # optional: clear a broken/partial session
glab auth login \
  --hostname gitlab.com \
  --web \
  --git-protocol https \
  --use-keyring
```

When prompted:

1. Git protocol: **HTTPS**
2. "Authenticate Git with your GitLab credentials?" → **Yes** (this wires the credential helper for
   you — see step 4).

Prefer a Personal Access Token (scope `api`) over browser OAuth? Drop `--web` and paste it:

```bash
glab auth login --hostname gitlab.com --git-protocol https --use-keyring --stdin < token.txt
```

**Keyring caveat.** `--use-keyring` can still fall back to writing the token into `config.yml` when
no working Secret Service backend is reachable (a known bug — [gitlab-org/cli#8132]). Confirm the
keyring actually holds it:

```bash
# config.yml should NOT contain a token line for the host
grep -A3 'gitlab.com' ~/.config/glab-cli/config.yml
# and glab should still report you as logged in
glab auth status
```

If `config.yml` holds the token in plaintext, your keyring/Secret Service isn't running for this
session (common in headless shells / containers) — start it or accept the config-file fallback.

[gitlab-org/cli#8132]: https://gitlab.com/gitlab-org/cli/-/issues/8132

## 4. Wire / verify the HTTPS credential helper

Unlike `gh` (which has `gh auth setup-git`), `glab` has **no** separate command to configure the git
credential helper — it's done during `glab auth login` (step 3) or manually. To set it by hand:

```bash
which glab   # confirm the binary path used below
git config --global credential.https://gitlab.com.helper '!/usr/bin/glab auth git-credential'
```

> Adjust `/usr/bin/glab` to match your actual `which glab`.

Confirm exactly one helper is registered:

```bash
git config --global --get-all credential.https://gitlab.com.helper
# Expected: a single line — !/usr/bin/glab auth git-credential
```

### Fixing duplicate entries

If a git operation errors with `cannot overwrite multiple values with a single value`, or
`--get-all` prints more than one line, reset to a single entry:

```bash
git config --global --unset-all credential.https://gitlab.com.helper
git config --global credential.https://gitlab.com.helper '!/usr/bin/glab auth git-credential'
```

## 5. Verify end-to-end

```bash
# Helper resolves credentials with no prompt (do not paste the output anywhere)
printf 'protocol=https\nhost=gitlab.com\n\n' | git credential fill
# Expected: prints protocol/host/username=oauth2/password=<token>

# A real HTTPS git operation succeeds without prompting
git fetch
```

## Troubleshooting

**HTTPS clone still invokes an askpass helper** (e.g.
`unable to read askpass response from '.../ssh-askpass-rofi'`) — git isn't getting credentials from
`glab`. Clear any askpass override so git uses the credential helper:

```bash
git config --global --get core.askPass   # inspect
echo "$GIT_ASKPASS"; echo "$SSH_ASKPASS"

git config --global --unset core.askPass  # if set globally
unset GIT_ASKPASS SSH_ASKPASS             # for this session
```

Then re-check step 4 (single helper, correct binary path) and step 5.

**`glab auth status` says SSH but you clone over HTTPS** — re-run step 3 with
`--git-protocol https`, or clone with the HTTPS URL and let the helper authenticate.

## How it works

`glab auth git-credential` implements the
[git credential helper protocol](https://git-scm.com/docs/gitcredentials). When git needs to
authenticate an HTTPS remote, it calls the configured helper, which returns the token from `glab`'s
store (keyring or `~/.config/glab-cli/config.yml`) — no prompt, no askpass. GitHub's
`gh auth git-credential` uses the same mechanism; see [gh-auth.md](./gh-auth.md).
