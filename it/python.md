# Python

<!-- vim-markdown-toc GFM -->

    * [Project Structure (files / directories)](#project-structure-files--directories)
* [Modules / Imports](#modules--imports)
    * [Poetry](#poetry)
        * [Deploy Example 1: `requirements.txt`](#deploy-example-1-requirementstxt)
        * [Deploy Example 2: Poetry inside container[^7]](#deploy-example-2-poetry-inside-container7)
    * [References](#references)

<!-- vim-markdown-toc -->

## Project Structure (files / directories)

- Models for apps layouts/structures (excelent resource)[^5]

Example from "Application with Internal Packages"[^5]

```
helloworld/
│
├── bin/
│
├── docs/
│   ├── hello.md
│   └── world.md
│
├── helloworld/
│   ├── __init__.py
│   ├── runner.py
│   ├── hello/
│   │   ├── __init__.py
│   │   ├── hello.py
│   │   └── helpers.py
│   │
│   └── world/
│       ├── __init__.py
│       ├── helpers.py
│       └── world.py
│
├── data/
│   ├── input.csv
│   └── output.xlsx
│
├── tests/
│   ├── hello
│   │   ├── helpers_tests.py
│   │   └── hello_tests.py
│   │
│   └── world/
│       ├── helpers_tests.py
│       └── world_tests.py
│
├── .gitignore
├── LICENSE
└── README.md
```

---

- `__init__.py`: is not required anymore (3.3+), but needed for compatibilty issues (as for correct use of `pytest`)[^3][^4]

# Modules / Imports

- About python modules/import[^2][^1]
    - Absolute / Relative paths to imports: https://realpython.com/absolute-vs-relative-python-imports/

[How to load all modules in a folder?](https://stackoverflow.com/questions/1057431/how-to-load-all-modules-in-a-folder)

Simple and working answer: https://stackoverflow.com/a/36231122

**`__init__.py`** (inside module dir)
```
import os, pkgutil
__all__ = list(module for _, module, _ in pkgutil.iter_modules([os.path.dirname(__file__)]))
```

From outside module, call:

```
from yourpackage import *
```

## Poetry

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

### Deploy Example 1: `requirements.txt`

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

### Deploy Example 2: Poetry inside container[^7]

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


## References

[^1]: [What is the best project structure for a Python application?](https://stackoverflow.com/a/3419951)
[^2]: [Python 3.10.5 Documentation » The Python Tutorial » 6. Modules](https://docs.python.org/3/tutorial/modules.html)
[^3]: [Is __init__.py not required for packages in Python 3.3+](https://stackoverflow.com/questions/37139786/is-init-py-not-required-for-packages-in-python-3-3)
[^4]: [Nick Coghlan's Python Notes >> Docs » Python Concepts » Traps for the Unwary in Python’s Import System](https://python-notes.curiousefficiency.org/en/latest/python_concepts/import_traps.html)
[^5]: [Python Application Layouts: A Reference](https://realpython.com/python-application-layouts/)
[^6]: [Poetry vs. Docker caching: Fight!](https://pythonspeed.com/articles/poetry-vs-docker-caching/)
[^7]: [Execute command on host during docker build](https://stackoverflow.com/a/42754636)
[^8]: [How to suppress pip upgrade warning?](https://stackoverflow.com/questions/46288847/how-to-suppress-pip-upgrade-warning)
[^9]: [Faster Docker builds with pipenv, poetry, or pip-tools](https://pythonspeed.com/articles/pipenv-docker/)
