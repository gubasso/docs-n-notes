# osc / OBS authentication inside a dctl devcontainer

How to make `osc` (the openSUSE Build Service CLI) authenticate cleanly
from inside a [dctl](https://github.com/devcontainerctl)-managed
devcontainer, without weakening the host setup and without relying on
graphical keyrings that don't exist inside the container.

> Audience: anyone running `osc` from inside a devcontainer where the
> host already has a working interactive `osc` setup (typically backed
> by KWallet / GNOME Keyring / similar).
>
> Scope: this doc targets the **public openSUSE OBS instance**
> (`https://api.opensuse.org` / `https://build.opensuse.org`). For
> SUSE's internal IBS or a self-hosted OBS instance with SSH-key auth
> enabled, see the "Future / SUSE IBS only" section near the end.

---

## Why this needs a deliberate setup

`osc` reads its config from `~/.config/osc/oscrc`. Each API URL gets
its own section:

```ini
[https://api.opensuse.org]
user = <obs-username>
credentials_mgr_class = osc.credentials.KeyringCredentialsManager:keyring.backends.kwallet.DBusKeyring
```

The host usually pins a `credentials_mgr_class` that delegates to a
**graphical keyring** (KWallet via D-Bus, GNOME Secret Service, etc.).
Inside a typical devcontainer there is **no D-Bus session, no Secret
Service daemon, and no graphical keyring**, so `osc` fails at startup
with:

```
Unable to instantiate creds mgr (section: https://api.opensuse.org)
Please enter new credentials.
```

This happens before any network call — `import keyring` blows up during
module load. The `--no-keyring` / `--no-gnome-keyring` flags do *not*
help, because keyring is imported before argparse runs
([osc#785](https://github.com/openSUSE/osc/issues/785)).

The fix is **not** "downgrade the host backend". It is "give the
container its own osc configuration, selected per-environment".

### Why not SSH-key auth?

The natural ask is "use SSH-key auth — no password on disk at all". On
the public `build.opensuse.org` instance, this is **not currently
viable** (as of 2026-06):

- The feature request, [openSUSE/open-build-service#7842](https://github.com/openSUSE/open-build-service/issues/7842),
  has been open since July 2019 with no assignee, no merged PR, and no
  milestone.
- Server-side SSH `Signature` auth (the `ssh-keygen -Y sign` flow) is
  deployed only on **SUSE's internal IBS** (`build.suse.de`), per the
  [SUSE Communities MFA article](https://www.suse.com/c/multi-factor-authentication-on-suses-build-service/)
  (June 2025). That article explicitly notes the public OBS doesn't
  have it yet.
- There is **no "SSH Public Keys" UI** in the user profile on
  `build.opensuse.org`. The "Tokens" page that does exist is for
  **OBS application tokens** — a completely different feature (see
  Tier 3 below).
- The `osc` client *does* support `sshkey =` in oscrc since
  [osc#1083](https://github.com/openSUSE/osc/pull/1083) (July 2022),
  but the option is only meaningful when the *server* accepts
  `Signature` auth. Against `build.opensuse.org` it silently degrades
  to (or fails at) password auth.

Re-evaluate this section when #7842 closes or the SUSE OBS team
announces SSH-key auth on the public instance.

---

## Decision matrix

`osc`'s `oscrc` is keyed by *apiurl*, not by a free-form profile name.
You cannot have two `[https://api.opensuse.org]` sections in the same
file with different backends. The escape hatch is `OSC_CONFIG` (env
var) or `--config` (CLI flag), which selects an alternative `oscrc`
file. Build on that.

Ranked for the **public `build.opensuse.org`** instance:

| Tier | Mechanism | Secret stored where | Revocation | Recommended? |
|------|-----------|---------------------|------------|--------------|
| 1 | Obfuscated password (`ObfuscatedConfigFileCredentialsManager`) in a container-only `oscrc` | base64+bz2-encoded in oscrc on host, read-only mounted | Rotate OBS password (or dedicated sub-account) | **Yes** — current best |
| 2 | Plaintext password (`PlaintextConfigFileCredentialsManager`) in a container-only `oscrc` | Plaintext in oscrc on host, read-only mounted | Same | Fallback only |
| 3 | OBS application tokens | Token in a config file or env var | Revoke in OBS web UI | Supplementary — covers only `rebuild` / `release` / `runservice` / `workflow` trigger verbs, not `branch` / `co` / `ci` / `buildinfo` / `buildlog` |
| 4 | SSH-key auth (`sshkey =` + `Signature` HTTP auth) | Private key on host, mounted read-only | Delete public key in OBS | **Not on public OBS as of 2026-06** — usable only on SUSE IBS or a self-hosted OBS that's been patched ([#7842](https://github.com/openSUSE/open-build-service/issues/7842)) |
| 5 | Forward host D-Bus / Secret Service socket into container | Host keyring | Same as host | Avoid — large attack surface, uid mismatches, fragile |

Tier 1 is the primary path covered below. Tier 2 is a small variation.
Tier 3 is a useful supplement for trigger-only verbs but never a
replacement. Tier 4 is documented for completeness and for readers on
IBS / self-hosted OBS. Tier 5 is mentioned only to be ruled out.

---

## Prerequisites

- `osc` installed inside the container image (typically from the distro
  repos via zypper).
- The container user's UID matches the host user's UID (so bind-mounted
  files have the right ownership). dctl does this by default.
- dctl is configured to compose `devcontainer.json` from layered
  fragments (base → tool image → per-project leaf), so you have a leaf
  layer you can edit.
- An OBS account on the target instance (this guide assumes
  `https://api.opensuse.org`).

You'll be touching files in three places:

| Path (host-side) | Purpose |
|------------------|---------|
| `${HOME}/.config/osc-container/oscrc` | Container-only `oscrc`, never read on the host |
| `<dctl-config-root>/devcontainer/<project>/devcontainer.json` | Project leaf layer: declares the mount + `OSC_CONFIG` env |
| (optional, Tier 2) the same `oscrc` with a different `credentials_mgr_class` line | Use plaintext instead of obfuscated |

The host's existing `~/.config/osc/oscrc` is **not modified**.

---

## Tier 1 — Obfuscated password in a container-only oscrc (recommended)

`ObfuscatedConfigFileCredentialsManager` stores the password as
`base64(bz2(plaintext))` directly in the oscrc file — no keyring, no
D-Bus, no graphical session needed. It works headless and survives
container recreates because the file is mounted from the host.

**Important up-front:** "obfuscated" is *not* encryption. Anyone with
read access to the file can recover the password. Treat the file
itself as a secret of the same sensitivity as the password. The steps
below assume:

- File permissions `600` on the host (tight enough that only your user
  can read it).
- A bind mount that is **read-only** so the container cannot corrupt
  the file.
- Either an OBS account / sub-account dedicated to the container, or a
  password that is **not reused** for any other service. The blast
  radius if the file leaks is "full authority of whatever OBS identity
  it holds", so keep that identity narrow.
- A rotation discipline (calendar reminder, password manager note,
  whatever you use elsewhere). Rotate immediately if the host or any
  backup is ever exposed.

### Step 1. Create the container-only oscrc directory

```bash
mkdir -p ~/.config/osc-container
chmod 700 ~/.config/osc-container
```

The directory lives **outside** `~/.config/osc/` so the host's regular
`osc` tooling doesn't pick it up by accident.

### Step 2. Write the container-only oscrc

```ini
# ~/.config/osc-container/oscrc

[general]
apiurl = <obs-api-url>

[<obs-api-url>]
user = <obs-username>
credentials_mgr_class = osc.credentials.ObfuscatedConfigFileCredentialsManager
```

Placeholders:
- `<obs-api-url>` — e.g. `https://api.opensuse.org` for the public
  openSUSE OBS, or your self-hosted OBS instance.
- `<obs-username>` — your OBS account (or dedicated sub-account)
  username.

Note: `pass =` is intentionally absent at this stage. Step 3 appends
it in obfuscated form. (Older copies of this doc said "`osc` will
write it back on first interactive use" — that interactive flow no
longer works on current osc; see Troubleshooting.)

```bash
chmod 600 ~/.config/osc-container/oscrc
```

### Step 3. Seed the obfuscated password once, on the host

Compute the obfuscated `pass =` line in pure Python and append it to
the oscrc. The format (`base64(bz2(password.encode("ascii")))`,
stored under the `pass` key) matches what
`ObfuscatedConfigFileCredentialsManager` writes itself — verified
against
[`osc/credentials.py`](https://github.com/openSUSE/osc/blob/master/osc/credentials.py).

```bash
python3 -c '
import base64, bz2, getpass
p = getpass.getpass("OBS password: ")
print("pass =", base64.b64encode(bz2.compress(p.encode("ascii"))).decode("ascii"))
' >> ~/.config/osc-container/oscrc

chmod 600 ~/.config/osc-container/oscrc
```

The one-liner is stdlib-only and intentionally inline so this doc
stays portable — no external script or repo required. If you prefer
a named tool, lift the body of the one-liner into
`~/.local/bin/obfuscate-osc-password`, `chmod +x`, then:

```bash
obfuscate-osc-password >> ~/.config/osc-container/oscrc
chmod 600 ~/.config/osc-container/oscrc
```

Either way, the helper / one-liner never touches the oscrc itself —
it just prints the `pass = <blob>` line for you to redirect. This
keeps the secret out of any script's process memory beyond the
duration of one stdout write.

Verify the file now has all three relevant lines:

```bash
grep -E '^(user|pass|credentials_mgr_class)' ~/.config/osc-container/oscrc
```

You should see `user=…`, `pass=…` (an opaque base64+bz2 blob), and
`credentials_mgr_class=…`.

> **Never commit the seeded oscrc to any repo (dotfiles included).**
> The obfuscation is reversible by anyone with read access to the
> file. Treat the seeded oscrc the same way you treat a plaintext
> password file: live only on the host, mode `600`, owner-only dir,
> rotated on a calendar, and explicitly out of every version-control
> tree.

> **Why not the interactive `osc … api /person/<user>` seed?** That
> flow is documented in older copies of this doc but crashes on
> current `osc` with
> `TypeError: object of type 'NoneType' has no len()` —
> see the [Troubleshooting entry below](#typeerror-object-of-type-nonetype-has-no-len-during-seed).
> The Python pre-seed above bypasses the broken interactive path.

### Step 4. Wire it into the dctl leaf layer

Edit your project's devcontainer leaf layer (path varies — typical
locations are `<dctl-config-root>/devcontainer/<project>/devcontainer.json`,
or a `.devcontainer/devcontainer.json` inside the project repo):

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.config/osc-container/oscrc,target=${containerEnv:HOME}/.config/osc/oscrc,type=bind,readonly"
  ],
  "containerEnv": {
    "OSC_CONFIG": "${containerEnv:HOME}/.config/osc/oscrc"
  }
}
```

Notes:
- The mount maps the container-only file onto the **standard**
  in-container location (`~/.config/osc/oscrc`). Scripts that don't
  know about `OSC_CONFIG` still work via the default file lookup.
- `OSC_CONFIG` is belt-and-braces — explicit and discoverable in
  `env | grep OSC`.
- The mount is `readonly`. This is safe because Step 3 already wrote
  the obfuscated `pass =` line; nothing the container does needs to
  modify the oscrc.
- If you previously had a 1:1 mount of `~/.config/osc` from the host
  (e.g. to ride on the host's keyring backend), **remove that mount
  entry** — the new one replaces it.

### Step 5. Rebuild the container and verify

From the host, recreate the container so the new mount takes effect:

```bash
# dctl-specific recreate command — varies by version
dctl ws reup
```

Inside the container:

```bash
# 1. OSC_CONFIG is set, and points to the bind-mounted file.
echo "$OSC_CONFIG"

# 2. The file is visible and has the expected backend.
grep -E 'credentials_mgr_class|user|pass' ~/.config/osc/oscrc

# 3. Auth round-trips to OBS.
osc -A <obs-api-url> api /person/<obs-username> >/dev/null && echo OK
```

The third command is the canonical scripted auth check: it's
read-only, fully non-interactive, requires authentication (unlike
`/about` or `/configuration` which are often public on OBS), exits 0
on success, and 401s cleanly on bad creds.

---

## Tier 2 — Plaintext password in a container-only oscrc (fallback)

If for some reason `ObfuscatedConfigFileCredentialsManager` doesn't
work on your `osc` version, use `PlaintextConfigFileCredentialsManager`
instead. Everything else (Steps 1, 3–5) is identical. Only the oscrc
content differs:

```ini
# ~/.config/osc-container/oscrc

[general]
apiurl = <obs-api-url>

[<obs-api-url>]
user = <obs-username>
pass = <obs-password>
credentials_mgr_class = osc.credentials.PlaintextConfigFileCredentialsManager
```

Here you write the `pass =` line yourself (no seeding step needed).

Tier 2's only difference from Tier 1 is whether the password is
recoverable from the file by `grep` (plaintext) or
`base64 -d | bunzip2` (obfuscated). Same blast radius if the file
leaks — apply the same security caveats from Tier 1.

---

## Tier 3 — OBS application tokens (supplementary)

The "Manage Your Tokens" page in your OBS profile creates
[application tokens](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-authorization-token).
They have desirable properties:

- Scoped per package.
- Revocable from the web UI without touching your password.
- No `credentials_mgr_class` complications — authenticated via HTTP
  Basic with the token as the password.

But they only authorize a narrow set of **trigger** operations:
`rebuild`, `release`, `runservice`, and `workflow`. They **cannot** be
used for `branch`, `co`, `ci`, `buildinfo`, `buildlog`, `meta`, etc. —
i.e. anything that reads or writes source, browses build state, or
manipulates project metadata.

So tokens are useful when:
- You have a CI / automation flow that only triggers rebuilds, OR
- You want a *second* identity (alongside Tier 1) whose authority is
  narrowly scoped for one specific automated action.

They do not replace Tier 1 for a general `osc` workflow.

---

## Tier 4 — SSH-key auth (future / SUSE IBS only — NOT on public OBS)

Documented for readers on SUSE's internal IBS or on a self-hosted OBS
instance with SSH `Signature` auth enabled.

The shape mirrors Tier 1, but with:

```ini
[<obs-api-url>]
user = <obs-username>
sshkey = ~/.ssh/<obs-container-key>
credentials_mgr_class = osc.credentials.TransientCredentialsManager
```

…plus an extra read-only mount for the private key:

```json
"source=${localEnv:HOME}/.ssh/<obs-container-key>,target=${containerEnv:HOME}/.ssh/<obs-container-key>,type=bind,readonly"
```

Public key is registered in the OBS web UI (where supported) or via
the OBS REST API. `TransientCredentialsManager` is the lightest
backend that satisfies the config schema without touching any keyring;
with `sshkey =` set, `osc` never asks it for a password.

**Do not enable this against `build.opensuse.org`** until
[#7842](https://github.com/openSUSE/open-build-service/issues/7842) is
closed and the feature is deployed. It will silently fall back to (or
fail at) password auth.

---

## Tier 5 — Forward host D-Bus / Secret Service (avoid)

You can mount the host's D-Bus user session socket into the container
to reuse the host keyring. This is mentioned only to be ruled out —
it requires `--privileged` or extra capabilities, trusts the host's
uid, is fragile across host/container user-id mismatches, and
substantially expands the container's attack surface. Tier 1 achieves
the same end (auth works in the container) without any of those
costs.

---

## What about just changing the host?

Don't. If you swap the host's `credentials_mgr_class` from a keyring
backend to obfuscated or plaintext, you've made the **host** strictly
less safe to fix a container-side problem. The container-only-oscrc
approach above:

- Leaves the host's keyring-backed setup intact.
- Confines any obfuscated or plaintext secret to a single file with
  one purpose.
- Lets you revoke the container's authority (rotate the dedicated
  password, or revoke the dedicated sub-account) without touching the
  host's main credentials.

---

## Troubleshooting

### `Unable to instantiate creds mgr (section: …)`

The oscrc the container is reading still names a keyring backend.
Check, from inside the container:

```bash
echo "$OSC_CONFIG"
grep -E 'credentials_mgr_class|user|pass' "$OSC_CONFIG"
```

The `credentials_mgr_class` line must be either
`osc.credentials.ObfuscatedConfigFileCredentialsManager` or
`osc.credentials.PlaintextConfigFileCredentialsManager`. **Never a
`KeyringCredentialsManager` variant inside a container**, unless
you've explicitly gone the Tier 5 route (forwarded a Secret Service /
KWallet socket — not recommended).

If the wrong file is being read, suspect:
- `OSC_CONFIG` not exported in the container environment.
- The bind mount target path doesn't match where `osc` looks (i.e. the
  file in `~/.config/osc/oscrc` is still an old image-baked copy).

### `TypeError: object of type 'NoneType' has no len()` during seed

Symptom: running `osc -A <apiurl> api /person/<user>` against a
pass-less oscrc (the "let osc prompt and write back" flow that older
versions of this doc described) crashes before reaching the prompt:

```
File ".../osc/connection.py", line 652, in __init__
    self.basic_auth_password = bool(basic_auth_password)
  File ".../collections/__init__.py", line 1413, in __len__
    return len(self.data)
TypeError: object of type 'NoneType' has no len()
```

Root cause (current osc, e.g. Tumbleweed / python3.13):

1. `ObfuscatedConfigFileCredentialsManager.get_password()` finds no
   stored `pass`/`passx` and returns a `conf.Password(None)` wrapper.
2. `connection.py:652` calls `bool()` on that wrapper.
3. `conf.Password` is a `UserString` subclass with no `__bool__`, so
   Python falls back to `__len__` → `len(self.data)` → `len(None)` →
   `TypeError`.

This is distinct from the earlier fix in
[osc#1083](https://github.com/openSUSE/osc/pull/1083) and is not yet
patched upstream. The fix is to **not run the interactive osc seed**
— use the Python pre-seed in Tier 1 Step 3, which writes the
obfuscated `pass =` line directly and bypasses the broken code path.

### `osc` re-prompts every run after seeding

If you previously used the (now-removed) interactive seed flow with a
read-only-mounted oscrc, osc couldn't write the obfuscated `pass =`
line back, so it re-prompted every run. Re-do Tier 1 Step 3 with the
Python pre-seed against a writable oscrc, then re-mount read-only.

### `HTTP Error 401: authentication required`

The credentials in the oscrc are wrong or expired. Re-run the seeding
step (Tier 1 Step 3) to overwrite the `pass =` line with current
credentials.

### `osc whoami` is "not a valid choice"

`osc` has no `whoami` subcommand. Use `osc api /person/<user>` or
`osc whois <user>` instead.

### Tokens UI exists but does nothing for general `osc` use

Correct — application tokens only authorize trigger verbs (`rebuild`,
`release`, `runservice`, `workflow`). For everything else, you still
need username+password (Tier 1) or SSH-key auth (Tier 4, where
available).

### oscrc is mounted but `osc` still reads `~/.config/osc/oscrc` from the image

Confirm `OSC_CONFIG` is exported in the container's environment, and
that the bind mount succeeded:

```bash
env | grep ^OSC_CONFIG
mount | grep -E '(oscrc|osc-container)'
ls -l ~/.config/osc/oscrc
```

### dctl doesn't pick up the new mount

Recreate the container, don't just restart it. Bind mounts are fixed
at `docker create` time:

```bash
dctl ws reup  # or your dctl flavor's recreate verb
```

---

## Quick reference — the minimal in-container check

After the setup above, this one line is all the proof you need that
auth is wired up correctly:

```bash
osc -A <obs-api-url> api /person/<obs-username> >/dev/null && echo OK
```

Exit 0 → ready to use any `osc` verb. Exit non-zero → walk the
troubleshooting list above.

---

## References

- [openSUSE/osc — source](https://github.com/openSUSE/osc)
- [osc/credentials.py — credentials manager classes (Obfuscated{en,de}code_password)](https://github.com/openSUSE/osc/blob/master/osc/credentials.py)
- [osc/conf.py — `Password` (UserString subclass, lacks `__bool__`)](https://github.com/openSUSE/osc/blob/master/osc/conf.py)
- [osc/connection.py — `SignatureAuthHandler.__init__` (the `bool(basic_auth_password)` site)](https://github.com/openSUSE/osc/blob/master/osc/connection.py)
- [oscrc(5) man page](https://manpages.opensuse.org/Tumbleweed/osc/oscrc.5.en.html)
- [osc(1) man page](https://linux.die.net/man/1/osc)
- [osc#785 — `--no-keyring` doesn't actually disable keyring import](https://github.com/openSUSE/osc/issues/785)
- [osc#441 — keyring init failure modes](https://github.com/openSUSE/osc/issues/441)
- [osc#1083 — `sshkey` crash fix when `pass` is unset (related but distinct from the current `bool()` regression)](https://github.com/openSUSE/osc/pull/1083)
- [openSUSE/open-build-service#7842 — Authentication with SSH key (open since 2019)](https://github.com/openSUSE/open-build-service/issues/7842)
- [SUSE Communities — Multi-factor authentication on SUSE's Build Service (June 2025)](https://www.suse.com/c/multi-factor-authentication-on-suses-build-service/)
- [OBS Authorization / Tokens — user guide](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-authorization-token)
- [Dev Container spec](https://containers.dev/implementors/spec/) — for the `mounts` / `containerEnv` schema dctl composes
