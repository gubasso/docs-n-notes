# anyzig Install

## Install anyzig

Use the official install page and select your OS/arch; it generates copy-paste commands for
available methods (Homebrew, curl, wget, PowerShell, direct download). ([anyzig install][1])

Alternative: download the latest release archive directly from GitHub Releases.
([anyzig releases][2])

---

## Example command pattern (Linux/macOS)

Use the exact command from the install page for your platform. Generic pattern:

```bash
curl -L https://github.com/marler8997/anyzig/releases/latest/download/anyzig-<arch-os>.tar.gz | tar xz
```

---

## Verify installation

```bash
zig any version
zig version
```

`zig any version` reports the anyzig build, and `zig version` reports the resolved Zig compiler
version. ([anyzig][3])

[1]: https://marler8997.github.io/anyzig/ "anyzig install"
[2]: https://github.com/marler8997/anyzig/releases "anyzig releases"
[3]: https://github.com/marler8997/anyzig "anyzig"
