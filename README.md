# /memory — Persistent Memory & Second Brain for AI Agents

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](CHANGELOG.md)

**Your AI agent has amnesia. Every session starts from zero. This fixes it.**

Context engineering for Claude Code, OpenClaw, and Gemini CLI — a 3-tier persistent memory system (HOT/WARM/COLD) backed by your Obsidian vault. Session hooks capture what your agent learns automatically. Your second brain grows with every session.

Claude Code:
```
/plugin marketplace add maxtechera/memory
```

OpenClaw:
```
clawhub install memory
```

Run `/memory setup` once — hooks fire on every session after that. No manual invocation ever.

---

## The problem: AI agent amnesia

LLMs are stateless. Every time you start a new session, your agent has forgotten everything — your preferences, past decisions, project context, what you built last week. You re-explain. It re-learns. You pay the token cost. Every. Single. Session.

This is the **AI amnesia tax**: wasted tokens, wasted time, degraded output quality because the agent is always catching up.

**Memory solves it** with session hooks that automatically capture what matters and a tiered architecture that loads only what's relevant — so your agent picks up exactly where it left off, without you doing anything.

**Requires**: [Obsidian](https://obsidian.md) with the Obsidian CLI (v1.12.7+) for long-term vault storage. Without Obsidian, hooks still save session state locally to `~/.claude/compaction-state/`.

---

## Why a 3-tier architecture, not a vector database

Most agent memory tools reach for a vector DB and call it done. Memory uses a tiered approach inspired by how operating systems manage memory — because not all context is equal:

```
HOT   Always in context — tiny, always loaded (≤2400 tokens)
WARM  Loaded on demand — domain facts, expire over time
COLD  Searched, never fully loaded — permanent knowledge in Obsidian vault
```

Your agent reads HOT on every session. It pulls WARM files when it needs domain context. It searches COLD when it needs something older. **No embeddings. No cloud dependency. No ongoing cost.** Just markdown files and your existing Obsidian vault.

| | /memory | Mem0 / Letta / Zep | Vector DB solutions |
|---|---|---|---|
| Storage | Markdown + Obsidian | Cloud API / hosted | Vector embeddings |
| Cost | Free | Paid API | Infrastructure cost |
| Privacy | 100% local | Cloud | Cloud |
| Cross-platform | Claude Code + OpenClaw + Gemini CLI | Framework-specific | Framework-specific |
| LLM wiki built-in | Yes (Karpathy pattern) | No | No |
| Setup | One command | SDK integration | Infrastructure setup |

---

## What people use it for

**Eliminating re-briefing.** Start a session, your agent already knows what you were working on, what decisions were made last week, what you prefer. Zero context dump required.

**Long-horizon projects.** The WAL protocol captures decisions as they happen. Compaction events flush them to the vault. A month later you can ask "what did we decide about the auth system?" and get the answer.

**Context engineering at scale.** Instead of packing a prompt with everything, Memory surfaces only what's relevant. HOT memory stays tiny. WARM and COLD tiers load on demand. Up to 71x fewer tokens per session.

**Cross-platform second brain.** Work in Claude Code on your Mac, switch to OpenClaw in a container, pick up in Gemini CLI. Memory syncs across all of them via your Obsidian vault — one source of truth, every platform.

**LLM wiki that compounds.** Every `/memory sync` feeds your Obsidian-backed knowledge graph and updates your LLM wiki (Karpathy pattern) — a structured, queryable second brain that gets smarter with every session.

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

This enables `/memory sync` to include OpenClaw journals automatically.

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
| `/memory sync` | Save everything to memory — all sources, all tiers, wiki |
| `/memory dream` | Consolidate + TTL audit + rebuild wiki (run weekly) |
| `/memory status` | Memory health: tier sizes, TTL alerts, last sync times |
| `/memory setup` | Configure vault path, detect platforms, install hooks |
| `/memory audit` | TTL audit + boundary check + health alerts |
| `/memory wiki sync` | **Full pipeline**: init → ingest all vault sources → Notion publish |
| `/memory wiki sync --full` | Full pipeline, reprocessing all sources from scratch |
| `/memory wiki init` | Initialize wiki/ folder structure in vault |
| `/memory wiki ingest [source]` | Process raw source → compile wiki pages |
| `/memory wiki ingest --from-memory` | Pull session digests + topics → wiki pages |
| `/memory wiki query [topic]` | Answer from compiled wiki, not raw sources |
| `/memory wiki sync notion` | Push publish-ready pages to Notion |
| `/memory wiki lint` | Health check: orphans, stale, broken links, missing provenance |
| `/memory wiki dream` | Bulk consolidation: merge, contradiction detection, rebuild index |
| `/memory wiki status` | Wiki stats: pages, stale count, publish queue, last sync |

---

## How It Works

### The agent knows because hooks tell it

When you start a Claude Code session, a small script runs in the background and tells the agent: where your vault is, what you were last working on, and where to find more context. That's it. No setup per session, no copy-pasting notes.

The same thing happens when the agent spawns a helper (a subagent). Before the helper starts working, it automatically receives a briefing: what the parent was doing, which project this belongs to, and where to look for more information.

**A session from start to finish:**

```
You open a session
  → agent learns your vault location + recent journal count

You work
  → agent notes decisions and current task as it goes (SESSION-STATE.md)

Claude needs to compress the conversation
  → current state is saved to your vault before anything is lost

You close the session
  → everything is flushed to the vault for next time
```

**When the agent spawns a helper:**

The helper gets a briefing before its first message:

```
What project/run this belongs to   ← from .ship-run file
What the parent was working on     ← from SESSION-STATE.md
Where to find more context         ← MEMORY.md index + topic files list
How to query HOT / WARM / COLD     ← access patterns
```

No re-briefing needed. The helper arrives knowing enough to start.

**How the project ID travels to helpers (multi-agent runs):**

At run start, the engine writes a small ID file:

```bash
echo "ship-ABC-123" > .ship-run
```

Every helper spawned in that folder picks it up automatically. If the file isn't there, the hook looks for an env var, then falls back to SESSION-STATE.md. You never wire this manually.

### 3 tiers — hot, warm, cold

Think of these as three places the agent looks, from fastest to deepest:

```
HOT   Always in context (≤2400 tokens)
  MEMORY.md         — index of what topics exist
  SESSION-STATE.md  — what's happening right now

WARM  Loaded on demand, one topic at a time
  memory/topics/*.md  — facts about a domain, expire over time
  memory/YYYY-MM-DD.md  — daily journals

COLD  Searched, never fully loaded
  Obsidian vault    — permanent knowledge, decisions, logs
```

The agent reads HOT on every session. It pulls WARM files when it needs domain context. It searches COLD when it needs something older or more specific.

### Syncing: 3 steps

1. **Detect** — find what changed (new decisions, stale entries, expired TTLs)
2. **Classify** — each insight goes to the right tier: fact → topics, pattern → vault, rule → AGENTS.md
3. **Write with proof** — a sync report shows exactly what was saved, skipped, or flagged

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

## Sync Sources

`/memory sync` collects from all available sources in one pass:

| Source | Path | Available when |
|--------|------|----------------|
| Session conversation | current context | always |
| Session state | `SESSION-STATE.md` | always |
| Local journals | `memory/YYYY-MM-DD.md` | if files exist |
| Compaction state | `~/.claude/compaction-state/latest.md` | if file exists |
| CC project memories | `~/.claude/projects/*/memory/*.md` | always |
| CC saved plans | `~/.claude/plans/*.md` | if files exist |
| OpenClaw journals | `$OPENCLAW_CONFIG_PATH/memory/*.md` | if env var set |
| OpenClaw topics | `$OPENCLAW_CONFIG_PATH/memory/topics/*.md` | if env var set |

Every sync routes to all tiers (HOT → WARM → COLD) and feeds the wiki automatically. Use `/memory dream` weekly to consolidate and rebuild the wiki index.

---

## LLM Wiki

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

1. `/memory sync` — all sources → tiers (HOT/WARM/COLD) + wiki pages updated automatically
2. `/memory wiki ingest --from-memory` — vault topics + session digests → wiki pages (manual re-ingest)
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
