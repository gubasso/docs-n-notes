# SelfHosted Gateway vs NetBird (overlay VPN)

**Core Architectural Difference**

* **SelfHosted Gateway** is essentially a **single gateway container** (running on your VPS) + a **client container** (on your home/server) that establish a **WireGuard tunnel** and auto-generate an HTTP(S) reverse-proxy configuration. All inbound traffic to `*.yourdomain.com` hits the VPS, then gets securely forwarded over WireGuard into your local Docker apps.

* **NetBird (an overlay VPN)** spins up a **full mesh** of WireGuard peers. Every machine running the NetBird agent joins an encrypted, peer-to-peer network, is assigned a private VPN IP (e.g. `100.x.x.x`), and can talk to any other allowed peer directly—no centralized HTTP proxy at all ([netbird.io][1], [docs.netbird.io][2]).

---

## Feature-by-Feature Comparison

|                            | SelfHosted Gateway                                                                      | NetBird Overlay VPN                                                                                                                                           |
| -------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Connectivity**           | One-to-site: VPS ↔ client server                                                        | Full mesh: any peer ↔ any peer directly ([netbird.io][1])                                                                                                     |
| **Protocols supported**    | HTTP(S) only (via Docker-generated reverse proxy)                                       | **Any** TCP/UDP (SSH, RDP, SMB, databases, custom apps)                                                                                                       |
| **DNS & discovery**        | Uses your public domain + subdomains                                                    | Uses virtual IPs (e.g. `100.x.x.x`) on the VPN—no public DNS required, though you can layer DNS on top if you like ([LIBTECHNOPHILE][3])                      |
| **Access control & users** | Implicit: whoever hits your subdomain                                                   | Fine-grained ACLs, groups, SSO/MFA integration, per-peer policies, audit logs ([GitHub][4])                                                                   |
| **NAT traversal**          | Outbound SSH only                                                                       | Built-in NAT traversal (UDP hole punching) for mesh connectivity ([FreshPorts][5])                                                                            |
| **Scalability**            | Ideal for exposing a **handful** of web services                                        | Scales to **dozens–hundreds** of nodes/devices, across home, offices, cloud, containers, IoT, etc.                                                            |
| **Deployment complexity**  | Very light: a couple `make` commands + DNS A-record                                     | Requires running a coordination server (self-hosted or cloud), installing agents on each peer, managing certificates/policies (though tooling is streamlined) |
| **Use-case focus**         | “I just want my web apps accessible from outside, without punching holes in my router.” | “I need a private LAN-like network across multiple devices and protocols, with user-based access and mesh routing.”                                           |

---

## When to Choose Each

### 🏠 SelfHosted Gateway

* You’re **only** exposing one or a few **web-based** services (e.g. Nextcloud, Home Assistant, internal dashboards).
* Your ISP blocks/CGNATs inbound ports, and you want a **zero-port-forwarding** solution.
* You’d rather not manage a full VPN mesh or deal with virtual IP addressing.
* You want a super-lightweight, Docker-first setup: one container on a cheap VPS + one on your home machine.

### 🌐 NetBird (Overlay VPN)

* You need **SSH**, **RDP**, **SMB**, database access, or any non-HTTP protocols across your devices.
* You’re connecting **multiple** devices (laptops, servers, containers, IoT) in different locations into one flat, secure network.
* You want **user authentication**, **ACLs**, **SSO/MFA**, group-based policies, and auditability.
* You’re comfortable running a small “coordination” server (or using NetBird’s cloud) and installing an agent on every peer.

---

**Bottom line**:

* If your goal is **simple, secure external access** to a handful of web apps behind CGNAT—go with **SelfHosted Gateway**.
* If you need a **full-blown, zero-trust, multi-protocol mesh** network spanning dozens of devices—go with **NetBird** (or another overlay VPN).

[1]: https://netbird.io/connect?utm_source=chatgpt.com "NetBird - Zero-Configuration Private Network"
[2]: https://docs.netbird.io/?utm_source=chatgpt.com "Introduction to NetBird - NetBird Docs"
[3]: https://libtechnophile.blogspot.com/2025/05/setting-up-netbird-wireguard-based-self.html?utm_source=chatgpt.com "Setting Up NetBird – A WireGuard-Based Self-Hosted VPN System"
[4]: https://github.com/netbirdio/netbird?utm_source=chatgpt.com "GitHub - netbirdio/netbird: Connect your devices into a secure ..."
[5]: https://www.freshports.org/security/netbird/?utm_source=chatgpt.com "FreshPorts -- security/netbird: Peer-to-peer VPN that seamlessly ..."
