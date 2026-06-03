# Codex / OpenAI Models — Pricing, Reasoning Effort & Benchmarks

A maintained reference for OpenAI models usable in **Codex** (CLI + agent), their pricing/quota
metering, reasoning-effort behavior, and coding benchmarks. Use it to ground cost/quality decisions
(e.g. the `codex-session` profile strategy in
[`codex-conventions.md`](./codex-conventions.md#profile-strategy)) and as a starting point for
future research.

- **Last verified:** 2026-06-02
- **Source policy:** **PRIMARY** = official OpenAI properties (`developers.openai.com`,
  `openai.com`, `help.openai.com`). **SECONDARY** = blogs / aggregators / leaderboards. Every claim
  below is tagged; treat SECONDARY figures as directional and re-check against PRIMARY before
  relying on exact numbers.
- **How to keep this updated:** re-run a web sweep of the PRIMARY URLs in [Sources](#sources),
  update the tables + the "Last verified" date, and append a line to [Changelog](#changelog). Model
  IDs, prices, and rate cards change often (the April 2026 Codex pricing shift is a recent example).

> Caveat: prices and the ChatGPT-plan credit rate card move frequently. The API per-token table is
> PRIMARY and most stable; the ChatGPT credit rate card below is SECONDARY (the help-center page
> returned HTTP 403 to automated fetch) — confirm in-app or on the help center before quoting it.

---

## TL;DR — the levers that matter

1. **Reasoning effort is the biggest cost lever.** Reasoning tokens bill at the **output** rate (the
   most expensive line), and higher effort multiplies token count several-fold (community estimate:
   `medium`→`xhigh` ≈ 8–15×). Drop effort before downgrading the model when you need savings.
2. **Model choice is the second lever.** Under **ChatGPT-subscription auth** the coding workhorse is
   **`gpt-5.4`** ("strong everyday coding", ~½ the per-token credit cost of `gpt-5.5`) —
   `gpt-5.3-codex` is coding-specialized and ~85% SWE-bench but **API-key-only** (it 400s on ChatGPT
   accounts), so it is not an option on subscription. See
   [Auth & subscription availability](#auth--subscription-availability).
3. **Caching only discounts input** (the cheapest line), so it is the _smallest_ lever for
   output-heavy agentic coding, though still worth structuring prompts for.
4. **Benchmark gaps ≤ ~3 pts are run-to-run noise**, not real quality differences. The real cliff is
   below the ~85–88 cluster (e.g. `gpt-5.2` ~80, mini models well below).

---

## 1. Model catalog (Codex-relevant)

From the Codex models page and per-model API pages (PRIMARY), as of 2026-06-02:

| Model ID              | Positioning                                                  | Context                | Max output | Reasoning levels                               | Cutoff            | Tier                |
| --------------------- | ------------------------------------------------------------ | ---------------------- | ---------- | ---------------------------------------------- | ----------------- | ------------------- |
| `gpt-5.5`             | Newest **flagship** (coding, computer-use, research)         | 1,050,000              | 128,000    | none, low, **medium\***, high, xhigh           | 2025-12-01        | PRIMARY             |
| `gpt-5.4`             | Flagship-tier, "more affordable"                             | 1,050,000              | 128,000    | **none\***, low, medium, high, xhigh           | 2025-08-31        | PRIMARY             |
| `gpt-5.4-mini`        | Fast / low-cost, subagents                                   | ~400k (not on primary) | —          | low, medium, high (**no xhigh** — SECONDARY)   | 2025-08-31 (inf.) | PRIMARY id + price  |
| `gpt-5.4-nano`        | Cheapest cost-tier                                           | not confirmed          | —          | unconfirmed                                    | —                 | API-only (see note) |
| `gpt-5.3-codex`       | **Coding-specialized** ("most capable agentic coding model") | 400,000                | 128,000    | low, medium, high, xhigh (**no minimal/none**) | 2025-08-31        | PRIMARY             |
| `gpt-5.3-codex-spark` | Text-only **research preview**, near-instant                 | —                      | —          | —                                              | —                 | PRIMARY             |
| `gpt-5.2`             | Previous general-purpose ("Alternative")                     | —                      | —          | —                                              | —                 | PRIMARY             |
| `gpt-5.2-codex`       | Coding; recommended for API-key where 5.5 unavailable        | —                      | —          | low/med/high/xhigh (rate-card implies)         | —                 | SECONDARY           |

`*` = default reasoning effort for that model.

**Notes & corrections:**

- `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.3-codex` — all **confirmed** model IDs (PRIMARY).
- `gpt-5.4-nano` — has API **pricing** (PRIMARY) but is **not listed as a selectable Codex model**;
  treat as API-only.
- Legacy `*-codex` still billable per the API rate card: `gpt-5.2-codex`, `gpt-5.1-codex-max`,
  `gpt-5.1-codex-mini` — **API-key auth only** (see below).
- **Default model:** ChatGPT-authenticated Codex → **`gpt-5.5`** ("for most tasks in Codex, start
  with gpt-5.5", PRIMARY).
- No PRIMARY retirement table was found; `gpt-5.2` is demoted to "Alternative".

### Auth & subscription availability

Model availability differs by **auth mode**, not just by model ID. This is the single most important
fact for our `codex-session` profiles (we authenticate via **ChatGPT subscription, never API key**).

- **ChatGPT-subscription auth (our mode).** The Codex CLI v0.135.0 "Select Model and Effort" picker
  exposes exactly three models (confirmed live in-app, ChatGPT subscription): **`gpt-5.5`**
  (frontier / complex coding), **`gpt-5.4`** (strong everyday coding), **`gpt-5.4-mini`**
  (small/fast). Legacy general **`gpt-5.2`** is reachable via `-m <model>` / config but not the
  picker. The **entire `-codex` family is unavailable**: selecting `gpt-5.3-codex` (or
  `gpt-5.2-codex`, `gpt-5.3-codex-spark`, etc.) returns
  `400 invalid_request_error: The '<model>' model is not supported when using Codex with
  a ChatGPT account`.
  Plan tier (Plus / Pro / Team / Business / Enterprise) changes **quotas/rate limits only**, not
  which models are selectable.
- **API-key auth.** The `-codex` family (`gpt-5.3-codex`, `gpt-5.2-codex`, `gpt-5.1-codex-*`) is
  selectable here; SECONDARY reports `gpt-5.5` may not yet be exposed under API-key auth. We do not
  use this mode.

⚠️ Consequence: a profile that pins `gpt-5.3-codex` **fails on our accounts**. All `codex-session`
profiles must pin `gpt-5.5` / `gpt-5.4` / `gpt-5.4-mini`. (Confidence: HIGH for the subscription
picker — verified in the live TUI; MEDIUM for the API-key lineup — SECONDARY.)

## 2. Reasoning effort

- **Accepted values:** `minimal`, `low`, `medium`, `high`, `xhigh` (some models also accept `none`)
  — model-dependent (PRIMARY reasoning guide).
- **Per-model support** (PRIMARY model pages unless noted):
  - `gpt-5.5`: none, low, **medium (default)**, high, xhigh
  - `gpt-5.4`: **none (default)**, low, medium, high, xhigh
  - `gpt-5.3-codex`: low, medium, high, xhigh — **no `minimal`, no `none`**
  - `gpt-5.4-mini`: **no `xhigh`** (SECONDARY)
  - `gpt-5.1-codex-mini` (legacy): medium + high only (SECONDARY)
- **Default by context:** global Codex default = `medium`; **plan mode default = `high`** when
  `plan_mode_reasoning_effort` is unset (SECONDARY, codex KB). Known bug: app automations may run at
  `medium` even when global is `xhigh` (GitHub issue #13536).
- **Relative compute/token cost** (medium = 1×): ~`minimal` 0.1×, `low` 0.3×, `medium` 1×, `high`
  3–5×, `xhigh` 8–15×. ⚠️ **COMMUNITY-MEASURED, not official** — OpenAI publishes no per-level
  multipliers. Efficiency also varies by model (a Codex-Max model beat its predecessor at the _same_
  `medium` effort while using ~30% fewer thinking tokens).

## 3. Usage metering & pricing

### 3a. API pricing — per 1M tokens (PRIMARY)

| Model           | Input | Cached input | Output |
| --------------- | ----- | ------------ | ------ |
| `gpt-5.5`       | $5.00 | $0.50        | $30.00 |
| `gpt-5.4`       | $2.50 | $0.25        | $15.00 |
| `gpt-5.4-mini`  | $0.75 | $0.075       | $4.50  |
| `gpt-5.4-nano`  | $0.20 | $0.02        | $1.25  |
| `gpt-5.3-codex` | $1.75 | $0.175       | $14.00 |

Cached-input discount is uniform: **10% of input price (90% off)**. Output is ~6× input across the
line (≈8× for `gpt-5.3-codex`).

### 3b. ChatGPT-plan Codex metering

- **April 2026 shift:** as of **2026-04-02**, Codex moved from per-message to **API-token-aligned**
  pricing for Plus/Pro/Business (existing Enterprise **2026-04-23**); rate limits reset for paid
  plans **2026-04-28** (PRIMARY codex/pricing).
- **Structure:** usage draws against a **5-hour rolling window** _and_ a **weekly limit**
  simultaneously (a request counts against both). Credits extend usage after included limits.
- **Token→credit rate card** (SECONDARY — citing the official card dated 2026-04-15; the PRIMARY
  help-center page 403'd). **Subscription-selectable models first; `-codex` rows are API-key-only
  and shown only for reference — they are NOT chargeable on ChatGPT-subscription auth (they 400, see
  [Auth & subscription availability](#auth--subscription-availability)):**

  | Model                        | Credits/1M input | Cached | Output | Subscription? |
  | ---------------------------- | ---------------- | ------ | ------ | ------------- |
  | `gpt-5.5`                    | 125              | 12.5   | 750    | ✅ picker     |
  | `gpt-5.4`                    | 62.50            | 6.25   | 375    | ✅ picker     |
  | `gpt-5.4-mini`               | 18.75            | 1.875  | 113    | ✅ picker     |
  | `gpt-5.3-codex` _(ref)_      | 43.75            | 4.375  | 350    | ❌ API-key    |
  | `gpt-5.2-codex` _(ref)_      | 43.75            | 4.375  | 350    | ❌ API-key    |
  | `gpt-5.1-codex-max` _(ref)_  | 31.25            | 3.125  | 250    | ❌ API-key    |
  | `gpt-5.1-codex-mini` _(ref)_ | 6.25             | 0.625  | 50     | ❌ API-key    |

  Implied rate ≈ **1 credit ≈ $0.04**. `gpt-5.5` / `gpt-5.4` credit rates are SECONDARY (research
  sweep, 2026-06-02). On subscription, `gpt-5.5` output ≈ **2×** `gpt-5.4` per token, so model
  choice between them is a real lever — but reasoning effort still dominates (§3c).
- **Reasoning tokens billed as output?** Not stated on the Codex primary pricing pages, but OpenAI's
  reasoning models generally bill internal reasoning tokens at the **output** rate (established with
  o1/o3/o4-mini). High-confidence inference for gpt-5.x → **output is the dominant cost line**.

### 3c. Biggest cost lever

**Reasoning effort > model choice > caching.** Effort multiplies the output-rate token count; model
choice scales the per-token rate (5.5 ≈ 2× 5.4 input/output, ≈3× 5.3-codex output); caching only
discounts input.

### 3d. Measuring actual usage (subscription)

How to observe what a run really consumed — use these to validate the ESTIMATE figures in
[`codex-models-comparison.md`](./codex-models-comparison.md) against reality (all wrapper/event
mechanics below verified live on 2026-06-03):

1. **Live window state — `codex-session account quota`.** Per-account **5-hour** and **weekly** bars
   with `% left` and reset ETAs, fetched from the official wham/usage endpoint (spec:
   `docs/wham-usage-api-spec.md` in the codex-session repo). `--format json` for scripting,
   `--detail` for scoring fields. Distinction: `account health` is the _selection_ view
   (scores/cooldowns for failover); `account quota` is the _measurement_ view.
2. **Exact per-call tokens — the `--json` event stream.** Every `codex-session exec --json` call the
   skills make already persists `*-events.jsonl` in the skill run dir; each agentic turn emits a
   `turn.completed` event with a `usage` object:

   ```json
   {
     "type": "turn.completed",
     "usage": {
       "input_tokens": 904519,
       "cached_input_tokens": 811392,
       "output_tokens": 6535,
       "reasoning_output_tokens": 853
     }
   }
   ```

   Sum a whole call (calls are multi-turn — do not read just the last event):

   ```bash
   jq -s '[.[] | select(.type == "turn.completed").usage]
     | { input: (map(.input_tokens) | add),
         cached: (map(.cached_input_tokens) | add),
         output: (map(.output_tokens) | add),
         reasoning: (map(.reasoning_output_tokens) | add) }' \
     "$RUN_DIR/stage1-events.jsonl"
   ```

   Convert to credits with the §3b rate card:
   `credits ≈ (input − cached)·rate_in + cached·rate_cached + output·rate_out` (rates per 1M tokens;
   `reasoning_output_tokens` is reported as a subset of `output_tokens` — MEDIUM confidence,
   OpenAI's usual usage-object convention). Worked example from a real `gpt-5.5` planning turn (the
   JSON above): `93,127×125 + 811,392×12.5 + 6,535×750` per 1M ≈ **26.7 credits ≈ $1.07** — note how
   caching absorbed ~90% of the input line, leaving output (incl. reasoning) as the lever that
   effort controls.
3. **Per-workflow cost — before/after delta.** Snapshot `account quota --format json` before and
   after a workflow (or sum every `*-events.jsonl` in the run dir) to get the true cost of one prex
   / review-loop cycle on the account that served it. This is the procedure for validating (or
   correcting) the comparison doc's effective-cost column after a profile change.
4. **In-app cross-check (SECONDARY/operational):** the ChatGPT usage settings page (Codex section)
   and the Codex CLI `/status` view show the same 5-hour/weekly state for the logged-in account —
   useful as the official-UI confirmation of what the wham endpoint reports.

## 4. Benchmarks — SWE-bench Verified

| Model           | SWE-bench Verified                       | Notes                                             |
| --------------- | ---------------------------------------- | ------------------------------------------------- |
| `gpt-5.5`       | **88.7%** (#1)                           | released 2026-04-23                               |
| Claude Opus 4.7 | 87.6%                                    | for reference                                     |
| `gpt-5.3-codex` | **85.0%**                                | ~2026-06-01                                       |
| `gpt-5.2`       | ~80%                                     | real cliff below the 85–88 cluster                |
| `gpt-5.4`       | no clean SWE-bench Verified figure found | 81.8% on Terminal-Bench 2.0 (different benchmark) |

- **Noise vs cliff:** ≤ ~3 pts = run-to-run noise (e.g. 5.5 vs Opus 4.7 = 1.1 pts). 5.5/Opus (~88)
  vs 5.3-codex (85) ≈ 3–4 pts (borderline). The drop to `gpt-5.2` (~80) is a **real cliff**.
- ⚠️ **All scores are SECONDARY** — no SWE-bench numbers appear on PRIMARY OpenAI model pages, and
  sources may mix SWE-bench Verified methodology versions (v2.0.x landed ~2026-02 / updated
  2026-03-06).

## 5. Prompt caching (PRIMARY)

- **Cost/latency:** cached input = **10% of input price** (90% cheaper); up to ~80% lower
  time-to-first-token.
- **Minimum prefix:** auto-enables at **≥1024 tokens**; below that, no caching.
- **TTL:** default in-memory cache active ~**5–10 min of inactivity, max ~1 hour**; **extended
  policy up to 24 h** for `gpt-5.5` / `gpt-5.5-pro` / select gpt-5.x.
- **Codex thread resume:** Codex stores transcripts **locally** (`~/.codex/sessions/...`); there is
  no server-side session state. Resume replays the local transcript as the prompt — if its prefix
  matches a recently processed one within the TTL, the server cache is reused, but this is
  **best-effort, not guaranteed** (evicted under load / after TTL).
- **Structuring for hits:** static content (system prompt, examples, repo context) first; variable /
  user-specific content last; keep the prefix byte-identical across calls.

## Mapping to our `codex-session` profiles

The [profile strategy](./codex-conventions.md#profile-strategy) applies the levers above; the
derived cost × quality tradeoffs behind these choices live in
[`codex-models-comparison.md`](./codex-models-comparison.md).

All models are **subscription-selectable** (`gpt-5.5` / `gpt-5.4` / `gpt-5.4-mini`); no `-codex`
pins (API-key-only — see [Auth & subscription availability](#auth--subscription-availability)).

| Profile  | Model          | Effort  | Why                                                              |
| -------- | -------------- | ------- | ---------------------------------------------------------------- |
| `deep`   | `gpt-5.5`      | high    | human-judged escalation only — `high` burns 3–5× tokens          |
| `medium` | `gpt-5.5`      | medium  | quality default (plan / implement / first review); ≈ parity cost |
| `low`    | `gpt-5.5`      | low     | follow-up rounds + cross-check Q&A; 5.5 stays coherent at `low`  |
| `quick`  | `gpt-5.4-mini` | medium  | trivial Q&A / commit messages                                    |
| `ping`   | `gpt-5.4-mini` | minimal | health/sandbox probes                                            |

## Sources

### PRIMARY (official OpenAI)

- Codex models — <https://developers.openai.com/codex/models>
- `gpt-5.5` — <https://developers.openai.com/api/docs/models/gpt-5.5> (snapshot
  `gpt-5.5-2026-04-23`)
- `gpt-5.4` — <https://developers.openai.com/api/docs/models/gpt-5.4> (snapshot
  `gpt-5.4-2026-03-05`)
- `gpt-5.3-codex` — <https://developers.openai.com/api/docs/models/gpt-5.3-codex>
- API pricing — <https://developers.openai.com/api/docs/pricing>
- Codex pricing/metering — <https://developers.openai.com/codex/pricing> ("Last updated April 2")
- Prompt caching — <https://developers.openai.com/api/docs/guides/prompt-caching>
- Reasoning models — <https://developers.openai.com/api/docs/guides/reasoning>
- Codex changelog — <https://developers.openai.com/codex/changelog>
- Codex CLI — <https://developers.openai.com/codex/cli>
- Codex rate card (help center) — <https://help.openai.com/en/articles/20001106-codex-rate-card> (⚠️
  HTTP 403 to automated fetch; open in a browser)
- Resume/cache discussion — <https://github.com/openai/codex/discussions/8339>; reasoning-effort bug
  — <https://github.com/openai/codex/issues/13536>

### SECONDARY (blogs / aggregators / leaderboards)

- Reasoning-effort tuning + plan-mode default —
  <https://codex.danielvaughan.com/2026/03/27/reasoning-effort-tuning/> (updated 2026-06-02)
- Codex model selection — <https://codex.danielvaughan.com/2026/03/26/codex-cli-model-selection/>
- Usage limits + credit rate card —
  <https://knightli.com/en/2026/04/15/codex-usage-limits-five-hour-weekly-credits/> (2026-04-15)
- SWE-bench leaderboard — <https://www.marc0.dev/en/leaderboard>; BenchLM —
  <https://benchlm.ai/benchmarks/sweVerified>; Epoch —
  <https://epoch.ai/benchmarks/swe-bench-verified>
- Reasoning-tokens-as-output —
  <https://www.codeant.ai/blogs/input-vs-output-vs-reasoning-tokens-cost>

## Confidence / uncertainty

- **§1 Catalog — HIGH** for 5.5/5.4/5.4-mini/5.3-codex (PRIMARY); **MEDIUM** for 5.4-nano (priced
  but not confirmed selectable) and the API-key default; no PRIMARY retirement list.
- **Auth & subscription availability — HIGH** for the subscription picker lineup (5.5/5.4/5.4-mini,
  verified live in Codex CLI v0.135.0 TUI + the `gpt-5.3-codex` 400 error); **MEDIUM** for the
  API-key-only `-codex` lineup (SECONDARY / GitHub issues).
- **§2 Reasoning — HIGH** for accepted values/per-model support; **LOW** for the token-multiplier
  table (community-measured); plan-mode default is SECONDARY.
- **§3 Pricing — HIGH** for API per-token rates; **MEDIUM** for the credit rate card (PRIMARY page
  403'd; values SECONDARY, `gpt-5.5` credit rate missing); "reasoning billed as output" is
  inference.
- **§3d Measuring — HIGH** for `account quota` output and the `turn.completed` usage events (both
  verified live 2026-06-03); **MEDIUM** for "reasoning is a subset of output_tokens" (convention,
  not stated for the Codex CLI) and the credit-conversion arithmetic (inherits §3b's MEDIUM rate
  card).
- **§4 Benchmarks — MEDIUM/LOW** — all SECONDARY, possibly mixed methodology versions; `gpt-5.4` has
  no clean figure.
- **§5 Caching — HIGH** for mechanics/TTL/discount; **MEDIUM** for Codex-resume reuse (best-effort).

## Changelog

- **2026-06-02** — Initial version. Researched the model catalog, reasoning-effort levels, API +
  ChatGPT-credit pricing, SWE-bench, and prompt caching to ground the `codex-session` profile
  refactor (planning/implementation/review-deep/review-followup/quick/ping).
- **2026-06-02** — Subscription-only correction. Added the **Auth & subscription availability**
  section after a `gpt-5.3-codex` 400 on ChatGPT-subscription auth: the `-codex` family is
  API-key-only; the subscription picker (Codex CLI v0.135.0) is `gpt-5.5`/`gpt-5.4`/`gpt-5.4-mini`.
  Repointed `implementation` → `gpt-5.4 @ medium` and `review-followup` → `gpt-5.4 @ low`, annotated
  the credit rate card (`-codex` rows are reference-only / not chargeable on subscription), and
  added the `gpt-5.5`/`gpt-5.4`/`gpt-5.4-mini` credit rows.
- **2026-06-03** — Tier-based profile redesign. Replaced the per-stage profiles
  (`planning`/`implementation`/`review-deep`/`review-followup`) with three `gpt-5.5` tiers (`deep` @
  high, `medium`, `low`) in the mapping table; cross-linked the new
  [`codex-models-comparison.md`](./codex-models-comparison.md) (derived cost × quality matrix behind
  the tiers).
- **2026-06-03** — Added §3d "Measuring actual usage": `codex-session account quota` (live 5h/weekly
  windows), per-call token extraction from `turn.completed` events in the persisted `--json` streams
  (with a worked credit-conversion example), the before/after per-workflow delta procedure, and the
  in-app/`/status` cross-check.
