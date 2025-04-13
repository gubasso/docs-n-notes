# Pydantic: model validators


In **Pydantic v2** , when you use `@model_validator(mode="after")`, the validator’s signature varies depending on whether it’s defined as: 

- An **instance method**  (the first parameter is `self` → the *model instance*), or
- A **class method**  (the first parameter is `cls`, the second is the model instance).

**class method**

```python
@model_validator(mode="after")
@classmethod
def validator_name(cls, instance: T) -> T:
    ...
    return instance
```
Or, if it’s an **instance method** :

```python
@model_validator(mode="after")
def validator_name(self: T) -> T:
    ...
    return self
```

Below are **two**  valid approaches with correct type hints—pick whichever style you prefer.

---

1) Instance method example

```python

class MyModel(BaseModel):
    field1: str
    field2: int

    @model_validator(mode="after")
    def apply_some_logic(self) -> "MyModel":
        # If user did not supply instance_type, fill from the map
        # logic manipulation here... self.field1 = "something"
        return self
```

### Explanation 
 
- `self` is the constructed model instance after normal validation.
- May return some error, raise a `ValueError`.
- Returning `self` is required for a “mode=after” validator.

---

2) Class Method  Example

```python

T = TypeVar("T", bound="MyModel")

class MyModel(BaseModel):
    field1: str
    field2: int

    @model_validator(mode="after")
    @classmethod
    def apply_some_logic(cls, instance: T) -> T:
        # some logic
        return instance
```

### Explanation 
 
- First param is `cls`, second param is the *model instance* (`instance`).
- We use a generic `T` (bound to `"MyModel"`) for correct type annotations, so mypy knows we return the same type we received.
- Rest of the logic is the same: set `instance.field1` from the dictionary if missing, and raise if it remains `None`.
