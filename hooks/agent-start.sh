#!/bin/bash
# Inject memory context into every subagent session.
# Fires on SubagentStart — output appears in the subagent's context as a system-reminder.

# ── 1. Counter (existing) ──────────────────────────────────────────────────────
COUNTER_FILE="/tmp/claude-agents-count"
CURRENT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
echo $((CURRENT + 1)) > "$COUNTER_FILE"

# ── 2. Detect run ID ──────────────────────────────────────────────────────────
# Priority: env var → .ship-run file → SESSION-STATE.md first matching line
RUN_ID="${SHIP_RUN_ID:-}"
LINEAR_REF="${LINEAR_ISSUE_ID:-}"

if [ -z "$RUN_ID" ] && [ -f "${PWD}/.ship-run" ]; then
  RUN_ID=$(cat "${PWD}/.ship-run" 2>/dev/null | tr -d '[:space:]')
fi

if [ -z "$RUN_ID" ] && [ -f "${PWD}/SESSION-STATE.md" ]; then
  RUN_ID=$(grep -m1 -E "^Run:|^run:|SHIP_RUN_ID|ship-[A-Z]" "${PWD}/SESSION-STATE.md" 2>/dev/null \
    | sed -E 's/.*ship-([A-Z]+-[0-9]+).*/ship-\1/' \
    | grep -E "^ship-" | head -1)
fi

# ── 3. Read MEMORY.md router (first 40 lines = index, skip body) ──────────────
MEMORY_ROUTER=""
for CANDIDATE in "${PWD}/MEMORY.md" "${HOME}/.claude/MEMORY.md"; do
  if [ -f "$CANDIDATE" ]; then
    MEMORY_ROUTER=$(head -40 "$CANDIDATE" 2>/dev/null)
    MEMORY_SOURCE="$CANDIDATE"
    break
  fi
done

# ── 4. Read SESSION-STATE current task ────────────────────────────────────────
SESSION_TASK=""
if [ -f "${PWD}/SESSION-STATE.md" ]; then
  SESSION_TASK=$(awk '/^## Current Task/{found=1; next} found && /^##/{exit} found{print}' \
    "${PWD}/SESSION-STATE.md" 2>/dev/null | head -6 | sed '/^$/d')
fi

# ── 5. List WARM topic files ──────────────────────────────────────────────────
WARM_TOPICS=""
if [ -d "${PWD}/memory/topics" ]; then
  WARM_TOPICS=$(ls "${PWD}/memory/topics/"*.md 2>/dev/null \
    | xargs -I{} basename {} .md | sort | tr '\n' ' ')
fi

# ── 6. Run artifacts path ─────────────────────────────────────────────────────
RUN_ARTIFACTS=""
if [ -n "$RUN_ID" ]; then
  TICKET=$(echo "$RUN_ID" | sed -E 's/ship-//')
  if [ -d "${PWD}/runs/${TICKET}" ]; then
    RUN_ARTIFACTS="${PWD}/runs/${TICKET}"
  fi
fi

# ── 7. Print context block (only if there's something useful to say) ──────────
HAS_CONTEXT=0
[ -n "$RUN_ID" ] && HAS_CONTEXT=1
[ -n "$SESSION_TASK" ] && HAS_CONTEXT=1
[ -n "$MEMORY_ROUTER" ] && HAS_CONTEXT=1

if [ "$HAS_CONTEXT" -eq 0 ]; then
  exit 0
fi

echo "## Agent Memory Context"
echo ""

# Run reference
if [ -n "$RUN_ID" ] || [ -n "$LINEAR_REF" ]; then
  echo "### Run Reference"
  [ -n "$RUN_ID" ]    && echo "Team:   $RUN_ID"
  [ -n "$LINEAR_REF" ] && echo "Ticket: $LINEAR_REF"
  [ -n "$RUN_ARTIFACTS" ] && echo "Artifacts: $RUN_ARTIFACTS"
  [ -z "$RUN_ARTIFACTS" ] && [ -n "$RUN_ID" ] && \
    TICKET=$(echo "$RUN_ID" | sed -E 's/ship-//') && \
    echo "Artifacts: runs/$TICKET/ (create if needed)"
  echo ""
fi

# Current task from parent session
if [ -n "$SESSION_TASK" ]; then
  echo "### Parent Session — Current Task"
  echo "$SESSION_TASK"
  echo ""
fi

# Memory router
if [ -n "$MEMORY_ROUTER" ]; then
  echo "### Memory Router"
  echo "$MEMORY_ROUTER"
  echo ""
fi

# WARM topic files
if [ -n "$WARM_TOPICS" ]; then
  echo "### WARM Topics Available"
  echo "$WARM_TOPICS"
  echo "Read: memory/topics/{topic}.md"
  echo ""
fi

# Access instructions
echo "### Memory Access"
echo "COLD (vault search): obsidian search query=\"{topic}\" limit=5"
echo "WARM (topic file):   Read memory/topics/{topic}.md"
echo "HOT (session state): Read SESSION-STATE.md"
echo "Run artifacts:       runs/{ticket}/ (blackboard.json, stage docs)"
