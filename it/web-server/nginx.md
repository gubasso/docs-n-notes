# NEW Nginx

<!-- toc -->

  - [Utils](#utils)
  - [Configutation](#configutation)
- [Config examples:](#config-examples)
  - [generic](#generic)
- [Installation](#installation)
  - [From Source:](#from-source)
- [Running](#running)
- [After](#after)
  - [certbot](#certbot)
  - [http2](#http2)
  - [General](#general)
- [Resources](#resources)
- [References](#references)

<!-- tocstop -->

## Utils

- [NginX Proxy Manager](./nginx-nginx-proxy-manager.md)

## Configutation

- config generators:
  - https://www.digitalocean.com/community/tools/nginx

- configuration examples:
  - https://wiki.archlinux.org/title/nginx#Configuration_example

Check these parameters at:
- `/etc/nginx/nginx.conf`: keep default
- `/etc/nginx/conf.d`: add general configs
- `/etc/nginx/sites-available` / `/etc/nginx/sites-enabled`: add specific apps/server configs

- `location` directive: filter by the URI
- `server` directive: filter by domain/subdomain/ip and/or port

`user <username> <groupname>;`
```
- if group name is omited, username = groupname
```

`server_tokens off;`
```
- hide nginx version at response header
```

`http { server_names_hash_bucket_size 64; }`[^1]

`http { add_header Strict-Transport-Security "max-age=15768000" always; }`[^2]

- To activate whatever site is available, run the following command:
```
ln -s /etc/nginx/sites-available/www.example.org.conf /etc/nginx/sites-enabled/
```

- to check if nginx configuration file is ok: `nginx -t`
- after check, reload config: `systemctl reload nginx` (if not using systemd, `nginx -s reload`)

# Config examples:

## generic

Default config:

**`/etc/nginx/nginx.conf`**
```
user <user_name>;
worker_processes auto;
worker_cpu_affinity auto;

http {
  server_tokens off;
  gzip on;
  gzip_comp_level 3;
  gzip_vary on;
  gzip_proxied expired no-cache no-store private auth;
  gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml;
  gzip_disable "MSIE [1-6]\.";
  server_names_hash_bucket_size 64;

  include conf.d/*;
  include sites-enabled/*;

  add_header Strict-Transport-Security "max-age=15768000; includeSubDomains" always;
}
```

REST API / Specific config:

**`/etc/nginx/sites-available/example.conf`**
```
server {
  listen 80;
  listen [::]:80;
  server_name example.com www.example.com;
  location / {
    proxy_pass http://localhost:5000;
  }
}
```

Static Site / Specific config:
  - https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04#step-5-setting-up-server-blocks-(recommended)

**`/etc/nginx/sites-available/example.conf`**
```
server {
  listen 80;
  listen [::]:80;
  server_name example.com www.example.com;
  location / {
    root /var/www/example;
    index index.html index.htm;
  }
}
```

# Installation

## From Source:

- [Nginx: Installation / Build from Source](./nginx-installation-build-source.md)

# Running

**RUN DIRECTLY**

if want to run nginx directly:

- run `nginx`
- check process `ps aux | grep nginx`

**SYSTEMD**

if want to set it up with systemd

- Save this file as `/lib/systemd/system/nginx.service`

**`/etc/systemd/system/nginx.service`**
```
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

- enable and start service, after check if its running and its ok
```
systemctl enable nginx --now
systemctl status nginx
```

- test if service is working after reboot the system `reboot`... run `systemctl status nginx` and/or `ps aux | grep nginx`

# After

## certbot

After nginx is installed and running, config https with certbot/let's encrypt:

[Nginx + certbot](./nginx-certbot.md)

## http2

Follow these steps: [^2]

- `listen 443 ssl http2;`: add `http2`, is needed, automatically falls back to HTTP 1.1 if not supported
- add `http2` (can be done just after a valid certificate)

[^2]`# Step 3 — Verifying that HTTP/2 is Enabled`

## General

If using with SSL/Let's encrypt/certbot:...
Better to **NOT** use with docker/container...

Simpler if it is installed directly on system.

**difference between `systemctl reload nginx` and `systemctl restart nginx**
```
- reload
    - does not stop service
    - try to reload config
    - if there is some problema with de config, it will keep the previous config with no issue
    - if the new config is ok, loads it
- restart
    - stop actual service
    - try to start service with the new config
    - if that is an error, service will not start
```


**default_server**
```
server{
   listen 1.2.3.4:80 default_server;
   ...
}

---
- From http://wiki.nginx.org/HttpCoreModule#listen_
    - If the directive has the default_server parameter, then the enclosing server {…} block will be the default server for the address:port pair. This is useful for name-based virtual hosting where you wish to specify the default server block for hostnames that do not match any server_name directives. If there are no directives with the default_server parameter, then the default server will be the first server block in which the address:port pair appears.
```

# Resources

[Understanding Nginx Server and Location Block Selection Algorithms](https://www.digitalocean.com/community/tutorials/understanding-nginx-server-and-location-block-selection-algorithms)
```
- Amazing article about how redirects, location blocks and URL/URI matches works
- Nginx Block Configurations
- How Nginx Decides Which Server Block Will Handle a Request
    - Parsing the listen Directive to Find Possible Matches
    - Parsing the server_name Directive to Choose a Match
- Matching Location Blocks
    - Location Block Syntax
    - Examples Demonstrating Location Block Syntax
    - How Nginx Chooses Which Location to Use to Handle Requests
    - When Does Location Block Evaluation Jump to Other Locations?
```

---

- nginx rate limiting, securing ddos attack
    - [Rate Limiting with NGINX and NGINX Plus](https://www.nginx.com/blog/rate-limiting-nginx/)
    - [Rate Limiting with Nginx](https://lincolnloop.com/blog/rate-limiting-nginx/)
    - [NGINX rate-limiting in a nutshell](https://www.freecodecamp.org/news/nginx-rate-limiting-in-a-nutshell-128fe9e0126c/)

---

- How to get HTTPS working on your local development environment in 5 minutes `https://www.freecodecamp.org/news/how-to-get-https-working-on-your-local-development-environment-in-5-minutes-7af615770eec/amp/?__twitter_impression=true`

---

- How does HTTPS work? What's a CA? What's a self-signed Certificate? https://youtu.be/T4Df5_cojAs

# References

[^1]: [How To Install Nginx on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04)
[^2]: [How To Set Up Nginx with HTTP/2 Support on Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-nginx-with-http-2-support-on-ubuntu-18-04)
