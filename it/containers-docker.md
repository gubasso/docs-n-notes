# Containers
> docker, kubernetes

[toc]

# Utils

- [Yacht - an Open Source, Self Hosted, Modern, Web GUI for Docker Management similar to Portainer. :awesome_open_source:](https://www.youtube.com/watch?v=eTQ2iB-hjkk)

- [Portainer](./containers-docker-portainer.md)

# After Install

Check if instalation is correct:

```
sudo systemctl status docker
sudo docker run hello-world
sudo docker compose version
```

# Commands


**execute commands inside container**
```
sudo docker exec <cont_name> ls
sudo docker exec -it <cont_name> bash
```

---

Listing things

- `docker ps -a`
    - list CONTAINERS
    - `ps`: list just running containers
    - `-a`: list all created (running or not)

- `docker images`
    - list IMAGES

---

```
docker stop <container_name>
```

---

Fetching remote images:

- `docker run <image_name>`
    - checks if already has this image saved/downloaded
    - if not, will download for the first time
    - if remote image is update, but has already a local version, will not check that
    - instead, just will run the local one

- `docker pull <image_name>`
    - will download from remote
    - if the same version from local, do nothing
    - always checks for updates from source
    - forces pull updated image from registry (docker hub)

---

- `docker run`
    - creates a NEW container (doesn't run a stoped one)
    - `docker run node`: Will download `node` image from docker hub, and run container

flags:

- `-it`: exposes interactive shell to host (nodejs REPL in this case)
    - `docker run -it node`:
    - `-i`: keeps STDIN open, for input
    - `-t`: creates a pseudo-TTY
- `-d`: runs in detached mode (or as a daemon)
    - `docker attach <container_name>` to be attached to a container running in background
        - will be able to see console outputs
- `--rm`: removes container when it stops

---

- `docker logs <container_name>`
    - prints the output of container console

flags:

- `-f, --follow`: keep listening, attached terminal

---

- `docker start <container_name>`
    - starts a previously stoped container
    - does not create a new one from an image

flags:

- `-a`: starts attached
- `-i`: STDIN opened to interact with terminal

---

remove commands / cleanup

stop all containers
```
sudo docker kill $(sudo docker ps -q)
```

- How To Remove Docker Images, Containers, and Volumes: https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes

```
sudo docker kill $(sudo docker ps -q)
sudo docker system prune -a -f && sudo docker volume prune -f
sudo docker network prune -f

```

- `docker rm [<container_name> <> ...]`
    - removes stoped conainters
    - `docker rm naed_dharen jafac_golen persad_thupac`

- `rmi [<image_id> <>]`
    - remove images
    - just if is not used by any container (stoped or running)

- `docker container prune`
    - removes ALL stoped containers

- `image prune`
    - removes ALL images
    - `-a`: ??

---

- `cp <source> <container_name>:<destination>` / `cp <container_name>:<source> <host_destination>`
    - copy copies files to a running container

---

naming tagging

- `docker tag <img_name>:<img_tag> <new_name>:<new_tag>`
    - "renames" images
    - creates a clone, keeps the old named one



# Dockerfile

To create my own image.

`FROM baseImage`: defines docker base image from hub
    - `FROM node:14` / `FROM node`
`WORKDIR /app`: sets the workdir (as a reference). dir with project files
    - if not set, the default is `/`
`COPY <host_source> <destination>`: copy from host file to workdir inside container
    - `<destination>` will be create, if no exist
    - `COPY package.json .`: example copying just one file
        - do it before `RUN npm install` to optimize rebuild
        - will be a layer to be monitored with a cache
        - just `package.json` will be watched
    - `COPY . .`: example copying hole project (where `Dockerfile` is) to workdir (except `Dockerfile` itself)
`RUN npm install`: command to run
    - will run when image is being built (build time)
    - used for multi-stage builds
`EXPOSE 3000`: port to expose to outside world
`CMD ["node","app.mjs"]`: command to run
    - should be last instruction
    - will run when container starts (runtime, not when it's built)
    - if not specified, the default `CMD` of the base image will be ran

At terminal:

```
docker build .
sudo docker build -t {img_name} .
```

- create a new custom image based on `Dockerfile`
- `.`: path to the `Dockerfile`

Then, to run the docker image:

```
docker run -p 3000:3000 <image_id>
```

- Run `CMD`
- `-p 3000:3000`: port fowarding
    - `<host_port>:<docker_internal_exposed_port>`
- `<image_id>`: hash with id of the image

### `.dockerignore`

Ignored by `COPY` command.

```
.git
node_modules
Dockerfile
.env
```

## Environment variables

- env can be used inside `Dockerfile`

```Dockerfile
ENV PORT 80
ENV DB_USERNAME=guga
EXPOSE $PORT
```

- When assigned with `=` is a default value

or

```bash
docker run -d -p 3000:8000 --rm \
    --env PORT=8000 \
    --name feedback-app \
    -v feedback:/app/feedback \
    feedback-node:volumes
```

- `--env` / `-e`

or

```.env
PORT=8000
```

- `--env-file ./.env`

# Sharing Images

Login to a private registry:

```
docker login localhost:8080
cat ~/my_password.txt | docker login --username foo --password-stdin
```

Docker Hub or a private registry

Automatically from docker hub:

`docker share <image_name>` / `docker pull <image_name>`

If wants to use a private registry:

`docker share <host>:<image_name>` / `docker pull <host>:<image_name>`

## Image to file[^5]

Save a docker image to file:

```
sudo docker save -o <path for generated tar file> <image name>
```

Load a docker image from file:

```
sudo docker load -i <path to image tar file>
```

# Arguments

(todo)
- when to use this instead of env variables?

## Usefull example:

```
FROM node:14-slim

RUN userdel -r node

ARG USER_ID

ARG GROUP_ID

RUN addgroup --gid $GROUP_ID user

RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user

USER user

WORKDIR /app
```

And then build the Docker image using the following (which also gives you a nice use of ARG):

```
$ docker build -t node-util:cliuser --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .
```

# Persistent Data Storages

## Volumes

- Dir in host machine
- Mapped inside a container (mounted)
- data is not removed when a container ir removed/deleted
- the dir path where volume is saved is managed by Docker

- `docker volume ls`: list volumes

- Anonymous volumes: removed when container ir removed
    - @ `Dockerfile`: `VOLUME [ "/app/feedback" ]`
    - (or) @ cli `-v /app/feedback`
    - only if container is started with `--rm`
    - if not, when container ir stoped, or even if container is later removed with `docker rm`
        - anon volume will still be preserved
    - if recreate the container, a NEW anon volume will be created
        - will not reference to the old volume created previously

- remove volumes:
    - `docker volume rm VOL_NAME` or `docker volume prune`

- Named volumes: will persist in host machine even if a container ir removed
    - @ cli: `docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback feedback-node:volumes`
        - `--name feedback-app`: name of the container being created
        - `feedback-node:volumes`: name of the image used to create this volume
        - `-v feedback:/app/feedback`: named volume `<volume_name>:<dir_path_inside_container>`

## Bind Mounts

- user define a path to host machine
- a map from host dir path to container dir path

```
docker run -d -p 3000:80 --rm \
    --name feedback-app \
    -v feedback:/app/feedback \
    -v /home/gubasso/Projects/docker-training:/app:ro \
    -v /app/node_modules \
    feedback-node:volumes
```

- `-v /home/gubasso/Projects/docker-training:/app:ro \`
    - saves all workdir files at app dir inside container
    - `-v <absolute_workdir_host_path>:<container_workdir_path>`
    - `-v $(pwd):/app`
    - dir or a single file too
    - `:ro`: enforces that the container cannot change files (Read Only)
    - the files will be changed only from the host, never from inside


- `-v /app/node_modules \`
    - make shure `node_modules` will not be overwritten
    - after `Dockerfile` is ran, container is created, than volumes are synced
    - this sets this subdir `node_modules` to remain the same

## Database Persistence

- read specific database docker doc (at docker hub, for example)

Example for mongodb[^1]:

- recommended, named volume: `-v data:/data/db`
- bind moung: `docker run --name some-mongo -v /my/own/datadir:/data/db -d mongo`


# Networking

## Container to Host communication

connect from container to database at host

- normal mongodb url: `mongodb://localhost:27017/mydb`
- access from container to host: `mongodb://host.docker.internal:27017/mydb`
    - `host.docker.internal` will be transformed to host IP address

## Container to Container comm

If want to hard code the container ip address:

- `docker container inspect <container_name>`: To find a container IP address
    - at `NetworkSettings.IPAddress`

---

Using docker native network for resolve ip addresses automaticaly

- create a network: `docker network create <network_name>`
    - have to be created first, docker will not create automatically if used in a `docker run` command
    - `docker network create favorites-net`

```
docker run -d --name mongodb \
    --network favorites-net
    mongo
```

- for a container to connect to another, running at the same network:
    - `mongodb://<container_name>:27017/mydb`
    - `mongodb://mongodb:27017/mydb`



# Docker-Compose

- defaults with `--rm`
- creates a `network` by default
    - adds all containers to this network

- cli to run: `docker-compose up`
    - will build and start all services
    - before run, check if it is needed to cleanup old images/containers
    - `-d`: deattached mode
    - `--build`: forces to rebuild
        - if not, if image already exists, will not rebuild
        - usefull if there was an update in image / source code / etc...
    - can specify which service will be up, and ignore others specified at yaml file
        - `docker-compose up server mysql php`
        - if `server` service `depends_on:` both `mysql` and `php`
            - `docker-compose up server` will spinup the other two automatically

- `docker-compose down`
    - deletes containers, networks, and shutsdown
    - does NOT delete volumes
    - `-v`: also deletes volumes

- `docker-compose build`
    - just builds all images


## `docker-compose.yaml`

- `services:`: each child is a container
    - key: is the service name (that can be used as a container name)
    - service name can be used as reference for networking, etc...
        - just like a container name

---

```docker-compose.yaml
services:
  myservice_name1:
    images: 'mongo'
    volumes:
      - .:/code
      - logvolume01:/var/log
    env_file:
      - .env
      - ./env/mongo.env
    ports:
      - '3000:80'
  myservice_name2:
    ...
    stdin_open: true
    tty: true
    depends_on:
      - myservice_name1
      - ...
volumes:
  logvolume01:
```

- inside a container (`services` child)

- `images:`: base image name (e.g. from docker hub, or custom one I created)
    - `images: 'mongo'` / `images: 'node:14'`

- `volumes:`
    - same syntax as cli
    - if named volumes, need a `volumes:` key, sibling of services, with the named volume
    - "To reuse a volume across multiple services, a named volume MUST be declared in the top-level `volumes` key."[^2]

- `build:`
    - relative path to `Dockerfile` (relative to `docker-compose.yaml`)

- `depends_on:`: will run after the dependencies

- `stdin_open:` / `tty:`: same as `-i` / `-t`

# Utility Containers

Use as a isolated environment.

```
docker run -it node npm init
```

- `npm init`: will overwright default image's `CMD`

In an empty project directory, create a simple `Dockerfile`

```
FROM node:14-alpine

WORKDIR /app
```

```
docker run -it -v $(pwd):/app <image_name> <command>
```

- `<command>`: can be `npm init`
- `package.json` will be created in the container and in our host directory too

```Dockerfile
ENTRYPOINT [ "npm" ]
```

- `ENTRYPOINT`:
    - will not be overwritten by appended commands (as it happens with `CMD`)
    - the appended commands will be appended to this entrypoint
    - usefull to allow only one kind of command

## Using with Docker-Compose

```docker-compose.yaml
version: "3.8"
services:
  guganpm:
    build: ./
    stdin_open: true
    tty: true
    volumes:
      - ./:/app
```

- Then run with `docker-compose run <service_name>` (not `up`).
    - this will allow appended commands
    - will not remove the container automatically (as it happens with `up`)

```
docker-compose run guganpm init
```

- Flags for `run`:
    - `--rm`: removes container after it stops


# Users / Permissions:[^3]

I wanted to point out that on a Linux system, the Utility Container idea doesn't quite work as you describe it.  In Linux, by default Docker runs as the "Root" user, so when we do a lot of the things that you are advocating for with Utility Containers the files that get written to the Bind Mount have ownership and permissions of the Linux Root user.  (On MacOS and Windows10, since Docker is being used from within a VM, the user mappings all happen automatically due to NFS mounts.)

So, for example on Linux, if I do the following (as you described in the course):

```Dockerfile
FROM node:14-slim
WORKDIR /app
```

```
$ docker build -t node-util:perm .
$ docker run -it --rm -v $(pwd):/app node-util:perm npm init
```

```
$ ls -la

total 16

drwxr-xr-x  3 scott scott 4096 Oct 31 16:16 ./

drwxr-xr-x 12 scott scott 4096 Oct 31 16:14 ../

drwxr-xr-x  7 scott scott 4096 Oct 31 16:14 .git/

-rw-r--r--  1 root  root   202 Oct 31 16:16 package.json
```

You'll see that the ownership and permissions for the package.json file are "root".  But, regardless of the file that is being written to the Bind Mounted volume from commands emanating from within the docker container, e.g. "npm install", all come out with "Root" ownership.

---

Solution 1:  Use  predefined "node" user (if you're lucky)

There is a lot of discussion out there in the docker community (devops) about security around running Docker as a non-privileged user (which might be a good topic for you to cover as a video lecture - or maybe you have; I haven't completed the course yet).  The Official Node.js Docker Container provides such a user that they call "node".

https://github.com/nodejs/docker-node/blob/master/Dockerfile-slim.template

```Dockerfile
FROM debian:name-slim
RUN groupadd --gid 1000 node \
         && useradd --uid 1000 --gid node --shell /bin/bash --create-home node
```

Luckily enough for me on my local Linux system, my "scott" uid:gid is also 1000:1000 so, this happens to map nicely to the "node" user defined within the Official Node Docker Image.

So, in my case of using the Official Node Docker Container, all I need to do is make sure I specify that I want the container to run as a non-Root user that they make available.  To do that, I just add:

```Dockerfile
FROM node:14-slim
USER node
WORKDIR /app
```

If I rebuild my Utility Container in the normal way and re-run "npm init", the ownership of the package.json file is written as if "scott" wrote the file.

```
$ ls -la

total 12

drwxr-xr-x  2 scott scott 4096 Oct 31 16:23 ./

drwxr-xr-x 13 scott scott 4096 Oct 31 16:23 ../

-rw-r--r--  1 scott scott 204 Oct 31 16:23 package.json
```

---

Solution 2:  Remove the predefined "node" user and add yourself as the user[^4].

However, if the Linux user that you are running as is not lucky to be mapped to 1000:1000, then you can modify the Utility Container Dockerfile to remove the predefined "node" user and add yourself as the user that the container will run as:

```Dockerfile
FROM node:14-slim

RUN userdel -r node

ARG USER_ID

ARG GROUP_ID

RUN addgroup --gid $GROUP_ID user

RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user

USER user

WORKDIR /app
```

And then build the Docker image using the following (which also gives you a nice use of ARG):

```
$ docker build -t node-util:cliuser --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) .
```

And finally running it with:

```
$ docker run -it --rm -v $(pwd):/app node-util:cliuser npm init
```

```
$ ls -la

total 12

drwxr-xr-x  2 scott scott 4096 Oct 31 16:54 ./

drwxr-xr-x 13 scott scott 4096 Oct 31 16:23 ../

-rw-r--r--  1 scott scott  202 Oct 31 16:54 package.json
```

Keep in mind that this image will not be portable, but for the purpose of the Utility Containers like this, I don't think this is an issue at all for these "Utility Containers"

# Deploy in production

- do NOT use bind mounts

## [Kubernetes](./it/containers-kubernetes.md)

# Resources

- [Docker Playground](https://labs.play-with-docker.com/)
- [Docker hub](https://hub.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [](https://yacht.sh/)
    - web ui for managing containers, available at linode
- Udemy Course Academind: [Docker & Kubernetes: The Practical Guide [2022 Edition]](https://www.udemy.com/share/103Ia03@_LG5LvM93j_prIuRNO6TDsc6YuhwqudbXhJirjmPbdAU7lSzxDsoTeCwzbGUXkS6/)

# General

Python images to choose:

[Don’t use Alpine Linux for Python images: Using Alpine can make Python Docker builds 50× slower](https://pythonspeed.com/articles/alpine-docker-python/)
[The best Docker base image for your Python application (May 2022)](https://pythonspeed.com/articles/base-image-python-docker-images/)
- summary: `python:<version>-slim-bullseye`

Mongodb images

## Optimization: build image

**[Reduce Build Context for Docker Build Command](https://www.baeldung.com/ops/docker-reduce-build-context)**

- Understanding the Docker Build Context
- Using EOF File Creation

```
$ docker build -t test -<<EOF
FROM   centos:7
MAINTAINER maintainer@baeldung.com
RUN echo "Welcome to Bealdung"
EOF
```

```
echo "FROM mongo:5.0.9" | sudo docker build -t {img_name} -
```



# References

[^1]: [official image mongo](https://hub.docker.com/_/mongo)
[^2]: [Reference / Compose file reference / Compose Specification / Volume](https://docs.docker.com/compose/compose-file/#volumes)
[^3]: [Utility Containers, Permissions & Linux from: Docker & Kubernetes: The Practical Guide [2022 Edition] ](https://www.udemy.com/course/docker-kubernetes-the-practical-guide/learn/#questions/12977214/)
[^4]: [Avoiding Permission Issues With Docker-Created Files](https://vsupalov.com/docker-shared-permissions/)
[^5]: [How to copy Docker images from one host to another without using a repository](https://stackoverflow.com/questions/23935141/how-to-copy-docker-images-from-one-host-to-another-without-using-a-repository)
