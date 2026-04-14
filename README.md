# /memory

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](CHANGELOG.md)

**Your AI agents forget everything between sessions. Memory fixes that.**

Claude Code:
```
/plugin marketplace add maxtechera/memory
```

OpenClaw:
```
clawhub install memory
```

Run `/memory setup` once — session hooks fire automatically after that.

---

Session hooks capture what your agent learns — decisions, preferences, context — and persist it across compactions and session boundaries. Your next session picks up where the last one left off.

**Requires**: [Obsidian](https://obsidian.md) with the Obsidian CLI (v1.12.7+) for long-term vault storage. Without Obsidian, hooks still save session state locally to `~/.claude/compaction-state/`.

## What people use it for

**Picking up where you left off.** Start a session, your agent already knows what you were working on, what decisions were made last week, and what the user prefers. No re-briefing, no context dump.

**Running long projects.** The WAL protocol captures decisions as they happen. Compaction events flush them to the vault. A month later you can ask "what did we decide about the auth system?" and get the answer.

**Cross-platform context.** Work in Claude Code on your Mac, switch to OpenClaw in a container, pick up in Gemini CLI. Memory syncs the HOT/WARM/COLD tiers across all of them via Obsidian vault or OpenClaw journals.

**Reducing token spend.** Instead of re-loading full project context every session, Memory surfaces only what's relevant. HOT memory (active session) stays tiny. WARM and COLD tiers are queried on demand.

---

## Install

### Claude Code

#### Install
```
/plugin marketplace add maxtechera/memory
```

#### Update
```
claude plugin update memory@memory-skill
```

### OpenClaw
```bash
clawhub install memory
```

### Manual
```bash
git clone https://github.com/maxtechera/memory.git ~/.claude/skills/memory
```

---

## Setup

### Level 0: Run Setup

After installing, run the setup wizard:

```
/memory setup
```

This detects your Obsidian vault, symlinks the session hooks to `~/.claude/hooks/`, and validates the CLI. Once setup completes, hooks fire automatically on every session — no manual invocation needed.

### Level 1: Connect Obsidian Vault

If auto-detection fails (e.g., Obsidian app isn't running), set the vault path manually in your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export OBSIDIAN_VAULT_PATH="$HOME/Documents/my-vault"
```

**Requires**: [Obsidian CLI](https://obsidian.md) v1.12.7+ installed and Obsidian app running for search/create operations. Without it, hooks fall back to direct filesystem writes.

### Level 2: Enable OpenClaw Sync (Optional)

**Skip this if you don't use OpenClaw.** This level is only for users running OpenClaw on Railway who want cross-platform journal sync.

```bash
export OPENCLAW_CONFIG_PATH="/path/to/openclaw-config"
```

This enables `/memory sync openclaw` to pull OpenClaw journals into your vault.

### Level 3: Dream (Analyze & Evolve)

The dream cycle analyzes your memory, consolidates insights, prunes old entries, and audits TTL decay. Trigger manually anytime:

```
/memory dream
```

Or set a cron schedule (Sunday 3am = `0 3 * * 0`) in your shell profile:

```bash
export DREAM_SCHEDULE="0 3 * * 0"
```

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

## How It Works

### How Hooks Connect the Agent to Memory

Claude Code fires lifecycle events — SessionStart, PreCompact, Stop, SubagentStart, SubagentStop — and hooks run shell scripts in response. The scripts' stdout is injected directly into the agent's context as a `system-reminder`. This is how memory reaches the agent without any manual invocation.

**Session lifecycle:**

```
SessionStart
  └─ session-start-vault.sh → injects vault stats (path, note count, journals)
     ↓ agent reads MEMORY.md router (HOT, always loaded)
     ↓ agent queries topics/*.md on demand (WARM)
     ↓ agent searches Obsidian vault on demand (COLD)

During session
  └─ agent writes SESSION-STATE.md before responding (WAL protocol)

PreCompact
  └─ pre-compact-vault.sh → flushes SESSION-STATE to vault daily journal

Stop
  └─ session-stop-vault.sh → final flush to vault + ~/.claude/compaction-state/latest.md
```

**Subagent context injection:**

Every spawned subagent gets memory context automatically via `SubagentStart → agent-start.sh`. The hook reads from the parent session and injects:

```
## Agent Memory Context
### Run Reference        ← ship run ID from .ship-run file or $SHIP_RUN_ID
### Parent Session Task  ← current task from SESSION-STATE.md
### Memory Router        ← MEMORY.md index (first 40 lines)
### WARM Topics          ← list of available memory/topics/*.md files
### Memory Access        ← HOT/WARM/COLD query patterns
```

This means every subagent starts with: who it belongs to (run ID), what the parent was doing, where to find more context — without the parent needing to re-brief it.

**Run ID propagation (multi-agent runs):**

When a ship run starts, the engine writes the run ID to `.ship-run` in the working directory. Every subagent spawned in that directory picks it up automatically:

```bash
# Written at run start:
echo "ship-ABC-123" > .ship-run

# Read by agent-start.sh (priority order):
1. $SHIP_RUN_ID env var
2. .ship-run file in $PWD
3. SESSION-STATE.md grep fallback
```

No manual plumbing. The hook does the wiring.

### The 3 Tiers

```
HOT   ≤2400tok, always loaded
  MEMORY.md         = router (pointers to topic files)
  SESSION-STATE.md  = WAL (current task, decisions, pending)

WARM  on-demand, domain-scoped
  memory/topics/*.md  facts with TTL decay
  memory/YYYY-MM-DD.md  daily journals

COLD  permanent, search-only
  Obsidian vault    knowledge/ logs/ projects/ identity/
```

### Sync: 3 Steps

1. **Detect** — Find what changed (new session state, stale journals, TTL expirations)
2. **Classify & Route** — Each insight goes to the right tier: fact → topics, pattern → vault, rule → AGENTS.md
3. **Write with Proof** — Structured sync report shows exactly what was written, skipped, or flagged

### Cross-Platform Architecture

```
┌────────────────────────────────────────────┐
│            OBSIDIAN VAULT                   │
│        (Single Source of Truth)             │
│  knowledge/ | logs/ | projects/ | identity/ │
└──────────────────┬─────────────────────────┘
                   │ writes via Obsidian CLI
      ┌────────────┼────────────┐
      │            │            │
┌─────┴─────┐ ┌───┴──┐  ┌─────┴──────┐
│ Claude    │ │ Open │  │  OpenClaw   │
│ Code      │ │ + hooks│  │ (Railway)   │
│ + hooks   │ │      │  │ git → local │
└───────────┘ └──────┘  └────────────┘
```

---

## Session Hooks

Hooks fire automatically on Claude Code lifecycle events. No manual invocation needed.

| Hook | When | What It Does |
|------|------|-------------|
| `session-start-vault.sh` | Session starts | Injects vault awareness: path, note count, journal count |
| `pre-compact-vault.sh` | Before compaction | Appends SESSION-STATE to vault daily journal |
| `session-stop-vault.sh` | Session ends | Flushes state to vault + `~/.claude/compaction-state/latest.md` |
| `agent-start.sh` | Subagent spawned | Injects run ID, parent task, MEMORY.md router, WARM topics into subagent context |
| `agent-stop.sh` | Subagent finished | Decrements agent counter |
| `compact-notification.sh` | After compaction | Prints vault stats + session state preview |
| `force-mcp-connectors.sh` | Session starts | Force-enables MCP connectors flag |

### Manual Hook Installation

If not using `/memory setup`:

```bash
# Replace /path/to/memory with your actual install path
MEMORY_DIR="/path/to/memory"  # e.g., ~/.claude/skills/memory
for hook in session-start-vault.sh pre-compact-vault.sh session-stop-vault.sh \
            agent-start.sh agent-stop.sh compact-notification.sh force-mcp-connectors.sh; do
  ln -sf "$MEMORY_DIR/hooks/$hook" ~/.claude/hooks/
done
```

Then add the following to the `"hooks"` key in `~/.claude/settings.json`. If a `hooks` key already exists, merge the events below into the existing structure — do not replace the whole file.

```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [
      {"type": "command", "command": "bash ~/.claude/hooks/session-start-vault.sh"},
      {"type": "command", "command": "bash ~/.claude/hooks/force-mcp-connectors.sh"}
    ]}],
    "PreCompact": [{ "hooks": [
      {"type": "command", "command": "bash ~/.claude/hooks/pre-compact-vault.sh"}
    ]}],
    "Stop": [{ "hooks": [
      {"type": "command", "command": "bash ~/.claude/hooks/session-stop-vault.sh", "async": true}
    ]}],
    "SubagentStart": [{ "hooks": [
      {"type": "command", "command": "bash ~/.claude/hooks/agent-start.sh", "async": true}
    ]}],
    "SubagentStop": [{ "hooks": [
      {"type": "command", "command": "bash ~/.claude/hooks/agent-stop.sh", "async": true}
    ]}],
    "Notification": [{ "matcher": "compact", "hooks": [
      {"type": "command", "command": "bash ~/.claude/hooks/compact-notification.sh"}
    ]}]
  }
}
```

Note: `~/.claude/hooks/` must exist. If it doesn't: `mkdir -p ~/.claude/hooks`. The `/memory setup` wizard creates this directory and symlinks the hooks automatically — manual installation is only needed if you skipped the wizard.

---

## Your First Sync

After setup, work normally in a Claude Code session. When you're ready to save what you learned:

```
/memory sync
```

Example output:

```
Memory sync complete
Mode: 1 session
Topic files updated: 2 entries across 1 file
Obsidian: 0 patterns, 1 decision, 0 learnings, 1 journal
SESSION-STATE: flushed to memory/2026-04-10.md
TTL: 0 entries reviewed, 0 archived
Skipped (duplicates): 0
Health: OK
```

**What happened**: The agent classified your session insights, wrote facts to topic files (with TTL decay), synced decisions to your Obsidian vault, and created a daily journal entry. Your next session will have access to everything you saved.

---

## 5 Sync Modes

| Mode | Command | What It Syncs | Direction |
|------|---------|---------------|-----------|
| 1 | `/memory sync` | Current session insights | Session → WARM → COLD |
| 2 | `/memory sync openclaw` | OpenClaw journals | OpenClaw → Obsidian |
| 3 | `/memory sync projects` | CC project memory files | `~/.claude/projects/` → Obsidian |
| 4 | `/memory dream` | Everything + consolidation | All tiers + prune + TTL audit |
| 5 | `/memory wiki sync` | Vault → compiled wiki → Notion | COLD → WIKI → Notion |

---

## LLM Wiki (Mode 5)

The wiki is a compounding knowledge base — compiled once from your vault sources, maintained by the LLM, published to Notion. Unlike RAG (which re-derives answers from raw docs every time), the wiki synthesizes knowledge into structured pages. You drop sources, run `/memory wiki sync`, and the wiki gets smarter over time.

```
Sessions → /memory sync → /memory wiki ingest --from-memory → /memory wiki sync notion → Notion
```

**Two parallel knowledge systems** — they never merge:

| System | Location | Authored by | Governed by |
|--------|----------|-------------|-------------|
| Vault | `knowledge/` | Human | TAXONOMY.md |
| Wiki | `wiki/` | LLM | `wiki/schema.md` |

The wiki feeds from your COLD tier (vault) and publishes outward to Notion. Index pages are curated to ≤30 entries — pages not in `index.md` don't operationally exist.

**The continuous loop:**

1. `/memory sync` — session insights → vault (COLD)
2. `/memory wiki ingest --from-memory` — vault topics + session digests → wiki pages
3. `/memory wiki sync notion` — publish-ready pages → Notion

**Cross-repo:** Orchestrator domain skills invoke `/memory sync` at ticket completion to persist execution learnings into the wiki. Over time the wiki builds a knowledge graph of what worked, what failed, and why — across every domain.

Full operational spec in SKILL.md — Mode 5 section.

---

## Memory Boundary Rules

The most important rule: **MEMORY.md contains facts. AGENTS.md contains rules. Never mix them.**

| File | Contains | Never Contains |
|------|----------|----------------|
| `MEMORY.md` | Facts, project index, pointers | Rules, instructions |
| `AGENTS.md` | Behavioral rules, policies | Facts, configs |
| `SESSION-STATE.md` | Live context, WAL entries | Long-term facts |
| `memory/topics/*.md` | Domain facts with TTL | Rules |
| Obsidian `knowledge/` | Patterns, decisions, learnings | Ephemeral session data |

**Boundary test**: `grep -c "NEVER\|ALWAYS\|must\|rule" MEMORY.md` must return 0.

---

## TTL Decay

Every memory entry has a shelf life:

| Class | Suffix | Default TTL | Example |
|-------|--------|-------------|---------|
| permanent | (no suffix) | forever | Core architecture decisions |
| operational | `[date:6m]` | 6 months | API versions, tool configs |
| project | `[date:3m]` | 3 months | Project-specific facts |
| session | `[date:1m]` | 30 days | Research notes, citations |

Dream (Mode 4) audits TTLs weekly and flags expired entries.

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

## What This Repo Contains

```
memory/
├── SKILL.md              # The skill — agents read this
├── WORKFLOW.md           # 5-stage sync lifecycle
├── README.md             # You are here
├── hooks/                # 7 session lifecycle hooks
├── docs/
│   ├── VISION.md         # Vision deck
│   ├── STATE_MACHINE.md  # Sync state transitions
│   ├── ARCHITECTURE.md   # 3-tier memory reference
│   └── SYNC_PROTOCOL.md  # Cross-platform contract
├── examples/             # Sync examples and reports
├── .claude-plugin/       # Claude Code marketplace manifests
├── .codex-plugin/        # Codex CLI discovery
├── .agents/              # OpenCode/OpenClaw skill discovery
├── gemini-extension.json # Gemini CLI manifest
├── .env.example          # All configuration variables
├── .clawhubignore        # Distribution exclusions
└── .github/workflows/    # CI validation + release
```

---

## Principles

1. **Vault is the single source of truth** — all platforms sync to Obsidian
2. **WAL-first** — write session state before responding
3. **Facts and rules never mix** — MEMORY.md ≠ AGENTS.md
4. **Everything decays** — TTL is mandatory, permanent is explicit
5. **Dedup before write** — search, patch, or skip
6. **Report what you did** — structured output, not silent writes

---

## License

MIT — see [LICENSE](LICENSE).

Maintained by [maxtechera](https://github.com/maxtechera).
