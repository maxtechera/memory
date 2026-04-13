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

### Mode 5: Wiki (LLM Wiki — Karpathy Pattern)

**What it is**: A compounding knowledge base in `wiki/` — parallel to TAXONOMY-governed `knowledge/`, not replacing it. Unlike RAG which re-derives answers from raw docs on every query, the wiki compiles knowledge once and keeps it current. The LLM owns all pages in `wiki/`; humans curate sources and ask questions.

**Based on**: Andrej Karpathy's llm-wiki gist (April 2026, 5K+ stars). Full schema in `wiki/schema.md`.

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
confidence: high|medium|low
domain: dev|operations|content|marketing|business|ai-agents|identity|product
tags: []
notion-id: ""       # auto-populated by sync notion
notion-url: ""
notion-synced: ""
---
```

**Confidence semantics**:
- `high` — multiple sources confirm, ready for Notion sync
- `medium` — one source, needs corroboration before publishing
- `low` — stub or contradicted, needs investigation

**Type → folder**:
| type | folder |
|------|--------|
| concept, synthesis | `concepts/` |
| entity | `entities/` |
| source-summary | `sources/` |
| comparison | `comparisons/` |
| contradiction | `concepts/` (unresolved conflicts) |

---

#### `/memory wiki init`
1. Confirm vault path via `obsidian vault info=path`
2. Verify structure: `wiki/{concepts,entities,sources,comparisons,raw/{web-clips,documents,sessions,external}}/`
3. Confirm `wiki/schema.md`, `wiki/index.md`, `wiki/log.md`, `wiki/overview.md` exist
4. Report pages by type, last log entry

#### `/memory wiki ingest [source|--from-memory]`

**`--from-memory`**: reads `logs/sessions/*.md` (last 7 days) + `memory/topics/*.md` as source material.
**`[file]`**: reads specified file from `wiki/raw/` or vault path.
**`[vault-cluster]`**: reads a folder of vault notes as a batch source (e.g., `knowledge/patterns/ai-agents/`).

Steps:
1. Read source(s). Skip any with `<!-- processed: YYYY-MM-DD -->`.
2. Read `wiki/index.md` — find existing pages this source touches.
3. For each affected page (5–15 typical):
   - Exists → patch: update body, `updated`, add to `sources:`, note contradictions
   - New → create: full frontmatter, place in correct type folder
4. Bidirectional cross-link: every `related:` entry must link back.
5. Update `wiki/index.md` (≤30 entries — prune least-linked to make room).
6. Append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | [source] | [n] pages touched`.
7. Mark source processed: prepend `<!-- processed: YYYY-MM-DD -->`.

**Ingest rule**: if a page isn't in `wiki/index.md`, it doesn't operationally exist. Always update index.

#### `/memory wiki query [question]`
1. Read `wiki/index.md` → identify 3–5 relevant pages by name
2. Read those pages
3. Synthesize answer with `[[page]]` citations
4. Gap found → create stub page (`confidence: low`), log `gap-identified`
5. Valuable answer → offer to file as new `synthesis` page

#### `/memory wiki sync notion`
1. Find pages: `notion-id: ""` + `confidence: high`
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
6. **Confidence gates publishing** — `high` only after ≥2 sources confirm. Never sync `medium` or `low` to Notion.
7. **log.md enables grep-based archaeology** — `grep "ingest" wiki/log.md` shows every source ever processed.
8. **overview.md is the human entry point** — update it when the wiki's topical coverage shifts significantly.

#### Wiki Anti-Patterns

| Anti-pattern | Why it fails |
|---|---|
| Treating wiki as RAG | Defeats compounding; rebuild cost grows with every query |
| Pages too granular | Atomic facts belong in knowledge/; wiki pages should synthesize ≥2 sources |
| Skipping index.md update | Pages become orphans; index is the operational registry |
| One-directional links | Creates disconnected subgraphs; lint will surface these |
| Syncing low/medium confidence | Pollutes Notion with unverified claims |
| wiki/ replaces knowledge/ | They're parallel; knowledge/ is atomic+human, wiki/ is synthetic+LLM |

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
