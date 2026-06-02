# Common mistakes & pitfalls when running OBS home projects

> Companion to [`setup-home-project-from-upstream.md`](setup-home-project-from-upstream.md) and
> [`broken-state-link-drift.md`](broken-state-link-drift.md). The happy-path guide says "do these
> steps in order"; this doc says "and here are the steps that bit me — don't repeat them."

Every entry is distilled from a real incident. Each entry has a fixed shape: **What** (the mistake),
**Why it bit** (what went wrong), **Avoid by** (the rule). Read end-to-end the first time; the table
of contents is the cheat sheet after that.

Each home-project repo that uses this pattern carries its own chronological mistakes-log in its own
`docs/` (mapping concrete incidents to the §-numbered entries below); this doc is the
project-agnostic distillation.

## Contents

- [1. Auth setup](#1-auth-setup)
  - 1.1. Bind-mounting a host `oscrc` that uses a keyring backend
  - 1.2. Using `osc … api /person/<user>` as the seed step
  - 1.3. Pre-creating bind-mount parents at container-start time instead of image-build time
- [2. Workspace & converger discipline](#2-workspace--converger-discipline)
  - 2.1. Renaming a satellite patch without `osc rm`'ing the old one
  - 2.2. Converger script that `osc add`s but never `osc rm`s
  - 2.3. Editing `_link` / patches in the wrong workspace
  - 2.4. Running the converger from a container missing `obs-build`
- [3. CLI verb foot-guns](#3-cli-verb-foot-guns)
  - 3.1. `osc getbinaries <prj> <pkg> <repo> <arch> binaries` — the 5th positional is a FILE
  - 3.2. Polling `osc results` in a loop instead of `osc results --watch`
  - 3.3. Inventing CLI verbs (`dctl image rebuild`, `osc whoami`) instead of checking
- [4. Patch / link evolution](#4-patch--link-evolution)
  - 4.1. Widening a `%if 0%{?sle_version}` gate without checking the newly-targeted SPs' build
    chains
  - 4.2. Trusting the disttag for python ABI proof
  - 4.3. Using `<topadd>` when you actually need `<apply>`
- [5. Diagnostic discipline](#5-diagnostic-discipline)
  - 5.1. Acting on `osc results` (plain) when only `-v` carries the message
  - 5.2. Treating "succeeded" per-package as terminal when the repository is still publishing
  - 5.3. Branching on `broken` as if it were `unresolvable`
  - 5.4. Fixing first, capturing later
  - 5.5. Self-repairing through preflight failures

---

## 1. Auth setup

### 1.1. Bind-mounting a host `oscrc` that uses a keyring backend

**What.** Mounting `~/.config/osc/oscrc` 1:1 from a desktop host into a headless container, where
the host file pins
`credentials_mgr_class = osc.credentials.KeyringCredentialsManager:keyring.backends.kwallet.DBusKeyring`
(or any GNOME / KWallet variant).

**Why it bit.** The container has no D-Bus session, no graphical keyring, no wallet daemon. `osc`
aborts at credentials-manager construction — _before_ any HTTPS attempt — with
`Unable to
instantiate creds mgr`. The error is opaque if you don't know about the
credentials_mgr_class line.

**Avoid by.** Keep a container-only oscrc, separate from the host's. The container file uses
`osc.credentials.ObfuscatedConfigFileCredentialsManager` and the obfuscated
`pass = base64(bz2(plaintext))` line. Bind-mount **that file** into the container; leave the host's
KWallet-backed oscrc alone. See [`auth-in-devcontainers.md`](auth-in-devcontainers.md) for the
Tier-1 walkthrough.

### 1.2. Using `osc … api /person/<user>` as the seed step

**What.** Running `osc -A https://api.opensuse.org api /person/<user>` on a pass-less oscrc,
expecting `osc` to prompt for the password and write the obfuscated line back.

**Why it bit.** `ObfuscatedConfigFileCredentialsManager` returns a `Password(None)` wrapper when no
`pass =` is stored; `osc/connection.py:652` calls `bool()` on it; the `Password` subclass has no
`__bool__`, Python falls back to `__len__`, `len(None)` raises
`TypeError: object of type 'NoneType' has no
len()`. The flow that _was_ recommended in older docs
simply crashes on current Tumbleweed (python3.13). Distinct from openSUSE/osc#1083; no upstream
patch at time of writing.

**Avoid by.** Pre-seed the obfuscated `pass =` line directly with a helper (`obfuscate-osc-password`
writes `base64(bz2(plaintext))` in the format `osc` would produce). Then the auth verification probe
(`osc … api /person/<user>`) only ever runs against a fully-seeded oscrc and the broken code path is
bypassed.

### 1.3. Pre-creating bind-mount parents at container-start time instead of image-build time

**What.** The container's `~/.config/osc/oscrc` is bind-mounted by the runtime (Docker, podman). If
`~/.config/osc/` doesn't already exist in the image, the container runtime creates the bind-mount
parent dir at container-start time — owned by **root**, mode 755. Then `osc`'s first HTTPS call hits
`os.makedirs(self.dir_path, mode=0o700)` for `trusted-certs/` and gets `PermissionError [Errno 13]`.

**Why it bit.** The fix has to land at _image_ build time, not container start. A `dctl ws reup` (or
`docker compose up`) by itself won't pick up a Dockerfile edit. You need
`dctl image build --full-rebuild` (or `docker build --no-cache`) first.

**Avoid by.** In the image Dockerfile, explicitly pre-create every bind-mount parent you'll mount
into, owned by the container user:

```dockerfile
RUN install -d -m 0755 -o $USERNAME -g $USERNAME \
        /home/$USERNAME/.config/osc \
        /home/$USERNAME/.config/<other-things>
```

And remember the diagnostic: `stat -c '%U:%G %a Birth=%w' <dir>`. If `Birth` matches container-start
time, the dir was created by the runtime, not baked in. If it matches image-build time (older), the
dir is in the image correctly.

---

## 2. Workspace & converger discipline

### 2.1. Renaming a satellite patch without `osc rm`'ing the old one

**What.** Bumping the `_link.apply` filename from `<old>.patch` to `<new>.patch`, committing the
`_link` change and the new patch file, but never `osc rm`'ing the old patch server-side.

**Why it bit.** OBS's source service sees a source tree containing `_link` + the _old_ patch, with
`_link.apply` referencing the _new_ patch that isn't there. Source-service expansion HTTP 400's.
Every lane reports `broken: patch '<new>' does not exist`. The resolver never runs, the buildlog
never exists, every diagnostic that expects a build (`osc buildinfo`, `osc buildlog`) returns
nothing useful. The error message is precise — but only if you ask for it with `osc results -v` or
hit `?expand=1` directly.

**Avoid by.** Always treat patch renames as a three-step server-side operation in **one commit**:
`osc add <new>.patch && osc rm
<old>.patch && osc ci`. If you're scripting it, see §2.2. Full
diagnosis + recovery: [`broken-state-link-drift.md`](broken-state-link-drift.md).

### 2.2. Converger script that `osc add`s but never `osc rm`s

**What.** A bootstrap / converger script that copies the new patch into the workspace, runs
`osc add _link <new-patch>.patch`, then `osc ci` — without enumerating server-tracked files and
`osc rm`ing any obsolete `*.patch`. Symmetric to §2.1, just baked into automation: every run
converges the source tree forward, never prunes.

**Why it bit.** As soon as `_link` references a new filename, the script _thinks_ it's converging
(the new file is added, the commit lands), but the old patch stays tracked and the source tree is
left inconsistent with `_link`. The script reports success; the next `osc
results` reports `broken`
on every lane.

**Avoid by.** Any converger that mutates patches must enumerate the server's tracked files filtered
to the relevant glob (`*.patch`, `*.tar.gz`, whatever), and `osc rm` anything that isn't the current
intended file:

```bash
while IFS= read -r tracked; do
  [[ -z "${tracked}" ]] && continue
  [[ "${tracked}" == "${current_patch_name}" ]] && continue
  case "${tracked}" in
    *.patch)
      osc rm "${tracked}" 2>/dev/null || osc rm --force "${tracked}"
      ;;
  esac
done < <(osc ls "${PROJECT}" "${PKG}" 2>/dev/null || true)
```

The `osc add` / `osc rm` / `osc ci` sequence must be **all in the same commit** so the source tree
is consistent at every revision — not partway through.

### 2.3. Editing `_link` / patches in the wrong workspace

**What.** Editing the satellite's `_link` file inside the source-code repository (e.g.
`scripts/obs-overlay/_link.tmpl`) expecting OBS to pick up the change — without running the
converger or `osc co`ing the actual OBS package, modifying its `_link`, and `osc ci`ing.

**Why it bit.** The OBS workspace (`~/Projects/_obs-work/<project>/<pkg>/`) is the authoritative
copy the OBS server reads from. The source-code repo's `_link.tmpl` is only a template the converger
writes from. Editing the template without running the converger leaves OBS unchanged.

**Avoid by.** Either:

- run the converger after any template / patch edit in the source-code repo, OR
- edit directly in the OBS workspace (`~/Projects/_obs-work/<project>/<pkg>/`), commit there with
  `osc
  ci`, then back-port the change to the source-code template afterwards so the next converger
  run reproduces the same state.

The "right" answer depends on what the change is for. For tracked, reproducible state: source-code
template + converger. For one-off debugging: OBS workspace directly.

### 2.4. Running the converger from a container missing `obs-build`

**What.** Running `bash obs-overlay-bootstrap.sh` (or equivalent) in a container that has `osc`
installed but NOT the `obs-build` package (which provides `/usr/lib/build/vc`).

**Why it bit.** The script's `osc vc -m "…"` step calls out to `/usr/lib/build/vc` to format a
`.changes` entry; without it the binary doesn't exist and `osc vc` exits nonzero with
`Error: vc ('/usr/lib/build/vc') command not found / Install the
build package from
http://download.opensuse.org/repositories/openSUSE:/Tools/`.
If the script doesn't guard the call, the whole converger crashes _without_ committing the actual
source changes — leaving the workspace in `?` / `!` / `M` mess that's confusing to recover from.

**Avoid by.** Either install `obs-build` in the environment that runs the converger
(`zypper in obs-build` on SUSE / openSUSE), or guard the `osc vc` call in the script so a missing
`/usr/lib/build/vc` only drops the `.changes` entry, not the whole commit:

```bash
if ! osc vc -m "${msg}"; then
  echo "WARN: osc vc unavailable; committing without .changes update"
fi
osc ci -m "${msg}"
```

For home/test projects, skipping `.changes` is acceptable; for real maintainer flows, install
`obs-build` and treat its absence as a hard error.

---

## 3. CLI verb foot-guns

### 3.1. `osc getbinaries <prj> <pkg> <repo> <arch> binaries` — the 5th positional is a FILE

**What.** Trying to download all built RPMs into a directory named `binaries/` by writing the
directory as the 5th positional:

```bash
osc getbinaries home:me:proj mypkg SLE_15_SP6 x86_64 binaries
```

**Why it bit.** `osc getbinaries`'s grammar is `PROJECT PACKAGE REPOSITORY ARCHITECTURE [FILE]`. The
5th positional is _a single filename to download_, not a destination dir. Passing `binaries` makes
`osc` try to download one file literally named `binaries`. It silently exits zero with no output.
The subsequent `rpm -qpl binaries/*.rpm` looks at an empty directory and matches nothing — and the
operator wastes time wondering why the build "succeeded but produced no files."

**Avoid by.** Always use the `-d <dir>` flag for the destination:

```bash
mkdir -p binaries
osc getbinaries -d binaries home:me:proj mypkg SLE_15_SP6 x86_64
```

The flag is unambiguous; the positional form silently picks a path shape you didn't intend.

### 3.2. Polling `osc results` in a loop instead of `osc results --watch`

**What.** A shell or script loop like `while ! osc results … | grep -q succeeded; do sleep 10; done`
to wait for a build.

**Why it bit.** Each `osc results` call opens a new HTTPS connection, hits the API server, and uses
your auth quota for no reason. With many lanes and many packages, this is also slow. The correct
mechanism is the server-side long-poll built into `osc
results --watch`, which holds a single
connection open and only returns when something changes.

**Avoid by.** `osc -A <api> results --watch <project> <package>`. Ctrl-C is safe — the server keeps
building even if the watch detaches. If you need to do other work while waiting, background the
watch (`&` or your shell's equivalent) and check its tail periodically.

### 3.3. Inventing CLI verbs (`dctl image rebuild`, `osc whoami`) instead of checking

**What.** Writing scripts or running ad-hoc commands using verbs you _assume_ exist
(`dctl image rebuild`, `osc whoami`, `osc reset`) because they're the obvious noun + verb. Or
because some other tool in the same family has them.

**Why it bit.** These specific verbs don't exist.

- `dctl image rebuild` → the verb is `dctl image build [--full-rebuild]`.
- `osc whoami` → `osc` has no `whoami`; use `osc -A <api> api /person/<user>` for an auth check.
- `osc reset` → there's no top-level reset; you want `osc revert <file>` or `osc up -r <rev>`.

Running an invented verb gets you "unknown command" — easy to spot once you try. Writing it into a
script you commit and forget is worse: it stays broken until the next run.

**Avoid by.** Before scripting around a verb, confirm with `<tool> --help`, `<tool> <verb> --help`,
or `man <tool>`. For `osc` specifically, the authoritative reference is
<https://manpages.opensuse.org/Tumbleweed/osc/osc.1.en.html>.

---

## 4. Patch / link evolution

### 4.1. Widening a `%if 0%{?sle_version}` gate without checking the newly-targeted SPs' build chains

**What.** Changing a spec / patch's `%if 0%{?sle_version} >= 150700` (SP7-only) to `>= 150400` (SP4
onward) to make the satellite build on more SPs — without checking whether the SPs you've just added
support the things inside the `%if` arm (e.g. `%pythons=python311`, or a specific BR).

**Why it bit.** SP4's `SUSE:SLE-15-SP4:GA` doesn't ship the python311 build chain
(`python311-setuptools`, `python311-devel`, `python311-PyYAML`, …). The widened gate activated the
`%pythons=python311` pin on SP4, the SP4 resolver couldn't satisfy
`BuildRequires: python311-setuptools`, lane went `unresolvable` for both the base package and the
satellite. The fix is real work (branch the python311 chain into the home project) — much more
expensive than the gate widening that triggered it.

**Avoid by.** Before merging a gate change, run for every newly- targeted SP:

```bash
osc -A <api> rebuild <project> <pkg> <new-lane> x86_64
osc -A <api> results --watch <project> <pkg>
osc -A <api> results -v <project> <pkg>
```

If any new lane goes `unresolvable`, the gate is wider than the infrastructure can support. Either
narrow the gate back, or commit to branching the missing providers into the home project (see §4
"Branched providers" in [`setup-home-project-from-upstream.md`](setup-home-project-from-upstream.md)
for the pattern).

### 4.2. Trusting the disttag for python ABI proof

**What.** Looking at a built RPM and concluding "it's `150700.x.y.z`, so it must be using python311"
— without verifying.

**Why it bit.** The `150700` disttag only proves the RPM was built in the SP7 context; it says
nothing about which `%pythons` the spec resolved to. A spec that doesn't pin `%pythons` defaults to
whatever upstream considers "primary python" for that SP, which on SP4-SP6 is typically python3.6,
not python3.11.

**Avoid by.** Verify the python ABI by RPM name prefix and by payload paths:

```bash
osc -A <api> ls -b <project> <pkg> <repo> <arch>
# Pass: filename begins with python311-…
# Fail: filename begins with python3-… or python-…

rpm -qpl <rpm> | grep site-packages
# Pass: /usr/lib/python3.11/site-packages/…
# Fail: /usr/lib/python3.6/site-packages/…
```

If both don't match the base package's ABI, the cross-ABI install helper will (correctly) fail-fast
at runtime.

### 4.3. Using `<topadd>` when you actually need `<apply>`

**What.** Writing a `_link` with a `<patches><topadd>…</topadd></patches>` block to prepend a few
`%define` lines to the upstream spec — and then needing to change something in `%build`, `%install`,
or `%files` later.

**Why it bit.** `<topadd>` only inserts content at the top of the spec preamble. It can't change
anything below `%description`. As soon as your overlay needs to touch `%build` (e.g. swap `python3`
for `%{py3_exe}`) you have to migrate to `<apply
name="…patch"/>` anyway — and now you have two
changes to manage instead of one.

**Avoid by.** Default to `<apply name="…patch"/>` for any non-trivial overlay from day one. A
`.patch` file is a single auditable diff, code review sees one artifact, and patches survive
upstream version bumps as long as context lines match. Reserve `<topadd>` only for the
genuinely-trivial single-line preamble case where maintaining a separate patch file feels overkill —
and even there, think hard about whether it's worth the future migration cost.

---

## 5. Diagnostic discipline

### 5.1. Acting on `osc results` (plain) when only `-v` carries the message

**What.** Reading `osc results` (no `-v`), seeing `SLE_15_SP6 ... broken`, and starting to fix
something based on the state alone.

**Why it bit.** The plain form only shows the state code (`broken`, `unresolvable`, `failed`,
`succeeded`, etc.). The actual error message is in the status column of the **verbose** form.
Without `-v`, `broken` is unactionable — it could be link drift, patch-apply failure, missing source
file, …

**Avoid by.** First thing on any failure: re-run with `-v`. For `unresolvable` you also want
`osc buildinfo`; for `failed` you also want `osc buildlog | tail -200`. For `broken`, the verbose
status column is usually enough; if not, hit `osc api '/source/<prj>/<pkg>?expand=1'` directly — the
HTTP 400 body has the precise message.

### 5.2. Treating "succeeded" per-package as terminal when the repository is still publishing

**What.** Seeing `osc results` report `<pkg> finished` or `<pkg> succeeded`, immediately running
`osc getbinaries …`, and getting an empty result — then concluding the build failed.

**Why it bit.** OBS reports the per-package state (`succeeded`) separately from the per-repository
state (which is still `building` during the publish phase). `getbinaries` returns nothing until
publish completes for the package's repo. The package binary list
(`osc api /build/<prj>/<repo>/<arch>/<pkg>`) shows the RPM exists on the server while `getbinaries`
still returns empty — that combination is the smoking gun for "build succeeded, publish in
progress."

**Avoid by.** Either wait for the repository state to fully settle (`osc results --watch` returns
when EVERYTHING is terminal), or query the binary list directly with
`osc api
/build/<prj>/<repo>/<arch>/<pkg>` before calling `getbinaries`. If the list has the RPM,
retry `getbinaries` a moment later.

### 5.3. Branching on `broken` as if it were `unresolvable`

**What.** Treating `broken: patch '…' does not exist` as a BuildRequires problem — running
`osc buildinfo`, looking for missing provides, considering whether to branch a provider.

**Why it bit.** `broken` is **pre-build**: the source service couldn't even produce an expanded
source tree. The resolver never ran. There's no `buildinfo` to read because there was nothing to
resolve. Spending time on resolver diagnosis is pure waste.

**Avoid by.** Memorize the state machine:

| State                   | What ran                      | Recovery starts with                           |
| ----------------------- | ----------------------------- | ---------------------------------------------- |
| `broken`                | nothing (source svc)          | `osc results -v` → fix link/source-tree        |
| `unresolvable`          | source svc + resolver         | `osc buildinfo` → fix BR / branch provider     |
| `failed`                | source svc + resolver + build | `osc buildlog \| tail -200` → fix spec / patch |
| `succeeded`             | everything                    | done; verify payload                           |
| `disabled` / `excluded` | nothing (skipped)             | check `_meta` `<build>` / `<arch>`             |

### 5.4. Fixing first, capturing later

**What.** Hitting a failure, eyeballing the error, immediately trying a fix — without first
capturing the exact verbatim error message anywhere.

**Why it bit.** When the fix doesn't work, you can't even remember the precise wording of what you
were trying to fix, let alone correlate two similar-looking failures across runs. The next time the
same class of failure hits, the previous diagnostic trail is gone.

**Avoid by.** Treat every failure as: (1) capture the verbatim error message to a log file with a
timestamp, (2) classify what state machine bucket it's in (§5.3 table), (3) propose a fix, (4) apply
it, (5) record what worked. A `<YYYYMMDD-HHMMSS>-<topic>.md` per incident under a project-local
`log/` dir (alongside the project's runbooks) is a working template for this discipline.

### 5.5. Self-repairing through preflight failures

**What.** Preflight check fails (e.g. `osc` not in PATH, oscrc missing `pass =` line,
`~/.config/osc` is root-owned). Instead of surfacing the failure to a human, the script attempts to
self-repair (`zypper in osc`, `chmod`, `chown`, `osc user` to re-seed, etc.).

**Why it bit.** Preflight failures usually mean the environment is mis-provisioned at a layer the
script doesn't own — the image build, the dotfiles, the bind mount, the host's KWallet. Self-repair
masks the root cause one layer too low: the next time the environment is rebuilt, the same failure
recurs because nothing real was fixed. Sometimes the self-repair makes things worse (e.g.
`sudo chown` on a bind-mount parent inside a container changes state on disk that doesn't survive a
reup).

**Avoid by.** Preflight should be read-only and binary: pass or surface the exact remediation to the
user. Treat "the environment needs to be fixed" as a hard escalation, not a script's responsibility.
Save the actual remediation steps in a separate recipe file (a `dctl-setup.md`-style doc) the
operator runs deliberately.

---

## Companion files

- [`setup-home-project-from-upstream.md`](setup-home-project-from-upstream.md) — the happy-path
  walkthrough this doc complements.
- [`broken-state-link-drift.md`](broken-state-link-drift.md) — deep-dive on the §2.1 / §2.2 failure
  mode and its recovery.
- [`auth-in-devcontainers.md`](auth-in-devcontainers.md) — full decision matrix for §1's auth setup.
- Curated upstream-URL index:
  `~/DocsNNotes/tech/systems/linux/opensuse/opensuse-build-service-obs.md`.

## Project-specific mistakes logs

Each home-project repo that uses this pattern carries its own chronological mistakes-log (typically
`docs/obs-test-project-mistakes-log.md` or similar). That log maps concrete dated incidents to the
§-numbered entries above; this doc is the project-agnostic distillation those logs roll up to.
