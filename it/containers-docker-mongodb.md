# Containers Docker MongoDB

<!-- vim-markdown-toc GFM -->

* [Resources](#resources)
* [Basic Guide (Step-by-step)](#basic-guide-step-by-step)
    * [1. Create seed script](#1-create-seed-script)
    * [2. Create/Run mongodb docker](#2-createrun-mongodb-docker)
    * [3. Check if its ok](#3-check-if-its-ok)
    * [4. Stops and removes containers](#4-stops-and-removes-containers)

<!-- vim-markdown-toc -->

## Resources

- [Dockerizing a Mongo Database](https://medium.com/swlh/dockerizing-a-mongo-database-ac8f8219a019)
    - mongodb script getting envvars

## Basic Guide (Step-by-step)

### 1. Create seed script

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

### 2. Create/Run mongodb docker

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

### 3. Check if its ok

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

### 4. Stops and removes containers

- Stop containers (will be deleted automatically with `--rm` flag)

Remove named volume:

```
docker volume rm <volume_name>
```

