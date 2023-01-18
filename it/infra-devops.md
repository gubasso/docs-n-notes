# Infrastructure / DevOps
> dev ops operations servers

[toc]

# Related

- [](./server-vps.md)
- [](./server-vps-home_server.md)
- [Dynamic DNS](./server-vps-home_server-ddns.md)

# Proxy / Reverse Proxy

- *[Traefik](./traefik.md)
- caddy
- nginx proxy manager

# Network / DNS

- [Netmaker](./netmaker.md)

- [What is FQDN for?  Fully Qualified Domain Name (FQDN)](https://www.linode.com/community/questions/19375/how-should-i-configure-my-hostname-and-fqdn#answer-71105)

- TTL: when possible, change to 600 seconds (10 min)

- VPC = Virtual Private Cloud[^net1]
  - full control of a private network
  - similar to a home network

[^net1]: [What is a VPC? | AWS Training](https://www.youtube.com/watch?v=7XnpdZF_COA)

# Organization

## Naming servers fqdn scheme conventions

- server name = subdomain
- Computer network naming scheme: https://en.wikipedia.org//wiki/Computer_network_naming_scheme
- A Proper Server Naming Scheme: https://mnx.io/blog/a-proper-server-naming-scheme/
-  Naming Convention Design (Servers, Computers, IT Assets)  https://www.process.st/checklist/naming-convention-design-servers-computers-it-assets/


## Naming subdomains apps

`<app_name>.app.example.com`

## Containers (Docker)

Server home dir: [^1]

- `~/docker`
- `~/container`
- `~/apps`
- `~/appstacks` *

One subdir for each "app" (one "app" can be a set of containers, within one docker-compose file). E.g.:

- `~/apps/seafile`
- `~/apps/radicale`

Or organize in categories. E.g.:

- `~/apps/home_mgmt.group/streamapp`
- `~/apps/testing.group/app_to_test`

Add this dir to a backup routine. It will have data dirs/files too, so, can not be a git repo.

[^1]: [Get Docker organized for easier backups & replication. Trust me, an hour can save you days! / docker organization :awesome_open_source:](https://www.youtube.com/watch?v=sGtTvV0xbYg&t=972s)

