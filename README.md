# docs-n-notes

Personal notes and documentations for tech and a bunch of unrelated topics.

## Structure

```
tech/                # tech knowledge base
├── programming/     # language-agnostic: paradigms, patterns, principles, architecture,
│                    # best-practices, design-decisions, dsa, research
├── languages/       # specific languages: rust/, python/, javascript/ (incl. ts, svelte, node), r/, …
├── platforms/       # specific runtimes/ecosystems: solana/, icp/, webdev/
├── infra/           # ops & infrastructure: aws/, gcp/, devops/, containers/, networking/,
│                    # server-vps/, web-server/, filesync/, research/
├── systems/         # OS-level: linux/, shell/, security/ (incl. pass), emails/
├── tools/           # editors, terminals, dev tools: git/, vim-neovim/, tmux, alacritty, …
├── data/            # data-engineering/, dbs-databases/
├── workflows/       # cross-cutting workflows
└── projects/        # project-specific notes

personal/            # life / non-tech
├── health/
└── articles/        # notes from articles/videos
```

### Where to add new content

- Cross-cutting idea (works for any language/stack) → `tech/programming/`
- "In Rust/Python/JS, you do X" → `tech/languages/<lang>/`
- Specific ecosystem (Solana program, ICP canister, browser DOM) → `tech/platforms/<name>/`
- Provisioning/deploying machines/networks → `tech/infra/`
- Lives on the box (kernel, shell, mail, encryption) → `tech/systems/`
- Dev tooling you run on your laptop → `tech/tools/`
- Schema/storage → `tech/data/`
- Research notes → `<bucket>/research/` matching the topic

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
