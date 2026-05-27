---
digest-of: tech/languages/javascript
last-synced: 2026-05-27
source-files:
  - code-review-guide.md
  - typescript-code-review-guide.md
  - react-code-review-guide.md
  - svelte-code-review-guide.md
  - javascript-js.md
  - typescript.md
  - node-npm.md
  - svelte.md
token-estimate: 500
---

# AGENTS

## Scope

JavaScript/TypeScript language notes, including code-review guides for JS, TS, React, and Svelte,
plus general language and framework references.

## Key Points

- **Code review guide (JS)**: JavaScript-specific review heuristics loaded by `review-code-deep`
  when `.js`/`.mjs`/`.cjs` files are in the diff.
- **TypeScript review guide**: TS-specific heuristics (strict mode, type narrowing, any/unknown,
  generics).
- **React review guide**: React-specific heuristics (hooks rules, key prop, effect dependencies,
  memo discipline).
- **Svelte review guide**: Svelte-specific heuristics (reactivity, stores, lifecycle,
  accessibility).
- **General JS notes** (`javascript-js.md`): Utility patterns and snippets.
- **TypeScript notes** (`typescript.md`): TypeScript-specific patterns and references.
- **Node/npm** (`node-npm.md`): Node.js and npm package management notes.
- **Svelte** (`svelte.md`): Svelte framework patterns and references.

## Source Map

| Topic                    | File                              |
| ------------------------ | --------------------------------- |
| JS review heuristics     | `code-review-guide.md`            |
| TS review heuristics     | `typescript-code-review-guide.md` |
| React review heuristics  | `react-code-review-guide.md`      |
| Svelte review heuristics | `svelte-code-review-guide.md`     |
| General JS patterns      | `javascript-js.md`                |
| TypeScript patterns      | `typescript.md`                   |
| Node.js / npm            | `node-npm.md`                     |
| Svelte framework         | `svelte.md`                       |

## Maintenance Notes

- Review guides are loaded on demand by the review-code-deep skill based on file extensions in the
  diff.
- No CLI-spec subdirectory exists for JavaScript; CLI patterns use the general `cli-design/` canon.
