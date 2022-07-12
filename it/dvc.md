# DVC Data Versioning
> https://dvc.org/doc

<!-- vim-markdown-toc GFM -->

* [Instalation and Setup](#instalation-and-setup)
    * [Setup remote](#setup-remote)
        * [Local remote](#local-remote)
    * [Remote server/cloud](#remote-servercloud)
* [Basic Usage](#basic-usage)
* [Other Use Cases](#other-use-cases)
    * [Space Optimization: Large datasets](#space-optimization-large-datasets)
    * [Access a separate DVC repo](#access-a-separate-dvc-repo)
    * [Remove / Stop tracking files:](#remove--stop-tracking-files)
    * [Merge Conflicts in DVC Files](#merge-conflicts-in-dvc-files)
    * [Share Cache Files](#share-cache-files)
* [Commands](#commands)
    * [DVC: fetch, checkout, pull](#dvc-fetch-checkout-pull)
* [References](#references)

<!-- vim-markdown-toc -->

## Instalation and Setup

1. asdf python local env
2. poetry add dvc
3. run with: `poetry run dvc`
    - `alias dvc='poetry run dvc'`

### Setup remote

- [External Dependencies](https://dvc.org/doc/user-guide/external-dependencies)
    - Amazon S3
    - Microsoft Azure Blob Storage
    - Google Cloud Storage
    - SSH
    - HDFS
    - HTTP
    - Local files and directories outside the workspace

- Managing External Data https://dvc.org/doc/user-guide/managing-external-data
    - remote storage Amazon S3, Wasabi...

#### Local remote

```
dvc remote add -d myremote /tmp/dvcstore
git commit .dvc/config -m "Configure local remote"
```

### Remote server/cloud

[Setup a Google Drive DVC Remote](https://dvc.org/doc/user-guide/setup-google-drive-remote)


## Basic Usage

Add data:

```
dvc add data/data.xml
git add data/data.xml.dvc data/.gitignore
git commit -m "Add raw data"
```

Push data to remote:

```
dvc push
```

Retrieve data from remote (download data):

```
dvc pull
```

After change the file `data/data.xml`, add changes to dvc:

```
dvc add data/data.xml
git commit data/data.xml.dvc -m "Dataset updates"
dvc push
```

If wants to access a different version of data, in a differente git branch or commit:

```
git checkout <...>
dvc checkout
```

---

[How to Update Tracked Data](https://dvc.org/doc/user-guide/how-to/update-tracked-data)

- Modifying content

```
dvc unprotect train.tsv
echo "new data item" >> train.tsv
dvc add train.tsv
git add train.tsv.dvc
git commit -m "modify train data"
dvc push
git push
```

- Replacing files

```
dvc remove train.tsv.dvc
echo new > train.tsv
dvc add train.tsv
<...>
```

- `dvc checkout`: sync data previously saved


## Other Use Cases

### Space Optimization: Large datasets

- Large datasets versioning https://dvc.org/doc/start/data-management#large-datasets-versioning
    - cache:
        - shared cache https://dvc.org/doc/user-guide/how-to/share-a-dvc-cache
        -[Setting up an external cache ](https://dvc.org/doc/user-guide/managing-external-data#setting-up-an-external-cache)
    - Managing External Data https://dvc.org/doc/user-guide/managing-external-data
        - remote storage Amazon S3, Wasabi...

[Large Dataset Optimization](https://dvc.org/doc/user-guide/large-dataset-optimization)

- File link types for the DVC cache
    - `reflink`
    - `hardlink`
    - `symlink`
    - `copy`

### Access a separate DVC repo

Supose there is a separate repo just for a dataset (data-registry repo):


```
+-------------+     +--------------+     +-------------+
|             |     |  Deployment  |     |             |
|  Project A  |     |    Server    |     |  Project B  |
|             |     +--------------+     |             |
+-------------+            ^             +-------------+
       ^                   |                    ^
       |         +---------+---------+          |
       |         |                   |          |
       |         |   Data Registry   |          |
       +---------+                   +----------+
                 |   (Git+DVC repo)  |
                 |                   |
                 +-------------------+
                           ^
                           |
               +-----------+----------+
               |                      |
               |     Data Storage     |
               |                      |
               | (S3, ssh, GCS, etc.) |
               |                      |
               +----------------------+
```

- A good way to organize DVC repositories into data registries is to use directories to group similar data, e.g. `images/`, `natural-language/`, etc.

---

Find a file or directory

```
dvc list https://github.com/iterative/dataset-registry get-started
.gitignore
data.xml
data.xml.dvc
```

---

Download (simple)

```
dvc get https://github.com/iterative/dataset-registry \
          use-cases/cats-dogs
```

---

Download and add to your repo (Import file or directory)

```
dvc import https://github.com/iterative/dataset-registry \
             get-started/data.xml -o data/data.xml
```

- similar to: `dvc get` + `dvc add`
- difference:  `.dvc` files includes metadata to track changes in the source repository. This allows you to bring in changes from the data source later using `dvc update`.

### Remove / Stop tracking files:

[How to Stop Tracking Data](https://dvc.org/doc/user-guide/how-to/stop-tracking-data)

### Merge Conflicts in DVC Files

[How to Merge Conflicts in DVC Files](https://dvc.org/doc/user-guide/how-to/merge-conflicts)

### Share Cache Files

[How to Share a DVC Cache](https://dvc.org/doc/user-guide/how-to/share-a-dvc-cache)

## Commands

### DVC: fetch, checkout, pull

```
Tracked files                Commands
---------------- ---------------------------------

remote storage
     +
     |         +------------+
     | - - - - | dvc fetch  | ++
     v         +------------+   +   +----------+
project's cache                  ++ | dvc pull |
     +         +------------+   +   +----------+
     | - - - - |dvc checkout| ++
     |         +------------+
     v
 workspace
```

- `dvc pull` = `dvc fetch` + `dvc checkout`
- `dvc fetch`: downloads all files and directories to `.dvc/cache` only (don't link files to workspace)
- `dvc checkout`: sync `.dvc/cache` to workspace data files (e.g. `myproject/data`)

## References

[^1]: [Versioning Data with DVC (Hands-On Tutorial!)](https://www.youtube.com/watch?v=kLKBcPonMYw)
[^2]: [Sharing Data and Models with DVC (Hands-On Data Science Tutorial!)](https://www.youtube.com/watch?v=EE7Gk84OZY8)
[^3]: [DVC: Data Registry](https://dvc.org/doc/use-cases/data-registry)





