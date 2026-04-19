# Python

## Run shell command with python

[How to Execute Shell Commands with Python](https://janakiev.com/blog/python-shell-commands/)

- Using the os Module
- Using the subprocess Module
- Conclusion
- Resources

Examples:

```
subprocess.call('echo $MY_SUDO_PASS | sudo -S chown -R username_here /home/username_here/folder_to_change_ownership_recursivley', shell=True)
```

```
from subprocess import Popen, PIPE

input = ['echo', 'FROM mongo:5.0.9']
cmd = ['sudo', 'docker', 'build', '-t', img_name, '-']
print(f"Shell style : {' '.join(input)} | {' '.join(cmd)}")
p1 = Popen(input, stdout=PIPE)
p2 = Popen(cmd, stdin=p1.stdout, stdout=PIPE)
print("Output from last process : " + (p2.communicate()[0]).decode())
```

## General

- python types
  - [mypy: Type hints cheat sheet](https://mypy.readthedocs.io/en/latest/cheat_sheet_py3.html)
  - [fastapi: Python Types Intro](https://fastapi.tiangolo.com/python-types/)

- library for CLI library
  - http://docopt.org/ Command-line interface description language
  - https://github.com/docopt/docopt

python pretty print (standard library)

```python
from pprint import pprint as pp
```

- pretty print rich library color
  - https://rich.readthedocs.io/en/stable/introduction.html
```python
from rich.pretty import pprint
```


- pre-commit examle in a python project
  - https://github.com/GitGuardian/ggshield/blob/main/.pre-commit-config.yaml

**[Python – List Files in a Directory](https://www.geeksforgeeks.org/python-list-files-in-a-directory/)**

---


---

[Convert Python Tuple to Dictionary](https://appdividend.com/2020/12/22/how-to-convert-python-tuple-to-dictionary/)

```
tup = ((11, "eleven"), (21, "mike"), (19, "dustin"), (46, "caleb"))
print(tup)

dct = dict((y, x) for x, y in tup)
print(dct)
```

Output:

```
((11, 'eleven'), (21, 'mike'), (19, 'dustin'), (46, 'caleb'))
{'eleven': 11, 'mike': 21, 'dustin': 19, 'caleb': 46}
```

---

Data validation with Cerberus:

- https://github.com/pyeve/cerberus
- https://zetcode.com/python/cerberus/
- https://docs.python-cerberus.org/en/stable/usage.html


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

## Modules / Imports

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
