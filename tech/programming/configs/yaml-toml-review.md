# YAML / TOML — Review Guide

## When to load

`.yaml`/`.yml`/`.toml` files. Lockfiles excluded.

## YAML

### Common bugs

- Booleans accidentally parsed as strings or vice versa (`yes`/`no`/`on`/`off` parsed as booleans in
  YAML 1.1; `true`/`false` only in YAML 1.2) → `[important]` "Pin the parser version or quote
  intentional strings."
- Indentation inconsistency (mixing 2-space and 4-space) → `[important]`.
- Unquoted version strings like `0.10` → parses as float `0.1` → `[blocking]`.
- Tabs instead of spaces → `[blocking]` (most parsers reject).
- Anchors and merge keys (`<<: *defaults`) without explicit documentation → `[suggestion]`.

### Schema

- Required field missing → `[blocking]`.
- Unknown field that should be flagged by a schema → `[important]` if schema exists.
- Secrets in YAML committed to git → `[blocking]`.

### Multi-doc files

- `---` separator missing between documents → `[blocking]`.
- Multi-line strings using `|` vs `>` confusion → `[important]` (literal vs folded).

## TOML

### Common bugs

- `[section.subsection]` table-of-tables vs array-of-tables (`[[...]]`) confusion → `[blocking]`.
- Inline table mixing with multi-line in the same key → `[important]`.
- Missing comma in inline table or array → `[blocking]`.
- Datetime without timezone where one is expected → `[important]`.

## Both

- File present but unused (orphan config) → `[suggestion]`.
- Two configs with overlapping responsibility (e.g., dependencies in both `package.json` and
  `pyproject.toml`) → `[important]`.

## See also

- YAML 1.2 spec: <https://yaml.org/spec/1.2.2/>.
- TOML 1.0 spec: <https://toml.io/en/v1.0.0>.
