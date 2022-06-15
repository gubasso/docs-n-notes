# Nginx
> $it $nginx $webserver $linux $server $reverse-proxy $proxy $load-balancer
> load balancer, reverse proxy


<!-- vim-markdown-toc GitLab -->

* [General Nginx](#general-nginx)
* [Installation](#installation)
* [Running](#running)
* [Configure Nginx](#configure-nginx)
* [Deploy projects to server](#deploy-projects-to-server)
* [Configure Nginx to serve each project](#configure-nginx-to-serve-each-project)
* [Setup secure connection (TSL and HTTP2)](#setup-secure-connection-tsl-and-http2)
* [Tuning / Optimizing](#tuning-optimizing)

<!-- vim-markdown-toc -->

## General Nginx
> `# Nginx`

- Amazing article about how redirects, location blocks and URL/URI matches works[^nx8]
[^nx8]: [Understanding Nginx Server and Location Block Selection Algorithms](https://www.digitalocean.com/community/tutorials/understanding-nginx-server-and-location-block-selection-algorithms)
- Nginx Block Configurations
- How Nginx Decides Which Server Block Will Handle a Request
    - Parsing the listen Directive to Find Possible Matches
    - Parsing the server_name Directive to Choose a Match
- Matching Location Blocks
    - Location Block Syntax
    - Examples Demonstrating Location Block Syntax
    - How Nginx Chooses Which Location to Use to Handle Requests
    - When Does Location Block Evaluation Jump to Other Locations?

- difference between `systemctl reload nginx` and `systemctl restart nginx` [^nx3][10. Creating a Virtual Host]
    - reload
        - does not stop service
        - try to reload config
        - if there is some problema with de config, it will keep the previous config with no issue
        - if the new config is ok, loads it
    - restart
        - stop actual service
        - try to start service with the new config
        - if that is an error, service will not start

- $nginx about the `default_server` [^nx2]
```
server{
   listen 1.2.3.4:80 default_server;
   ...
}
```
- From http://wiki.nginx.org/HttpCoreModule#listen_
    - If the directive has the default_server parameter, then the enclosing server {…} block will be the default server for the address:port pair. This is useful for name-based virtual hosting where you wish to specify the default server block for hostnames that do not match any server_name directives. If there are no directives with the default_server parameter, then the default server will be the first server block in which the address:port pair appears.

## Installation
> `# Nginx`

**INSTALL / BUILD FROM SOURCE:**

Preferred way to install nginx is building itself (not using the os package manager).

It allows to add plugins

- install probable dependencies/libraries:
    - os specific dev tools: `make`, etc...
    - `pcre` `pcre-devel`
    - `gzip` `zlib1g` `bzip2` `libzip-devel` `libbz2-devel`
    - `openssl` `ssl` `libssl` `libopenssl-devel`

- nginx.org: download link, mainline version
- copy the link... `wget link` to download
- extract `tar -zxvf file`
- create a install script `install.sh` with env variables for the flags of configure
- run `./configure --sbin-path=/usr/bin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-pcre --pid-path=/var/run/nginx.pid --with-http_ssl_module --with-http_v2_module`
- `make`
- `make install`
- check installation `nginx -V` (get configure parameters/flags and nginx version)

**ADD NEW MODULE / DYNAMIC MODULE:**

if want to try to install a new module later.

- nginx install a new module (dynamic module)[^nx3][20. Adding Dynamic Modules]
    - `nginx -V`: get all command for configuration, copy and paste the same for new config
    - add just the new parameters/flags/new module, e.g.:
    `nginx -V` (then copy configure flags)
    `./configure --help | rg http_v2`(search for the extra modulo you want to install)
    `./configure <paste copied flags> --with-http_v2_module` (append module flag)
    `make`
    `make install`
    check instalation `nginx -V` (get configure parameters/flags and nginx version)
    `systemctl restart nginx`
    run `nginx` check process `ps aux | grep nginx` (or run `systemctl status nginx`)
- `nginx.conf`: `load_module modules/mymodule.so;`

## Running
> `# Nginx`

**RUN DIRECTLY**

if want to run nginx directly:

- run `nginx`
- check process `ps aux | grep nginx` 

**SYSTEMD**

if want to set it up with systemd

- Save this file as `/lib/systemd/system/nginx.service`[^nx7]
```
/etc/systemd/system/nginx.service
---
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


**TROUBLESHOOTING AFTER RUNNING / INSTALLATION**

if pid file is removed (or was not created)
- stop and disable services (with systemd and/or `nginx -s stop` and/or kill process)
- check if service is stopped: `ps aux | grep nginx`
- run `./configure`, compile and install again
- run nginx once (systemd OR nginx command... one or the other)

## Configure Nginx
> `# Nginx`

**CONFIG PARAMETERS**

Check these parameters at:
- `/etc/nginx/nginx.conf`
- `/etc/nginx/conf.d`
- `/etc/nginx/sites-available` / `/etc/nginx/sites-enabled`

```
/etc/nginx/nginx.conf
---
user username groupname;

events {}

http{
    server_tokens off;
    gzip on;
    gzip_comp_level 3;
    gzip_vary on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml;
    gzip_disable "MSIE [1-6]\.";

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*.conf;

    server{
        listen 80;
        listen [::]:80;
        server_name projects.cwnt.io www.projects.cwnt.io;
    }

}
```

- `user username groupname;`: [^nx3][17. Php processing] to run nginx worker as this user... when authorization issues
    - can use just `user username;`, if username = groupname
- `server_tokens off;`: [^nx3][29. Hardening Nginx] hide nginx version at response header
- `gzip on;`: [^nx3][22. Compressed Responses with gzip]
    - [^nx4]:
    ```
    gzip_comp_level 3;
    gzip_vary on;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml;
    gzip_disable "MSIE [1-6]\.";
    ```
- `proxy_pass http://localhost:8000/;`: [^nx3][32. Reverse Proxy]
    - if use "/" at the final: 'cadelab-api' is the root. URI starts from here:
        - e.g. `projects.cwnt.io/cadelab-api/meuovo`, the URI is 'meuovo'
    - if DO NOT use "/" at the final: URI starts from '/cadelab...'
        - e.g. `projects.cwnt.io/cadelab-api/meuovo`, the URI is '/cadelab-api/meuovo'

**CONFIG FILES AND DIR STRUCTURES**

- `/etc/nginx/nginx.conf` use it for general **default** server config, not for specific site config, don't edit this file
- `/etc/nginx/conf.d`: general config, here can be edited
- `/etc/nginx/sites-available`: specific site config, where sites config can be edited
    - editing the nginx site config file `/etc/nginx/sites-available/landchad` [^nx2]
- `/etc/nginx/sites-enabled`: containing just symlinked config files from `sites-available`. 

- check/create those directories structures:[^nx6]
```
mkdir /etc/nginx/conf.d /etc/nginx/sites-enabled /etc/nginx/sites-available
```
- To activate whatever site is available, run the following command:
```
ln -s /etc/nginx/sites-available/www.example.org.conf /etc/nginx/sites-enabled/
```

- to check if nginx configuration file is ok: `nginx -t`
- after check, reload config: `systemctl reload nginx` (if not using systemd, `nginx -s reload`)

- `/etc/nginx/sites-available/default`: if there is default config file
    - `cp /etc/nginx/sites-available/default /etc/nginx/sites-available/landchad`: create a new file (copy). Every new site has its own config file
    - remove `/etc/nginx/sites-enabled/default` (this is a symlink, check)

**OTHER CONFIGURATION SETUPS AND NOTES:**

- `rewrite ^/user/\w+ /greet;`: [^nx3][13. Rewrites & Redirects], keeps the original url
    - e.g. `rewrite /cadelab /greet;`

## Deploy projects to server
> `# Nginx`

**STATIC FILES**

- (static) upload website files to the site dir `/var/www/html` or `/var/www/landchad` or any other I have
    - `rsync -vrzP --delete-after ~/website/ user@host:/var/www/html/`
- for undestanding paths, and relative paths, location[^nx8]

To serve static files in another URI, e.g.: `http://my.domain.com/cadelab`

- if setup `root /var/www/html;`
    - all sub-dirs will host a path for site:
    - e.g: static files at `root /var/www/html/cadelab;`
        - don't need to setup any location block or redirect or rewrite
- the correct navigation for this relative path depends on the correct configuration at the static files project
    - see the [configuration for Sapper / Svelte project](articles/it-webdev.md)(#svelte-sapper)."Serve static in another URI"

**SERVICE**

- e.g. python gunicorn, node.js, etc..
- [Set up a python project with gunicorn](articles/it-python.md)
- [PostgREST](articles/it.md)(#postgrest)

## Configure Nginx to serve each project
> `# Nginx`

- `location` directive: filter by the URI
- `server` directive: filter by domain/subdomain/ip and/or port

## Setup secure connection (TSL and HTTP2)
> `# Nginx`

- install `python-certbot-nginx`

- run `certbot --nginx`
    - put email
    - (A)gree
    - give email? no
    - which domain? (enter to accept all)
    - do you wanna redirect these sites? (http to https, removing http access)... yes
(when finished, certbot will have changed nginx config files)

- after certbot:
    - `listen 443 ssl http2;`: add `http2`, is needed, automatically falls back to HTTP 1.1 if not supported
    - add `http2` (can be done just after a valid certificate)[^nx3][24. HTTP2][26. Https (SSL)]

- check if certbot have added:
    ```
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2; #disable SSL
    # check if certbot has added:
        # ciphers directive
        # DH params
        # HSTS adD_header Stric-Transport-Security
        # ssl_session_cache ssl_session_timeout ssl_session_tickets
    ```

- after you already have a Nginx running with certbot, and then adds another service (site):
- run again `certbot --nginx`
    - will ask to expand your already created certificate

- check a renew certificate: `sudo certbot renew --dry-run`
- set a cronjob to renew certificate every 30 days (the certificate lasts for 90 days)
    - `sudo certbot renew`
    ```
    sudo crontab -e
    ---
    30 4 1 * * sudo certbot renew --quiet
    ```
Other resources:
- How to get HTTPS working on your local development environment in 5 minutes `https://www.freecodecamp.org/news/how-to-get-https-working-on-your-local-development-environment-in-5-minutes-7af615770eec/amp/?__twitter_impression=true`
- How does HTTPS work? What's a CA? What's a self-signed Certificate? https://youtu.be/T4Df5_cojAs

## Tuning / Optimizing
_breadcrumbs: `#Nginx`_

- tool for test server requests, multiple requests, paralel requests[^nx3][27. Rate Limiting]
    - cli `siege` (https://www.joedog.org/siege-home/)

- nginx rate limiting, securing ddos attack
    - [^nx3][27. Rate Limiting]
    - [Rate Limiting with NGINX and NGINX Plus](https://www.nginx.com/blog/rate-limiting-nginx/)
    - [Rate Limiting with Nginx](https://lincolnloop.com/blog/rate-limiting-nginx/)
    - [NGINX rate-limiting in a nutshell](https://www.freecodecamp.org/news/nginx-rate-limiting-in-a-nutshell-128fe9e0126c/)

- tuning nginx [^nx3]
    - [18. worker processes]... 19... 
    - [Section 4]

