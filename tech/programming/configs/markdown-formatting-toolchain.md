# Markdown Formatting Toolchain — dprint + markdownlint

Canonical rationale for the markdown pre-commit stack used in the dotfiles
`_templates/pre-commit/markdown/` template and in this repo's own root config. This note exists
because `dprint.json` is validated by the `pretty-format-json` hook as **strict JSON** (no comments
allowed), so the options/rationale cannot live inline in that file. See also
[markdown-review.md](./markdown-review.md).

## Division of labor

- **dprint** is the canonical CommonMark/GFM **formatter** (autofix): whitespace, list markers,
  emphasis, table column padding, fenced-code spacing, and code _inside_ fenced blocks (via dprint's
  other language plugins).
- **markdownlint-cli2** is a **linter** that gates on what dprint can't normalize (semantic style,
  link integrity, heading hierarchy) **and** autofixes the one thing dprint cannot do: ordered-list
  renumbering (MD029).

### markdownlint is NOT a formatter

A linter with surgical per-span autofixes cannot replace a formatter. markdownlint **cannot**:

- reflow / unwrap prose paragraphs (no `textWrap`/`proseWrap` equivalent),
- normalize GFM table column padding/alignment (its table rules only _report_),
- format code inside fenced blocks.

So dprint stays. Full consolidation to a single tool is not viable. Ref:
<https://github.com/DavidAnson/markdownlint/blob/main/doc/Prettier.md>

## dprint: prose wrapping (`textWrap`)

`dprint.json` → `markdown.textWrap` controls paragraph wrapping:

| Value      | Behavior                                                  |
| ---------- | --------------------------------------------------------- |
| `always`   | Reflow every paragraph to `lineWidth` (hard-wraps prose). |
| `maintain` | Keep line breaks exactly as written. **CHOSEN.**          |
| `never`    | Collapse a wrapped paragraph toward a single line.        |

**Chosen: `maintain`.** Prose is authored one-paragraph-per-line by hand and arrives pre-wrapped
from LLM tools (Claude Code, Codex); `maintain` leaves both untouched. Caveats:

- `maintain` does **not** retroactively unwrap already-wrapped text — it only stops new wrapping.
- `never` _would_ actively collapse wraps, but it can also merge intentional line breaks, so it was
  not chosen.

`lineWidth` (100) is only consulted when wrapping; it is kept because it still governs table layout
and other plugins.

dprint does **not** renumber ordered lists (`1.`/`1.`/`1.` stays as written) under any `textWrap`
value — that is markdownlint's MD029 job. Ref: <https://dprint.dev/plugins/markdown/config/>

## markdownlint: ordered-list renumbering (MD029)

`MD029.style` enforces ordered-list numbering:

| Style     | Enforces              |
| --------- | --------------------- |
| `one`     | `1. 1. 1.`            |
| `ordered` | `1. 2. 3.` **CHOSEN** |
| `zero`    | `0. 0. 0.`            |

**Chosen: `ordered`** — incrementing numbers read naturally and are easy to reference. MD029 carries
`fixInfo`, so markdownlint can **autofix** the renumbering, but only when fix mode is on. Ref:
<https://github.com/DavidAnson/markdownlint/blob/main/doc/md029.md>

### Isolating fix-mode to MD029

`"fix": true` in `.markdownlint-cli2.jsonc` enables autofix, but it is **global** — there is no
per-rule fix toggle, and it fixes every enabled fixable rule. To keep fix-mode from fighting dprint
or silently editing content, **every other fixable rule is disabled** in the config, leaving MD029
as the only rule fix-mode can act on. Non-fixable rules are unaffected and still gate (report-only).

If a future markdownlint version makes a new rule fixable, add it to the disabled block to preserve
isolation.

## Single source of truth: use `.markdownlint-cli2.jsonc` only

Do **not** keep both a `.markdownlint-cli2.jsonc` and a `.markdownlint.{yaml,json}`. When both exist
in the same directory, the `.markdownlint.*` rules win and silently override the `config` block of
the `.jsonc` (observed: a `.markdownlint.yaml` with `MD029: false` defeated the `.jsonc`'s
`MD029: ordered`). Standardize on `.markdownlint-cli2.jsonc` because:

- it is the only file that can hold both the rule `config` **and** cli2-only options (`fix`,
  `customRules`, `ignores`); `.markdownlint.*` holds rules only,
- it supports JSONC comments (so rationale can live inline), and
- `markdownlint-cli2` also reads it in VS Code, keeping editor + pre-commit in sync.

Ref: <https://github.com/DavidAnson/markdownlint-cli2#configuration>

## References

- markdownlint rules: <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md>
- MD029: <https://github.com/DavidAnson/markdownlint/blob/main/doc/md029.md>
- linter ≠ formatter: <https://github.com/DavidAnson/markdownlint/blob/main/doc/Prettier.md>
- dprint markdown config: <https://dprint.dev/plugins/markdown/config/>
- Prettier `proseWrap` (comparison): <https://prettier.io/docs/options>
- Semantic Line Breaks (the wrapping debate): <https://sembr.org/>
