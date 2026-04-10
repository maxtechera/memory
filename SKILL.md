---
name: memory
version: "1.0.0"
description: "Cross-platform memory system. 3-tier architecture, vault sync, session hooks, weekly consolidation."
argument-hint: 'memory sync, memory status, memory rem-sleep, memory setup, memory audit'
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
  - run REM sleep
  - rem sleep
  - memory audit
metadata:
  openclaw:
    emoji: "🧠"
    optionalEnv:
      - OBSIDIAN_VAULT_PATH
      - OBSIDIAN_CLI_PATH
      - OPENCLAW_CONFIG_PATH
      - MEMORY_ROUTER_MAX_LINES
      - MEMORY_TOPIC_MAX_ENTRIES
      - REM_SLEEP_SCHEDULE
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

Cross-platform memory system for AI agents. 3-tier architecture (HOT/WARM/COLD), Obsidian vault sync, session hooks, and weekly consolidation. Your agents forget everything between sessions — this fixes that.

---

## Commands

| Command | Description |
|---------|-------------|
| `/memory sync` | Sync current session to memory (Mode 1) |
| `/memory sync openclaw` | Pull OpenClaw journals into Obsidian (Mode 2) |
| `/memory sync projects` | Sync Claude Code project memory to Obsidian (Mode 3) |
| `/memory rem-sleep` | Weekly consolidation: journals→topics, prune, TTL audit (Mode 4) |
| `/memory status` | Memory health: tier sizes, TTL alerts, last sync times |
| `/memory setup` | Configure vault path, detect platforms, install hooks |
| `/memory audit` | TTL audit + boundary check + health alerts |

---

## Memory Architecture

```
HOT   ≤2400tok, always loaded
  MEMORY.md          = router (identity, focus, project index, topic pointers)
  SESSION-STATE.md   = WAL hot RAM (current task, decisions, pending actions)

WARM  on-demand read when domain is relevant
  memory/topics/*.md   domain-scoped facts with TTL
  memory/YYYY-MM-DD.md daily journals (last 7 days)

COLD  search-only, permanent
  Obsidian vault     knowledge/, logs/, projects/, identity/, dev/
```

**Sync direction**: Session → HOT → WARM → COLD (Obsidian).
OpenClaw writes independently to `openclaw-config/memory/` → synced to Obsidian via Mode 2.

### Tier Rules

| Tier | Token Budget | Read Pattern | Write Pattern |
|------|-------------|--------------|---------------|
| HOT | ≤2400 tokens | Always loaded | Write-before-respond (WAL) |
| WARM | On-demand | Read when domain matches | Append with TTL suffix |
| COLD | Search-only | `obsidian search` → read | Create/patch via Obsidian CLI |

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

1. **Update SESSION-STATE.md** (WAL) — if significant fact/decision surfaced
2. **Classify each insight**:
   - Platform/infra fact → `memory/topics/infra.md`
   - Project fact → `memory/topics/{project}.md`
   - Tool/credential → `memory/topics/tools-creds.md`
   - Pattern (reusable) → Obsidian `knowledge/patterns/`
   - Decision (strategic) → Obsidian `knowledge/decisions/`
   - Learning (one-time) → Obsidian `knowledge/learnings/`
   - Daily event → `memory/YYYY-MM-DD.md` + Obsidian `logs/journals/`
   - Behavioral rule → `AGENTS.md` (NEVER to MEMORY.md)
3. **Dedup before writing** — read target, check >80% match, update in-place or append
4. **Add TTL suffix** to topic entries
5. **Keep MEMORY.md as router** — never grows, only pointers

### Mode 2: OpenClaw → Obsidian Pull Sync

Trigger: "sync openclaw" / "pull openclaw memory"

1. Discover new journals in `openclaw-config/memory/`
2. Read + clean (strip raw metadata, keep insights)
3. Write to Obsidian `logs/journals/YYYY-MM-DD.md` with proper frontmatter
4. Sync topic files → Obsidian `knowledge/learnings/`

### Mode 3: Claude Code Project Memory → Obsidian

Trigger: "sync claude code memory" / "sync projects"

1. Scan `~/.claude/projects/*/memory/*.md` and `~/.claude/plans/*.md`
2. Classify and route:
   - pattern → `knowledge/patterns/cc-{name}.md`
   - learning → `knowledge/learnings/cc-{name}.md`
   - decision → `knowledge/decisions/cc-{name}.md`
   - project → update `projects/{name}.md`
   - plan → `knowledge/patterns/cc-plan-{name}.md`
3. Prefix all vault notes with `cc-` to indicate Claude Code origin

### Mode 4: REM Sleep (Weekly Consolidation)

Trigger: Weekly cron OR "run REM sleep"

1. Read last 7 daily journals
2. Extract insights → classify → route to `memory/topics/*.md`
3. Prune MEMORY.md: keep ≤15 lines, zero behavioral rules
4. TTL audit: scan all topic files for entries past review date → flag or archive
5. Health check:
   - Topic file > 50 entries → split into sub-topics
   - MEMORY.md > 15 lines → prune immediately
   - Entry > 6 months with no TTL suffix → assign TTL or archive
6. Sync to Obsidian (Mode 2 pull sync)
7. Push openclaw-config to git

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

### Obsidian Frontmatter Schema

All vault notes must conform to `knowledge/TAXONOMY.md`:

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
Mode: [1 session | 2 openclaw-pull | 3 cc-project | 4 REM-sleep]
Topic files updated: X entries across Y files
Obsidian: X patterns, Y decisions, Z learnings, N journals
SESSION-STATE: flushed to memory/YYYY-MM-DD.md
TTL: X entries reviewed, Y archived
Skipped (duplicates): N
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
| `REM_SLEEP_SCHEDULE` | Cron expression for weekly consolidation | `0 3 * * 0` |

---

## Runtime Principles

1. **Obsidian vault is the single source of truth** — all platforms sync to it, never away from it
2. **WAL-first** — write SESSION-STATE.md BEFORE responding, not after
3. **MEMORY.md = facts only. AGENTS.md = rules only** — boundary test enforced
4. **Every entry decays** — TTL is mandatory, permanent is an explicit choice
5. **Dedup before writing** — search existing content, patch or skip, never duplicate
6. **The system reports what it did** — sync reports are structured, not silent
