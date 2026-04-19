# Company Chatbot System Spec — WhatsApp-Integrated AI Agent Backend

> **Status:** Exploration / Architecture Draft
> **Date:** 2026-04-18
> **Author:** Gustavo (with Claude assistance)
> **Purpose:** Reference document for continuing exploration and eventual implementation of a company-facing AI chatbot integrated with WhatsApp.

---

## 1. Problem Statement

Build a backend for a company chatbot integrated with WhatsApp that:

- Handles multiple concurrent customer sessions (multi-tenant)
- Provides first-contact customer service (orientation, FAQs, SOPs, workflow guidance)
- Uses LLMs to understand natural language queries and provide accurate, contextual responses
- Is cost-efficient and maintainable with minimal infrastructure overhead
- Scales to hundreds of daily interactions without requiring a dedicated ML/ops team

---

## 2. Chosen Architecture: Agentic (No RAG)

### 2.1 Core Insight

Traditional RAG (Retrieval-Augmented Generation) is not the only — nor necessarily the best — approach for a company chatbot with a moderate-sized knowledge base.

Modern coding agents (Claude Code, Codex CLI, pi) demonstrate that the pattern of **"user asks → agent searches → agent reads → agent responds"** works extremely well without any vector database, embedding pipeline, or chunking strategy. These agents use simple tools — `grep`, `find`, `read_file` — and let the LLM reason about what to search, evaluate results, and iterate if necessary.

This is fundamentally different from RAG's one-shot retrieval. The agent gets multiple chances to find the right information, can refine its search, and can cross-reference multiple documents.

### 2.2 Why This Works for Our Use Case

- **Document scale:** A few hundred to a few thousand documents (SOPs, FAQs, product catalog, internal procedures). Well under the threshold where vector search becomes necessary.
- **No embedding/indexing pipeline:** When a document changes, you update the file. Done. No re-indexing, no chunking strategy to re-tune.
- **Better answer quality:** Multi-step reasoning catches what semantic similarity misses. The agent understands file names, folder structure, and document types — not just raw text similarity scores.
- **Self-correction:** If the first search doesn't find what's needed, the agent tries a different query. RAG gets one shot.

### 2.3 When This Stops Working

If the document corpus grows beyond ~50,000 documents, or if `grep`/`find` operations become too slow, the agentic approach without additional tooling becomes cost-prohibitive (too many tool calls per query). At that point, RAG can be added as an optimization layer (see Section 7).

---

## 3. Technology Stack

### 3.1 Agent Runtime: pi-mono

**Repository:** [github.com/badlogic/pi-mono](https://github.com/badlogic/pi-mono)

Pi-mono is a TypeScript monorepo by Mario Zechner that provides composable building blocks for AI agents. It is the engine behind OpenClaw, a multi-channel AI assistant that runs on WhatsApp, Telegram, Slack, Discord, and 20+ other platforms.

#### Key Packages

| Package | Role |
|---|---|
| `@mariozechner/pi-ai` | Unified multi-provider LLM API (Anthropic, OpenAI, Google, etc.). Provider-agnostic abstraction that enables smart model routing. |
| `@mariozechner/pi-agent-core` | Agent runtime with tool calling, state management, and event streaming. The core agent loop where tools are registered and executed. |
| `@mariozechner/pi-coding-agent` | Full coding agent CLI (the flagship product). Can be used as an SDK for embedding in custom apps. |
| `@mariozechner/pi-tui` | Terminal UI library with differential rendering. Useful for building monitoring dashboards. |
| `@mariozechner/pi-web-ui` | Web components for AI chat interfaces. |
| `@mariozechner/pi-pods` | CLI for managing vLLM deployments on GPU pods (self-hosted inference). |

#### Why pi-mono Over Alternatives

- **Provider independence:** Swap between Anthropic, OpenAI, Google, or self-hosted vLLM without changing agent code.
- **Composable:** The coding agent is just one product built on the primitives. The same core can power a customer service bot, a Slack bot, a Telegram bot — whatever channel adapter you add.
- **Proven at scale:** OpenClaw uses all four core packages to run agents across WhatsApp, Telegram, Discord, Slack, Signal, iMessage, Google Chat, Microsoft Teams, and more, with shared memory and persistent sessions.
- **You own the agent loop:** Custom approval flows, context management, escalation logic, model routing — all configurable at the `pi-agent-core` level.
- **Open source (MIT):** Full control, no vendor lock-in.

#### Reference Architecture (from pi-mono docs)

```
┌─────────────────────────────────────────┐
│         Your Application                │
│    (chatbot gateway + WhatsApp adapter) │
├────────────────────┬────────────────────┤
│  pi-coding-agent   │      pi-tui       │
│  Sessions, tools,  │   Terminal UI,     │
│  extensions        │   markdown, editor │
├────────────────────┴────────────────────┤
│            pi-agent-core                │
│   Agent loop, tool execution, events    │
├─────────────────────────────────────────┤
│               pi-ai                     │
│   Streaming, models, multi-provider LLM │
└─────────────────────────────────────────┘
```

### 3.2 WhatsApp Integration

Use the WhatsApp Business API (Meta's Cloud API) or a BSP (Business Solution Provider) like Twilio or 360dialog. OpenClaw already has a WhatsApp channel adapter that can serve as a reference implementation.

### 3.3 Knowledge Base

A well-organized directory of plain files (Markdown, PDF, text) on the server filesystem:

```
knowledge/
├── faqs/
│   ├── general.md
│   ├── pricing.md
│   └── returns.md
├── sops/
│   ├── first-contact.md
│   ├── escalation.md
│   └── refund-process.md
├── products/
│   ├── catalog-2026.md
│   └── pricing-table.md
└── policies/
    ├── privacy-lgpd.md
    └── terms-of-service.md
```

No database. No indexing. The agent navigates this directory using `find`, `grep`, and `read_file` tools — exactly like a coding agent navigates a codebase.

### 3.4 Session Management

`pi-agent-core` manages per-user sessions natively. Each WhatsApp user gets an isolated session with its own conversation history, persisted as JSONL files with a tree structure (append-only DAG with branching support).

```
WhatsApp message arrives (user: +55 11 9xxxx-xxxx)
  → gateway looks up or creates session for that user ID
  → agent runs with that session's context
  → response streams back to that specific WhatsApp user
```

50 clients chatting simultaneously = 50 isolated sessions.

---

## 4. Cost Optimization Strategy

### 4.1 The Four Caching Layers

The system uses four complementary layers to minimize LLM API costs:

```
Layer 1: Exact match cache         → eliminates ~15% of queries     (free)
Layer 2: Semantic cache            → eliminates ~55% of queries     (free)
Layer 3: API prompt caching        → 90% savings on static prefix   (provider-level)
Layer 4: Smart model routing       → cheap model for 80% of runs    (pi-ai level)
```

#### Layer 1: Exact Match Cache

Hash the user's question (normalized: lowercase, stripped whitespace/punctuation), store the response in Redis or SQLite with a TTL.

```
"what are your business hours" → hash → cache hit → return stored answer
```

Catches copy-paste questions and very common phrasings. Cheap, fast, ~15% hit rate. Zero LLM cost.

**Implementation:** ~20 lines of code with a dict/SQLite.

#### Layer 2: Semantic Cache

Embed the user's question using a small local model (e.g., `all-MiniLM-L6-v2` via `sentence-transformers`, ~80MB, runs on CPU in milliseconds). Search a cache of previous Q&A pairs by cosine similarity.

```
User asks: "what time do you guys open?"
  → embed the question (local, no API call)
  → search cache of previous Q&A pairs
  → similarity > 0.92? → return cached answer
  → below threshold? → run the agent, store new Q&A pair in cache
```

This catches all natural language variations: "what are your hours", "when do you open", "horário de funcionamento", "que horas abre" — all map to the same cached answer.

**Important distinction:** This technically uses embeddings, but it is NOT RAG. You're caching your own answers, not retrieving from a knowledge base. No external API cost — the embedding model runs locally.

**Expected hit rate:** 50-70% for a typical company chatbot where customers repeatedly ask the same categories of questions. Could reach 80%+ over time.

**Libraries:** GPTCache, LangChain's semantic cache, or roll your own with SQLite + `sentence-transformers`.

#### Layer 3: API Prompt Caching (Provider-Level)

Major LLM providers offer prompt caching that caches the static prefix of your request (system prompt, tool definitions, knowledge context) and charges reduced rates on subsequent requests.

**Anthropic:**

- Add `cache_control: {"type": "ephemeral"}` to mark content for caching.
- Default TTL: 5 minutes (refreshed on each hit). Extended: 1 hour with beta header.
- Cache reads cost **0.1x** the base input price (90% savings).
- Cache writes cost 1.25x (5-min) or 2x (1-hour).

```python
SYSTEM_BLOCKS = [
    {
        "type": "text",
        "text": "You are a customer service agent for CompanyX..."
    },
    {
        "type": "text",
        "text": "[entire company knowledge context here]",
        "cache_control": {"type": "ephemeral"}  # cache everything above
    }
]
```

**OpenAI:** Implicit caching — automatic for prompts over 1024 tokens, no opt-in needed.

**Google (Vertex AI):** Supports the same `cache_control` format.

**Design principle:** Keep the cached prefix stable. Everything that doesn't change across users goes in the system prompt (cached). Everything that changes per user goes in the messages array (not cached).

#### Layer 4: Smart Model Routing

`pi-ai` enables routing queries to different models based on complexity:

- **Simple queries** (greetings, FAQ, straightforward lookups) → cheap model (Gemini Flash, Claude Haiku, GPT-4o-mini) at ~$0.10-0.80/M tokens.
- **Complex queries** (multi-step reasoning, policy interpretation, edge cases) → expensive model (Claude Sonnet, GPT-4o) at ~$3-15/M tokens.

Routing can be implemented via:

- A lightweight classifier (keyword-based or small model) that categorizes the query before routing.
- The agent itself, starting with a cheap model and escalating to an expensive one if the first attempt isn't confident enough.

### 4.2 Automated Cache Management

Beyond the per-query caching, a periodic batch job can optimize the cache over time:

1. Collect all questions from the last 7 days.
2. Embed them all.
3. Cluster (DBSCAN or k-means).
4. Each cluster = one "canonical question" with a cached answer.
5. Review: does the cached answer still apply? Are documents stale?
6. Flag clusters with no cache hit → these are new question patterns to watch.

This provides a feedback loop for understanding what customers ask most, whether cached answers are drifting, and where the agent spends the most tokens.

**Recommended implementation timeline:**

1. **Day 1:** API prompt caching (zero effort, just structure API calls correctly)
2. **Day 1:** Exact match cache (~20 lines of code)
3. **Week 2-3:** Semantic cache (after real traffic data exists)
4. **Month 2+:** Clustering/analytics for automated cache management

### 4.3 Subscription vs API Pricing — Critical Distinction

**Consumer subscriptions (Claude Pro/Max, ChatGPT Plus, Gemini Advanced) CANNOT be used as a backend for commercial products.** This is a Terms of Service violation for every provider. These subscriptions provide a chat UI for personal use, not an API endpoint.

**You must use API access with pay-per-token pricing.** This is non-negotiable.

The cost optimization levers available at the API level (model routing, prompt caching, semantic caching) more than compensate. A well-optimized agentic system at 500 queries/day costs less than a single Claude Pro subscription.

---

## 5. Cost Comparison: Agentic vs. RAG

### 5.1 Assumptions

- 500 customer queries/day
- ~2000 documents in knowledge base
- System prompt + knowledge context: ~4000 tokens
- Agent averages 3.5 tool calls (simple) to 5 tool calls (complex) per query

### 5.2 Standard RAG Architecture

```
Per query:
  - 1 embedding call (ada-002):            ~$0.0001
  - 1 LLM call (Sonnet):                   ~$0.004
    (4000 tok system+chunks input + 500 tok output)
  Total per query:                          ~$0.004

Daily (500 queries):                        $2.00
Monthly LLM cost:                           $60

Infrastructure:
  - Vector DB (Qdrant/Pinecone):            $25-70/month
  - Embedding pipeline (compute):           $10-20/month
  - Total infra:                            $35-90/month

RAG TOTAL:                                  $95-150/month
```

### 5.3 Optimized Agentic Architecture (with all 4 caching layers)

```
500 queries arrive per day

Layer 1 - Exact match cache:
  500 × 0.15 = 75 queries → instant response            $0
  Remaining: 425 queries

Layer 2 - Semantic cache:
  425 × 0.65 = 276 queries → cached response             $0
  (local embedding, no API call)
  Remaining: 149 queries hit the LLM

Layer 3+4 - Agent runs with API caching + model routing:

  80% simple (119 queries) → cheap model (Haiku/Flash)
    Per query: ~3.5 tool calls average
    With API prompt caching:
      - First call:  4000 × 1.25x + 800 = 5800 tok-equiv input
      - Calls 2-3.5: 4000 × 0.1x  + 800 = 1200 tok-equiv each
      - Output: ~400 tok per call
    Avg cost per query (Haiku pricing):       ~$0.013

  20% complex (30 queries) → expensive model (Sonnet)
    Per query: ~5 tool calls average
    Same caching math at Sonnet pricing:
    Avg cost per query:                       ~$0.062

Daily LLM cost:
  Simple: 119 × $0.013 =                     $1.55
  Complex:  30 × $0.062 =                    $1.86
  Total daily:                                $3.41

Monthly LLM cost:                             $102

Infrastructure:
  - Semantic cache (SQLite + local model):    $0
  - No vector DB                              $0
  - No embedding pipeline                     $0
  - VPS running the agent:                    $5-15/month

AGENTIC TOTAL:                                $107-117/month
```

### 5.4 Side-by-Side Comparison

| Metric | Standard RAG | Optimized Agentic |
|---|---|---|
| Monthly LLM API cost | $60 | $102 |
| Monthly infrastructure | $35-90 | $5-15 |
| **Total monthly cost** | **$95-150** | **$107-117** |
| Answer quality | One-shot retrieval | Multi-step, self-correcting |
| Chunking tuning required | Yes | No |
| Embedding pipeline | Yes | No |
| Re-indexing on doc changes | Yes | No |
| Vector DB operations | Yes | No |
| Maintenance complexity | High | Low |
| Update workflow | Re-index pipeline | Edit file, done |

**Key takeaway:** Costs are essentially equivalent. The agentic approach trades slightly higher LLM costs for dramatically lower infrastructure costs and maintenance burden. At 80%+ semantic cache hit rate (realistic for company chatbots with repetitive questions), the agentic approach becomes cheaper overall.

---

## 6. Architecture Diagrams

### 6.1 Request Flow (with caching)

```
WhatsApp message arrives
  │
  ▼
Normalize text (lowercase, strip punctuation)
  │
  ▼
Exact match cache (hash lookup)
  │
  ├── HIT → return cached response → WhatsApp
  │
  ▼
Semantic cache (local embedding + similarity search)
  │
  ├── HIT (similarity > 0.92) → return cached response → WhatsApp
  │
  ▼
Agent run (pi-agent-core)
  │
  ├── Model router: classify query complexity
  │     ├── Simple → Haiku / Flash
  │     └── Complex → Sonnet / GPT-4o
  │
  ├── API prompt caching: system prompt + tools cached at provider level
  │
  ├── Agent tool loop:
  │     ├── grep / find → locate relevant docs
  │     ├── read_file → read content
  │     ├── evaluate → is this sufficient?
  │     │     ├── No → refine search, try again (max 5-8 iterations)
  │     │     └── Yes → synthesize response
  │
  ▼
Store Q&A pair in both caches
  │
  ▼
Return response → WhatsApp
```

### 6.2 System Components

```
┌──────────────────────────────────────────────────────┐
│                   WhatsApp Cloud API                 │
│                  (or Twilio / 360dialog)              │
└───────────────────────┬──────────────────────────────┘
                        │ webhook
                        ▼
┌──────────────────────────────────────────────────────┐
│                  Gateway Service                     │
│  - Webhook handler                                   │
│  - Session manager (per WhatsApp user ID)            │
│  - Cache layers (exact + semantic)                   │
│  - Model router                                      │
│  - Rate limiting                                     │
└───────────────────────┬──────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────┐
│               pi-agent-core                          │
│  - Agent loop with tool calling                      │
│  - Tools: grep, find, read_file                      │
│  - Session persistence (JSONL)                       │
│  - Extension hooks (context pruning, compaction)     │
└───────────────────────┬──────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────┐
│                    pi-ai                             │
│  - Multi-provider LLM abstraction                    │
│  - Anthropic / OpenAI / Google / vLLM                │
│  - Prompt caching configuration                      │
│  - Streaming                                         │
└──────────────────────────────────────────────────────┘
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
┌──────────────────┐  ┌──────────────────────┐
│  Knowledge Base  │  │   Session Storage     │
│  (filesystem)    │  │   (~/.pi/sessions/)   │
│  knowledge/      │  │   Per-user JSONL      │
│  ├── faqs/       │  │                       │
│  ├── sops/       │  └──────────────────────┘
│  ├── products/   │
│  └── policies/   │
└──────────────────┘
```

---

## 7. Future Optimization: RAG as an Agent Tool

If the document corpus grows significantly (beyond ~10,000-50,000 documents) or if the agent consistently burns too many tool calls scanning files, a vector index can be added as **an additional tool** — not a replacement for the agentic architecture.

### 7.1 Agentic RAG Pattern

The vector database becomes just another tool in the agent's toolbox, alongside `grep` and `read_file`. The agent decides when to use it, what to query, and whether the results were good enough.

```
Agent receives user question
  → thinks: "this is about pricing, let me check the catalog"
  → tool: vector_search("pricing tiers for product X")
  → evaluates: "these chunks mention product X but not the 2025 update"
  → tool: grep("2025.*pricing", path="docs/pricing/")
  → finds the right file
  → tool: read_file("docs/pricing/2025-update.md")
  → synthesizes final answer from all three sources
```

### 7.2 Why This Is Better Than Pure RAG

The agent compensates for RAG's weaknesses (bad chunks, missed semantic matches) while RAG compensates for the agent's weaknesses (slow full-text search over huge corpora). The vector search narrows the haystack fast; the agent reasons about whether it found the right needle.

### 7.3 Implementation Approach

Adding RAG is a low-friction change in the agentic architecture:

1. Set up a vector index (e.g., Qdrant, Chroma, or pgvector) alongside the existing knowledge directory.
2. Create an embedding pipeline that indexes the knowledge directory.
3. Register `vector_search` as a new tool in `pi-agent-core`.
4. The agent code barely changes — it just has one more tool available.
5. The agent naturally learns when to use vector search vs. grep vs. direct file reads.

The architecture is the same. RAG becomes an optimization you bolt on later, not a foundational decision you commit to upfront.

---

## 8. Compliance and Operational Considerations

### 8.1 LGPD (Lei Geral de Proteção de Dados)

Since this operates in Brazil, LGPD compliance is mandatory:

- Customer conversation data must be handled according to LGPD requirements.
- Retention policies for session data must be defined.
- Customers must be informed they are interacting with an AI.
- PII handling in the knowledge base and session logs must be audited.

### 8.2 Escalation to Human Agents

The system should support escalation when:

- The agent cannot find a satisfactory answer after max iterations.
- The customer explicitly requests a human.
- The query involves sensitive topics (complaints, legal, financial decisions).

This can be implemented as a tool or extension in `pi-agent-core` that triggers a notification (e.g., via ntfy, Slack, or email) and transfers the session context to a human agent.

### 8.3 Monitoring

- **OTEL telemetry:** pi-agent-core can emit OpenTelemetry events for session tracking, token usage, tool calls, and error rates.
- **Cache hit rate monitoring:** Track Layer 1 and Layer 2 hit rates to verify cost assumptions.
- **Answer quality:** Periodically review agent responses (can be automated with a separate LLM-as-judge evaluation).

---

## 9. Implementation Roadmap

### Phase 1: MVP (Week 1-2)

- Set up pi-mono locally.
- Implement the gateway service with WhatsApp Cloud API webhook.
- Create the knowledge directory with initial company documents.
- Register `grep`, `find`, and `read_file` as agent tools.
- Implement exact match cache (SQLite).
- Configure API prompt caching.
- Deploy on Hetzner VPS (existing infrastructure).

### Phase 2: Optimization (Week 3-4)

- Add semantic cache layer (local embedding model + SQLite).
- Implement smart model routing (Haiku for simple, Sonnet for complex).
- Set up basic OTEL monitoring for cost/usage tracking.
- Implement human escalation tool.

### Phase 3: Refinement (Month 2+)

- Deploy question clustering batch job for automated cache management.
- Add analytics dashboard for cache hit rates and cost per query.
- Optimize knowledge directory structure based on agent search patterns.
- Evaluate whether RAG tool is needed based on real-world performance data.

### Phase 4: Scale (As Needed)

- Add RAG as an additional agent tool if document corpus grows.
- Add more channels (Telegram, web chat) via pi-mono's multi-channel support.
- Consider self-hosted inference (vLLM via `pi-pods`) if API costs become significant.

---

## 10. Key Decisions Log

| Decision | Rationale |
|---|---|
| Agentic over RAG | Better answer quality, lower maintenance, equivalent cost at our scale. RAG can be added later as a tool if needed. |
| pi-mono as runtime | Provider-agnostic, composable, proven by OpenClaw across 20+ channels, MIT licensed, active development. |
| Filesystem knowledge base | No indexing pipeline, instant updates, agent navigates it naturally with file tools. |
| Four-layer caching | Eliminates 70%+ of LLM calls, brings agentic cost below or equal to RAG. |
| API pricing only | Consumer subscriptions (Pro/Max/Plus) violate ToS for commercial use. API pay-per-token is required and cost-efficient at our scale. |
| No vector DB initially | Unnecessary complexity for < 50k documents. Can be added as an agent tool later without architectural changes. |

---

## 11. Open Questions for Further Exploration

- **Multi-language support:** Customers may interact in Portuguese and English. How does this affect cache hit rates and model selection?
- **Conversation context window management:** For long customer conversations, how should the agent compact/summarize earlier context?
- **Knowledge base versioning:** Should we use git to track document changes and enable rollback?
- **A/B testing models:** Can we run two models in parallel on a subset of queries to compare quality?
- **Offline/async queries:** Should the system support "I'll look into this and get back to you" patterns for complex queries that take too long for real-time response?
- **Session supervisor dashboard:** A TUI-based dashboard for monitoring all active agent sessions across customers (see earlier exploration of pi-tui for this use case).

---

## References

- [pi-mono repository](https://github.com/badlogic/pi-mono)
- [OpenClaw repository](https://github.com/openclaw/openclaw)
- [Armin Ronacher's blog post on Pi](https://lucumr.pocoo.org/2026/1/31/pi/)
- [Building a Custom Agent Framework with Pi (Nader Dabit)](https://nader.substack.com/p/how-to-build-a-custom-agent-framework)
- [Anthropic Prompt Caching docs](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [Claude Code OTEL monitoring docs](https://code.claude.com/docs/en/monitoring-usage)
- [ColeMurray/claude-code-otel (Grafana stack)](https://github.com/ColeMurray/claude-code-otel)
- [Swarek/claude-session-manager](https://github.com/Swarek/claude-session-manager)
