# Create a Reverse Proxy for self hosted services using Netmaker and Wireguard
> link: https://www.youtube.com/watch?v=CGw4Kc424VE
> :awesome_open_source:

# Goal

<draw></draw>

- Each call in the proxy, access only one machine (one service), in one port.
- Does not access all network

Apps/Steps:

1. Traefik (reverse proxy)
- Authelia
- Crowdsec
- Portainer

# Setup "Entry VPS"

"Entry VPS" = Netmaker Netclient Proxy

- Create a "Entry VPS"
- Install NetClient

- Custom DNS:

```
A record

*.myapps.example.com

redirects to "Entry VPS" IP
```

# Setup Netmaker

- Create a new network
- Create network access key
- At "Entry VPS", run `netclient join ...` command
- Check if "Entry VPS" is shown at Netmaker nodes
- At "Entry VPS" run `wg show` to see the network node peers of this machine

# Install/Setup Proxy

(video shows how to install nginx proxy manager)

- setup proxies (url -> ip:port)
- if the service is at the same machine (e.g. "Entry VPS")
  - ip = `localhost`
  - port = app port in `localhost`
- check for https/ssl and http/2 support
- after https, block port 80
- if service is at another machine
  - ip = local network ip (not public VPS ip anymore)

