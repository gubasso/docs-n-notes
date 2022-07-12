# Caprover
> https://caprover.com/
> https://caprover.com/docs/get-started.html

<!-- vim-markdown-toc GFM -->

* [Instalation](#instalation)
    * [Hidden Root Domain](#hidden-root-domain)
    * [Custom Default Password](#custom-default-password)
    * [Enforce HTTPS](#enforce-https)
* [Basic Workflow](#basic-workflow)
* [captain-definition](#captain-definition)
* [Connection between containers](#connection-between-containers)
* [Docker compose](#docker-compose)
    * [Method 1: From "One Click Apps/Databases" Template](#method-1-from-one-click-appsdatabases-template)
    * [Method 2: "Pure" docker-compose + Nginx Proxy](#method-2-pure-docker-compose--nginx-proxy)
* [Nginx customization](#nginx-customization)
* [Maintenance](#maintenance)
    * [Cleaning environment](#cleaning-environment)
    * [Remove Caprover from server](#remove-caprover-from-server)
* [References:](#references)

<!-- vim-markdown-toc -->

## Instalation

Add a swapfile to server

setup firewall:[Firewall & Port Forwarding ](https://caprover.com/docs/firewall.html)

Follow Best Practices[^1]

### Hidden Root Domain

- when setting up CapRover, instead of entering `server.domain.com`, enter `something.server.domain.com`

### Custom Default Password

```
docker run -e DEFAULT_PASSWORD='myinitialpassword' -p 80:80 -p 443:443 -p 3000:3000 -v /var/run/docker.sock:/var/run/docker.sock -v /captain:/captain caprover/caprover
```

- `-e DEFAULT_PASSWORD='myinitialpassword'`: initial random passwd to avoid "30 sec window attack", before actual setup[]

### Enforce HTTPS

- enable HTTPS and enable "Enforce HTTPS" (dashboard)

## Basic Workflow

- do not build at caprover server (as is in default `caprover deploy`)
    1. local machine build: build images in my local machine (to not overload server)[^2]
    2. separate build system (ci/cd)[^3]
        - teaches just with gitlab
        -[Alternative Method](https://caprover.com/docs/ci-cd-integration.html#alternative-method )
            - `docker run caprover/cli-caprover:v2.1.1 caprover deploy....`
            - uses caprover webhooks

- setup a `captain-definition` file (#captain-definition)

- login to caprover

```
caprover login
```

- deploy app with those command variations:

```
caprover deploy #1
caprover deploy -d #2
caprover deploy -h https://captain.root.domain.com -p password -b branchName -a app-name #3
```

1. prompt asking a lot of questions
2. no prompt: will use the previously-entered values for the current directory
3. all information inline

## captain-definition

- `captain-definition` file at the root of project dir, side-by-side with `Dockerfile`

**`captain-definition`**
```
 {
  "schemaVersion": 2,
  "dockerfilePath": "./Dockerfile"
 }
```

---

To use image directly from DockerHub:

**`captain-definition`**
```
 {
  "schemaVersion": 2,
  "imageName": "nginxdemos/hello"
 }
```

## Connection between containers

For example, if you want your NodeJS app to access your MongoDB database, and you do not need to access your MongoDB from your laptop, you don't need Port Mapping. Instead, you can use the fully qualified name for the MongoDB instance which is srv-captain--mongodb-app-name (replace mongodb-app-name with the app name you used).

[Connecting to Databases](https://caprover.com/docs/one-click-apps.html#connecting-to-databases)
[Database Connection](https://caprover.com/docs/database-connection.html)

- Connecting Within CapRover Cluster:
    - `srv-captain--<app-name-in-caprover>:3306`
    - `srv-captain--mysqlappname1:3306`
    - `srv-captain--mysqlappname2:3306`

## Docker compose

### Method 1: From "One Click Apps/Databases" Template

[How to Run Docker Compose on CapRover](https://caprover.com/docs/docker-compose.html#how-to-run-docker-compose-on-caprover)

- only supports:
    - `image`
    - `environment`
    - `ports`
    - `volumes`
    - `depends_on`
    - `hostname`

### Method 2: "Pure" docker-compose + Nginx Proxy

[Alternative Approach](https://caprover.com/docs/docker-compose.html#alternative-approach)

```
networks:
  captain-overlay-network:
    external: true
```

## Nginx customization

https://caprover.com/docs/nginx-customization.html

## Maintenance

### Cleaning environment

[Disk Clean-Up](https://caprover.com/docs/disk-cleanup.html)

- make shure have a Docker registry set up (local or remote). 

clean images

```
docker container prune --force
docker image prune --all
```

list and clean volumes

```
docker service ls
docker volume prune
docker volume ls                          # lists all volumes
docker volume rm volume-name-goes-here    # removes a specific volume
```

### Remove Caprover from server

[How to stop and remove Captain?](https://caprover.com/docs/troubleshooting.html#how-to-stop-and-remove-captain)

## References:

[^1]: [Caprover: Best Practices](https://caprover.com/docs/best-practices.html)
[^2]: [Caprover: Static React App (exemple local build)](https://caprover.com/docs/recipe-deploy-create-react-app.html)
[^3]: [Caprover: CI/CD Integration](https://caprover.com/docs/ci-cd-integration.html)
