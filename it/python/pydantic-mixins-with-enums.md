# Python Mixins with enums

- Python, pydantic v2, enum

- In the example bellow the mixin only works because the class attribute names are between two underscores `__attribute_name__`.
- If not, python would interpret `match_strings` and `default` as enum variants

```python
from enum import Enum
from typing import Dict, List, Type, TypeVar

T = TypeVar("T", bound="ClassifierMixin")


class ClassifierMixin:
    __match_strings__: Dict[str, List[str]] = {}
    __default__: str = ""

    @classmethod
    def from_name(cls: Type[T], name: str) -> T:
        for enum_name, substrings in cls.__match_strings__.items():
            if all(s in name for s in substrings):
                return cls[enum_name]
        return cls[cls.__default__]


class Construction(ClassifierMixin, Enum):
    __match_strings__ = {
        "BUILDING": ["apto", "number"],
    }
    __default__ = "HOUSE"

    BUILDING = "building"
    HOUSE = "house"


class Architecture(ClassifierMixin, Enum):
    __match_strings__ = {
        "MODERN": ["build", "classic"],
    }
    __default__ = "CLASSIC"

    MODERN = "modern"
    CLASSIC = "classic"
```
