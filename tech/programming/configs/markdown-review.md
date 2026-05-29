# Markdown — Review Guide

## When to load

`.md`/`.markdown`/`.mdx` files.

## Top review heuristics

### Fenced code blocks

- Code block without language specifier → `[blocking]` per markdownlint MD040; use a language tag
  (`text` if none applies). Confirms tooling alignment with this dotfiles' rule.
- Mixed language fences in a tutorial without callouts → `[suggestion]`.

### Headings

- `# H1` more than once per document → `[important]` (most processors expect one).
- Heading levels skipped (`# H1` then `### H3`) → `[important]` (accessibility + ToC).
- Trailing punctuation on heading → `[nit]`.

### Links

- Bare URL pasted without angle brackets / autolink → `[nit]` "Use `<https://...>` or
  `[text](url)`."
- Relative link broken by repo restructure → `[blocking]`.
- Link text "click here" / "this" → `[important]` "Accessibility; link text should be descriptive."

### Tables

- Table column count mismatch between header and rows → `[blocking]`.
- Pipes inside cell content not escaped → `[blocking]`.

### Lists

- Mixed ordered/unordered styles → `[nit]`.
- Items indented inconsistently → markdownlint catches; mention only if linter not configured.

### Front matter

- YAML front matter missing required fields per project convention → `[important]`.
- Trailing colon style in YAML inconsistent → `[nit]`.

### Common bugs

- Backtick-fenced code expected but used 4-space indent (mixes with surrounding lists) →
  `[important]`.
- `<details>`/`<summary>` HTML missing blank lines around it → `[important]` (renderer
  inconsistencies).

## See also

- Canonical: <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md>.
- Per-project lint config: `.markdownlint-cli2.jsonc` (single SoT) + pre-commit
  `markdownlint-cli2` + dprint. Toolchain rationale and options:
  [markdown-formatting-toolchain.md](./markdown-formatting-toolchain.md).
