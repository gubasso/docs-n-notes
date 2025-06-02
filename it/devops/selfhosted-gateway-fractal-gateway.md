# SelfHosted Gateway (Fractal Gateway)

This “utility” is the open-source **SelfHosted Gateway** (sometimes called the Fractal Gateway), a tiny Docker-based toolchain that:

1. **Spins up a WireGuard VPN tunnel** between

   * **Your cloud VPS** (e.g. a \$5/month Ubuntu droplet on DigitalOcean) and
   * **Your home-lab or self-hosted server**
2. **Automatically reverse-proxies** traffic for any number of subdomains on your domain through that tunnel, without requiring any port-forwards on your home router.

---

### Why use it?

* **Bypass ISP NAT and port-blocking**
  Many ISPs put you behind CGNAT or selectively block ports 80/443. Because your home server never needs to accept inbound connections directly, you sidestep all of that.
* **Zero router config**
  All you need is outbound SSH from your home network. No fiddling with UPnP, static NAT, firewalls, or router firmware.
* **End-to-end encryption**
  Your data travels through a WireGuard tunnel between VPS ↔ home server. Even the reverse proxy traffic is encrypted in transit.
* **Flexible multi-app hosting**
  You can expose as many apps as you like—just point different subdomains (e.g. `app1.yourdomain.com`, `app2.yourdomain.com`) at your VPS’s wildcard DNS record, then run the same “make link” command with different `--fqdn` and `--expose` values.
* **All in Docker**
  Both the gateway and your client apps live in containers. Setup is just `git clone`, `make setup && make gateway` on the VPS, then `make link GATEWAY=… FQDN=… EXPOSE=…` on your home server to generate the WireGuard keys + Docker Compose snippet.

---

### At a glance, the workflow is:

1. **On your VPS**

   ```bash
   # install Docker & Docker Compose
   make setup
   # deploy the gateway container
   make gateway
   ```
2. **In your DNS**

   * Create an A record (or wildcard `*.yourdomain.com`) pointing at your VPS IP.
3. **On your home/self-hosted machine**

   ```bash
   git clone https://github.com/self-hosted-gateway.git
   cd self-hosted-gateway
   # add your SSH key to the agent so the script can SSH back
   ssh-agent bash -c "ssh-add ~/.ssh/id_rsa"
   # generate WireGuard keys, SSH-in to your VPS, and output a Docker Compose snippet:
   make link \
     GATEWAY=brian@myget.routemehome.org \
     FQDN=myget.routemehome.org \
     EXPOSE=getmy:3000
   ```
4. **Paste the generated snippet** into your existing `docker-compose.yml` for the app you want to expose, then:

   ```bash
   docker-compose up -d
   ```
5. **Visit** `https://myget.routemehome.org` (or whatever `FQDN` you chose)—requests will hop through your VPS into the WireGuard tunnel and land on your local app.

---

### Who it’s for

* **Home-lab enthusiasts** who hate wrestling with CGNAT or ISP firewalls.
* **Small-scale self-hosters** who want a secure, maintainable way to expose multiple apps.
* **Anyone** wanting a one-line add-on to their Docker Compose stack for remote access without punching holes in their network.
