# Home Server

Find public ip address: `curl ifconfig.me`

Private ip address:

```
ifconfig -a
ip addr (ip a)
hostname -I | awk '{print $1}'
ip route get 1.2.3.4 | awk '{print $7}'
nmcli -p device show
```

Port foward for tplink archer C6: [Port forwarding: how to set up virtual server on TP-Link wireless router? ](https://www.tp-link.com/cz/support/faq/1379/)



DDNS / DynDNS / Dynamic DNS

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


