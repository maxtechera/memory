---
name: memory
version: "1.0.0"
description: "Cross-platform memory system. 3-tier architecture, vault sync, session hooks, weekly consolidation."
argument-hint: 'memory sync, memory status, memory dream, memory setup, memory audit'
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

Cross-platform memory system for AI agents. 3-tier architecture (HOT/WARM/COLD), Obsidian vault sync, session hooks, and weekly consolidation. Your agents forget everything between sessions — this fixes that.

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
Mode: [1 session | 2 openclaw-pull | 3 cc-project | 4 dream]
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
| `DREAM_SCHEDULE` | Cron expression for weekly consolidation | `0 3 * * 0` |

---

## Runtime Principles

1. **Obsidian vault is the single source of truth** — all platforms sync to it, never away from it
2. **WAL-first** — write SESSION-STATE.md BEFORE responding, not after
3. **MEMORY.md = facts only. AGENTS.md = rules only** — boundary test enforced
4. **Every entry decays** — TTL is mandatory, permanent is an explicit choice
5. **Dedup before writing** — search existing content, patch or skip, never duplicate
6. **The system reports what it did** — sync reports are structured, not silent
