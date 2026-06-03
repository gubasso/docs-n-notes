# Codex Models Comparison — gpt-5.5 vs gpt-5.4 Across Reasoning Efforts

A decision-support matrix for choosing model + reasoning effort per task tier in the `codex-session`
profiles (`deep` / `medium` / `low`; see
[`codex-conventions.md` §Profile Strategy](./codex-conventions.md#profile-strategy)). Raw catalog,
pricing, and benchmark facts live in [`codex-models-pricing.md`](./codex-models-pricing.md) — this
doc derives the cost × quality tradeoffs from those inputs and records the tier guidance the
profiles encode.

- **Last verified:** 2026-06-03
- **Source policy:** same as `codex-models-pricing.md` (**PRIMARY** = official OpenAI properties,
  **SECONDARY** = blogs / aggregators / leaderboards). Figures _derived_ here from those inputs are
  tagged **ESTIMATE** — directional decision aids, not measured values.
- **How to keep this updated:** refresh whenever `codex-models-pricing.md` re-syncs (its credit rate
  card and effort multipliers are the inputs to every table below): re-derive the matrix, update the
  "Last verified" date, and append a line to [Changelog](#changelog).

---

## TL;DR

1. **`gpt-5.5 @ medium` is the quality default.** Roughly cost parity with `gpt-5.4 @ medium` (after
   5.5's token efficiency) for a clearly better result on planning/review/implementation work
   (ESTIMATE).
2. **High effort is an escalation, not a default.** `high` multiplies reasoning-token burn ~3–5× for
   a modest quality bump — reserve it for human-judged hard cases (stuck, looping, genuinely novel
   design).
3. **`gpt-5.5 @ low` replaces `gpt-5.4` for light work.** At ~⅓ the baseline cost it stays coherent
   on already-triaged follow-up tasks where `gpt-5.4 @ low` flails (ESTIMATE).
4. **`gpt-5.4 @ high` is an anti-pattern.** 3–5× the cost with no meaningful quality gain over its
   own `medium`; if a task needs high effort it also needs the better model.

## 1. Inputs (from `codex-models-pricing.md`)

Everything below is derived from these four facts:

| Input                                                                             | Value                                                                            | Source tier                    |
| --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------ |
| Per-token credit rate ratio, `gpt-5.5` vs `gpt-5.4` (subscription)                | ≈ **2×** (input and output)                                                      | SECONDARY (credit rate card)   |
| Reasoning-effort token multiplier (per model, `medium` = 1×)                      | `minimal` ~0.1×, `low` ~0.3×, `high` 3–5×, `xhigh` 8–15×                         | SECONDARY (community-measured) |
| `gpt-5.5` token efficiency at equal effort (fewer thinking tokens, fewer retries) | ≈ **0.5–0.7×** the tokens of `gpt-5.4`                                           | SECONDARY / ESTIMATE           |
| SWE-bench Verified                                                                | `gpt-5.5` **88.7%**; `gpt-5.4` no clean figure (below 5.5, above the ~80% cliff) | SECONDARY                      |

Effective relative cost is estimated as `rate ratio × effort multiplier × token efficiency`,
normalized to `gpt-5.4 @ medium` = 1.0×.

## 2. Cost × quality matrix (ESTIMATE)

Normalized to `gpt-5.4 @ medium` = 1.0× on both axes. Quality is a directional composite for agentic
coding tasks (planning / review / implementation), not a benchmark score.

| Model @ effort     | Effective quota cost | Quality    | Best use                                                      |
| ------------------ | -------------------- | ---------- | ------------------------------------------------------------- |
| `gpt-5.5 @ high`   | ≈ 3–7×               | 1.25–1.35× | Human-judged escalation: stuck/looping cases, novel design    |
| `gpt-5.5 @ medium` | ≈ 1.0–1.4×           | 1.15–1.20× | **Default** for planning, first-pass review, implementation   |
| `gpt-5.5 @ low`    | ≈ 0.3–0.45×          | 0.85–0.95× | Follow-up review rounds, cross-check Q&A, small triaged fixes |
| `gpt-5.4 @ high`   | ≈ 3–5×               | ~1.0×      | **Avoid** — pays high-effort burn without the better model    |
| `gpt-5.4 @ medium` | 1.0× (baseline)      | 1.0×       | Superseded by `gpt-5.5 @ medium` (parity cost, better result) |
| `gpt-5.4 @ low`    | ≈ 0.3×               | 0.70–0.80× | Only truly trivial work; superseded by `gpt-5.5 @ low`        |

## 3. Side-by-side: `gpt-5.4 @ medium` vs `gpt-5.5 @ medium`

| Dimension        | `gpt-5.4 @ medium`                                | `gpt-5.5 @ medium`                                             |
| ---------------- | ------------------------------------------------- | -------------------------------------------------------------- |
| Effective cost   | 1.0× (baseline)                                   | ≈ 1.0–1.4× (2× rate, offset by token efficiency) — ESTIMATE    |
| Quality          | 1.0×                                              | 1.15–1.20× — ESTIMATE                                          |
| Token efficiency | More tokens for the same outcome; retry-loop risk | Fewer thinking tokens, fewer false starts                      |
| Planning         | Adequate for straightforward specs                | Better constraint handling, fewer scope-creep mistakes         |
| Review           | Catches obvious bugs, misses nuance               | Better architectural judgment, fewer false positives/negatives |
| Implementation   | Solid spec-following workhorse                    | Better on complex transformations; cleaner first pass          |
| Failure modes    | Undershoots hard logic; can loop                  | Rare; cleaner first-pass output shortens review loops          |

**Verdict:** at near-parity effective cost, `gpt-5.5 @ medium` wins everywhere quality matters.
Fewer review-loop rounds compound the savings — each avoided round saves a full review + fix cycle.
Worst case (if the efficiency gain does not materialize for a workload) the premium is bounded by
the raw 2× rate; measure real consumption after adopting (per-call `turn.completed` token sums and
`codex-session account quota` deltas — see
[`codex-models-pricing.md` §3d](./codex-models-pricing.md#3d-measuring-actual-usage-subscription))
and re-evaluate.

## 4. Side-by-side: `gpt-5.4 @ low` vs `gpt-5.5 @ low`

| Dimension       | `gpt-5.4 @ low`                                    | `gpt-5.5 @ low`                                           |
| --------------- | -------------------------------------------------- | --------------------------------------------------------- |
| Effective cost  | ≈ 0.3×                                             | ≈ 0.3–0.45× — ESTIMATE                                    |
| Quality         | 0.70–0.80×                                         | 0.85–0.95× — ESTIMATE                                     |
| Behavior at low | Underthinks: boilerplate, missed context, flailing | Degrades gracefully; stays coherent on bounded tasks      |
| Best fit        | Truly trivial probes                               | Follow-up review rounds, cross-check Q&A, iterative fixes |

**Verdict:** `gpt-5.5 @ low` is the better low tier for any substantive task at a marginal premium.

### The "`gpt-5.5 @ low` vs `gpt-5.4 @ medium`" claim

- **Cost: confirmed.** ≈ 0.3–0.45× vs 1.0× — roughly half or less (ESTIMATE).
- **Quality: qualified.** 0.85–0.95× — _near_ but slightly **below** baseline, and task-dependent:
  - Near-parity on follow-up reviews, Q&A, and small triaged fixes, where prior context already
    carries the reasoning load.
  - Visibly weaker on multi-step reasoning (planning, first-pass review) — low effort underthinks.

**Rule:** use `gpt-5.5 @ low` where reasoning was already done upstream. Never for multi-step
reasoning — that is `medium`-tier work.

## 5. Tier guidance — mapping to `codex-session` profiles

The profile set encodes the matrix as three `gpt-5.5` tiers (plus the unchanged mini profiles):

| Profile  | Model          | Effort  | Role                                                      |
| -------- | -------------- | ------- | --------------------------------------------------------- |
| `deep`   | `gpt-5.5`      | high    | On-demand escalation; never a skill default               |
| `medium` | `gpt-5.5`      | medium  | Quality default: prex stages 1 & 3, review-loop round 1   |
| `low`    | `gpt-5.5`      | low     | Light tier: review-loop rounds 2+, `ask -c` cross-check   |
| `quick`  | `gpt-5.4-mini` | medium  | Trivial Q&A / commit messages (codex-side `ask -f`, `gc`) |
| `ping`   | `gpt-5.4-mini` | minimal | Health/sandbox probes only                                |

A side benefit of one shared `medium` profile: prex stage 3 `exec resume` continues the stage 1
thread on the **same model and effort**, instead of switching models mid-thread.

### Escalation heuristics (`medium` → `deep`)

Escalation is a **human judgment call**, made in the moment — the skills never auto-select `deep`:

1. Escalate when a `medium` run is stuck or looping, the design space is genuinely novel, or the
   change is security-critical / cross-cutting.
2. Before escalating, check whether the failure is context or prompt underspecification — a tighter
   prompt or a context refresh often beats more reasoning, for free.
3. Escalate the _next_ attempt; never re-run already-accepted work at higher effort retroactively.

## Sources

Derived from [`codex-models-pricing.md`](./codex-models-pricing.md) (see its
[Sources](./codex-models-pricing.md#sources) for the full PRIMARY/SECONDARY list). Inputs used
directly here:

- Credit rate card (SECONDARY) —
  <https://knightli.com/en/2026/04/15/codex-usage-limits-five-hour-weekly-credits/>
- Reasoning-effort multipliers (SECONDARY, community-measured) —
  <https://codex.danielvaughan.com/2026/03/27/reasoning-effort-tuning/>
- Reasoning models guide (PRIMARY) — <https://developers.openai.com/api/docs/guides/reasoning>
- SWE-bench aggregation (SECONDARY) — <https://llm-stats.com/blog/research/gpt-5-5-vs-gpt-5-4>;
  <https://www.marc0.dev/en/leaderboard>

## Confidence / uncertainty

- **§1 Inputs — MEDIUM/LOW**: the 2× rate ratio and effort multipliers are SECONDARY; the 0.5–0.7×
  token-efficiency factor is the weakest input (single-vendor claims + one Codex-Max datapoint).
- **§2–§4 Matrices — ESTIMATE**: directionally robust (each cell follows from the inputs), exact
  ranges are not measured. The _ordering_ of cells is far more reliable than the numbers.
- **§5 Tier guidance — decision record**, not a measurement; revisit if measured usage
  ([`codex-models-pricing.md` §3d](./codex-models-pricing.md#3d-measuring-actual-usage-subscription))
  contradicts the estimates.

## Changelog

- **2026-06-03** — Initial version. Derived the cost × quality matrix and medium/low side-by-sides
  from `codex-models-pricing.md` (2026-06-02 sync) to ground the tier-based profile redesign (`deep`
  / `medium` / `low` replacing `planning` / `implementation` / `review-deep` / `review-followup`).
