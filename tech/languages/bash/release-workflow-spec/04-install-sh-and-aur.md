# Bash Release — install.sh & AUR

Part of the [bash release-workflow spec](./README.md). General principle: **distribution channels**
— see the [general principles](../../../programming/release-workflow/README.md).

End-user install methods, in priority order. This chapter covers the two user-driven channels: the
`curl | bash` installer and the AUR packages. The OBS-hosted distro repos are covered in the
[OBS chapter](./05-obs-multi-distro.md).

## `install.sh` curl one-liner

Primary path — works everywhere. README shows:

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/<tool>/master/install.sh | bash
```

The script **must**:

1. Discover the latest tag via the GitHub Releases API.
2. Download the tarball **and** its `.sha256`.
3. **Verify the checksum before extracting.** This is the only legitimate complaint about the
   `curl|bash` pattern — address it.
4. Unpack to a temp dir.
5. Run `make install` (default `PREFIX=$HOME/.local`, overridable via env var).

Optionally also verify with `gh attestation verify` when the user has `gh` installed.

Sketch:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO="<user>/<tool>"
PREFIX="${PREFIX:-$HOME/.local}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
       | grep -oP '"tag_name":\s*"\K[^"]+')"

cd "$TMP"
curl -fsSLO "https://github.com/$REPO/releases/download/$TAG/<tool>-${TAG#v}.tar.gz"
curl -fsSLO "https://github.com/$REPO/releases/download/$TAG/<tool>-${TAG#v}.tar.gz.sha256"
sha256sum -c "<tool>-${TAG#v}.tar.gz.sha256"

tar -xzf "<tool>-${TAG#v}.tar.gz"
cd "<tool>-${TAG#v}"
make PREFIX="$PREFIX" install
```

## AUR package

On Arch, publish two packages per the
[ArchWiki VCS package guidelines](https://wiki.archlinux.org/title/VCS_package_guidelines):

- `<tool>` — pins to the latest tag,
  `source=("$pkgname-$pkgver.tar.gz::https://github.com/.../archive/v$pkgver.tar.gz")`, with
  `sha256sums` from your published `SHA256SUMS`.
- `<tool>-git` — VCS variant tracking `master`, with the standard `pkgver()` function and `-git`
  suffix.

Because the Makefile now respects `DESTDIR`/`PREFIX`, `package()` is one line:

```bash
package() {
  cd "$pkgname-$pkgver"
  make DESTDIR="$pkgdir" PREFIX=/usr install
}
```

Keep the PKGBUILDs in the project repo under `packaging/aur/<tool>/PKGBUILD` and
`packaging/aur/<tool>-git/PKGBUILD`, then `git subtree push` to the corresponding AUR repos at
release time.
