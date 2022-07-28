# Dynamic DNS
> ddns, dyndns
> DDNS / DynDNS / Dynamic DNS



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


