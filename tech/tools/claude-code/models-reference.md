# Claude Code Models Reference

> Last updated: 2026-05-27
>
> Review and refresh this document whenever Anthropic releases a new model family, retires a model,
> or changes pricing. Check at least quarterly.

## Available Models

Model aliases (`opus`, `sonnet`, `haiku`) auto-resolve to the latest model in each tier and update
when Anthropic releases new versions. Pin with full model IDs only when reproducibility matters.

| Model             | Alias    | Model ID                    | Context | Max Output | Input $/MTok | Output $/MTok |
| ----------------- | -------- | --------------------------- | ------- | ---------- | ------------ | ------------- |
| Claude Opus 4.7   | `opus`   | `claude-opus-4-7`           | 1M      | 128k       | $5           | $25           |
| Claude Sonnet 4.6 | `sonnet` | `claude-sonnet-4-6`         | 1M      | 64k        | $3           | $15           |
| Claude Haiku 4.5  | `haiku`  | `claude-haiku-4-5-20251001` | 200k    | 64k        | $1           | $5            |

### Cost Ratios

- Opus is **5x** Haiku (input and output)
- Sonnet is **3x** Haiku (input and output)
- Effort level compounds on top of model cost (more thinking tokens = higher output spend)

### Additional Pricing

- **Batch API**: 50% discount on all token pricing
- **Prompt caching (5-min write)**: 1.25x base input; **cache hit**: 0.1x base input
- **Prompt caching (1-hour write)**: 2x base input; **cache hit**: 0.1x base input

### Tokenizer Note (Opus 4.7)

Opus 4.7 uses a new tokenizer that may generate up to 35% more tokens for the same text. Per-token
price is unchanged, but effective cost per request can be higher than Opus 4.6 for identical
prompts.

## Effort Levels

Effort controls how much adaptive thinking the model does per turn. It is a behavioral signal, not a
strict token budget.

| Level  | Default For                  | Use Case                                                    |
| ------ | ---------------------------- | ----------------------------------------------------------- |
| low    | —                            | Latency-sensitive, high-volume, simple tasks                |
| medium | —                            | Cost-sensitive work that can trade some intelligence        |
| high   | Opus (our config)            | Intelligence-sensitive work; good cost/quality balance      |
| xhigh  | Opus 4.7 (Anthropic default) | Deep reasoning; recommended by Anthropic for agentic/coding |
| max    | —                            | Deepest reasoning; session-only, not persistent in settings |

**Haiku 4.5 does NOT support effort levels.** It uses fixed inference. Setting `effort:` on a Haiku
skill is meaningless — omit it.

**Sonnet 4.6** supports: low, medium, high, xhigh, max.

### Setting Effort

- **Skill frontmatter**: `effort: medium` (overrides session level)
- **Settings file**: `effortLevel` in `settings.json` (accepts low, medium, high, xhigh; not max)
- **Session**: `/effort [level]` or `/effort auto` to reset to model default
- **Environment**: `CLAUDE_CODE_EFFORT_LEVEL` overrides all other methods
- **Keyword**: Include `ultrathink` in a prompt for deeper reasoning on a single turn

## Skill Frontmatter

Skills accept `model:` and `effort:` in their YAML frontmatter:

```yaml
---
name: my-skill
description: What this skill does
model: haiku
effort: low
---
```

### `model:` Field

Accepted values:

- Aliases: `haiku`, `sonnet`, `opus` (resolve to latest per provider)
- Full model IDs: `claude-opus-4-7`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`
- Omit to inherit the session model (default behavior)

For skills with `disable-model-invocation: true`, the harness does not enforce `model:` frontmatter.
The field serves as documentation for tooling and authors. Add a visible prose note in the skill
body to state the intended tier.

### `effort:` Field

Accepted values: `low`, `medium`, `high`, `xhigh`, `max`.

Frontmatter effort overrides session level but NOT the `CLAUDE_CODE_EFFORT_LEVEL` environment
variable.

## Three-Tier Skill Assignment

This dotfiles repo classifies skills into three tiers. Only skills that downgrade from the default
get explicit frontmatter — the powerful default (opus/high) is implicit.

| Tier       | Model  | Effort | Criteria                                                                       |
| ---------- | ------ | ------ | ------------------------------------------------------------------------------ |
| Mechanical | haiku  | —      | Deterministic: file ops, classification, dispatch, JSON. Haiku ignores effort. |
| Procedural | sonnet | medium | Structured procedures, teaching, moderate judgment                             |
| Default    | (opus) | (high) | Implicit. Everything requiring deep reasoning. No frontmatter needed.          |

### Skill Inventory

**Haiku** (model: haiku): `commit`, `project-classification`

**Default with effort: medium** (inherits session Opus at reduced effort — workaround for Sonnet 1M
routing bug, see [Known Issues](#known-issues)): `ask`, `ast-grep`, `claudemd`, `project-preflight`

**Default (opus/high, no frontmatter)**: `plan-reviewer`, `plan-writer`, `pre-commit`, `prex`,
`refactor-migration-plan`, `review-code-deep`, `review-findings`, `review-loop`, `skill-builder`,
`suckless-patcher`, `test-review`, `tsk-impl`, `tsk-new`

## Benchmarks

| Benchmark          | Opus 4.7 | Sonnet 4.6 | Haiku 4.5 |
| ------------------ | -------- | ---------- | --------- |
| SWE-bench Verified | 87.6%    | 79.6%      | —         |
| GPQA Diamond       | 94.2%    | —          | —         |
| Visual Acuity      | 98.5%    | —          | —         |

## Knowledge Cutoffs

| Model      | Reliable Knowledge | Training Cutoff |
| ---------- | ------------------ | --------------- |
| Opus 4.7   | Jan 2026           | Jan 2026        |
| Sonnet 4.6 | Aug 2025           | Jan 2026        |
| Haiku 4.5  | Feb 2025           | Jul 2025        |

## Known Issues

### Sonnet 1M context routing bug

> **Status:** open as of 2026-05-27. **Workaround applied:** removed `model: sonnet` from enforced
> skills; they inherit session Opus with `effort: medium`.

Claude Code routes ALL Sonnet 4.6 requests to the 1M billing tier regardless of which alias is used
(`sonnet` vs `sonnet[1m]`). The client sets `effectiveWindow=980000` for Sonnet by default, pushing
every request into the long-context tier — even on fresh sessions with ~46K tokens.

On Max/Team/Enterprise plans, Opus 1M is included but Sonnet 1M requires usage credits. This makes
`model: sonnet` in skill frontmatter unusable without paying API rates.

`CLAUDE_CODE_DISABLE_1M_CONTEXT=1` is not viable as a workaround — it removes ALL 1M variants
globally, including Opus.

**Upstream issues:**

- [#62314](https://github.com/anthropics/claude-code/issues/62314) — Sonnet routes every request to
  long-context tier (primary, still open)
- [#45847](https://github.com/anthropics/claude-code/issues/45847) — skill `model:` frontmatter
  inherits 1M from parent session (closed as dup of #34296)
- [#61692](https://github.com/anthropics/claude-code/issues/61692) — Sonnet blocked by false "usage
  credits required" error
- [#34296](https://github.com/anthropics/claude-code/issues/34296) — root duplicate

**Restore action:** when upstream fixes Sonnet to correctly use 200K tier for the `sonnet` alias,
re-add `model: sonnet` and `effort: medium` to `ask`, `ast-grep`, `claudemd`, `project-preflight`.
Also tracked in `_docs/TRACKING.md` in the dotfiles repo.

## Sources

- <https://platform.claude.com/docs/en/about-claude/models/overview>
- <https://platform.claude.com/docs/en/about-claude/pricing>
- <https://code.claude.com/docs/en/model-config>
- <https://platform.claude.com/docs/en/build-with-claude/effort>
- <https://www.anthropic.com/news/claude-opus-4-7>
