# anyzig Workflow

## What anyzig does

`anyzig` provides one `zig` executable that can run multiple Zig versions. You can select a version
explicitly as the first argument or let it resolve from the nearest `build.zig.zon` (searching
current and parent directories). ([anyzig][1])

---

## Version resolution

anyzig can resolve a compiler version from:

1. Explicit argv version:

```bash
zig <zig-version> <command>
```

1. `build.zig.zon` fields in the nearest project tree:

- `.mach_zig_version = "<mach-version>-mach"` for Mach nominated versions
- `.minimum_zig_version = "<zig-version>"` for standard Zig versions

When `.mach_zig_version` is present, anyzig uses it instead of `.minimum_zig_version`. ([anyzig][1])

---

## Bootstrap a new project

In a brand-new directory, start with an explicit version:

```bash
mkdir -p ~/Projects/my-project
cd ~/Projects/my-project
zig <zig-version> init
```

Confirm the project is pinned:

```bash
rg -n "minimum_zig_version|mach_zig_version" build.zig.zon
```

Expected field for normal Zig projects:

```zig
.minimum_zig_version = "<zig-version>",
```

After bootstrap, use `zig` normally:

```bash
zig version
zig build
zig build run
zig build test
```

---

## Why `zig init` fails in an empty directory

`zig init` in an empty directory is expected to fail with anyzig unless you pass a version, because
there is no `build.zig.zon` yet for version inference. `init` creates that file, so bootstrap must
be explicit (`zig <zig-version> init`). ([anyzig][1])

---

## Discover available Zig versions

anyzig does not currently provide a built-in command to list all remote available Zig versions.
([anyzig][1])

List versions from Zig's official download index:

```bash
curl -fsSL https://ziglang.org/download/index.json | jq -r 'keys[]'
```

Show only semantic versions (exclude `master`):

```bash
curl -fsSL https://ziglang.org/download/index.json \
  | jq -r 'keys[] | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))'
```

Check whether a specific version exists:

```bash
VER="<zig-version>"
curl -fsSL https://ziglang.org/download/index.json | jq -e --arg v "$VER" 'has($v)'
```

List versions already installed in your anyzig cache:

```bash
zig any list-installed
```

---

## Troubleshooting

If compiler download fails with `NetworkUnreachable` while IPv4 works and IPv6 fails, see:

- [anyzig-networkunreachable-ziglang-download](troubleshooting/anyzig-networkunreachable-ziglang-download.md)

---

The downloads index format and keys come from Zig's official download metadata. ([zig download][2])
For release-tag browsing, use the Zig releases page. ([zig releases][3])

[1]: https://github.com/marler8997/anyzig "anyzig"
[2]: https://ziglang.org/download/index.json "Zig download index JSON"
[3]: https://github.com/ziglang/zig/releases "zig releases"
