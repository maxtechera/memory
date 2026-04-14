---
name: memory
version: "1.0.0"
description: "Cross-platform memory system. 3-tier HOT/WARM/COLD + LLM Wiki (Mode 5). Vault sync, session hooks, weekly consolidation, Notion publishing."
argument-hint: 'memory sync, memory status, memory dream, memory setup, memory audit, memory wiki ingest, memory wiki sync notion'
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
homepage: https://github.com/maxtechera/memory
repository: https://github.com/maxtechera/memory
author: maxtechera
license: MIT
user-invocable: true
triggers:
  - memory
  - memory sync
  - memory status
  - memory setup
  - sync memory
  - save to memory
  - remember this
  - sync openclaw
  - memory dream
  - dream
  - memory audit
  - memory wiki
  - memory wiki sync
  - wiki sync
  - memory wiki init
  - memory wiki ingest
  - memory wiki query
  - memory wiki lint
  - memory wiki sync notion
  - memory wiki dream
  - memory wiki status
metadata:
  openclaw:
    emoji: "🧠"
    requires:
      env: []
      optionalEnv:
        - OBSIDIAN_VAULT_PATH
        - OBSIDIAN_CLI_PATH
        - OPENCLAW_CONFIG_PATH
        - MEMORY_ROUTER_MAX_LINES
        - MEMORY_TOPIC_MAX_ENTRIES
        - DREAM_SCHEDULE
      bins: []
    primaryEnv: ""
    files: []
    tags:
      - memory
      - obsidian
      - vault-sync
      - cross-platform
      - session-hooks
      - consolidation
      - skill-first
---

# Memory

Cross-platform memory system for AI agents. 3-tier architecture (HOT/WARM/COLD), Obsidian vault sync, session hooks, weekly consolidation, and LLM Wiki (Mode 5) — a compounding knowledge base that publishes to Notion. Your agents forget everything between sessions — this fixes that.

---

## Commands

| Command | Description |
|---------|-------------|
| `/memory sync` | Sync current session to memory (Mode 1) |
| `/memory sync openclaw` | Pull OpenClaw journals into Obsidian (Mode 2) |
| `/memory sync projects` | Sync Claude Code project memory to Obsidian (Mode 3) |
| `/memory dream` | Analyze memory and evolve: journals→topics, prune, TTL audit (Mode 4) |
| `/memory status` | Memory health: tier sizes, TTL alerts, last sync times |
| `/memory setup` | Configure vault path, detect platforms, install hooks |
| `/memory audit` | TTL audit + boundary check + health alerts |
| `/memory wiki sync` | **Full pipeline**: init → ingest all vault sources → Notion publish (Mode 5) |
| `/memory wiki sync --full` | Full pipeline, reprocessing all sources from scratch (Mode 5) |
| `/memory wiki init` | Initialize wiki/ folder structure in vault (Mode 5) |
| `/memory wiki ingest [source]` | Process raw source → compile wiki pages (Mode 5) |
| `/memory wiki ingest --from-memory` | Pull session digests + topics → wiki pages (Mode 5) |
| `/memory wiki query [topic]` | Answer from compiled wiki, not raw sources (Mode 5) |
| `/memory wiki sync notion` | Push publish-ready pages to Notion (Mode 5) |
| `/memory wiki lint` | Health check: orphans, stale, broken links, missing provenance (Mode 5) |
| `/memory wiki dream` | Bulk consolidation: merge, contradiction detection, rebuild index (Mode 5) |
| `/memory wiki status` | Wiki stats: pages, stale count, publish queue, last sync (Mode 5) |

---

## Memory Architecture

```
HOT   ≤2400tok, always loaded
  MEMORY.md          = router (project index, topic pointers — facts only)
  SESSION-STATE.md   = WAL hot RAM (current task, decisions, pending actions)

WARM  on-demand read when domain is relevant
  memory/topics/*.md   domain-scoped facts with TTL
  memory/YYYY-MM-DD.md daily journals (last 7 days)

COLD  search-only, permanent
  Obsidian vault     knowledge/, logs/, projects/, identity/, dev/
  ↕  parallel, not replacing COLD ↕

WIKI  LLM-owned, compounding synthesis (Mode 5)
  wiki/concepts/     compiled concept + synthesis pages
  wiki/entities/     people, products, tools
  wiki/sources/      per-source summaries
  wiki/comparisons/  structured option comparisons
  wiki/raw/          immutable inputs (web-clips, docs, sessions, external)
```

**Sync direction**: Session → HOT → WARM → COLD (Obsidian) → WIKI → Notion.
OpenClaw writes independently to `openclaw-config/memory/` → synced to Obsidian via Mode 2.
Wiki feeds from COLD tier via `ingest --from-memory` and publishes outward to Notion.

### Tier Rules

| Tier | Token Budget | Read Pattern | Write Pattern |
|------|-------------|--------------|---------------|
| HOT | ≤2400 tokens | Always loaded | Write-before-respond (WAL) |
| WARM | On-demand | Read when domain matches | Append with TTL suffix |
| COLD | Search-only | `obsidian search` → read | Create/patch via Obsidian CLI |
| WIKI | On-demand | `wiki/index.md` → targeted reads | LLM compiles + patches pages |

---

## Boundary Rules (Critical)

| File | Contains | Never Contains |
|------|----------|----------------|
| `MEMORY.md` | Facts about the world, project index, identity | Behavioral rules, instructions |
| `AGENTS.md` | Behavioral rules, instructions, compaction policy | Domain facts, API configs |
| `SESSION-STATE.md` | Live working memory, WAL entries | Long-term facts |
| `memory/topics/*.md` | Domain-scoped facts with TTL | Rules or instructions |
| Obsidian `knowledge/` | Patterns, decisions, learnings | Ephemeral session data |

**Boundary test**: `grep -c "NEVER\|ALWAYS\|must\|rule" MEMORY.md` must return 0.

**Corruption risk**: Mixing behavioral rules into MEMORY.md teaches agents facts that should be instructions. Mixing facts into AGENTS.md teaches agents rules that should decay. Both corruptions compound silently — the system appears healthy until an agent follows a stale rule or ignores a live fact.

---

## WAL Protocol (Session-State)

Write SESSION-STATE.md BEFORE responding — not after.

| Trigger | Action |
|---------|--------|
| User states preference | Write SESSION-STATE.md → THEN respond |
| User makes decision | Write SESSION-STATE.md → THEN respond |
| User gives deadline | Write SESSION-STATE.md → THEN respond |
| User corrects you | Write SESSION-STATE.md → THEN respond |
| Session ending | Flush SESSION-STATE.md → daily journal + topic files |

### SESSION-STATE.md Format

```markdown
## Current Task
[What you're working on right now]

## Key Context
[Important facts from this session]

## Pending Actions
- [ ] [Action items]

## Recent Decisions
- [Decision with reasoning]

## Blockers
- [Anything blocking progress]
```

---

## TTL Convention

All entries in `memory/topics/*.md` must have a decay class:

| Class | Suffix | Default TTL | Examples |
|-------|--------|-------------|---------|
| permanent | (no suffix) | never | User prefs, core arch decisions |
| operational | `[date:6m]` | 6 months | API versions, tool configs |
| project | `[date:3m]` | 3 months | Project-specific facts |
| session | `[date:1m]` | 30 days | Session notes, research citations |

Example: `Stripe API v2024-12 [2026-03-16:6m]`

---

## Sync Modes

### Mode 1: Session → Memory

Trigger: "save to memory" / "remember this" / "sync memory" / session compaction

**Paths**: All paths are relative to the current working directory unless specified.
- `SESSION-STATE.md` — in the current working directory (Claude Code creates it here)
- `MEMORY.md` — in the current working directory
- `memory/topics/*.md` — subdirectory of current working directory
- `memory/YYYY-MM-DD.md` — daily journal in same subdirectory

**Steps**:

1. **Update SESSION-STATE.md** (WAL) — if significant fact/decision surfaced, write it now
2. **Classify each insight** using this decision logic:
   - Contains a server, deploy, hosting, or infrastructure fact → `memory/topics/infra.md`
   - References a specific project by name → `memory/topics/{project}.md`
   - Contains an API key, CLI tool, credential, or version number → `memory/topics/tools-creds.md`
   - Is a reusable framework, architecture, or technique applicable beyond this session → Obsidian `knowledge/patterns/`
   - Records a strategic choice with reasoning ("chose X over Y because...") → Obsidian `knowledge/decisions/`
   - Is a one-time gotcha, bug fix, or "I learned that..." → Obsidian `knowledge/learnings/`
   - Is a timestamped event or session summary → `memory/YYYY-MM-DD.md` + Obsidian `logs/journals/`
   - Is a behavioral instruction (NEVER, ALWAYS, must, should) → `AGENTS.md` (NEVER to MEMORY.md)
   - If ambiguous: prefer the more specific category. If still unclear: ask the user.
3. **Dedup before writing**:
   - Read the target file
   - For each new entry, check if an existing entry covers the same topic (same subject + same conclusion)
   - Semantic match >80% → update in-place (patch). <80% → append as new entry.
   - If the existing entry says the same thing: skip (duplicate)
   - If the existing entry covers the same topic but with outdated info: update it in-place
   - If no match: append as new entry
4. **Add TTL suffix** to topic entries using this rule:
   - User preference or core architecture decision → permanent (no suffix)
   - API version, tool config, credential → `[today:6m]` (operational)
   - Project-specific fact → `[today:3m]` (project)
   - Research note, session-specific finding → `[today:1m]` (session)
5. **Keep MEMORY.md as router** — max 15 lines, format: `- [Title](memory/topics/file.md) — one-line description`. If a new domain emerges, create the topic file first, then add the pointer.

### Mode 2: OpenClaw → Obsidian Pull Sync

Trigger: "sync openclaw" / "pull openclaw memory"

**Requires**: `$OPENCLAW_CONFIG_PATH` env var set (path to the local openclaw-config repo).

1. **Discover new journals**: List files in `$OPENCLAW_CONFIG_PATH/memory/*.md`. Compare dates against Obsidian `logs/journals/` — find dates not yet in the vault.
2. **Read + clean**: For each new journal, read the file. Strip any raw JSON metadata blocks (e.g., Telegram API responses, webhook payloads). Keep human-readable insights, summaries, and decisions.
3. **Write to Obsidian**: Create `logs/journals/YYYY-MM-DD.md` with this frontmatter:
   ```yaml
   type: journal
   status: active
   agent-use: medium
   use-when: "daily log, YYYY-MM-DD, [key topics extracted from content]"
   summary: "[one-line summary of the day's work]"
   domain: operations
   created: 'YYYY-MM-DD'
   source: "openclaw-config/memory/YYYY-MM-DD.md"
   ```
4. **Sync topic insights**: For entries in `$OPENCLAW_CONFIG_PATH/memory/topics/*.md`, compare against Obsidian `knowledge/learnings/openclaw-operational-lessons.md` — patch in new entries.

### Mode 3: Claude Code Project Memory → Obsidian

Trigger: "sync claude code memory" / "sync projects"

1. **Scan** these paths using the Glob tool:
   - `~/.claude/projects/*/memory/*.md` — project memory files
   - `~/.claude/plans/*.md` — saved plans
2. **Read each file**, examine its frontmatter `type` field (if present) or infer from content
3. **Classify and route** (prefix filenames with `cc-` to indicate Claude Code origin):
   - type=reference or contains reusable pattern → Obsidian `knowledge/patterns/cc-{name}.md`
   - type=feedback or contains "I learned that..." → Obsidian `knowledge/learnings/cc-{name}.md`
   - type=project or contains strategic reasoning → Obsidian `knowledge/decisions/cc-{name}.md`
   - type=project with active status → update Obsidian `projects/{name}.md`
   - Plan file → Obsidian `knowledge/patterns/cc-plan-{name}.md`
4. **Dedup**: Search Obsidian for existing `cc-{name}` notes before creating. Patch if exists.

### Mode 4: Dream (Analyze & Evolve)

**Mode 4 runs on schedule (Sunday 3am UTC via `DREAM_SCHEDULE` cron) or manually. It is not optional hygiene — it is the system preventing its own decay. If it hasn't run in 7+ days, memory health degrades silently: journals pile up unclassified, topics bloat past their limits, expired TTLs accumulate.**

Trigger: Weekly cron OR "memory dream" OR "dream"

1. Read last 7 daily journals from `memory/YYYY-MM-DD.md` (relative to working directory)
2. For each journal entry, classify using the decision logic above → route to `memory/topics/*.md`
3. Prune MEMORY.md: keep ≤15 lines, zero behavioral rules
4. TTL audit: scan all topic files, compare `[YYYY-MM-DD:Nm]` suffix against today's date → flag expired
5. Health check:
   - Topic file > 50 entries → split into sub-topics
   - MEMORY.md > 15 lines → prune immediately
   - Entry > 6 months with no TTL suffix → assign TTL or archive
6. Sync to Obsidian (Mode 2 pull sync)
7. If OpenClaw is configured, ask the user before pushing openclaw-config to git

---

---

## LLM Wiki — Karpathy Reference

> Read this section before implementing any `/memory wiki` command. It is the canonical source of truth for why the wiki works the way it does. The operational details are in `wiki/schema.md`; this section explains the principles behind them.

**Source**: Andrej Karpathy, *llm-wiki* gist (April 4, 2026). 5K+ stars, 3.7K forks within days of publication.
**URL**: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

---

### The Core Insight

Traditional RAG re-derives answers from raw documents on every query — knowledge never accumulates. The LLM Wiki pattern inverts this:

> "Rather than retrieving from raw documents each time, have the LLM incrementally build and maintain a persistent wiki — structured markdown files that synthesize and cross-reference sources."

The wiki is **compiled knowledge**. Like compiled code vs always recompiling from source — the compilation happens once, the cost amortizes across every subsequent query. Cross-references are already built in. Contradictions are already flagged. Synthesis is already done.

**Why human-maintained wikis fail**: The maintenance burden (updating cross-references, noting contradictions, keeping summaries current) grows faster than perceived value. Humans abandon wikis. LLMs don't get bored — they handle 15-file updates in one pass. The human's job becomes curation, direction, and asking the right questions.

---

### Three Layers

Karpathy defines exactly three layers. This is not flexible — the structure is load-bearing:

```
Layer 1 — Raw Sources
  Immutable documents the LLM reads but never modifies.
  PDFs, articles, transcripts, web clips, session notes.
  Ground truth. If something here is wrong, fix it here.

Layer 2 — The Wiki
  LLM-generated and LLM-maintained markdown files.
  Summaries, entity pages, concept pages, syntheses, contradiction flags.
  The LLM owns this entirely.

Layer 3 — The Schema
  A configuration document (CLAUDE.md or equivalent) that tells the LLM
  how to structure and maintain the wiki.
  Updated only intentionally, not automatically.
```

**Why three layers and not two**: The schema layer is what prevents the wiki from drifting. Without explicit operating rules, LLMs make inconsistent structural decisions across sessions. The schema is the contract that makes the wiki coherent over time.

---

### Three Operations

Karpathy specifies exactly three operations. Every `/memory wiki` command maps to one of these:

#### Operation 1: Ingest

> "The LLM reads the source, discusses key takeaways, writes a summary page in the wiki, updates the index, updates relevant entity and concept pages across the wiki, and appends an entry to the log."

**Key behaviors**:
- A single source typically touches **5–15 existing pages** — ingest is not a one-page operation
- The index (`wiki/index.md`) is updated on **every** ingest — it is the operational registry
- The log (`wiki/log.md`) is updated on **every** ingest — it is the audit trail
- Raw sources are marked `<!-- processed: YYYY-MM-DD -->` — idempotency guarantee
- Cross-links are bidirectional — A references B means B must reference A

#### Operation 2: Query

> "You ask questions against the wiki. The LLM searches for relevant pages, reads them, and synthesizes an answer with citations. Answers can take different forms — markdown page, comparison table, slide deck, chart."

**Key behaviors**:
- The LLM reads `wiki/index.md` first to identify relevant pages — not the raw sources
- Citations use `[[wikilink]]` format — verifiable, navigable
- If the answer reveals a knowledge gap: create a stub page and log it as `gap-identified`
- Valuable answers can be filed as new wiki pages — query output compounds the wiki

#### Operation 3: Lint

> "Periodically, ask the LLM to health-check the wiki. Look for: contradictions between pages, stale claims that newer sources have superseded, orphan pages with no inbound links, important concepts mentioned but lacking their own page, missing cross-references, data gaps."

**Key behaviors**:
- Lint is periodic hygiene, not continuous — run it manually or with dream
- **Report only** — lint never auto-deletes or auto-fixes; it presents findings to the user
- Contradictions are surfaced, not resolved — resolution requires human judgment on which source to trust

---

### Special Files

Two files are essential to every wiki. Without them, the wiki degrades:

#### `wiki/index.md` — The Catalog

> "Catalog organized by category with links, one-line summaries, and metadata."

- **Hard limit: ≤30 entries.** This is not a soft guideline — it is a forced curation constraint. When full, the LLM must decide what to prune (least-linked) to add something new. This pressure is what prevents wiki rot.
- Updated on every ingest, every dream, every new page creation.
- If a page is not in `index.md`, it functionally does not exist — the LLM won't find it in a query.
- Format: `- [[page-name]] — one-line summary (type)`

#### `wiki/log.md` — The Audit Trail

> "Append-only chronological record with consistent prefixes: `## [YYYY-MM-DD] operation | Description`"

- Grep-parseable by design: `grep "ingest" wiki/log.md` returns every source ever processed
- Never edited, only appended
- Operations: `init` · `ingest` · `update` · `query` · `lint` · `sync-notion` · `dream` · `gap-identified`
- Example: `## [2026-04-13] ingest | tiered-agent-memory-architecture.md | 7 pages touched`

---

### Why This Works (and When It Doesn't)

**Why it works**:
- Maintenance burden shifts entirely to the LLM — humans only need to drop sources and ask questions
- Knowledge compounds: each ingest enriches existing pages rather than adding isolated documents
- Cross-references are structural: the wiki has topology (graph), not just content (pile of files)
- Echoes Vannevar Bush's 1945 Memex — associative trails through personal knowledge — but solves the maintenance problem Bush couldn't

**Known failure modes** (community consensus from 120+ gist comments):

| Failure mode | Root cause | Fix |
|---|---|---|
| Wiki becomes unreliable | Error accumulation — LLM paraphrases instead of citing | Require `sources:` in every page; lint for missing provenance |
| Pages drift apart | Asymmetric links, no re-synthesis | Bidirectional link rule; periodic dream |
| Index becomes stale | Pages created without updating index | Enforce: index update is part of ingest, not optional |
| Near-duplicates proliferate | No dedup check before creation | Read index.md before creating; merge on dream |
| Confidence inflation | LLM marks everything `high` | Require ≥2 source-refs for `confidence: high` |

---

### Community Extensions (v2 Pattern — rohitg00)

Extends the original with production lessons from building agentmemory:

- **Confidence scoring** — facts weighted by recency and confirmation count
- **Supersession tracking** — contradicted claims marked, not deleted
- **Ebbinghaus forgetting** — stale knowledge deprioritized on queries
- **Schema validation** — `resolver.py` catches malformed frontmatter before it hits the filesystem
- **Event-driven hooks** — auto-ingest on new source drop; auto-lint on schedule
- **Hybrid search at scale** — BM25 + vector + graph traversal fused via RRF (needed beyond ~200 pages)

These are opt-in extensions. The base three-layer pattern is sufficient for most use cases.

---

### Relationship to This Memory System

The wiki is Mode 5 — the output tier of the full memory pipeline:

```
HOT   SESSION-STATE.md (WAL, current session)
  ↓ /memory sync (Modes 1–4)
WARM  memory/topics/*.md + journals
  ↓
COLD  Obsidian vault: knowledge/ + logs/ + projects/
  ↓ /memory wiki ingest --from-memory (Mode 5)
WIKI  wiki/concepts/ + entities/ + sources/   ← LLM compiles from COLD
  ↓ /memory wiki sync notion
OUT   Notion: Pattern Library + Learnings & Insights
```

**The key integration**: `ingest --from-memory` treats recent session digests (`logs/sessions/`) and topic files (`memory/topics/*.md`) as raw sources for the wiki. Every `/memory sync` session potentially feeds the wiki. Knowledge accumulates without extra effort.

**Parallel systems**: `wiki/` runs alongside `knowledge/` — they are not the same system and must never be merged. `knowledge/` is atomic, human-authored, TAXONOMY-governed. `wiki/` is synthetic, LLM-authored, schema.md-governed. They have different granularity, different ownership, different output targets.

---

### Mode 5: Wiki (LLM Wiki — Karpathy Pattern)

**What it is**: A compounding knowledge base in `wiki/` — parallel to TAXONOMY-governed `knowledge/`, not replacing it. Unlike RAG which re-derives answers from raw docs on every query, the wiki compiles knowledge once and keeps it current. The LLM owns all pages in `wiki/`; humans curate sources and ask questions.

**Full schema and operational rules**: `wiki/schema.md` — read before any wiki operation.

**Parallel systems rule**:
| | `knowledge/` | `wiki/` |
|---|---|---|
| Owner | Human | LLM |
| Granularity | Atomic (one concept per note) | Synthesized (cross-source) |
| Schema | TAXONOMY.md | wiki/schema.md |
| Structure | Type + domain folders | Type folders: concepts/entities/sources/comparisons/ |
| Trigger | Human writes | `/memory wiki ingest` |
| Output | Stays in vault | → Notion (Pattern Library + Learnings) |

**Continuous loop**:
```
Sessions (HOT)
  ↓ /memory sync (Modes 1–4)
WARM + COLD (topics/, knowledge/, logs/)
  ↓ /memory wiki ingest --from-memory
wiki/concepts/ + entities/ + sources/
  ↓ /memory wiki sync notion
Notion: Pattern Library + Learnings & Insights
```

---

#### Wiki Frontmatter Schema

Every page in `wiki/` must have:
```yaml
---
title: Page Title
type: concept|entity|source-summary|comparison|synthesis|contradiction
sources: []         # vault paths or wiki/raw/ files that informed this page
related: []         # [[wikilinks]] to other wiki pages (bidirectional)
created: YYYY-MM-DD
updated: YYYY-MM-DD
last_confirmed: YYYY-MM-DD  # date confidence was last verified; lint flags if >90 days old
confidence: high|medium|low
supersedes: ""      # [[page]] this page replaces (if any)
superseded_by: ""   # [[page]] that has replaced this page (set + downgrade to low)
domain: dev|operations|content|marketing|business|ai-agents|identity|product
tags: []
notion-id: ""       # auto-populated by sync notion
notion-url: ""
notion-synced: ""
---
```

**Confidence semantics**:
- `high` — ≥2 sources confirm AND `last_confirmed` ≤90 days old. Ready for Notion sync.
- `medium` — one source, or unverified in >90 days. Needs corroboration before publishing.
- `low` — stub, contradicted, or superseded. Do not publish.

**`last_confirmed` rule**: set to today on every ingest that touches the page. Lint flags `confidence: high` pages where `last_confirmed` > 90 days — downgrade to `medium` pending re-verification.

**Supersession rule**: when a concept evolves, create the new page with `supersedes: [[old-page]]`. On the old page, set `superseded_by: [[new-page]]` and downgrade to `confidence: low`. Do NOT delete — the history of belief changes matters.

**Type → folder**:
| type | folder |
|------|--------|
| concept, synthesis | `concepts/` |
| entity | `entities/` |
| source-summary | `sources/` |
| comparison | `comparisons/` |
| contradiction | `concepts/` (unresolved conflicts) |

---

#### `/memory wiki sync [--full]`

The primary wiki command. Orchestrates the complete pipeline: init → ingest all vault sources in order → Notion publish. Safe to run repeatedly — incremental by default.

**`--full`** flag: reprocesses all sources from scratch, ignoring `<!-- processed:` markers.

**Strategy**: The vault has ~479 notes. This command ingests by **cluster** (MOC-first), not note-by-note. Each cluster becomes 1–3 synthesis pages, not N individual pages. This keeps the wiki as a synthesis layer, not a mirror.

---

**Phase 1 — Init** (always runs)
1. Run `obsidian vault info=path` — confirm vault is reachable
2. Verify `wiki/` folder tree: `{concepts,entities,sources,comparisons,raw/{web-clips,documents,sessions,external}}/`
3. If any folder or file missing: create it (same as `/memory wiki init`)
4. Read `wiki/schema.md` — load operating rules before any write

---

**Phase 2 — Knowledge Graph (Obsidian COLD tier)**

Ingest the vault's `knowledge/` folder by **cluster via MOC**. Read the MOC for each cluster + the 3–5 highest-`agent-use: high` notes per cluster. Do not read every note individually.

```
Source                                 → Wiki target
knowledge/patterns/ai-agents/          → concepts/ai-agent-patterns.md   (update or create)
knowledge/patterns/business/           → concepts/business-patterns.md
knowledge/patterns/content/            → concepts/content-patterns.md
knowledge/patterns/marketing/          → concepts/marketing-patterns.md
knowledge/patterns/technical/          → concepts/technical-patterns.md
knowledge/learnings/                   → sources/vault-learnings.md       (rolling summary)
knowledge/decisions/                   → sources/vault-decisions.md       (rolling summary)
```

Steps per cluster:
1. Read `knowledge/patterns/{cluster}/_*MOC.md` — get cluster landscape
2. Read notes with `agent-use: high` (use `obsidian search` to filter)
3. Create or patch the target concept page: synthesize across all notes, cite top 5 by name in `sources:`
4. Update `[[related]]` cross-links to other concept pages in the same ingest pass

Mark each MOC as `<!-- processed: YYYY-MM-DD -->` on incremental runs to skip on re-run.
On `--full`: ignore `processed` markers, reprocess all clusters.

---

**Phase 3 — Projects**

Ingest `projects/` folder. One entity page per active project.

Steps:
1. Read `projects/_Projects MOC.md` — get full project list with statuses
2. For each project with `status: active` or `status: building`:
   - Read `projects/{name}.md`
   - Create or patch `wiki/entities/{name}.md` with full frontmatter
   - Extract: stack, status, key architecture decisions, relationships to other projects
   - Cross-link to any concept pages that apply (e.g., openclaw.md links to ai-agent-patterns.md)
3. Skip `status: paused`, `archived`, `reference` unless `--full`

---

**Phase 4 — Dev / Identity / Operations**

Ingest supporting vault folders via their MOCs.

```
Source                    Strategy                           → Wiki target
dev/_Dev MOC.md           Read MOC + top stacks/tools        → sources/dev-stack-reference.md
identity/                 Read all identity notes            → entities/neo-identity.md
operations/               Read operational playbooks MOC     → sources/operations-playbooks.md
```

---

**Phase 5 — Memory Tier (`--from-memory`)**

Ingest the HOT/WARM tier — the most recent session knowledge not yet in COLD.

1. Read `memory/topics/*.md` — all topic files
2. Read `logs/sessions/*.md` — last 7 days of session digests
3. Route each insight to the most relevant existing wiki page (patch) or create new if no match
4. Do not create pages for ephemeral session facts — only route insights that would survive TTL

---

**Phase 6 — Raw Sources (`wiki/raw/`)**

Process any unprocessed files dropped into the raw/ subdirs.

1. Scan `wiki/raw/{web-clips,documents,sessions,external}/` for files without `<!-- processed:` header
2. For each unprocessed file: run standard ingest (Phase 2 steps per source)
3. Mark each as `<!-- processed: YYYY-MM-DD -->`

---

**Phase 7 — Finalize**

1. **Rebuild `wiki/overview.md`**: update project landscape, concept cluster map, wiki vs knowledge/ table
2. **Rebuild `wiki/index.md`**: scan all wiki pages, count inbound links per page, keep top ≤30 by inbound-link count
3. **Append to `wiki/log.md`**: `## [YYYY-MM-DD] sync | full-pipeline | [n] pages created | [n] patched | [n] Notion queued`
4. **Update `wiki/sources.md`**: append any newly processed sources to the registry
5. **Notion publish**: run `/memory wiki sync notion` — push all `confidence: high` + `notion-id: ""` + `last_confirmed` ≤90 days pages
   - Skip stale pages (last_confirmed > 90 days); report count in sync report

---

**Phase 7 — Sync Report**

```
Wiki sync complete
──────────────────────────────────────────
Phase 2 (knowledge graph):
  Clusters processed: 7
  Pages created: [n] | patched: [n]

Phase 3 (projects):
  Active projects: [n]
  Entity pages created: [n] | patched: [n]

Phase 4 (dev/identity/operations):
  Sources processed: 3
  Pages created: [n] | patched: [n]

Phase 5 (memory tier):
  Topic files: [n] | Session digests: [n]
  Wiki pages updated: [n]

Phase 6 (raw sources):
  Unprocessed files found: [n]
  Pages created: [n]

Finalize:
  Index: [n]/30 entries
  Notion queue: [n] pages (confidence:high, last_confirmed ≤90d)
  Notion published: [n]
  Confidence stale (skipped Notion): [n] pages

Health: [OK | ALERTS: ...]
──────────────────────────────────────────
```

---

#### `/memory wiki init`
1. Confirm vault path via `obsidian vault info=path`
2. Verify structure: `wiki/{concepts,entities,sources,comparisons,raw/{web-clips,documents,sessions,external}}/`
3. Confirm `wiki/schema.md`, `wiki/index.md`, `wiki/log.md`, `wiki/overview.md` exist
4. Report pages by type, last log entry

#### `/memory wiki ingest [source|--from-memory] [--interactive]`

**`--from-memory`**: reads `logs/sessions/*.md` (last 7 days) + `memory/topics/*.md` as source material.
**`[file]`**: reads specified file from `wiki/raw/` or vault path.
**`[vault-cluster]`**: reads a folder of vault notes as a batch source (e.g., `knowledge/patterns/ai-agents/`).
**`--interactive`**: default for single-source ingests. Presents key takeaways before writing. Batch mode (`--from-memory`, `wiki sync`) is non-interactive.

Steps:
1. Read source(s). Skip any with `<!-- processed: YYYY-MM-DD -->`.
1.5 (**interactive mode only**) Present key takeaways before writing:
   - Summarize 3–5 key insights from the source
   - List which existing wiki pages this source touches
   - Ask: "Any emphasis or angles to focus on? [enter to proceed]"
   - Adjust synthesis based on user direction before writing
   *(Karpathy: "I prefer to ingest sources one at a time and stay involved — I read the summaries, check the updates, and guide the LLM on what to emphasize.")*
2. Read `wiki/index.md` — find existing pages this source touches.
3. For each affected page (5–15 typical):
   - Exists → patch: update body, `updated`, `last_confirmed`, add to `sources:`, note contradictions
   - New → create: full frontmatter (including `last_confirmed: today`), place in correct type folder
4. Bidirectional cross-link: every `related:` entry must link back.
5. Update `wiki/index.md` (≤30 entries — prune least-linked to make room).
6. Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | [source] | [n] pages touched`.
7. Mark source processed: prepend `<!-- processed: YYYY-MM-DD -->`.
8. Append to `wiki/sources.md`: add row `| [source] | [type] | [today] | [today] | [pages touched] |`.

**Ingest rule**: if a page isn't in `wiki/index.md`, it doesn't operationally exist. Always update index.

#### `/memory wiki query [question]`
1. Read `wiki/index.md` → identify 3–5 relevant pages by name
2. Read those pages
3. Synthesize answer with `[[page]]` citations
4. Gap found → create stub page (`confidence: low`), log `gap-identified`
5. Evaluate answer quality for filing:
   - Synthesizes ≥2 wiki pages into a new conclusion → **synthesis** candidate
   - Compares options from ≥2 pages → **comparison** candidate
   - Merely restates one existing page → not a candidate
6. If candidate, offer to file as new wiki page:
   - `type: synthesis` → `concepts/` · `type: comparison` → `comparisons/`
   - `sources:` = the wiki pages read during this query
   - `confidence: medium` (one query session = one source; needs corroboration to reach `high`)
   - `last_confirmed:` today
   - Add to `wiki/index.md` + append to `wiki/log.md` as `query-filed`

*(Karpathy: "good answers can be filed back into the wiki as new pages... This way your explorations compound in the knowledge base just like ingested sources do.")*

#### `/memory wiki sync notion`
1. Find pages: `notion-id: ""` + `confidence: high` + `last_confirmed` ≤90 days old
   - Pages with `confidence: high` but `last_confirmed` > 90 days: skip + report as "confidence stale"
2. Route by type:
   - `concept|entity|synthesis` → **Pattern Library** (`bb55a805-3f8d-4958-8c89-0f353e8572de`)
   - `source-summary|contradiction` → **Learnings & Insights** (`0e411a6b-1367-4e9d-af52-5d2c534cc356`)
3. Property mapping:
   - Pattern Library: `title`→Pattern Name · `domain`→Category · body→Description · `tags`→Projects Used · `created`→Date Discovered
   - Learnings & Insights: `title`→Learning · `domain`→Category · body→Insight · `tags`→Tags · `created`→Date Learned
4. `notion api POST /v1/pages` (create) or `PATCH /v1/pages/{id}` (update existing)
5. Write `notion-id`, `notion-url`, `notion-synced: YYYY-MM-DD` back to frontmatter
6. Append to `wiki/log.md`

#### `/memory wiki lint`
Check and report (never auto-fix):
- Orphan pages not in `wiki/index.md`
- Pages with `updated` > 90 days ago
- Broken `[[wikilinks]]` (target file doesn't exist)
- Raw files without `<!-- processed:` header
- Pages missing `sources:` entries
- Asymmetric `related:` links (A lists B but B doesn't list A)
- **Concept gaps**: `[[wikilink]]` in body text pointing to a non-existent wiki page → "concept mentioned, no page"
- **Confidence staleness**: `confidence: high` + `last_confirmed` > 90 days ago → "confidence unverified"
- **Supersession orphans**: `superseded_by:` points to non-existent page → "broken supersession"
- **Sources registry gaps**: sources in `wiki/raw/` not listed in `wiki/sources.md` → "unregistered raw source"

After the problem report, always output a **Growth Suggestions** section:
```
=== GROWTH SUGGESTIONS ===
Concepts worth creating (mentioned but no page):
  - [[concept-name]] — mentioned in [n] pages
New questions to explore:
  - [LLM-generated questions based on cluster gaps and missing citations]
Sources to investigate:
  - [Suggested sources based on concept gaps]
```
*(Karpathy: "The LLM is good at suggesting new questions to investigate and new sources to look for.")*

#### `/memory wiki dream`
Runs alongside or after `/memory dream`. Steps:
1. Run full lint, present findings
2. Re-synthesize stale pages (check if `sources:` have been updated since `updated` date)
3. Detect contradiction pairs across pages → create `contradiction` typed pages
4. Merge near-duplicates (>80% semantic overlap) → keep richer page, add redirect note to other
5. Rebuild `wiki/index.md` from scratch: scan all pages, rank by inbound-link count, keep ≤30

#### `/memory wiki status`
```
Wiki Status
Pages:   [n] total — concepts:[n] entities:[n] sources:[n] comparisons:[n]
Index:   [n]/30 entries
Queue:   [n] pending Notion sync (confidence:high, notion-id empty)
Stale:   [n] pages not updated in 90+ days
Log:     last — [YYYY-MM-DD] [operation]
Health:  [OK | ALERTS: orphans:[n] broken-links:[n] unprocessed-raw:[n]]
```

---

#### Wiki Design Principles (from Karpathy pattern + production lessons)

1. **Compounding beats retrieval** — the wiki accumulates; RAG re-derives. Both have a place; wiki wins for frequently-accessed synthesis.
2. **index.md is the access gateway** — if a page isn't in index.md (≤30 entries), it functionally doesn't exist. This constraint forces curation.
3. **LLM owns wiki/; humans own knowledge/** — never merge these. TAXONOMY governs knowledge/, wiki/schema.md governs wiki/.
4. **Dedup first, always** — read index.md before creating any page. Patch existing; create new only when genuinely different.
5. **Bidirectional links are load-bearing** — asymmetric links create orphans. Every related: entry must link back.
6. **Confidence gates publishing** — `high` only after ≥2 sources confirm AND `last_confirmed` ≤90 days. Never sync `medium` or `low` to Notion.
7. **log.md enables grep-based archaeology** — `grep "ingest" wiki/log.md` shows every source ever processed.
8. **overview.md is the human entry point** — update it when the wiki's topical coverage shifts significantly.
9. **Query output compounds the wiki** — when a query produces a new synthesis or comparison, file it as a wiki page. Explorations should not disappear into chat history. *(Karpathy's most-emphasized behavior.)*
10. **Confidence must be actively maintained** — `last_confirmed` decays. A page that hasn't been re-verified in 90 days is not `high` confidence, regardless of how many sources it had at creation.

#### Wiki Anti-Patterns

| Anti-pattern | Why it fails |
|---|---|
| Treating wiki as RAG | Defeats compounding; rebuild cost grows with every query |
| Pages too granular | Atomic facts belong in knowledge/; wiki pages should synthesize ≥2 sources |
| Skipping index.md update | Pages become orphans; index is the operational registry |
| One-directional links | Creates disconnected subgraphs; lint will surface these |
| Syncing low/medium confidence | Pollutes Notion with unverified claims |
| wiki/ replaces knowledge/ | They're parallel; knowledge/ is atomic+human, wiki/ is synthetic+LLM |
| Discarding query answers | Valuable syntheses disappear into chat history instead of compounding the wiki |
| Deleting superseded pages | History of belief changes matters; use `superseded_by:` + downgrade to `low` |
| Never re-verifying confidence | `high` without `last_confirmed` is a confidence lie; lint enforces 90-day rule |

---

## `/memory setup` Implementation

When the user runs `/memory setup`:

1. **Detect Obsidian vault**:
   - Check env: `$OBSIDIAN_VAULT_PATH` → use if set
   - Try CLI: `obsidian vault info=path` → use if Obsidian app is running
   - Fallback: read `~/Library/Application Support/obsidian/obsidian.json` (macOS) or `~/.config/obsidian/obsidian.json` (Linux), find the open vault path
   - If none found: ask the user for the vault path

2. **Validate Obsidian CLI**:
   - Run `which obsidian` → confirm binary exists
   - Run `obsidian vault info=name` → confirm app is reachable
   - If CLI missing: inform user to install it, but continue (hooks have filesystem fallback)

3. **Install hooks**:
   - Determine this skill's installation path (the directory containing this SKILL.md)
   - For each hook in `hooks/*.sh`: create symlink at `~/.claude/hooks/{hook-name}.sh` pointing to the skill's `hooks/{hook-name}.sh`
   - If `~/.claude/hooks/` doesn't exist: `mkdir -p ~/.claude/hooks/`
   - If a symlink already exists and points to the same file: skip
   - If a symlink exists pointing elsewhere: warn the user, ask before overwriting

4. **Report setup results**:
   ```
   Memory setup complete
   Vault: /path/to/vault (detected via CLI)
   CLI: obsidian v1.12.7 ✓
   Hooks: 7/7 installed at ~/.claude/hooks/
   ```

---

## `/memory status` Implementation

When the user runs `/memory status`:

1. **HOT tier**: Read `MEMORY.md` → count lines, check for boundary violations
2. **WARM tier**: List `memory/topics/*.md` → count entries per file, flag any over 50
3. **TTL alerts**: Scan topic files for entries with expired `[YYYY-MM-DD:Nm]` suffixes
4. **Last sync**: Read the most recent `memory/YYYY-MM-DD.md` → show date
5. **Vault status**: Run `obsidian vault info=path` and `obsidian files ext=md total` → show stats
6. **Output format**:
   ```
   Memory Status
   HOT:  MEMORY.md (12/15 lines) | SESSION-STATE.md (exists)
   WARM: 4 topic files, 91 total entries
   COLD: Obsidian vault at /path (475 notes)
   TTL:  2 entries expired, 0 missing suffix
   Last sync: 2026-04-09 (Mode 1)
   Health: OK
   ```

---

## `/memory audit` Implementation

When the user runs `/memory audit`:

1. **Boundary test**: `grep -c "NEVER\|ALWAYS\|must\|rule" MEMORY.md` → must return 0. If not: list violations.
2. **TTL audit**: For each entry in `memory/topics/*.md`:
   - Parse the `[YYYY-MM-DD:Nm]` suffix
   - If today > (date + N months): flag as expired
   - If entry has no suffix and is older than 6 months: flag as missing TTL
3. **Size audit**: Check each topic file for >50 entries. Check MEMORY.md for >15 lines.
4. **Report**: List all flagged entries with their file and line number. Do NOT auto-delete — present findings to the user for decision.

---

## Session Hooks

These hooks fire automatically on Claude Code session lifecycle events. Install via `/memory setup` or manually symlink from this repo's `hooks/` directory.

| Hook | Event | What It Does |
|------|-------|-------------|
| `session-start-vault.sh` | SessionStart | Injects vault awareness: path, note count, journal count |
| `pre-compact-vault.sh` | PreCompact | Appends SESSION-STATE to vault daily journal before compaction |
| `session-stop-vault.sh` | Stop | Flushes session state to vault + `~/.claude/compaction-state/latest.md` |
| `agent-start.sh` | SubagentStart | Increments `/tmp/claude-agents-count` |
| `agent-stop.sh` | SubagentStop | Decrements `/tmp/claude-agents-count` |
| `compact-notification.sh` | Notification (compact) | Prints vault stats + SESSION-STATE preview |
| `force-mcp-connectors.sh` | SessionStart (utility) | Force-enables MCP connectors flag |

---

## Obsidian Integration

**Dependency**: Obsidian CLI v1.12.7+ (`/usr/local/bin/obsidian`) with Obsidian app running.

### Key CLI Commands

```bash
obsidian vault info=path          # Get vault path
obsidian daily:append content=""  # Append to daily journal
obsidian search query="" limit=10 # Search vault notes
obsidian read path=""             # Read a specific note
obsidian create name="" path="" content=""  # Create note
obsidian files folder="" ext=md   # List files
obsidian tags counts sort=count   # List tags
```

### Vault Folder Map

| Content | Folder | Tier |
|---------|--------|------|
| Reusable patterns | `knowledge/patterns/` | COLD |
| Learnings & gotchas | `knowledge/learnings/` | COLD |
| Strategic decisions | `knowledge/decisions/` | COLD |
| Daily journals | `logs/journals/` | WARM→COLD |
| Session digests | `logs/sessions/` | COLD |
| Project status | `projects/` | WARM |
| Identity docs | `identity/` | HOT-equivalent |
| Stack references | `dev/stacks/` | COLD |
| Operational playbooks | `operations/` | COLD |
| **LLM Wiki** | **`wiki/`** | **WIKI (Mode 5)** |
| Wiki agent contract | `wiki/schema.md` | WIKI |
| Wiki master catalog | `wiki/index.md` (≤30 entries) | WIKI |
| Wiki operations log | `wiki/log.md` (append-only) | WIKI |
| Wiki synthesis entry | `wiki/overview.md` | WIKI |
| Raw sources (immutable) | `wiki/raw/{web-clips,documents,sessions,external}/` | WIKI |
| Compiled concept pages | `wiki/concepts/` | WIKI |
| Compiled entity pages | `wiki/entities/` | WIKI |
| Per-source summaries | `wiki/sources/` | WIKI |
| Option comparisons | `wiki/comparisons/` | WIKI |

### Obsidian Frontmatter Schema

All vault notes must conform to this schema (defined in your vault's `knowledge/TAXONOMY.md`):

```yaml
---
type: pattern|learning|decision|journal|session-digest|project|moc|reference|identity|operations
status: active|draft|archived
agent-use: high|medium|low
use-when: "comma-separated keywords"
summary: "one-line description"
tags: [tag1, tag2]        # YAML array, kebab-case
domain: dev|operations|content|marketing|business|ai-agents|identity|product
created: 'YYYY-MM-DD'
source: "origin"           # optional
---
```

---

## Sync Report Format

Every sync operation outputs a structured report:

```
Memory sync complete
Mode: [1 session | 2 openclaw-pull | 3 cc-project | 4 dream | 5 wiki]
Topic files updated: X entries across Y files
Obsidian: X patterns, Y decisions, Z learnings, N journals
SESSION-STATE: flushed to memory/YYYY-MM-DD.md
TTL: X entries reviewed, Y archived
Skipped (duplicates): N
Wiki: [X pages created | Y pages patched | Z queued for Notion] (Mode 5 only)
Health: [OK | ALERTS: ...]
```

---

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `OBSIDIAN_VAULT_PATH` | Absolute path to Obsidian vault | Auto-detected if app running |
| `OBSIDIAN_CLI_PATH` | Path to obsidian CLI binary | `/usr/local/bin/obsidian` |
| `OPENCLAW_CONFIG_PATH` | Path to openclaw-config repo | None (Mode 2 only) |
| `MEMORY_ROUTER_MAX_LINES` | Max lines in MEMORY.md router | 15 |
| `MEMORY_TOPIC_MAX_ENTRIES` | Max entries per topic file | 50 |
| `DREAM_SCHEDULE` | Cron expression for weekly consolidation | `0 3 * * 0` |

---

## Runtime Principles

1. **Obsidian vault is the single source of truth** — all platforms sync to it, never away from it
2. **WAL-first** — write SESSION-STATE.md BEFORE responding, not after
3. **MEMORY.md = facts only. AGENTS.md = rules only** — boundary test enforced
4. **Every entry decays** — TTL is mandatory, permanent is an explicit choice
5. **Dedup before writing** — search existing content, patch or skip, never duplicate
6. **The system reports what it did** — sync reports are structured, not silent
7. **wiki/ is parallel to knowledge/, not a replacement** — knowledge/ is atomic+human-curated; wiki/ is synthetic+LLM-compiled. Never merge them.
8. **index.md gates wiki access** — if a wiki page isn't in wiki/index.md (≤30 entries), it doesn't operationally exist
9. **Confidence gates Notion publishing** — only `confidence: high` pages sync to Notion; unverified claims stay in the vault
