# Infrastructure / DevOps

> dev ops operations servers

<!--TOC-->

- [Related](#related)
- [Notes in this directory](#notes-in-this-directory)
- [CI / CD](#ci--cd)
- [Proxy / Reverse Proxy](#proxy--reverse-proxy)
- [Network / DNS](#network--dns)
- [Organization](#organization)
  - [Naming servers fqdn scheme conventions](#naming-servers-fqdn-scheme-conventions)
  - [Naming subdomains apps](#naming-subdomains-apps)
  - [Containers (Docker)](#containers-docker)

<!--TOC-->

## Related

- [server-vps](../server-vps/server-vps.md)
- [home server](../server-vps/server-vps-home_server.md)
- [dns](../networking/dns.md)
- [backups](./backups.md)

## Notes in this directory

- [ansible](./ansible.md) — Ansible roles, organization models, best practices, and Vault
- [backups](./backups.md) — backup strategy: the 3-2-1 rule, tools, and general concepts
- [restic-backups](./restic-backups.md) — Restic backup tool notes
- [storage-wasabi](./storage-wasabi.md) — Wasabi S3-compatible object storage configuration
- [iac-infra-as-code](./iac-infra-as-code.md) — Infrastructure-as-Code overview, combining Terraform
  and Ansible
- [terraform](./terraform.md) — Terraform install (`tfenv`), conventions, and resources
- [github-actions-ci-cd](./github-actions-ci-cd.md) — GitHub Actions workflows for CI and automated
  Rust releases
- [selfhosted-gateway-fractal-gateway](./selfhosted-gateway-fractal-gateway.md) — SelfHosted/Fractal
  Gateway: Docker toolchain for exposing self-hosted services

## CI / CD

- [github-actions-ci-cd.md](./github-actions-ci-cd.md)

## Proxy / Reverse Proxy

- \*[Traefik](../networking/traefik.md)
- caddy
- nginx proxy manager

## Network / DNS

- [Netmaker](../networking/netmaker.md)

- [What is FQDN for? Fully Qualified Domain Name (FQDN)](https://www.linode.com/community/questions/19375/how-should-i-configure-my-hostname-and-fqdn#answer-71105)

- TTL: when possible, change to 600 seconds (10 min)

- VPC = Virtual Private Cloud[^net1]

  - full control of a private network
  - similar to a home network

## Organization

### Naming servers fqdn scheme conventions

- server name = subdomain
- Computer network naming scheme: https://en.wikipedia.org//wiki/Computer_network_naming_scheme
- A Proper Server Naming Scheme: https://mnx.io/blog/a-proper-server-naming-scheme/
- Naming Convention Design (Servers, Computers, IT Assets)
  https://www.process.st/checklist/naming-convention-design-servers-computers-it-assets/

### Naming subdomains apps

`<app_name>.app.example.com`

### Containers (Docker)

Server home dir: [^1]

- `~/docker`
- `~/container`
- `~/apps`
- `~/appstacks` \*

One subdir for each "app" (one "app" can be a set of containers, within one docker-compose file).
E.g.:

- `~/apps/seafile`
- `~/apps/radicale`

Or organize in categories. E.g.:

- `~/apps/home_mgmt.group/streamapp`
- `~/apps/testing.group/app_to_test`

Add this dir to a backup routine. It will have data dirs/files too, so, can not be a git repo.

[^net1]: [What is a VPC? | AWS Training](https://www.youtube.com/watch?v=7XnpdZF_COA)

[^1]: [Get Docker organized for easier backups & replication. Trust me, an hour can save you days! / docker organization :awesome_open_source:](https://www.youtube.com/watch?v=sGtTvV0xbYg&t=972s)
