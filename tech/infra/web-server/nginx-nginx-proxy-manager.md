# NginX Proxy Manager

<!-- toc -->

- [Add proxy host](#add-proxy-host)
- [Resources](#resources)

<!-- tocstop -->

`host.docker.internal` -> localhost

## Add proxy host

- **Domain Names:** `brag.gubasso.xyz`
- **Scheme:** `http` (connection inside the host)
- **Forward Hostname / IP:** `brag-server` (service name from the `compose.yaml` at the same network)
- **Forward Port:** `3000` (e.g. API_PORT)
- Check:
  - `Block common exploits`
- SSL Certificate
  - Force SSL / HTTP/2 support / HSTS Enabled

## Resources

https://www.linode.com/docs/guides/using-nginx-proxy-manager/

[^1]: [NginX Proxy Manager is a free, open source, GUI for the NginX Reverse Proxy making it easy to use. :awesome_open_source:](https://www.youtube.com/watch?v=RBVcnxTiIL0)
