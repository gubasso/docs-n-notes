# Containers Docker MongoDB

[toc]

# Resources

- [Dockerizing a Mongo Database](https://medium.com/swlh/dockerizing-a-mongo-database-ac8f8219a019)
    - mongodb script getting envvars

# Mongoimport

Import data to db inside container (without copy the file to container):

```
docker exec -i <container-name-or-id> sh -c 'mongoimport -c <c-name> -d <db-name> --drop' < xxx.json
```

# Basic Guide (Step-by-step)

## 1. Create seed script

- Scripts to run automatically
- When initializing a fresh instance
- With `.sh` or `.js`
- Executed in alphabetical order
- Placed at: `/docker-entrypoint-initdb.d`
    - inside container
    - read-only (`:ro`)

Import data to mongodb (will run when container is created, first run)

**`20-mongo_seed.sh`**
```
#!/bin/bash
mongoimport -d mydb -c myCollection --drop --type csv --headerline --file /path/to/yourfile.csv
```

Where:

- `--drop` is drop the collection if already exist.

Need to create a db before importing?

**`10-mongo_init.js`**
```
db = db.getSiblingDB('test-database')
```

## 2. Create/Run mongodb docker

Select which image

```
mongo:<version>
mongo:5.0.9
mongo
mongo:latest
```

Create a network to connect to an app:

```
docker network create my_net
```

Pull desired image:

```
sudo docker pull mongo:5.0.9
```

Create and run container:

```
sudo docker run -d --rm \
    -p 27017:27017 \
    --name mongo-dvc-run \
    -v my_named_volume:/data/db \
    -v ./path/to/csvs:/home/mongodb/data_seed:ro
    -v ./path/to/init/scripts:/docker-entrypoint-initdb.d:ro
    --network my_net \
    mongo-dvc
```

## 3. Check if its ok

- After:
    - created container
    - run server
    - run init scripts
    - imports seed data

Test the correct creation of container:

```
sudo docker exec -it <container_name> bash
```

- runs terminal inside container

```
> mongosh
> show dbs
> use MongoDB
> show collections
> db.Bank_data.findOne()
```

And/or: connect externally (from host or from other container) to mongodb:

```
mongodb://<mongo_container_name>:27017
```

## 4. Stops and removes containers

- Stop containers (will be deleted automatically with `--rm` flag)

Remove named volume:

```
docker volume rm <volume_name>
```

# MongoDB Image installed in Ubuntu Container

**`Dockerfile`**
```
FROM ubuntu:focal AS ubuntu_mongo
RUN apt-get update -y && apt-get upgrade -y \
    && apt-get install -y apt-utils locales software-properties-common gnupg \
      apt-transport-https ca-certificates wget \
    && rm -rf /var/lib/apt/lists/* \
	  && localedef -i en_US -c -f UTF-8 \
        -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - \
    && echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list \
    && apt-get update -y && apt-get install -y mongodb-org
ENV LANG en_US.utf8

FROM ubuntu_mongo
RUN mkdir -p /data/db \
    && chown -R mongodb /data \
    && chmod -R 755 /data
EXPOSE 27017
CMD ["mongod", "--dbpath", "/data/db", "--bind_ip", "0.0.0.0"]
```



