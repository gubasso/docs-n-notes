# DNS

<!-- toc -->

- [Fully qualified domain name (FQDN)](#fully-qualified-domain-name-fqdn)
  - [Hostname](#hostname)
- [Setup a DNS](#setup-a-dns)
- [Dynamic DNS](#dynamic-dns)
- [ddclient](#ddclient)
  - [Debugging](#debugging)
- [Docs and References:](#docs-and-references)

<!-- tocstop -->

## Fully qualified domain name (FQDN)

```
<FQDN> = hostname + domain
<hostname>.<domain>
# Examples:
web-01-prod.crownandtrunk.com
api.cwnt.io
example-hostname.example.com
```

### Hostname

- Descriptive and/or Structured (e.g. [purpose]-[number]-[environment] / `web-01-prod`)
- part of a FQDN (e.g. `web-01-prod.example.com`)

## Setup a DNS

- setup a dns record that points to your server (ip)
  - choose a provider: EPIK, Namecheap, Linode DNS
  - choose a FQDN to your server
  - setup `A` and/or `AAAA` record [^2]
- (wait to dns propagate)
- check with: https://dnschecker.org

## Dynamic DNS
> ddns, dyndns
> DDNS / DynDNS / Dynamic DNS

- https://github.com/jc21/route53-ddns
  - amazon route53

https://www.makeuseof.com/tag/5-best-dynamic-dns-providers-can-lookup-free-today/

1. https://www.dynu.com/
- https://www.noip.com/

read dynu docs

At Dynu:

- login
- DDNS Services
- enter random hostname / or my domain?

at server set a cronjob to update automatically ip

password hash (dynu site) as a env variable at cronjob wget url

at server:
- if it serves a web app, config nginx at port 80 / 443, etc...


check if port is open/accessible:
- https://canyouseeme.org/
- https://www.portchecktool.com/
- https://www.dynu.com/networktools/portcheck

About /etc/hosts: https://unix.stackexchange.com/questions/421491/what-is-the-purpose-of-etc-hosts

Access my server by public ip address (or dns/ddns), from inside same network:

nat loopback, nat reflection, hairpin
http://opensimulator.org/wiki/NAT_Loopback_Routers
https://en.wikipedia.org/wiki/Network_address_translation#NAT_hairpinning

[Cannot Access Public IP while connected Locally?](https://community.spiceworks.com/topic/2240145-cannot-access-public-ip-while-connected-locally)

[Enable dynamic DNS (DynDNS, Duck DNS, etc.) inside networks without NAT loopback support on router](https://chester.me/archives/2019/08/a-fix-for-domestic-dynamic-dns-inside-network/)


[Create a Home Network DNS Server Using DNSMasq](https://stevessmarthomeguide.com/home-network-dns-dnsmasq/)

## ddclient

https://github.com/ddclient/ddclient

### Debugging

enable debugging and verbose messages:

```
ddclient -daemon=0 -debug -verbose -noquiet
```

The configuration can be tested by running

```
ddclient -daemon=0 -noquiet -debug
```

## Docs and References:

- DNS Records:
  - https://www.linode.com/docs/guides/dns-manager/
- Reverse DNS:
  - https://www.linode.com/docs/guides/configure-your-linode-for-reverse-dns/

[^2]: `A` is ipv4 record and `AAAA` is ipv6


