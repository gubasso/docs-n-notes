# Troubleshooting: anyzig can't download Zig from ziglang.org (`NetworkUnreachable`)

## Symptoms

- `zig <zig-version> init` (via anyzig) fails during download with:
  - `error: unable to connect to server: NetworkUnreachable`
- IPv4 works but IPv6 fails:
  - `curl -4I https://ziglang.org/download/index.json` succeeds
  - `curl -6I https://ziglang.org/download/index.json` fails

---

## Root cause

You are on a dual-stack network where IPv6 connectivity to `ziglang.org:443` is broken while IPv4 is
fine. In this scenario, clients without effective dual-stack fallback behavior can fail on IPv6
attempts instead of quickly succeeding over IPv4. ([RFC 6555][1])

---

## Fast fix (no file edits): temporarily disable IPv6 system-wide

This forces IPv4-only connectivity for the download window.

### One-shot workflow (recommended)

```bash
# Disable IPv6 immediately (runtime)
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1

# Run the anyzig bootstrap/download
zig <zig-version> init

# Re-enable IPv6 immediately (runtime)
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0
```

`sysctl -w` writes runtime kernel parameters, and `disable_ipv6` is a documented IPv6 sysctl toggle.
([sysctl(8)][2]) ([Linux kernel ip-sysctl][3])

### Verify (optional)

```bash
# Shortcut for IPv6 family output
ip -6 addr
```

`ip -6` is equivalent to `ip -family inet6`. ([ip(8)][4])

---

## Caveats

- This affects the entire machine while disabled.
- IPv6-only applications/connections will fail during that window.
- This is a workaround, not a root-cause fix; the underlying issue is broken IPv6 pathing to
  `ziglang.org`.

---

## Safer rollback on command failure

Use a shell trap so IPv6 is restored even if `zig` errors:

```bash
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
trap 'sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0; sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0' EXIT

zig <zig-version> init
```

---

## After success

After the initial download/bootstrap succeeds and `build.zig.zon` exists, normal project commands
can run without prefixing a version in that project tree (`zig build`, `zig build run`,
`zig build test`).

[1]: https://www.rfc-editor.org/rfc/rfc6555 "RFC 6555: Happy Eyeballs: Success with Dual-Stack Hosts"
[2]: https://man7.org/linux/man-pages/man8/sysctl.8.html "sysctl(8)"
[3]: https://docs.kernel.org/networking/ip-sysctl.html "Linux kernel ip-sysctl"
[4]: https://man7.org/linux/man-pages/man8/ip.8.html "ip(8)"
