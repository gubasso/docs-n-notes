# docs-n-notes

Personal notes and documentations for tech and a bunch of unrelated topics.

> **Starting a new project?** →
> [tech/programming/project-bootstrap/](tech/programming/project-bootstrap/README.md) — the
> once-per-project setup recipe (general → language → implementation-kind), with a Rust reference
> binding.
>
> **Shipping a Rust crate, fast?** →
> [tech/languages/rust/cookbook/](tech/languages/rust/cookbook/README.md) — one-file TLDR runbook:
> scaffold → gates → branch security → CI → release/publish.

## Structure

`tech/` is the tech knowledge base; `personal/` holds life / non-tech notes. Each top-level area
reserves a domain — put new content where its domain matches (the directories themselves are the
source of truth for what currently exists):

- **`tech/programming/`** — language-agnostic software engineering: paradigms, patterns, principles,
  architecture, best-practices, design-decisions, dsa. _Any cross-cutting idea that holds for any
  language or stack._
- **`tech/languages/`** — language-specific guidance, one subdirectory per language. _"In
  Rust/Python/JS, you do X."_
- **`tech/platforms/`** — specific runtimes/ecosystems. _A Solana program, an ICP canister, the
  browser DOM._
- **`tech/infra/`** — provisioning and operating machines and networks. _Cloud, devops, containers,
  networking, servers._
- **`tech/systems/`** — what lives on the box. _Kernel/Linux, shell, mail, encryption/security._
- **`tech/tools/`** — dev tooling you run on your laptop. _Git, Nix, editors, terminals._
- **`tech/data/`** — schema and storage. _Data engineering, databases._
- **`tech/workflows/`** — cross-cutting workflows that span the buckets above.
- **`tech/projects/`** — notes scoped to one specific project.
- **`personal/`** — life / non-tech (health, notes from articles and videos).

Research notes live in a `research/` subdirectory of whichever bucket matches the topic.

## Web Resources (Utils)

- [Emoji Cheat Sheet](https://www.webfx.com/tools/emoji-cheat-sheet/)

## Markdown notes

### Github diagrams

Mermaid, geoJSON and topoJSON, and ASCII STL.

## ASCII Art Headers

Config file headers use toilet for ASCII art:

```bash
toilet -f future -F border "Fish config"
```

## License

This repository is dual-licensed to reflect its mix of prose and code:

- **Documentation and notes** (prose, Markdown, generated `AGENTS.md` digests) are licensed under
  [CC-BY-4.0](LICENSE).
- **Scripts, configuration, and other code** are licensed under the [MIT License](LICENSE-CODE).

Copyright (c) 2026 Gustavo Basso.
