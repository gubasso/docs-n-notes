# NetworkManager: Choosing the Right DNS Strategy for Void Linux: Symlink, openresolv, or systemd-resolved


## Summary

When choosing between a quick symlink-based fix (Option 2) and a more comprehensive resolver-management setup (Option 3), the right approach depends on your desired balance of simplicity versus control. **Option 2**—symlinking `/etc/resolv.conf` to NetworkManager’s runtime copy—is exactly how Arch Linux’s NetworkManager package is configured by default, requiring no extra packages or per-connection tweaks ([wiki.archlinux.org][1]). **Option 3** adds explicit fallback DNS servers, ignores broken DHCP-supplied DNS, and installs `openresolv` to coordinate multiple sources modifying `/etc/resolv.conf`, mirroring the classic Debian/`resolvconf` paradigm ([wiki.debian.org][2]). An even more modern alternative—used by Ubuntu (≥16.10) and Fedora (≥33)—is to enable **systemd-resolved** and point the symlink at its stub resolver, combining simplicity with built-in caching and per-link DNS handling ([askubuntu.com][3], [wiki.archlinux.org][4]).

---

## Option 2: Symlink to NetworkManager’s Resolver (Arch’s Default)

By default, NetworkManager on Arch sets its DNS management mode to **symlink**, writing a fresh `/run/NetworkManager/resolv.conf` on each connection change and expecting `/etc/resolv.conf` to point there ([wiki.archlinux.org][1]). To model that:

```bash
sudo rm -f /etc/resolv.conf
sudo ln -s /run/NetworkManager/resolv.conf /etc/resolv.conf
sudo nmcli connection up "$(nmcli -g NAME,TYPE con show --active | awk -F: '/wifi/ {print $1}')"
```

* **Pros**: Minimal setup, no extra packages.
* **Cons**: No built-in fallback if DHCP fails to supply DNS.

---

## Option 3: Persistent & Robust via `openresolv` & `nmcli`

This approach layers on four tasks to ensure DNS always works—even when DHCP is broken—and lets multiple services modify `/etc/resolv.conf` safely:

| Task                             | Command                                                              | Why                                                                                     |
| -------------------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **Add fallback servers**         | `nmcli con mod <name> ipv4.dns "1.1.1.1 8.8.8.8"`                    | Use Cloudflare/Google if DHCP gives none ([infotechys.com][5])                          |
| **Ignore broken DHCP DNS**       | `nmcli con mod <name> ipv4.ignore-auto-dns yes`                      | Prevent DHCP entries from clobbering your fallbacks ([serverfault.com][6])              |
| **Install resolver-coordinator** | `sudo xbps-install -Sy openresolv`                                   | Provides the `resolvconf` interface for multiple clients ([wiki.archlinux.org][7])      |
| **Hand off NM to `resolvconf`**  | Add `rc-manager=resolvconf` in `/etc/NetworkManager/conf.d/dns.conf` | Tells NetworkManager to invoke `openresolv` instead of symlink ([bbs.archlinux.org][8]) |

* **Pros**: Resilient to network glitches; harmonizes DNS info from VPN, DHCP, manual settings.
* **Cons**: More moving parts; you must maintain extra configuration.

---

## Alternative: systemd-resolved (Modern Default on Ubuntu & Fedora)

Instead of `openresolv`, many distributions now ship with **systemd-resolved**, which offers a stub listener at `127.0.0.53` and DNS caching via D-Bus ([wiki.archlinux.org][4]). You can emulate this on Void/Arch:

```bash
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl enable --now systemd-resolved
```

Optionally, configure NetworkManager to hand off DNS to systemd-resolved by adding `dns=systemd-resolved` under `[main]` in `/etc/NetworkManager/conf.d/dns.conf`. Ubuntu (since 16.10) and Fedora 33+ do exactly this automatically ([askubuntu.com][3]).

* **Pros**: Single service manages DNS for all clients, per-link settings, caching, DoT/DoH integration.
* **Cons**: Requires running systemd-resolved; some legacy tools may need `systemd-resolvconf`.

---

## Recommendation

* **For a lean setup** on Void Linux (aligned with Arch defaults), **Option 2** is sufficient: a simple symlink and let NetworkManager do the rest.
* **If you frequently roam across networks** with flaky DHCP or need split-DNS, **Option 3** gives you granular control and reliable fallbacks.
* **If you prefer the most “set-and-forget” experience**, enable **systemd-resolved**: it combines the simplicity of Option 2 with caching and robust per-link DNS, matching the defaults on Ubuntu and Fedora.

[1]: https://wiki.archlinux.org/title/NetworkManager "NetworkManager - ArchWiki"
[2]: https://wiki.debian.org/resolv.conf?action=raw&utm_source=chatgpt.com "Debian Wiki"
[3]: https://askubuntu.com/questions/941613/configuring-networkmanager-to-use-systemd-resolved-without-dnsmasq-in-17-04 "network manager - Configuring NetworkManager to use systemd-resolved without dnsmasq in 17.04 - Ask Ubuntu"
[4]: https://wiki.archlinux.org/title/Systemd-resolved "systemd-resolved - ArchWiki"
[5]: https://infotechys.com/change-dns-settings-using-the-nmcli-utility/ "Change DNS Settings using the NMCLI utility - Infotechys.com"
[6]: https://serverfault.com/questions/810636/how-to-manage-dns-in-networkmanager-via-console-nmcli "How to manage DNS in NetworkManager via console (nmcli)?"
[7]: https://wiki.archlinux.org/title/Openresolv "openresolv - ArchWiki"
[8]: https://bbs.archlinux.org/viewtopic.php?id=297707&utm_source=chatgpt.com "[SOLVED] NetworkManager - Arch Linux Forums"
