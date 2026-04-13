# /memory

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](CHANGELOG.md)

**Your AI agents forget everything between sessions. Memory fixes that.**

```
/plugin marketplace add maxtechera/memory
```
```bash
clawhub install memory
```

Zero config. Run `/memory setup` once — session hooks fire automatically after that.

---

Your AI agents forget everything between sessions. Memory fixes that.

Session hooks capture what your agent learns — decisions, preferences, context — and persist it across compactions and session boundaries. Your next session picks up where the last one left off.

**Requires**: [Obsidian](https://obsidian.md) with the Obsidian CLI (v1.12.7+) for long-term vault storage. Without Obsidian, hooks still save session state locally to `~/.claude/compaction-state/`.

## What people use it for

**Picking up where you left off.** Start a session, your agent already knows what you were working on, what decisions were made last week, and what the user prefers. No re-briefing, no context dump.

**Running long projects.** The WAL protocol captures decisions as they happen. Compaction events flush them to the vault. A month later you can ask "what did we decide about the auth system?" and get the answer.

**Cross-platform context.** Work in Claude Code on your Mac, switch to OpenClaw in a container, pick up in Gemini CLI. Memory syncs the HOT/WARM/COLD tiers across all of them via Obsidian vault or OpenClaw journals.

**Reducing token spend.** Instead of re-loading full project context every session, Memory surfaces only what's relevant. HOT memory (active session) stays tiny. WARM and COLD tiers are queried on demand.

---

## Install

**Claude Code (Recommended)**

```
/plugin marketplace add maxtechera/memory
/plugin install memory@memory
```

**Manual (Claude Code)**

```bash
git clone https://github.com/maxtechera/memory.git ~/.claude/skills/memory
```

**ClawHub / OpenClaw**

```bash
clawhub install memory
```

**Gemini CLI**

```bash
gemini extensions install maxtechera/memory
```

**Codex CLI**

```bash
git clone https://github.com/maxtechera/memory.git ~/.agents/skills/memory
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

---

## How It Works

### 3 Steps

1. **Detect** — Find what changed (new session state, stale journals, TTL expirations)
2. **Classify & Route** — Each insight goes to the right tier: fact → topics, pattern → vault, rule → AGENTS.md
3. **Write with Proof** — Structured sync report shows exactly what was written, skipped, or flagged

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
│ Code      │ │ Code │  │ (Railway)   │
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
| `agent-start.sh` | Subagent spawned | Increments agent counter |
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

Then update `~/.claude/settings.json` to register the hooks. See [hooks/README.md](hooks/README.md) for the full JSON configuration.

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

## 4 Sync Modes

| Mode | Command | What It Syncs | Direction |
|------|---------|---------------|-----------|
| 1 | `/memory sync` | Current session insights | Session → WARM → COLD |
| 2 | `/memory sync openclaw` | OpenClaw journals | OpenClaw → Obsidian |
| 3 | `/memory sync projects` | CC project memory files | `~/.claude/projects/` → Obsidian |
| 4 | `/memory dream` | Everything + consolidation | All tiers + prune + TTL audit |

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
├── hooks/                # Session lifecycle hooks
├── docs/
│   ├── VISION.md         # Vision deck
│   ├── STATE_MACHINE.md  # Sync state transitions
│   ├── ARCHITECTURE.md   # 3-tier memory reference
│   └── SYNC_PROTOCOL.md  # Cross-platform contract
├── examples/             # Sync examples and reports
├── .claude-plugin/       # Claude Code marketplace
├── gemini-extension.json # Gemini CLI manifest
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
