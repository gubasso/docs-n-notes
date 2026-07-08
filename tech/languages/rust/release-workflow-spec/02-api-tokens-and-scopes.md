# 02 — API tokens and scopes

crates.io API tokens carry **scopes**: an _endpoint_ scope (what actions the token may perform) and
an optional _crate_ scope (which crates it may act on). Scoped tokens exist so you can hand out
least-privilege, per-crate credentials instead of one all-powerful key. Create tokens at
<https://crates.io/settings/tokens>.

## Endpoint scopes

| Scope            | Grants                                                                            |
| ---------------- | --------------------------------------------------------------------------------- |
| `publish-new`    | Publish a **brand-new** crate (first upload creates it).                          |
| `publish-update` | Publish **new versions** of a crate you already own.                              |
| `yank`           | Yank / unyank published versions.                                                 |
| `change-owners`  | Add or remove crate owners.                                                       |
| `legacy`         | Everything except creating tokens. **Avoid** — this is the old unscoped behavior. |

## Crate scopes

A crate scope restricts the token to named crates:

- **Exact name** — `my-crate` limits the token to that one crate.
- **Single trailing glob** — `my-crate*` matches any present or future crate you own whose name
  starts with `my-crate`. Only one trailing `*` is allowed.
- A crate scope grants access to matching crates _the user owns_, present and future — so an exact
  scope on a not-yet-published name still works for the first publish that creates it.

## Best practices

- **One narrow token per crate**, not a single "manage everything" key. A single broad token that
  can publish, yank, and change owners across all your crates is exactly the blast radius that
  scopes were introduced to eliminate.
- **Least privilege by action.** For a first publish, `publish-new` only. For a crate whose releases
  are automated, you usually need _no_ long-lived token at all — see
  [03 — Trusted Publishing](03-trusted-publishing-oidc.md).
- **Short expiration.** A bootstrap token needs to live only long enough for one publish. Prefer the
  shortest expiry offered over "no expiration".
- **Revoke when done.** Once CI publishes over OIDC, the manual token has no job — delete it.
- **Copy once.** crates.io shows the token value a single time; `cargo login` stores it in
  `$CARGO_HOME/credentials.toml`. Never commit it, never echo it, and never build an auth check that
  inspects its value (see [06 — Helper scripts](06-helper-scripts.md)).

## Token vs OIDC — when to use which

| Situation                        | Use                                                                                    |
| -------------------------------- | -------------------------------------------------------------------------------------- |
| First-ever publish of a crate    | Long-lived token, `publish-new`, exact crate scope, short expiry, revoked after.       |
| Automated CI releases            | **No stored token** — Trusted Publishing / OIDC ([03](03-trusted-publishing-oidc.md)). |
| Local publish when CI is down    | Long-lived token via `cargo login`, `publish-update`, exact crate scope.               |
| CI without OIDC (rare / mirrors) | `CARGO_REGISTRY_TOKEN` secret, `publish-update`, exact crate scope.                    |

## Reference

- [Improved API tokens for crates.io — Rust Blog](https://blog.rust-lang.org/2023/06/23/improved-api-tokens-for-crates-io/)
- [RFC 2947 — crates.io token scopes](https://rust-lang.github.io/rfcs/2947-crates-io-token-scopes.html)
