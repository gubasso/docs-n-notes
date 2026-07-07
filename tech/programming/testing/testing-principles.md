# Testing Principles — Embedded Fallback

Loaded by `test-review` only when the canonical principles file
(`08-testing-and-quality/testing-strategy.md`) cannot be resolved from any of the higher-precedence
paths.

**Authoritative source:** the full version of these principles, with examples and tooling pointers,
lives at `tech/programming/cli-design/09-testing-and-quality/testing-strategy.md` in the user's
docs-n-notes repo. Update this excerpt when the canonical file changes substantively — but the
test-review skill should still prefer the canonical file via the resolution chain whenever it is
reachable.

## Non-negotiable principles

1. **Best practices first.** Clean, maintainable tests in the idioms the language community
   considers standard.
2. **Test major public APIs and core interfaces** — the behavior that defines the product, not
   incidental helpers.
3. **Test behavior and contracts, not implementation details.** If you can refactor without changing
   the public contract, the test should still pass.
4. **Don't test third-party libraries.** Assume they're correct. Mock or fake them at their
   boundary.
5. **Deterministic and fast.** Isolate side effects; no shared state, no real clock, no network, no
   order dependence.
6. **Meaningful coverage driven by risk and impact**, not line-count.
7. **Clear names, minimal mocking, readable assertions.** A test reads as documentation of the
   contract it locks down.

When the skill cites a violation, format the citation as `principles-excerpt:<heading>` if it had to
fall back to this file (instead of `08-testing-and-quality/testing-strategy.md:<line>` against the
canonical source).

## Test-shape models

- **Pyramid** (default for CLIs / libraries / monoliths): wide base of unit tests, narrowing through
  integration to a thin E2E apex.
- **Trophy** (Kent C. Dodds): integration-heavy, on top of a static-analysis base. Fits apps that
  mostly orchestrate I/O.
- **Honeycomb** (Spotify): equal weight on intra-service unit + contract + inter-service E2E. Fits
  microservice fleets.

Decision rule: CLI/library → pyramid; service orchestrating I/O → trophy; microservice fleet →
honeycomb. The principles below are shape-neutral.

## The pyramid

- **Unit** — colocated, fast, every module with logic.
- **Integration** — one file per public API boundary (per subcommand for CLIs). Tests _interactions_
  between components; uses fakes/stubs at external boundaries.
- **Snapshot** — long structured output. Lives inside unit and integration.
- **Compile-fail / typestate** — only when a typestate API exists.
- **E2E** — whole product against real systems. CI only, never in pre-commit/pre-push.

## Test-structure vocabulary

- **FIRST**: Fast, Independent, Repeatable, Self-validating, Timely.
- **AAA**: Arrange-Act-Assert. Or its BDD twin Given-When-Then.
- **Test-doubles** (Meszaros): Dummy, Stub, Spy, Mock, Fake. Default for boundaries is a **fake**,
  not a mock.

## DRY vs DAMP

Production code is DRY; test code is **DAMP — Descriptive And Meaningful Phrases**. Apply DRY only
to _test mechanics_ (fixture builders, custom matchers). Keep _scenarios_ visible — the
arrange/act/assert body should read top-to-bottom without chasing helpers.

## Detecting "testing the third-party library"

Five heuristics — language-agnostic, central to the lint rules:

1. **Assertion subject is a non-project import.** LHS of the assertion is a symbol imported from a
   third-party module. The test is teaching the reader the library, not the project.
2. **The mock is the only subject.** Test fully stubs an external dependency and the assertions only
   check the stub's recorded calls. Project code is bypassed.
3. **Doc-mirroring.** Test body reads as the library's published usage example with minor renaming.
4. **Mocking your own pure function.** A project-internal pure function appears as a mock target;
   defeats the entire reason for the function being pure.
5. **The import-removal test.** Mentally delete the third-party import the test sets up. If the test
   still passes, it isn't testing the boundary — it's testing the mock.

These heuristics drive the critical-severity lint rules `TR-001` through `TR-005` in
`anti-patterns.md`.

## What to mock, what not to mock

| Subject                     | Default                                                |
| --------------------------- | ------------------------------------------------------ |
| Filesystem                  | Real, sandboxed in tempdir. Don't mock.                |
| Network HTTP                | Fake at the adapter trait, or use a recording library. |
| Clock                       | Inject a `Clock` trait.                                |
| Subprocess (wrapped CLIs)   | Fake at the `Process` adapter trait.                   |
| Database                    | sqlite tempfile in-process.                            |
| Random                      | Inject a seeded RNG.                                   |
| Environment variables       | `env_clear` + curated env.                             |
| Third-party library symbols | Never assert on them directly.                         |

## Coverage philosophy

Coverage is a floor against accidental regressions, not a goal. **Pair coverage with mutation
testing** — a test suite with high coverage and low mutation score is the symptom of the
third-party-library anti-pattern.

## Anti-patterns (condensed)

- Shared temp dirs across tests.
- Global env / cwd mutation.
- One monolithic integration test for every subcommand.
- Mocking the filesystem.
- Mocking your own pure functions.
- Letting `--help` text drift untested.
- Sleeping in tests.
- Over-DRY scenarios.
- Asserting on third-party library symbols.
- Mock-only assertions.
- Doc-mirroring tests.
- Chasing line coverage with tests that don't kill mutants.
