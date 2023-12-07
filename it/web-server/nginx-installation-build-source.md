# Nginx: Installation / Build from Source

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

## ADD NEW MODULE / DYNAMIC MODULE:

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

## TROUBLESHOOTING AFTER RUNNING / INSTALLATION

if pid file is removed (or was not created)
- stop and disable services (with systemd and/or `nginx -s stop` and/or kill process)
- check if service is stopped: `ps aux | grep nginx`
- run `./configure`, compile and install again
- run nginx once (systemd OR nginx command... one or the other)
