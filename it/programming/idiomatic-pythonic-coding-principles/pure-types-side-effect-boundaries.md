# Pure Types, Side-Effect Boundaries

> Why Parsing and I/O Belong Outside Your Domain Models (Lessons from Rust, Pydantic, and Functional Design)

Short answer: keep your domain types **pure and side-effect free**; put I/O (files, sockets, env) in thin, external helpers. It’s fine (and ergonomic) for a type to expose **pure** (de)serialization that works on in-memory data (str/bytes), but **file paths and readers/writers belong outside**. This lines up with widely used architectural guidance (functional core/imperative shell, hexagonal), Rust’s idioms (traits like `Serialize/Deserialize`, `FromStr`, `Display`, and `Read`/`Write`-based APIs), and Pydantic v2’s model dump/validate APIs. ([Destroy All Software][1])

Here’s the reasoning, with concrete takeaways:

## Why keep types “dumb” about I/O

* **Testability & determinism.** Functional-core/imperative-shell recommends pushing side effects to the edges. Your “core” (domain types) is pure and easy to unit test; the “shell” does I/O and is integration-tested. ([Destroy All Software][1])
* **Architecture boundaries.** Hexagonal/ports-and-adapters keeps the domain independent of infrastructure (files, HTTP, DB). Your models shouldn’t know where bytes came from or where they’ll be stored. ([Code With Arho][2])
* **API ergonomics in Rust & beyond.** Idiomatic Rust code separates data representation from I/O: you implement parsing/formatting via traits and accept generic `Read`/`Write` streams for persistence—never hard-wire file paths into your types. ([Rust Documentation][3])

## What “idiomatic” looks like in Rust

* **Serialize/Deserialize with Serde** on the type; let *callers* choose the format crate (`serde_json`, `serde_yaml`, etc.). The type stays format-agnostic and I/O-agnostic. ([Serde][4])
* **Parsing from strings**: implement `FromStr` (and/or `TryFrom<&str>`) so callers can do `"…".parse::<T>()`. Community guidance and clippy lean toward `FromStr` for actual parsing. ([Stack Overflow][5])
* **Formatting to strings**: implement `Display` (and `ToString` comes for free). Keep filesystem access in separate functions that take `impl Read/Write` to maximize reuse and testability. ([GitHub][6])

## What “idiomatic” looks like in Python with Pydantic v2

* Use **pure** conversions on the model: `model.model_dump()` / `model.model_dump_json()` and `Model.model_validate(...)` / `Model.model_validate_json(...)`. These are side-effect free and align with the library’s intended usage. ([Pydantic][7])
* Keep **file I/O** in helpers (e.g., `load_active_products(fp: TextIO)` / `save_active_products(fp: TextIO, ap: ActiveProducts)`) so tests can pass `io.StringIO` or temp files. This mirrors Rust’s `Read`/`Write` style abstractions for better test isolation. ([Rust Documentation][3])
* If you want YAML support, it’s fine to provide **string-level** helpers on the type (`to_yaml_str()` / `from_yaml_str()`), but prefer file handling outside. Pydantic doesn’t ship YAML itself; this separation keeps the model decoupled from optional dependencies. ([Pydantic][7])

## A pragmatic compromise (what great codebases do)

1. **Domain types** expose **string/bytes** conversions (pure):

   * Python: `to_yaml_str()`, `from_yaml_str()`, `model_dump_json()`, `model_validate_json()` (no file access). ([Pydantic][7])
   * Rust: `impl Serialize/Deserialize`, `impl FromStr`, `impl Display`. ([Serde][4])
2. **Adapters/services** own **I/O**:

   * Python: `load_from_yaml(path | fp)` / `save_to_yaml(path | fp)` live in a `io_/persistence` module and accept file-like objects for testing.
   * Rust: `fn read_from<R: Read>(r: R) -> Result<T, _>` / `fn write_to<W: Write>(w: W, value: &T) -> Result<(), _>`. ([Rust Documentation][3])
3. **Optional convenience** methods on the model (e.g., `ActiveProducts.save(path)`): if you keep them, make them **thin wrappers** that delegate to the adapter. This preserves the clean separation while remaining ergonomic.

### TL;DR

* **Best practice:** *Types stay pure; I/O lives outside.*
* **Allow on-type helpers** that work with in-memory data (str/bytes) only.
* **Use traits/standard APIs** for parsing/formatting and generic I/O (Rust’s `Serialize/Deserialize`, `FromStr`/`Display`; Python’s Pydantic `model_dump`/`model_validate` and file-like objects).
  This approach gives you maximal testability, portability, and composability while keeping ergonomics high. ([Destroy All Software][1])

If you want, I can refactor your `ActiveProducts` to this pattern (string-level methods on the class + small `io.py` with file/stream helpers).

[1]: https://www.destroyallsoftware.com/screencasts/catalog/functional-core-imperative-shell?utm_source=chatgpt.com "Functional Core, Imperative Shell - Destroy All Software"
[2]: https://www.arhohuttunen.com/hexagonal-architecture/?utm_source=chatgpt.com "Hexagonal Architecture Explained - Code With Arho"
[3]: https://doc.rust-lang.org/std/io/?utm_source=chatgpt.com "std::io - Rust"
[4]: https://serde.rs/impl-serialize.html?utm_source=chatgpt.com "Implementing Serialize · Serde"
[5]: https://stackoverflow.com/questions/71487308/is-there-any-real-difference-between-fromstr-and-tryfromstr?utm_source=chatgpt.com "rust - Is there any real difference between `FromStr` and `TryFrom<&str ..."
[6]: https://github.com/rust-lang/api-guidelines/blob/master/src/interoperability.md?utm_source=chatgpt.com "api-guidelines/src/interoperability.md at master · rust-lang/api ..."
[7]: https://docs.pydantic.dev/latest/concepts/serialization/?utm_source=chatgpt.com "Serialization - Pydantic"
