# Git Commit Signing with SSH (`git commit -S`) Cheatsheet

## Assumptions

- Git is already installed.
- Git version supports SSH commit signing (>= 2.34).
- SSH keys already exist.
- SSH keys are already working for Git/GitHub authentication.
- The goal is to configure SSH-based commit signing.
- `commit.gpgsign` is left **unset** by default (which means automatic signing is off).
- Commits are signed only when explicitly using:

```bash
git commit -S
```

- Local verification with `git log --show-signature` and `git verify-commit` should also work, which requires `gpg.ssh.allowedSignersFile`.

______________________________________________________________________

## 1. Check Current Git Signing Configuration

Run this inside the repository:

```bash
git config --list --show-origin --show-scope | grep -E 'user.name|user.email|user.signingkey|commit.gpgsign|gpg.format|gpg.program|gpg.ssh.allowedSignersFile|tag.gpgsign'
```

This shows:

- Git identity
- Signing key
- Signing format
- Whether commits are signed automatically
- Allowed signers file for verification
- Where each setting is configured

______________________________________________________________________

## 2. Check Individual Settings

```bash
git config --show-origin --show-scope --get user.name
git config --show-origin --show-scope --get user.email
git config --show-origin --show-scope --get user.signingkey
git config --show-origin --show-scope --get commit.gpgsign
git config --show-origin --show-scope --get gpg.format
git config --show-origin --show-scope --get gpg.program
git config --show-origin --show-scope --get gpg.ssh.allowedSignersFile
```

Expected SSH signing setup with automatic signing off:

```text
gpg.format=ssh
user.signingkey=/path/to/your/public/ssh/key.pub
gpg.ssh.allowedSignersFile=/home/user/.config/git/allowed_signers
```

`commit.gpgsign` is intentionally unset. When unset, Git treats it as `false`, so commits are not signed automatically.

______________________________________________________________________

## 3. Confirm Your Public SSH Key Path

List your SSH directory:

```bash
ls -la ~/.ssh
```

Common public key files:

```text
~/.ssh/id_ed25519.pub
~/.ssh/id_rsa.pub
```

View the public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Use the `.pub` file for Git signing configuration.

______________________________________________________________________

## 4. Add SSH Signing Key to GitHub

Copy your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Then go to GitHub:

```text
GitHub → Settings → SSH and GPG keys → New SSH key
```

Set:

```text
Key type: Signing Key
Title: Your machine/key name
Key: Paste your public SSH key
```

Important:

```text
Authentication Key ≠ Signing Key
```

The same public key may need to be added separately as a signing key.

______________________________________________________________________

## 5. Configure Git to Use SSH Signing Globally

Set SSH as the signing format:

```bash
git config --global gpg.format ssh
```

Set your SSH public key as the signing key:

```bash
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

Make sure `commit.gpgsign` is unset (default behavior, no automatic signing):

```bash
git config --global --unset commit.gpgsign 2>/dev/null || true
```

Confirm it is unset:

```bash
git config --show-origin --show-scope --get commit.gpgsign
```

If nothing is returned, automatic signing is off. You sign explicitly with:

```bash
git commit -S
```

______________________________________________________________________

## 6. Configure the Allowed Signers File for Local Verification

Without this, `git log --show-signature` and `git verify-commit` fail with:

```text
error: gpg.ssh.allowedSignersFile needs to be configured and exist for ssh signature verification
No signature
```

This file maps `email → trusted SSH public key` so Git can verify signatures locally.

### 6.1 Create the file

```bash
mkdir -p ~/.config/git
echo "your-email@example.com namespaces=\"git\" $(cat ~/.ssh/id_ed25519.pub)" \
  > ~/.config/git/allowed_signers
```

The `namespaces="git"` option scopes trust to git signing only, so the same key cannot be silently used to verify other SSH signatures (file signing, etc.). Drop it if you want broader trust.

Example resulting line:

```text
your-email@example.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@host
```

### 6.2 Tell Git to use it

```bash
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

### 6.3 Why an extra file?

A `.pub` key file contains only `<type> <key> <comment>` and carries no identity. Git needs an explicit identity → key mapping to decide which signatures to trust. That mapping is the allowed signers file.

### 6.4 Multiple keys / teammates

One signer per line:

```text
you@example.com         namespaces="git" ssh-ed25519 AAAA...
teammate@example.com    namespaces="git" ssh-ed25519 AAAA...
personal@example.com    namespaces="git" ssh-ed25519 AAAA...
```

For team workflows, a shared allowed signers file can be committed in the repo and configured per repository:

```bash
git config --local gpg.ssh.allowedSignersFile .github/allowed_signers
```

______________________________________________________________________

## 7. Optional: Enable Automatic Signing Globally

Default in this guide is **manual signing only**. If you want every commit signed automatically:

```bash
git config --global commit.gpgsign true
```

With this enabled, normal commits are signed automatically:

```bash
git commit -m "your commit message"
```

To go back to manual signing, just unset it:

```bash
git config --global --unset commit.gpgsign
```

You can also enable auto-signing only for specific repositories:

```bash
git config --local commit.gpgsign true
```

______________________________________________________________________

## 8. Configure Per Repository Instead of Globally

Inside the target repository:

```bash
git config --local gpg.format ssh
git config --local user.signingkey ~/.ssh/id_ed25519.pub
```

Optionally a repo-scoped allowed signers file:

```bash
git config --local gpg.ssh.allowedSignersFile .github/allowed_signers
```

Use local config when:

- You only want signing configured for one repository.
- Different repositories use different signing keys.
- Work and personal GitHub accounts use different SSH keys.
- You want a repository to override global signing behavior (for example, force auto-signing on with `git config --local commit.gpgsign true`).

______________________________________________________________________

## 9. Local `user.name` and `user.email` with Global Signing

A repository can use a different local identity:

```bash
git config --local user.name "Work Name"
git config --local user.email "work@example.com"
```

This does not disable signing.

If global SSH signing is configured, this repository can still create signed commits with:

```bash
git commit -S -m "your commit message"
```

The commit author identity comes from the local repository config, while the signing key comes from the global config unless overridden locally.

Check the effective config:

```bash
git config --list --show-origin --show-scope | grep -E 'user.name|user.email|user.signingkey|commit.gpgsign|gpg.format|gpg.ssh.allowedSignersFile'
```

Example result:

```text
local   .git/config       user.name=Work Name
local   .git/config       user.email=work@example.com
global  ~/.gitconfig      gpg.format=ssh
global  ~/.gitconfig      user.signingkey=/home/user/.ssh/id_ed25519.pub
global  ~/.gitconfig      gpg.ssh.allowedSignersFile=/home/user/.config/git/allowed_signers
```

This means:

```text
Local identity
Global signing key
Automatic signing off (commit.gpgsign unset)
Manual signing available with git commit -S
Local verification works via allowed_signers
```

For verification of commits made under a different email, that email must also appear in `allowed_signers`.

______________________________________________________________________

## 10. Configure a Different Signing Key for One Repository

Inside the repository:

```bash
git config --local gpg.format ssh
git config --local user.signingkey ~/.ssh/work_signing_key.pub
```

If verifying locally with a key/email not in your global allowed signers file, append it:

```bash
echo "work@example.com namespaces=\"git\" $(cat ~/.ssh/work_signing_key.pub)" \
  >> ~/.config/git/allowed_signers
```

Then sign manually:

```bash
git commit -S -m "your commit message"
```

______________________________________________________________________

## 11. Confirm Final Configuration

Run:

```bash
git config --list --show-origin --show-scope | grep -E 'user.signingkey|commit.gpgsign|gpg.format|gpg.ssh.allowedSignersFile'
```

Expected output:

```text
gpg.format=ssh
user.signingkey=/home/user/.ssh/id_ed25519.pub
gpg.ssh.allowedSignersFile=/home/user/.config/git/allowed_signers
```

`commit.gpgsign` should not appear (it is unset, hence default false).

______________________________________________________________________

## 12. Create an Unsigned Commit

Because automatic signing is off, this creates an unsigned commit:

```bash
git commit -m "your commit message"
```

______________________________________________________________________

## 13. Create a Signed Commit Manually

Use `-S`:

```bash
git commit -S -m "your commit message"
```

______________________________________________________________________

## 14. Verify Locally

Latest commit:

```bash
git log --show-signature -1
```

Recent commits:

```bash
git log --show-signature --oneline -5
```

Direct verification of a specific commit:

```bash
git verify-commit HEAD
git verify-commit <sha>
```

Expected output for a trusted signature:

```text
Good "git" signature for your-email@example.com with ED25519 key SHA256:...
```

______________________________________________________________________

## 15. Push and Verify on GitHub

Push your branch:

```bash
git push
```

Then check the commit on GitHub.

Expected result for signed commits:

```text
Verified
```

Unsigned commits will not show the verified status.

______________________________________________________________________

## 16. Troubleshooting

### Commit was not signed

Check whether you used `-S`:

```bash
git log --show-signature -1
```

Manual signing:

```bash
git commit -S -m "your commit message"
```

______________________________________________________________________

### `gpg.ssh.allowedSignersFile needs to be configured and exist`

This is local verification, not signing. The commit may already be signed; Git just cannot verify it.

Confirm the commit is actually signed:

```bash
git cat-file -p HEAD | grep -A1 '^gpgsig'
```

If you see `BEGIN SSH SIGNATURE`, the commit is signed and you only need to configure the allowed signers file (see section 6).

______________________________________________________________________

### Git is not using SSH signing

Check:

```bash
git config --show-origin --show-scope --get gpg.format
```

Expected:

```text
ssh
```

If missing or different:

```bash
git config --global gpg.format ssh
```

______________________________________________________________________

### Git is using the wrong signing key

Check:

```bash
git config --show-origin --show-scope --get user.signingkey
```

Set the correct public key globally:

```bash
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

Or locally for one repository:

```bash
git config --local user.signingkey ~/.ssh/work_signing_key.pub
```

______________________________________________________________________

### Verification fails: "No principal matched" / signing key not in allowed signers

Inspect which key signed the commit:

```bash
git cat-file -p HEAD | sed -n '/BEGIN SSH SIGNATURE/,/END SSH SIGNATURE/p'
```

List candidate public keys and their fingerprints:

```bash
for k in ~/.ssh/*.pub; do ssh-keygen -lf "$k"; done
```

Add the matching key to `~/.config/git/allowed_signers` under the same email used as the commit author.

______________________________________________________________________

### Commits are being signed automatically but should not be

Check:

```bash
git config --show-origin --show-scope --get commit.gpgsign
```

Unset it:

```bash
git config --global --unset commit.gpgsign
git config --local --unset commit.gpgsign
```

When unset, Git defaults to no automatic signing.

______________________________________________________________________

### GitHub does not show `Verified`

Check your Git commit email:

```bash
git config --show-origin --show-scope --get user.email
```

Set it to an email associated with your GitHub account:

```bash
git config --global user.email "your-email@example.com"
```

Or locally:

```bash
git config --local user.email "work@example.com"
```

Also confirm your SSH public key was added as a GitHub **Signing Key**, not only as an **Authentication Key**.

______________________________________________________________________

## 17. Useful Commands Summary

Check signing-related config:

```bash
git config --list --show-origin --show-scope | grep -E 'user.name|user.email|user.signingkey|commit.gpgsign|gpg.format|gpg.program|gpg.ssh.allowedSignersFile|tag.gpgsign'
```

Configure SSH signing globally (manual signing, with verification):

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global --unset commit.gpgsign 2>/dev/null || true

mkdir -p ~/.config/git
echo "your-email@example.com namespaces=\"git\" $(cat ~/.ssh/id_ed25519.pub)" \
  > ~/.config/git/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

Configure SSH signing locally (manual signing):

```bash
git config --local gpg.format ssh
git config --local user.signingkey ~/.ssh/id_ed25519.pub
```

Explicitly create a signed commit:

```bash
git commit -S -m "your commit message"
```

Create an unsigned commit:

```bash
git commit -m "your commit message"
```

Verify latest commit:

```bash
git log --show-signature -1
git verify-commit HEAD
```

Enable automatic signing globally (optional):

```bash
git config --global commit.gpgsign true
```

Disable automatic signing globally (back to default):

```bash
git config --global --unset commit.gpgsign
```

Push commit:

```bash
git push
```
