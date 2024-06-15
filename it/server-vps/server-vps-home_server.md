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


