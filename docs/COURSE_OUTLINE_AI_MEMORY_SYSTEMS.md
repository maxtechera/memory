# AI Memory Systems / Memoria para Agentes IA

Offer stack: `/memory`
Free tool: [maxtechera/memory](https://github.com/maxtechera/memory)
Course price: **$97**
Tagline EN: **Build the memory layer your AI agents are missing**
Tagline ES: **Construye el sistema de memoria que tus agentes necesitan**

## Course promise

This course teaches builders, operators, and technical teams how to give AI agents durable memory across sessions, tools, and time. Students learn how to move beyond fragile context windows by implementing a three-tier memory architecture, a write-ahead logging discipline, and an Obsidian-backed source of truth that survives compaction, crashes, and cross-platform handoffs.

## Ideal student

- Builders already using Claude Code, OpenClaw, Gemini CLI, or similar tools
- Operators frustrated by agents that forget decisions between sessions
- Founders who want agents to accumulate context instead of restarting from zero
- Technical teams building reusable workflows on top of AI assistants

## Transformation

### Before
- The agent loses context after compaction or a fresh session
- Important decisions stay trapped in chat history
- Cross-platform work breaks continuity between tools
- The human keeps re-explaining project context

### After
- The agent can recover decisions, preferences, and project history on demand
- Session memory flows into durable topic memory and long-term vault storage
- Claude Code, OpenClaw, and Gemini CLI can share the same memory substrate
- The human spends less time re-briefing and more time shipping

## Course outcomes

By the end of the course, students will be able to:

1. Explain why agents forget, even when the model is capable.
2. Implement a HOT, WARM, and COLD memory architecture.
3. Use WAL-style memory capture to survive compaction and session crashes.
4. Configure `/memory` with Obsidian as the long-term source of truth.
5. Connect memory flows across Claude Code, OpenClaw, and Gemini CLI.
6. Design retention, TTL, and weekly consolidation rituals that keep memory useful instead of noisy.

## Module outline

## Module 1. Why agents forget
**Goal:** Make the memory problem visible before introducing the solution.

### Lessons
1. Context windows are not memory
2. Why compaction causes session amnesia
3. Failure modes: lost preferences, missing decisions, broken handoffs
4. Why chat history alone is not a durable operating system

### Takeaways
- Model capability does not solve persistence by itself
- Long projects fail when memory lives only inside the current window
- Durable systems need explicit memory architecture

### Exercise
Review one recent agent session and list three things that were lost or had to be repeated in the next session.

---

## Module 2. The 3-tier architecture: HOT, WARM, COLD
**Goal:** Show students how memory should be structured by retrieval cost and time horizon.

### Lessons
1. HOT memory: what must always stay in context
2. WARM memory: topic files, journals, and selective recall
3. COLD memory: vault search and durable archival knowledge
4. How routing between tiers keeps context small but useful

### Takeaways
- Not all memory belongs in the prompt
- Retrieval quality matters more than raw accumulation
- Tiering is what makes memory scalable across long-running work

### Exercise
Map one real project into HOT, WARM, and COLD memory buckets.

---

## Module 3. WAL protocol: write before compaction
**Goal:** Teach students how to preserve memory before it disappears.

### Lessons
1. What write-ahead logging means for agent systems
2. Capturing decisions before compaction fires
3. Surviving crashes, interruptions, and partial sessions
4. Building confidence through explicit sync and audit trails

### Takeaways
- Memory should be persisted before the system needs it
- WAL turns fragile session state into recoverable state
- Reliability comes from discipline, not hope

### Exercise
Design a simple WAL flow for an agent session: what gets captured, when, and where.

---

## Module 4. Installing `/memory` and using Obsidian as source of truth
**Goal:** Move from theory into working implementation.

### Lessons
1. Installing `/memory` in Claude Code and OpenClaw
2. Running setup and validating hooks
3. Connecting an Obsidian vault as the durable knowledge layer
4. Using journals, topics, and vault structure as a practical operating system

### Takeaways
- The vault is the source of truth, not the temporary session
- Setup quality determines whether memory stays automatic or becomes manual overhead
- Good file structure makes later retrieval dramatically easier

### Exercise
Install `/memory`, connect a vault, and verify that a captured session fact can be found after a restart.

---

## Module 5. Cross-platform sync: Claude Code → OpenClaw → Gemini CLI
**Goal:** Show how one memory layer can travel with the operator across tools.

### Lessons
1. Why multi-tool workflows usually break context continuity
2. Shared vaults, local journals, and sync surfaces
3. What changes between Claude Code, OpenClaw, and Gemini CLI
4. Debugging cross-platform drift and missing state

### Takeaways
- Cross-platform continuity requires a shared memory contract
- The tool can change without losing the project brain
- Memory becomes an asset when it outlives any single interface

### Exercise
Run one task across two tools and document which memory artifacts carried over correctly.

---

## Module 6. TTL decay and the weekly `/memory dream` ritual
**Goal:** Help students keep memory clean, current, and strategically useful.

### Lessons
1. Why stale memory becomes a liability
2. TTL decay for preferences, facts, and active project context
3. Consolidation patterns for recurring insights
4. The weekly dream cycle: audit, merge, prune, and rebuild

### Takeaways
- Good memory systems forget intentionally, not accidentally
- Cleanup is part of memory quality, not an optional maintenance chore
- Weekly consolidation keeps the system trustworthy over time

### Exercise
Define one TTL rule per memory tier and design a weekly dream checklist.

## Suggested bonus module. Designing the memory layer for your own agents
**Goal:** Turn the course into an implementation plan for each student’s workflow.

### Lessons
1. Choosing what deserves durable memory
2. What not to store in HOT memory
3. Deciding when to journal, summarize, or archive
4. Operational tradeoffs: precision, noise, privacy, and cost

### Exercise
Draft a memory blueprint for one personal or team workflow using the HOT/WARM/COLD model.

## Delivery format

- 6 core modules, 1 optional bonus module
- Designed for short lesson videos plus implementation exercises
- English and Spanish tracks share the same structural backbone
- Each module ends with one concrete build step

## Recommended lesson pacing

- Module 1: 15 to 20 minutes
- Module 2: 20 to 25 minutes
- Module 3: 20 to 25 minutes
- Module 4: 25 to 30 minutes
- Module 5: 20 to 25 minutes
- Module 6: 15 to 20 minutes
- Bonus module: 15 to 20 minutes

Estimated total runtime: **2 hours 10 minutes to 2 hours 45 minutes**

## English hooks

- Your agent is not broken. It is just forgetting everything that matters.
- Context windows are a temporary scratchpad, not a memory system.
- If your agent starts from zero every session, you are rebuilding trust from zero too.

## Spanish hooks

- Tu agente no está roto. Solo está olvidando lo que importa.
- La ventana de contexto es una libreta temporal, no un sistema de memoria.
- Si tu agente arranca desde cero en cada sesión, tu confianza también vuelve a cero.

## Spanish adaptation notes

- Keep the architecture terms HOT, WARM, and COLD in English, but explain them naturally in Spanish.
- Translate WAL as protocolo de escritura previa or write-ahead log depending on audience sophistication.
- Use concrete examples from freelance operators, founders, and technical teams in LATAM.
- Position Obsidian as a source of truth, not just a note-taking app.

## Final deliverable recommendation

Turn this outline into:
1. a lesson-by-lesson script brief in English,
2. a Spanish adaptation pass that preserves examples and tone,
3. a course page tied directly to the `/memory` GitHub install friction point,
4. a README CTA that routes users from the free tool into the paid course.
