# Pytest: Conftest fixture

conftest.py (at the same level of tests files)

```python
import pytest

from some_module_dep import some_func


@pytest.fixture()
def check_something(host):
    def f():
        result = host.run(f"sudo python3 -c '{some_string_cmd}'")
        if result.rc == 1:
        result = host.run("sudo python3 -c 'some other command'")
        output = result.stdout.strip()
        return output in ("1", "True")

    return f


@pytest.fixture()
def check_ltss_activated(host):
    def f():
        returned_res = some_func(host)
        return returned_res.get("status") == "Registered"

    return f
```


At the test file:


```python
# check_something fixture will be passed as an argument to the test function
def test_my_test(check_something, host):
  ...
```
