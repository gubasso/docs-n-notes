# Python Poetry

- Poetry alternative (written in Rust): https://github.com/astral-sh/rye

To add a local module

```sh
poetry add --editable ../my-module-dir
```

Generates:

```toml
my-module-dir = {path = "../my-module-dir", develop = true}
```


```pyproject.toml
[tool.poetry.scripts]
my-script = "my_module:main"
```

`poetry run my-script`

`poetry export --output requirements.txt`

- `PIP_DISABLE_PIP_VERSION_CHECK=1`: pip install -r /tmp/requirements.txt

To deploy in production with Docker (example):[^6]

```entrypoint.sh
python main.py
or
python myapp
```

About `__main__.py` as entrypoint: https://docs.python.org/3/library/__main__.html

## Deploy Example 1: `requirements.txt`

- Generate `requirements.txt` with a shell script, and build image[^7][^9]:

```build.sh
poetry export -o requirements.txt
docker build .
```

```Dockerfile
FROM python:3.8-slim-buster
PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
RUN pip install /tmp/myapp
ENTRYPOINT ["entrypoint.sh"]
```

## Deploy Example 2: Poetry inside container[^7]

```Dockerfile
FROM python:3.8-slim-buster
PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app
RUN pip install poetry
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-root --no-dev
COPY . .
RUN poetry install --no-dev
ENTRYPOINT ["entrypoint.sh"]
```

[^7]: [Execute command on host during docker build](https://stackoverflow.com/a/42754636)
[^9]: [Faster Docker builds with pipenv, poetry, or pip-tools](https://pythonspeed.com/articles/pipenv-docker/)


## General

### reset a poetry virtual env

To reset a Poetry virtual environment, you can follow these steps to effectively remove the current virtual environment and recreate it. This can be useful if your environment becomes corrupted or you want to start fresh.

#### Steps to Reset a Poetry Virtual Environment: 
 
1. **Remove the Existing Virtual Environment** :
Use the following command to remove the current virtual environment:

```bash
poetry env remove <python-version>
```
To get the specific `<python-version>`, you can use:

```bash
poetry env info --path
```

For example, if you’re using Python 3.9, you could run:


```bash
poetry env remove 3.9
```

If you want to remove all virtual environments for the project, you can use:


```bash
poetry env remove --all
```
 
2. **Recreate the Virtual Environment** :
After removing the old virtual environment, you can recreate a new environment with:

```bash
poetry install
```
This will install all the dependencies listed in your `pyproject.toml` file into a new virtual environment.
 
3. **Check the Status** :
You can verify the status of your new virtual environment by running:

```bash
poetry env info
```

This should successfully reset the virtual environment for your Poetry-managed project.

maybe remove `poetry.lock`
