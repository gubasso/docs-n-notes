# 07 — SemVer, yank, and rollback

crates.io versions are **immutable**: once published, a version can never be overwritten or deleted,
only _yanked_. That makes version discipline and a clear recovery path essential.

## SemVer policy

Crates follow [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`.

- **PATCH** — backward-compatible bug fixes.
- **MINOR** — backward-compatible additions to the public API.
- **MAJOR** — breaking changes to the public API.
- `0.x` versions treat the **minor** as the breaking position (`0.y` bumps may break), per Cargo's
  compatibility rules.

For a **library crate**, the public API is a contract; use
[`cargo-semver-checks`](https://github.com/obi1kenobi/cargo-semver-checks) to catch accidental
breakage:

```bash
cargo semver-checks check-release
```

This runs natively inside [release-plz](05-release-plz-automation.md) when `semver_check = true`, so
an incompatible change forces a major bump instead of slipping out as a minor/patch.

A **binary-only crate** exposes no public API, so `cargo-semver-checks` does not apply — but its
releases still follow SemVer for users pinning versions.

## Yank — the only "undo"

Yanking prevents _new_ dependents from selecting a version; it does not delete it, and existing
`Cargo.lock` files that already pin it keep working.

```bash
cargo yank --version 1.2.3          # stop new selections of 1.2.3
cargo yank --version 1.2.3 --undo   # reverse a yank
```

Yank when a version is broken, insecure, or published in error. It is a speed-bump, not a recall —
anything already depending on it is unaffected.

## Rollback = fix forward

Because you cannot edit or delete a published version, "rolling back" means **publishing a new
one**:

1. Fix the problem on the default branch.
1. Cut a new PATCH version (let [release-plz](05-release-plz-automation.md) do it, or bump
   manually).
1. Publish the new version.
1. Optionally `cargo yank` the bad version so new dependents skip it.

Never try to re-publish the same version number — crates.io rejects it.

## Reference

- [The Cargo Book — SemVer compatibility](https://doc.rust-lang.org/cargo/reference/semver.html)
- [The Cargo Book — `cargo yank`](https://doc.rust-lang.org/cargo/commands/cargo-yank.html)
- [`cargo-semver-checks`](https://github.com/obi1kenobi/cargo-semver-checks)
