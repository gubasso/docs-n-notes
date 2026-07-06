---
digest-of: tech/programming/release-workflow
last-synced: 2026-07-06
source-files:
  - README.md
  - 00-branch-model.md
  - 01-release-automation.md
  - 02-trusted-publishing-oidc.md
  - 03-tooling-by-ecosystem.md
token-estimate: 1700
---

# AGENTS

## Scope

Language-agnostic general principles for development + release workflow: the `develop`/`master`
branch model, the automated release-PR pattern, Trusted Publishing / OIDC, and CI-driven promotion.
The source of truth that the per-language `tech/languages/*/release-workflow-spec/` bindings
implement (rust + bash full; python + JS stubs). Mirrors the `cli-design/` → `cli-spec/` pattern.

## Key Points

- **Branch model:** `develop` integrates (feature branches merge via reviewed PRs, green CI) and is
  the release trigger; `master` mirrors the latest published release and is **written only by CI**
  (`main` is the common alias). Promotion is fast-forward-only onto the release tag, guarded by an
  ancestry check (the tag must be reachable from `develop`).
- **Release-PR invariant:** change intent (Conventional Commits _or_ changeset files) → a bot opens
  and maintains a release PR (version bump + changelog) → **merging it is the release gate** → tag +
  registry publish → CI promotes `master`. SemVer + Keep-a-Changelog; published versions are
  immutable (fix forward, never overwrite).
- **Trusted Publishing / OIDC** is the cross-ecosystem auth convergence (crates.io, PyPI, npm):
  short-lived keyless tokens minted at job time, matched on repo + workflow filename (+ environment)
  and **branch-agnostic**. The first publish is manual (TP attaches to an existing package). Enable
  enforcement (e.g. crates.io "require trusted publishing") once OIDC works.
- **Tooling:** rust=release-plz, python=release-please / python-semantic-release, JS=Changesets,
  cross-language=release-please (tags only, bring your own publish), Go=GoReleaser (no registry —
  tagging is publishing).
- **Promotion pattern (official):** promote `master` onto the release **tag**, not a SHA. When a bot
  creates the tag with `GITHUB_TOKEN` (no workflow retrigger), run promote as a `needs:` job in the
  same run reading the tool's output; when a human pushes the tag, use a separate `on: push: tags`
  release-promote workflow.

## Source Map

| Topic                                            | File                            |
| ------------------------------------------------ | ------------------------------- |
| Index, TL;DR defaults, binding links             | `README.md`                     |
| Branch model, promotion, who-writes-master       | `00-branch-model.md`            |
| Release-PR invariant, SemVer, changelog          | `01-release-automation.md`      |
| Trusted Publishing / OIDC, enforcement, fallback | `02-trusted-publishing-oidc.md` |
| Per-ecosystem tools + the promotion wiring       | `03-tooling-by-ecosystem.md`    |

## Maintenance Notes

- Bindings live at `tech/languages/{rust,bash,python,javascript}/release-workflow-spec/`, each with
  its own digest (or, for stubs, covered by the parent language digest). Platform enforcement
  runbooks/assets live at `tech/tools/git/branch-protection/`; git mechanics at
  `tech/tools/git/{rebase-workflow.md,feature-lifecycle.md}`.
- External auth model is perishable: re-verify crates.io / PyPI / npm Trusted Publishing status and
  the release-plz / release-please / Changesets behavior against upstream on a cadence.
- Standardize on `develop`/`master` — flag and fix any reintroduced `main`/`devel` in the bindings.
