# NginX Proxy Manager

<!--TOC-->

- [Add proxy host](#add-proxy-host)
- [Resources](#resources)

<!--TOC-->

## Add proxy host

- **Domain Names:** `brag.gubasso.xyz`
- **Scheme:** `http` (connection inside the host)
- **Forward Hostname / IP:** `brag-server` (service name from the `compose.yaml` at the same
  network)
- **Forward Port:** `3000` (e.g. API_PORT)
- Check:
  - `Block common exploits`
- SSL Certificate
  - Force SSL / HTTP/2 support / HSTS Enabled

## Resources

https://www.linode.com/docs/guides/using-nginx-proxy-manager/
