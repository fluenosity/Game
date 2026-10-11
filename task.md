# MASTER PROMPT — ROBLOX SURVIVAL HORROR GAME KNOWLEDGE BASE, TECHNICAL DESIGN & 10,000-IDEA RESEARCH SYSTEM

## 1. Your Role

You are acting as a senior Roblox game director, systems designer, gameplay programmer, technical architect, horror designer, multiplayer engineer, UX designer, game producer, QA lead, and game research analyst.

Your task is to transform the existing game design document into a **complete, maintainable, implementation-ready game documentation repository** that can guide future AI coding agents throughout development.

Do not merely summarize the existing document. Expand it into a coherent set of interconnected technical and design documents that explain what the game is, how every gameplay system works, how each day progresses, how systems interact, how to implement them safely in Roblox, how to test them, and how to evaluate future improvements.

You are also responsible for creating a large, structured idea-research database containing **10,000 distinct candidate improvements**, evaluating those candidates systematically, and producing an evidence-based shortlist of the ten strongest proposals for human review.

Work directly in the accessible project workspace and create the actual documentation files. Do not return only a plan or a single enormous response in chat.

Documentation is the primary deliverable. Do not start implementing the full game code during this task.

---

# 2. Project Context

## Working title

Use `Project: Undecided` until an official name is approved.

Do not invent an official brand identity and silently treat it as final.

## Platform

Roblox.

Primary gameplay: solo and cooperative survival horror.

Target session size: 1–5 players.

Target devices:
- Windows and macOS computers supported by Roblox.
- Mobile phones and tablets.
- Consoles and controller users where practical.

All core mechanics must be designed with multiplayer correctness, readable controls, and performance constraints in mind.

## Existing core concept

The player begins in a city devastated by an unknown monster. The monster appears to fear fire. Following an escape sequence, the player enters a forest and finds an abandoned shelter enclosed by a damaged metal fence.

The player must gather wood, maintain a campfire, survive dangerous nights, and gradually improve their shelter.

As the campaign progresses, players discover salvageable resources such as metal scraps, plastic, rope, and other materials. These can support crafting, trading, shelter upgrades, exploration, and long-term progression.

The intended experience combines:

- Survival horror.
- Exploration and scavenging.
- A day/night cycle.
- Limited resources and meaningful decisions.
- Fire-based protection.
- A threatening, memorable monster.
- Solo and cooperative gameplay.
- Base construction and upgrades.
- Environmental storytelling.
- A finite campaign objective.
- Replayability and future content updates.

## Current design as described in the supplied game design document

The existing document contains these concepts:

1. A lobby with player-count choices for sessions accommodating one through five players.
2. Separate sessions for different groups.
3. An opening ruined-city sequence establishing the monster's fear of fire.
4. A forest escape sequence and first-person gameplay.
5. A fenced shelter, abandoned sofa, table, and visible campfire location.
6. Initial wood gathering and the first night of survival.
7. Subsequent wood gathering and campfire upgrades.
8. Later access to scavenging, salvage materials, a wandering trader, and base upgrades.
9. Increasing monster aggression.
10. Potential lore, multiple endings, persistent unlocks, achievements, cosmetics, leaderboards, and future updates.

Treat these as the existing design source, not as proof that any mechanic has been implemented.

Inspect the actual project files before deciding what already exists in code.

---

# 3. Non-Negotiable Rules

## 3.1 Preserve the difference between facts and proposals

Every important design decision must have a clear status:

- `EXISTING_CANON`: explicitly specified by the supplied design document.
- `PROPOSED`: a recommendation that has not been approved.
- `ASSUMPTION`: a temporary value or rule used to continue design work.
- `APPROVED`: a proposal explicitly accepted by the project owner.
- `IMPLEMENTED`: verified in the actual codebase.
- `VERIFIED`: tested against the relevant implementation or authoritative source.
- `DEPRECATED`: previously used but replaced by a documented decision.

Never label a proposed feature as approved, or an unimplemented feature as implemented.

Maintain a central source-of-truth document.

If two documents disagree, identify the conflict and resolve it through an explicit decision record. Do not independently invent conflicting rules in different files.

## 3.2 Do not blindly expand every idea

More mechanics do not automatically produce a better game.

Evaluate proposed features based on their effect on the actual player experience, uniqueness, technical feasibility, development cost, mobile usability, multiplayer behavior, performance, accessibility, replayability, and interaction with existing systems.

Prefer a small number of deeply integrated mechanics over dozens of disconnected features.

## 3.3 Do not copy competitors

Use other Roblox games as market references at a high level. Do not replicate distinctive characters, maps, art, names, sounds, storylines, or signature implementation details.

The game must establish its own identifiable gameplay and visual identity.

## 3.4 Keep the horror effective, not merely loud

Do not rely exclusively on jumpscares.

Explore anticipation, uncertainty, distant silhouettes, spatial audio, interrupted visibility, resource pressure, changing monster behavior, environmental clues, and cooperative panic.

Use jumpscares as one tool, not the entire horror system.

## 3.5 No undocumented magic numbers

Every significant numerical value should be documented and tunable.

Examples include:

- Day duration.
- Night duration.
- Matchmaking timeout.
- Campfire fuel consumption.
- Fuel capacity.
- Protection radius.
- Monster detection distance.
- Hearing distance.
- Attack cooldown.
- Monster movement speed.
- Resource spawn rates.
- Crafting costs.
- Player health and damage.
- Interaction range.
- Network update frequency.
- Persistence limits.

Mark values as `INITIAL_BALANCE_PROPOSAL` until playtesting supports them.

Explain why each initial value exists, what changing it affects, and how it should be tested.

## 3.6 Do not fabricate research

When web research is available, use current authoritative Roblox Creator documentation for platform APIs, server behavior, persistence, networking, moderation, and publishing limitations.

Use credible evidence for current competitor metrics or industry claims. Record the source and the date accessed.

When a claim cannot be verified, mark it `UNVERIFIED`. Never invent citations or present guesses as measured facts.

---

# 4. Workspace Inspection and Documentation Workflow

Before writing the documents:

1. Inspect the supplied game design document in full.
2. Inspect the project folder and existing documentation.
3. Determine whether an actual Roblox Studio project, source files, assets, configuration files, or tests already exist.
4. Identify the current tools, programming language, architecture, and implementation status where observable.
5. Record missing information and contradictions.
6. Create a documentation plan.
7. Build the documentation repository in the existing project workspace without overwriting useful files or modifying unrelated source code.

If the repository is empty, establish the proposed documentation structure below.

If it already has a suitable structure, adapt the structure instead of creating unnecessary duplicates.

Do not stop to ask questions for every unknown. Record assumptions, make reversible proposals, and proceed.

## Recommended directory structure

```text
docs/
├── README.md
├── 00_PROJECT_STATUS.md
├── 01_GAME_VISION.md
├── 02_SOURCE_OF_TRUTH.md
├── 03_GLOSSARY.md
├── 04_CORE_GAMEPLAY_LOOP.md
├── 05_CAMPAIGN_OVERVIEW.md
├── 06_PLAYER_EXPERIENCE.md
├── 07_GAMEPLAY_BALANCE.md
│
├── campaign/
│   ├── DAY_00_PROLOGUE.md
│   ├── DAY_01_FIRST_SURVIVAL.md
│   ├── DAY_02_FIRE_AND_PREPARATION.md
│   ├── DAY_03_SCAVENGING_AND_DISCOVERY.md
│   ├── DAY_04_DARKNESS_AND_ESCALATION.md
│   └── DAY_05_SIGNAL_AND_ESCAPE.md
│
├── systems/
│   ├── SESSION_MATCHMAKING.md
│   ├── DAY_NIGHT_CYCLE.md
│   ├── MONSTER_AI.md
│   ├── MONSTER_IDENTITY_AND_BEHAVIOR.md
│   ├── FIRE_AND_FUEL.md
│   ├── LIGHT_NETWORK.md
│   ├── RESOURCES_AND_GATHERING.md
│   ├── SHELTER_AND_BASE_BUILDING.md
│   ├── CRAFTING_AND_UPGRADES.md
│   ├── TRADING_AND_ECONOMY.md
│   ├── PLAYER_HEALTH_AND_DEATH.md
│   ├── INVENTORY_AND_ITEM_RULES.md
│   ├── COOPERATION_AND_PARTIES.md
│   ├── ENVIRONMENTAL_EVENTS.md
│   ├── LORE_AND_STORY.md
│   ├── ENDINGS_AND_EXTRACTION.md
│   ├── META_PROGRESSION.md
│   └── DIFFICULTY_AND_REPLAYABILITY.md
│
├── technical/
│   ├── TECHNICAL_OVERVIEW.md
│   ├── ROBLOX_ARCHITECTURE.md
│   ├── RECOMMENDED_FOLDER_STRUCTURE.md
│   ├── SERVER_AUTHORITY_AND_SECURITY.md
│   ├── NETWORKING_AND_REMOTES.md
│   ├── MATCH_LIFECYCLE_AND_STATE_MACHINES.md
│   ├── DATA_MODELS_AND_SCHEMAS.md
│   ├── PERSISTENCE_AND_SAVE_RECOVERY.md
│   ├── PLAYER_JOIN_LEAVE_AND_DISCONNECTS.md
│   ├── MONSTER_AI_TECHNICAL_DESIGN.md
│   ├── INTERACTION_FRAMEWORK.md
│   ├── UI_AND_INPUT_ARCHITECTURE.md
│   ├── AUDIO_AND_LIGHTING_PIPELINE.md
│   ├── PERFORMANCE_AND_MOBILE.md
│   ├── TELEMETRY_AND_ANALYTICS.md
│   └── EXPLOIT_THREAT_MODEL.md
│
├── production/
│   ├── ART_DIRECTION.md
│   ├── ENVIRONMENT_AND_MAP_LAYOUT.md
│   ├── AUDIO_DESIGN.md
│   ├── ANIMATION_REQUIREMENTS.md
│   ├── ACCESSIBILITY_AND_ONBOARDING.md
│   ├── QA_AND_ACCEPTANCE_CRITERIA.md
│   ├── PLAYTEST_PLAN.md
│   ├── RELEASE_CHECKLIST.md
│   ├── CONTENT_ROADMAP.md
│   └── RISK_REGISTER.md
│
├── research/
│   ├── MARKET_AND_COMPETITOR_RESEARCH.md
│   ├── DESIGN_PILLARS.md
│   ├── DIFFERENTIATION_STRATEGY.md
│   ├── IDEA_TAXONOMY.md
│   ├── IDEA_GENERATION_PROTOCOL.md
│   ├── IDEA_SCORING_MODEL.md
│   ├── IDEA_CATALOG.csv
│   ├── IDEA_CATALOG_README.md
│   ├── IDEA_QUALITY_REPORT.md
│   ├── TOP_100_CANDIDATES.md
│   ├── TOP_30_CANDIDATES.md
│   ├── TOP_10_RECOMMENDATIONS.md
│   └── REJECTED_IDEAS_AND_RATIONALE.md
│
├── decisions/
│   ├── DECISION_LOG.md
│   ├── OPEN_QUESTIONS.md
│   └── CHANGELOG.md
│
├── testing/
│   ├── TEST_STRATEGY.md
│   ├── CORE_GAMEPLAY_TESTS.md
│   ├── MULTIPLAYER_TESTS.md
│   ├── EXPLOIT_AND_ABUSE_TESTS.md
│   └── DEVICE_COMPATIBILITY_MATRIX.md
│
└── implementation/
    ├── IMPLEMENTATION_ROADMAP.md
    ├── PHASE_00_PROTOTYPE.md
    ├── PHASE_01_VERTICAL_SLICE.md
    ├── PHASE_02_CAMPAIGN.md
    ├── PHASE_03_POLISH.md
    └── DEFINITION_OF_DONE.md
```

Add or remove files when there is a clear reason. The important part is a coherent repository, not blindly matching every filename.

The catalog may also be stored in a structured format such as JSONL if that better suits the available tooling. Explain the choice in `IDEA_CATALOG_README.md`.

---

# 5. Campaign Documentation: Day 0 Through Day 5

Create six substantial, independently useful design documents.

Do not make six superficial descriptions of different days. Each must describe player experience, system behavior, implementation needs, failure states, testing, and progression.

## Global campaign requirements

The campaign must teach its mechanics in a deliberate order.

Players should initially understand where they are, what threatens them, what to do next, and why the objective matters.

Difficulty must increase through meaningful changes in the situation, not just inflated enemy health or arbitrary resource costs.

Plan the campaign around a proposed five-night escape structure. Clearly label the ending, signal tower, connected-light network, and other unapproved additions as proposals until the project owner approves them.

The narrative and mechanics must reinforce one another.

## DAY 00 — PROLOGUE: THE CITY FALLS

Purpose: create an unforgettable introduction, establish the threat, and lead naturally into the forest survival experience.

Document:

- The player's starting context.
- Ruined-city environment and visual composition.
- Cinematic sequence and camera transitions.
- The monster's first appearance.
- The monster observing a large fire and retreating.
- What the player learns without spoken exposition.
- Environmental storytelling and sound.
- How the city sequence transitions into playable escape.
- Optional lightweight escape gameplay versus a fully scripted sequence.
- How the sequence behaves in multiplayer.
- Cutscene synchronization and camera ownership.
- Skip controls and replay behavior.
- Players joining, disconnecting, or losing control during a cutscene.
- Loading failures and safe fallback behavior.
- Performance requirements.
- Exact exit conditions into Day 1.

Do not make this sequence so long that replaying the game becomes irritating.

Provide a proposed beat-by-beat timeline, with approximate timestamps clearly marked as tunable.

Acceptance criteria must explain how a tester can verify the scene, its transition, and the player's understanding of the monster's fear of fire.

## DAY 01 — FIRST SURVIVAL

Purpose: teach the core loop without overwhelming new players.

The starting concept includes fleeing toward the forest, finding a visible shelter, collecting wood, returning before nightfall, lighting a campfire, and surviving until morning.

Document:

- Player spawn and first-person presentation.
- Objective progression.
- Shelter discovery.
- Movement and interaction controls.
- How players learn to collect wood.
- Resource pickup, chopping, carrying, and inventory behavior.
- The first campfire lighting sequence.
- Fire protection rules.
- The first monster encounter.
- Nightfall warnings and urgency.
- Survival, death, revival if applicable, and failure recovery.
- Cooperative assistance.
- What happens when one player completes an objective ahead of others.
- Dawn and the transition into Day 2.
- Onboarding feedback and tutorial completion.
- Mobile input and readable objective UI.
- What should be deliberately withheld until later days.

Do not introduce every system on Day 1.

The first day must demonstrate the full core loop: explore, gather, prepare, defend, survive.

## DAY 02 — FIRE AND PREPARATION

Purpose: introduce preparation, fuel management, fire upgrades, and the first meaningful survival decisions.

Investigate the following as design options:

- Fuel consumption and fire maintenance.
- Different fuel types.
- Fire intensity and protection radius.
- Fire deterioration.
- Weather and environmental effects.
- Limited shelter improvements.
- Monster behavior that responds to the player's progress.
- Decisions between upgrading the main fire and gathering more resources.
- Risks of being away from the shelter.
- Early discoveries about why the monster fears fire.

Specify exact proposed rules for every mechanic you recommend, not merely feature names.

Define the information displayed to players, resource costs, failure states, recovery opportunities, and whether each mechanic is essential or optional.

Avoid adding complexity without adding interesting decisions.

## DAY 03 — SCAVENGING AND DISCOVERY

Purpose: expand the world beyond the shelter while giving players reasons to venture farther.

Evaluate and document:

- Metal scraps, plastic, rope, and other salvageable materials.
- Resource spawn logic and respawn rules.
- Safe and dangerous exploration areas.
- Crafting prerequisites.
- Shelter expansion.
- Storage and inventory limits.
- Trader appearance and trading rules, if included.
- Environmental storytelling.
- Abandoned structures and useful landmarks.
- Player cooperation during exploration.
- Carry capacity and the tradeoff between bringing home different items.
- Resource scarcity and how to prevent frustrating softlocks.

Design at least two distinct exploration decisions that have meaningful consequences.

Do not make the trader a mandatory waiting event that interrupts the campaign without giving the player another useful activity.

## DAY 04 — DARKNESS AND ESCALATION

Purpose: make players feel that their previous knowledge is no longer sufficient on its own.

Evaluate a new threat behavior or system change that transforms the experience.

Potential directions include:

- The monster learns from previous encounters.
- The monster probes weak defenses rather than attacking randomly.
- Darkness becomes dangerous between sources of protection.
- Players must maintain several defensible positions.
- Environmental hazards interfere with familiar strategies.
- Light sources can fail under specific, understandable conditions.
- A major scouting or preparation objective precedes the final night.

If the connected-light network is selected, define its gameplay role, traversal rules, activation costs, failure conditions, and counterplay.

Avoid arbitrary difficulty spikes or unavoidable deaths.

The player must have a reasonable opportunity to understand the threat, prepare, and recover.

## DAY 05 — THE SIGNAL AND ESCAPE

Purpose: provide a satisfying conclusion to the initial campaign.

The signal tower and escape objective are proposals to evaluate, not established canon.

Document:

- How the player learns the escape objective.
- Required components and previous-day prerequisites.
- The path to the final objective.
- The final resource-gathering decisions.
- Whether solo and cooperative teams receive different opportunities.
- Monster behavior during preparation.
- The final defensive encounter.
- What happens if a player dies or disconnects.
- Signal activation conditions.
- Escape sequence, ending, and rewards.
- Campaign failure and replay behavior.
- Post-campaign choices.
- Persistent unlocks versus run-specific resources.
- How the next session remains appealing after the ending.

The conclusion must feel earned by the mechanics established earlier. Do not introduce a completely new combat system at the final moment merely to manufacture a boss fight.

Provide the success path, failure path, and exceptional cases.

## Required template for EVERY daily document

Each of the six documents must contain:

1. Document metadata and status.
2. Purpose and intended player emotion.
3. Narrative context.
4. Player starting conditions.
5. Prerequisites.
6. Primary objective.
7. Optional objectives.
8. Exact step-by-step gameplay flow.
9. Time-of-day timeline.
10. Locations, landmarks, and level-design needs.
11. Resources and proposed numerical values.
12. Monster behavior and state transitions.
13. UI messages, audio cues, and visual feedback.
14. Multiplayer behavior.
15. Solo-player behavior.
16. Mobile and controller considerations.
17. Accessibility considerations.
18. Success and failure conditions.
19. Death, disconnect, and recovery behavior.
20. Edge cases and exploits.
21. Interactions with other systems.
22. Required assets.
23. Implementation dependencies.
24. Technical implementation notes.
25. Acceptance criteria.
26. QA test cases.
27. Analytics events.
28. Unresolved questions.
29. Changes that would invalidate this day.

Include diagrams, state transitions, or tables where they genuinely clarify the design.

---

# 6. Core Technical Documentation

Now translate the design into a coherent Roblox architecture.

These documents must guide a future coding AI without requiring it to guess the intended behavior.

## 6.1 Technical overview

Define:

- The project's technical goals.
- The main system boundaries.
- Proposed Roblox services and their responsibilities.
- Authoritative game-state ownership.
- Client responsibilities.
- Shared data and configuration strategy.
- Runtime initialization.
- Error handling.
- Logging and debugging.
- Development, staging, and production considerations.

Explain how the architecture supports testing, future updates, and the day-based campaign.

## 6.2 Recommended folder and module architecture

Propose a maintainable Roblox structure suitable for Luau.

Consider separation of responsibilities among:

- Server-side session orchestration.
- Campaign and day management.
- Monster AI.
- Resource spawning.
- Gathering and inventory.
- Fire and light management.
- Crafting, trading, and base upgrades.
- Player state.
- Networking.
- Configuration and balancing values.
- Client controllers.
- UI presentation.
- Audio and camera controllers.
- Data persistence.
- Diagnostics and tests.

For each significant module, specify:

- Responsibility.
- Public interface.
- Inputs and outputs.
- Data it owns.
- Dependencies.
- Events it emits.
- Events it consumes.
- What it must never do.

Avoid needless abstractions and excessively fragmented modules.

Do not write the actual full implementation at this stage.

## 6.3 Matchmaking and session lifecycle

Specify a complete lifecycle:

`WaitingForPlayers → PreparingSession → Loading → Prologue → DayLoop → SuccessOrFailure → Cleanup`

Adapt the states as needed.

Define:

- Lobby party creation.
- Player-count selection.
- Party membership.
- Full-party behavior.
- Waiting timeout.
- Partial parties when a timer expires.
- Solo-session immediate start.
- Session isolation.
- Reserved-server or other appropriate session allocation.
- Player teleportation failures.
- Player disconnects during each lifecycle state.
- Unexpected server shutdown.
- Rejoining policy.
- Session cleanup.
- Duplicate-start prevention.
- Idempotent transitions.

Verify relevant Roblox platform behavior before documenting API-specific implementation details.

Do not assume that a successful teleport, saved record, or network operation is guaranteed.

## 6.4 Day/night orchestration

Define a single source of truth for the campaign phase and day.

Specify:

- When a day begins.
- How the daytime timer progresses.
- The point at which warnings appear.
- When night starts.
- When the monster's night behaviors become eligible.
- What conditions allow dawn.
- What happens when mandatory objectives are incomplete.
- Whether time continues while players are dead or disconnected.
- How event-driven transitions are synchronized across players.
- How interrupted sessions recover.

Avoid separate systems independently deciding whether it is day or night.

## 6.5 Fire and light system

This is a key system and requires a detailed technical design.

Define:

- Campfire entity and state.
- Fuel inventory and consumption.
- Fire intensity.
- Burn duration.
- Protection radius.
- Upgrade tiers.
- Ignition and extinguishing.
- Extinction conditions.
- Light-source registration.
- Optional network of light sources.
- Environmental modifiers.
- Monster response to protective boundaries.
- Multiplayer interactions.
- Server-side validation.
- UI state synchronization.
- Performance constraints.
- Debugging tools.

Evaluate the connected-light concept as a candidate until approved.

If adopted, define what "connected" actually means. A network should not be a vague metaphor that different systems interpret inconsistently.

Specify whether connections are based on distance, line of sight, fixed routes, powered devices, or another explicit rule.

Explain how to prevent players from bypassing the network through overlapping radii or unexpected geometry.

## 6.6 Monster AI architecture

Create both a design document and a technical companion.

Document:

- Idle and roaming behavior.
- Patrol and investigation.
- Hearing and visual detection.
- Darkness-related behavior, if approved.
- Fire avoidance.
- Threat escalation.
- Chasing.
- Attack and recovery.
- Search behavior after losing a player.
- Retreat.
- Target selection in cooperative play.
- Difficulty scaling.
- Pathfinding failure.
- Stuck detection.
- Threat state transitions.
- Server-side decisions.
- Replicated presentation.
- Navigation performance.
- Fallback behavior.

Use a well-defined finite-state machine or an appropriately justified alternative.

For every state, define entry conditions, exit conditions, permitted transitions, actions, cooldowns, interruption rules, and recovery.

Never make the monster omniscient without intentionally defining that behavior.

If the monster "learns," define exactly what information it learns, where that information is stored, how it affects future decisions, and what prevents it from feeling unfair.

## 6.7 Resource, inventory, crafting, and economy architecture

Define schemas for:

- Resource definitions.
- Item definitions.
- Inventory entries.
- Resource nodes.
- Gathering actions.
- Stack limits.
- Crafting recipes.
- Crafting stations.
- Upgrade definitions.
- Trader inventory.
- Currency, if used.
- Purchase and sale transactions.
- Dropped items.
- Session-specific items.
- Persistent unlocks.

Specify how resource quantity changes are validated.

Prevent duplicate collection, item duplication from network retries, negative quantities, fabricated rewards, and simultaneous transactions that bypass costs.

Explain how resource values can be tuned without changing dozens of independent scripts.

## 6.8 Saving and persistence

Document which data belongs to an individual player and which belongs to a session or party.

Evaluate whether the campaign is primarily run-based, persistent, or a hybrid.

For every persistent field, specify:

- Schema and type.
- Default value.
- Ownership.
- Validation.
- Versioning.
- Migration strategy.
- Write timing.
- Retry policy.
- Failure handling.
- Data-loss risks.
- Exploit risks.

Address Roblox data-store limitations and relevant current API guidance.

Avoid saving every tiny event unnecessarily.

A player leaving, joining, or crashing must not silently corrupt progress or grant duplicated rewards.

## 6.9 Multiplayer and networking

Document the client/server trust model.

The server must validate gameplay-critical actions, including gathering rewards, damage, crafting, purchases, upgrades, inventory changes, objective completion, and escape conditions.

For each remote interaction, define:

- Purpose.
- Direction.
- Parameters.
- Validation.
- Permission.
- Rate limits.
- Expected result.
- Failure response.
- Logging.
- Relevant exploit scenarios.

Do not trust a client merely because the request originates from the official game interface.

## 6.10 UI and input architecture

Specify the HUD, objective panel, day indicator, fuel display, inventory, interaction prompts, menus, cutscene controls, and failure/recovery screens.

Define:

- Keyboard/mouse controls.
- Touch controls.
- Controller inputs.
- Input conflicts.
- Hold-versus-tap actions.
- Interaction priorities.
- Camera behavior.
- Objective visibility.
- Dynamic text and localization readiness.
- Color, contrast, scale, and motion preferences.
- UI state synchronization.

Mobile must not be treated as a scaled-down PC interface.

The most important actions should be understandable and usable on small screens.

## 6.11 Performance and technical risks

Set provisional performance budgets rather than vague goals such as "high FPS."

Cover:

- Terrain and world rendering.
- Lighting and shadow costs.
- Particles.
- Audio sources.
- Monster pathfinding.
- NPC counts.
- Replication.
- Memory use.
- Streaming.
- Physics.
- Client versus server work.
- Mobile quality settings.

Specify measurable acceptance thresholds and how to test them on representative low-end devices.

Treat all proposed thresholds as tunable until measured.

---

# 7. The 10,000-Idea Research Bank

The goal is not to clutter the game with 10,000 features.

The goal is to create an extensive, searchable pool of candidate ideas so that the team can identify the small number of mechanics and improvements that meaningfully strengthen the game.

Create an indexed research database containing exactly 10,000 valid, distinct candidate records.

Do not generate the entire bank in one response or one uncontrolled output.

Generate it in persistent batches, validate every batch, and continue until the target is actually reached. Preserve progress so work can continue across AI sessions.

If tools or context limits prevent completion during one session, leave a precise progress record and resume from the next unprocessed batch. Do not claim that 10,000 ideas exist until the database count and quality checks demonstrate it.

Do not pad the bank with trivial variations of the same idea.

## 7.1 Research categories

Explore candidate ideas across the following fields and develop finer-grained subcategories.

### Core gameplay

- Survival rules.
- Resource scarcity.
- Time pressure.
- Meaningful tradeoffs.
- Risk/reward decisions.
- Exploration incentives.
- Inventory constraints.
- Crafting choices.
- Base-building systems.
- Defensive preparation.
- Escape mechanics.
- Recovery systems.

### Fire, light, and darkness

- Fire behavior.
- Fuel types.
- Light intensity.
- Light deterioration.
- Temporary light sources.
- Portable protection.
- Connected light networks.
- Environmental darkness.
- Visibility tradeoffs.
- Light-related puzzles.
- Fire-related hazards.
- Light-network failures.

### Monster and threat design

- Recognition and identity.
- Movement.
- Sound-based detection.
- Vision and line of sight.
- Search behavior.
- Chases.
- Ambushes.
- Retreat.
- Defensive testing.
- Adaptive behavior.
- Multiple threat types.
- Environmental interactions.
- Threat escalation.
- Fair counterplay.
- Boss or set-piece encounters.

### Co-op and social systems

- Cooperative roles.
- Shared responsibilities.
- Emergency assistance.
- Resource distribution.
- Rescue mechanics.
- Team coordination.
- Information asymmetry.
- Group decisions.
- Solo balancing.
- Party formation.
- Rejoining.
- Team failure.
- Shared victories.
- Social replay value.

### World and level design

- Forest landmarks.
- Ruined buildings.
- Abandoned settlements.
- Underground locations.
- Environmental hazards.
- Traversal opportunities.
- Hidden areas.
- Safe zones.
- Dangerous shortcuts.
- Dynamic map events.
- Exploration secrets.
- Interactive props.
- Environmental storytelling.

### Campaign and narrative

- Day-by-day escalation.
- Lore clues.
- Environmental stories.
- Characterless storytelling.
- Audio logs and recordings.
- Mysteries.
- Optional discoveries.
- Rescue objectives.
- Signal-tower objectives.
- Escape variations.
- Conditional endings.
- New-campaign hooks.

### Resources and production

- Gathering variants.
- Salvage categories.
- Resource nodes.
- Resource regeneration.
- Weight or carrying constraints.
- Storage.
- Crafting recipes.
- Repair systems.
- Traders.
- Scarcity events.
- Resource sinks.
- Upgrade tradeoffs.

### Environmental systems

- Weather.
- Wind.
- Rain.
- Fog.
- Temperature.
- Visibility.
- Terrain conditions.
- Fire behavior.
- Sound propagation.
- Environmental damage.
- Power or electricity failures.
- Dynamic events.

### Progression and replayability

- Difficulty modifiers.
- Different campaign routes.
- Challenge runs.
- Randomized encounters.
- Optional objectives.
- Unlockable recipes.
- Persistent abilities.
- Cosmetic progression.
- Achievements.
- Leaderboards.
- Endgame modes.
- Replay modifiers.

### Presentation and horror

- Monster silhouettes.
- Distinctive animation.
- Environmental audio.
- Audio misdirection.
- Lighting reveals.
- Camera effects.
- Tension pacing.
- Anticipation.
- Rare encounters.
- Interactive cutscenes.
- Environmental changes.
- Memorable encounter composition.

### UX and accessibility

- Tutorial mechanics.
- Contextual instruction.
- Objective clarity.
- Interaction feedback.
- Screen-reader and assistive considerations where supported.
- Color accessibility.
- Camera comfort.
- Subtitle controls.
- Audio options.
- Difficulty choices.
- Reduced motion options.
- Mobile-first controls.

### Technical enhancements

- AI efficiency.
- Pathfinding optimization.
- Network traffic reduction.
- Modular configuration.
- Data validation.
- Save reliability.
- Replication efficiency.
- Streaming strategies.
- Error recovery.
- Automated tests.
- Diagnostic tools.
- Live balancing tools.

### Abuse prevention and robustness

- Item duplication.
- Invalid resource requests.
- Spam interactions.
- Remote-event abuse.
- Teleport exploits.
- Matchmaking abuse.
- Griefing.
- Deliberate objective sabotage.
- Disconnect abuse.
- AFK abuse.
- Leaderboard manipulation.
- Economic exploits.
- Save corruption.
- Rejoin inconsistencies.

### Ethical retention and monetization

- Earnable cosmetics.
- Clear optional purchases.
- Fair difficulty selection.
- Social rewards.
- Campaign challenges.
- Transparent progression.
- Cosmetic collection.
- Optional cosmetic customization.
- Community events.
- Fair replay rewards.
- Optional premium convenience, subject to a fairness review.

Never treat dark patterns, coercive spending, artificial frustration, deceptive purchases, or pay-to-win mechanics as good design simply because they might increase short-term revenue.

### Additional discovery categories

Explore additional opportunities in:

- Tutorial pacing.
- Player-generated strategies.
- Spectator behavior.
- Streamer-friendly moments.
- Sound and animation synchronization.
- Fail-forward design.
- Game-state recovery.
- Seasonal events.
- Content production efficiency.
- Live-operations tools.
- Localization.
- QA automation.
- Accessibility.
- Emergent gameplay.
- Cooperative storytelling.
- Unusual interaction combinations.
- Controlled randomness.
- Fair competitive challenges.
- Community-generated challenges.
- Systems that create stories players want to share.

The list above establishes a starting taxonomy. Expand it until the idea database has broad coverage and no major subsystem is ignored.

## 7.2 Required idea record

Every idea must have a stable, unique ID.

Use the following compact database schema:

| Field | Description |
|---|---|
| `id` | Unique sequential ID, `IDEA-00001` through `IDEA-10000` |
| `category` | Primary research category |
| `title` | Distinct, searchable idea name |
| `mechanic` | What the feature actually does |
| `player_value` | Why this improves the experience |
| `differentiation` | How it may distinguish the game |
| `effort` | S, M, L, or XL |
| `dependencies` | Required systems or assets |
| `risk` | Principal design or technical risk |
| `novelty_score` | Preliminary score from 1–5 |
| `fun_score` | Preliminary score from 1–5 |
| `feasibility_score` | Preliminary score from 1–5 |
| `status` | Candidate, shortlisted, rejected, or approved |

For the full 10,000-record bank, keep descriptions concise. Expand shortlisted entries into detailed design briefs later.

Do not fabricate precise financial benefits, player-retention percentages, or expected revenue.

Preliminary scores are hypotheses, not playtest results.

## 7.3 Idea quality rules

Every candidate must:

- Describe an understandable mechanic or improvement.
- Have a plausible player-facing benefit.
- Fit the Roblox platform or explain why it may not.
- Be distinct from other candidates.
- Identify major dependencies.
- Identify a meaningful risk.
- Avoid relying on unimplemented infrastructure without acknowledging it.
- Avoid being merely a renamed version of an existing candidate.
- Avoid requiring a complete game redesign unless explicitly labeled a major alternative.

Do not count these as distinct ideas:

- Changing only the name of the monster.
- Changing only the color of a fire.
- Replacing wood with another resource without changing gameplay.
- Adding cosmetic objects that have no meaningful system or presentation value, unless categorized explicitly as cosmetic variants.

Cosmetic ideas may exist in their own category, but do not use cosmetic variations to inflate the core-mechanics research count.

## 7.4 Batch generation protocol

Generate candidates in manageable batches, for example 100–250 ideas at a time.

For every batch:

1. Allocate the next sequential ID range.
2. Generate candidates within assigned categories.
3. Check IDs and record completeness.
4. Compare candidates against existing entries.
5. Flag exact duplicates and likely semantic duplicates.
6. Replace rejected duplicates with new candidates.
7. Validate the required fields.
8. Save the batch to persistent storage.
9. Update a batch manifest and running count.
10. Record unresolved quality problems.

If the system cannot reliably maintain a large CSV, use validated JSONL or another structured format and provide documented import/export procedures.

Do not silently reuse IDs or overwrite previously approved records.

## 7.5 Deduplication and diversity

Deduplicate by meaning, not just by matching titles.

Compare each proposal with existing ideas based on:

- Primary mechanic.
- Player action.
- Player benefit.
- Trigger condition.
- Consequence.
- Required system.
- Overall gameplay effect.

Keep two similar ideas only when their differences lead to genuinely distinct decisions or player experiences.

Use different categories, but do not assume that putting an idea in a different category automatically makes it unique.

Maintain a quality report containing:

- Total records.
- Valid records.
- Missing fields.
- Duplicate IDs.
- Exact duplicates.
- Suspected semantic duplicates.
- Count by category.
- Count by effort.
- Count by status.
- Top categories with underdeveloped coverage.
- Batch completion status.
- Remaining work to reach 10,000 valid candidates.

The count must refer to valid, distinct candidates—not simply the number of generated rows.

---

# 8. Systematic Evaluation and Selection of the Best Ten

After creating the idea bank, do not select ten ideas arbitrarily.

Build a transparent evaluation process.

## 8.1 First stage: broad screening

Evaluate the complete bank using the preliminary information available.

Exclude or flag ideas that:

- Contradict the approved design pillars.
- Offer little player-facing value.
- Are duplicative.
- Require unreasonable development effort.
- Depend on unsupported platform behavior.
- Damage solo or cooperative balance without a clear justification.
- Create significant performance or exploit risks.
- Are commercially or ethically undesirable.
- Make the game resemble a competitor more closely.
- Add complexity without meaningful decisions.

Record rejection reasons for noteworthy candidates.

Do not reject technically difficult ideas solely because they are difficult; identify their actual tradeoffs.

## 8.2 Second stage: develop the top 100

Write detailed design briefs for approximately 100 strong candidates.

Each brief must explain:

1. The player problem or opportunity.
2. The proposed mechanic.
3. Exact player actions.
4. The resulting game-state changes.
5. How it creates fun, tension, surprise, cooperation, or meaningful choice.
6. Why it suits this game.
7. How it differs from the current design.
8. Dependencies.
9. Server/client responsibilities.
10. Mobile requirements.
11. Performance costs.
12. Abuse and exploit scenarios.
13. Interaction with existing systems.
14. Minimum playable prototype.
15. Testable success criteria.
16. Estimated effort using relative sizing.
17. Reasons it may fail.

Do not write implementation code.

## 8.3 Third stage: weighted scoring

Use this initial scoring model. Adjust it only when a documented reason justifies the change.

| Criterion | Weight |
|---|---:|
| Meaningful differentiation | 20% |
| Moment-to-moment fun and horror tension | 20% |
| Technical feasibility | 15% |
| Mobile and input usability | 10% |
| Cooperative and solo gameplay quality | 10% |
| Replayability and long-term interest | 10% |
| Alignment with the game vision | 10% |
| Performance and implementation efficiency | 5% |
| **Total** | **100%** |

Score each criterion from 1 to 5.

Calculate the weighted result using:

`Weighted score = SUM(weight × rating / 5)`

The result is a score out of 100.

A high aggregate score must not conceal a fatal flaw. Add explicit risk gates and mandatory review for major security, feasibility, performance, or originality concerns.

## 8.4 Fourth stage: combinations and conflicts

Do not assume the ten highest-scoring standalone ideas will form the best game.

Identify synergies and conflicts.

For example:

- Fuel depletion may complement monster escalation.
- A light network may complement exploration and cooperative assignments.
- Too many environmental hazards may undermine resource planning.
- Multiple complex subsystems may be unrealistic for an initial release.
- A mechanic that creates tension in solo play may be trivialized by five coordinated players.

Evaluate feature combinations and their dependencies.

Create a compatibility matrix showing whether proposed systems complement, conflict with, or are independent of one another.

## 8.5 Fifth stage: final shortlist

Produce `TOP_10_RECOMMENDATIONS.md`.

For each of the ten recommendations, include:

- Name.
- Score.
- Confidence level.
- Player-facing value.
- Differentiation argument.
- Expected moment of delight, fear, or cooperation.
- Implementation cost.
- Main dependencies.
- Biggest design risk.
- Prototype plan.
- Acceptance criteria.
- Why it ranked above alternatives.
- What should be removed or postponed if implementation cost grows.

The final ten are **recommendations for the project owner to approve**. Do not silently change their status to approved.

A smaller combination of three excellent systems can be better than ten independent features.

If only six or seven ideas meet the quality threshold, explain that rather than inflating the ranking.

---

# 9. Monster Identity and Signature Gameplay

Create dedicated design work for a memorable original monster.

Do not start by giving a generic monster a name and an unusual model.

Explore a coherent design across four layers:

### Visual identity

Define silhouette, proportions, movement, distinctive features, distance readability, and how the monster appears in low light.

### Behavioral identity

Define what it does that players can learn, anticipate, exploit, fear, and discuss.

### Audio identity

Define a recognizable sound language: distant cues, approach signals, misleading sounds if justified, attack indicators, and retreat cues.

### Mechanical identity

Define the interaction between the monster and the game's signature systems.

Possible design directions to evaluate include:

- Fear or avoidance of specific types of fire or light.
- Hunting through darkness.
- Learning from repeated player strategies.
- Testing defenses before attacking.
- Investigating sound.
- Reacting differently to isolated and grouped players.
- Changing behavior when the fire is weak.
- Searching for ways to interrupt exploration.
- Distinctive behavior during key story events.

These are candidates, not a requirement to include them all.

Create at least several substantially different monster concepts for research, compare their strengths and weaknesses, and explain why the recommended design belongs to this game.

Avoid simply reproducing an existing Roblox horror monster.

Do not finalize a monster design without reviewing its gameplay, silhouette, production cost, and originality together.

---

# 10. Environmental Storytelling and Campaign Identity

Develop the world as a system of clues rather than a collection of decorative props.

Explain how players can discover:

- What happened to the city.
- Why the monster fears fire.
- Who occupied the abandoned shelter.
- Why important resources are left behind.
- What happened to previous survivors.
- Whether the forest and city have a deeper connection.
- What activating the proposed escape objective actually means.

Create a lore timeline and consistency rules.

Distinguish facts the player can observe from interpretations the story encourages.

Let optional discoveries enrich the story without making the primary survival loop dependent on finding every hidden object.

Evaluate how the narrative can produce memorable player discoveries and discussion without requiring long exposition scenes.

---

# 11. Fair Retention, Progression, and Monetization

Explore progression systems, but focus on genuine replay value.

Potential areas include:

- Run-specific resources.
- Permanent unlocks.
- Cosmetic items.
- Campaign modifiers.
- Difficulty settings.
- Achievements.
- Optional challenges.
- Player statistics.
- Cooperative milestones.
- Environmental discoveries.
- New monster encounters.
- New map configurations.
- Seasonal content.

Clearly distinguish progression that affects gameplay balance from cosmetic or convenience rewards.

Do not punish players for missing a day of logins.

Do not sell advantages that invalidate the core survival challenge.

Do not design artificial waiting periods or frustrating failure loops solely to pressure purchases.

Document any proposed monetization separately from the core survival experience, including fairness, clarity, and platform-policy risks.

Prioritize whether the game remains fun without spending Robux.

---

# 12. Test Strategy and Acceptance Criteria

Create a measurable verification strategy for the project.

Every essential system and daily campaign document must have explicit tests.

## Core gameplay tests

Test:

- A new player understanding the objective.
- Gathering and resource delivery.
- Lighting the campfire.
- Fuel consumption and extinction.
- Monster retreat from a protective area.
- Day-to-night transitions.
- Night survival.
- Morning reset and progression.
- Escape objectives.
- Success and failure conditions.

## Multiplayer tests

Test:

- Solo.
- Two players.
- Five players.
- A player joining at an unsupported point.
- A player disconnecting during a critical event.
- The party leader leaving.
- Simultaneous interactions.
- Two players attempting the same resource.
- Duplicate objective completion.
- Teleport failure.
- Save failure.
- Server shutdown.

## Abuse tests

Test:

- Forged remote parameters.
- Repeated resource claims.
- Invalid crafting requests.
- Negative or excessive quantities.
- Purchase duplication.
- Movement and interaction edge cases.
- Objective skipping.
- Unintended safe spots.
- Monster pathfinding abuse.
- Disconnect/rejoin exploitation.
- Unauthorized reward claims.

## Device tests

Define scenarios for desktop, mobile, tablet, and controller where supported.

Evaluate low-end hardware, low memory, unstable connections, small screens, and changing network conditions.

## Playtesting questions

Determine:

- How quickly new players understand the first objective.
- Where confusion occurs.
- Whether the monster feels threatening but fair.
- Whether players understand why fire protects them.
- Whether collecting and maintaining resources remains engaging.
- Whether cooperation adds value.
- Whether solo play remains viable.
- Whether players voluntarily replay.
- Which features produce memorable moments.
- Which systems create frustration rather than tension.

Never claim a test passed unless evidence of execution exists.

Clearly separate test cases that have been written from tests that have actually been run.

---

# 13. Analytics and Evidence-Based Balancing

Design instrumentation that can answer specific product questions.

Consider events such as:

- Session started.
- Prologue completed.
- Shelter discovered.
- First resource collected.
- Campfire ignited.
- First night survived.
- Fire extinguished.
- Monster encountered.
- Player chased.
- Player damaged or eliminated.
- Resource gathered and spent.
- Base upgrade purchased or crafted.
- Objective completed or failed.
- Player disconnected.
- Campaign escaped.
- Campaign failed.
- Session ended.
- Returning player session started.

For every important event, specify its purpose, parameters, ownership, privacy considerations, and the gameplay decision it helps inform.

Do not collect personal information unnecessarily.

Define how to measure onboarding completion, campaign completion, failure rates, session engagement, and return behavior using legitimate platform analytics and appropriate aggregated measurements.

Do not establish false success targets based on invented industry averages.

Initial thresholds should be explicitly marked as hypotheses.

---

# 14. Technical Design Standards

All technical documents must be clear enough for a different AI coding assistant or developer to implement each subsystem consistently.

Use:

- Clear responsibilities.
- Explicit ownership.
- State diagrams.
- Data schemas.
- Event contracts.
- Preconditions and postconditions.
- Error-handling rules.
- Security validation.
- Acceptance criteria.
- Dependencies.
- Configuration tables.
- Cross-references to related docs.

Where pseudocode helps, use language-neutral pseudocode or small Luau-oriented examples. The primary task remains documentation, not implementation.

Do not use vague requirements such as:

- "Make the monster smarter."
- "Improve the lighting."
- "Add better multiplayer."
- "Save progress properly."
- "Optimize everything."

Replace them with observable, testable behavior.

For example, specify the conditions under which the monster changes state, the authority that makes the decision, what players observe, and which tests prove the behavior is correct.

Verify technical details against current official Roblox documentation when possible. Record API references and any applicable caveats.

---

# 15. Cross-Document Consistency

Build an explicit link between high-level design and implementation.

For example:

`Campaign Day 2 → Fire System → Server Authority → UI Fuel Display → QA Tests → Analytics`

When a mechanic changes, identify its downstream dependencies.

Maintain:

- A system dependency matrix.
- A requirements traceability table.
- A decision log.
- An unresolved-questions register.
- A change log.
- A list of features requiring approval.
- A list of verified implementations.
- A list of known inconsistencies.

The documentation must not claim a system is approved or implemented merely because the related file exists.

When a recommendation is rejected, preserve the reason if it is likely to matter in future design decisions.

---

# 16. Recommended Implementation Plan

The documentation should support phased development.

## Phase 0 — Foundation and prototype

Prioritize:

- Minimal test map.
- Basic player controls.
- One shelter.
- Basic resource gathering.
- Campfire.
- Day/night state machine.
- One monster.
- One complete survival night.

Success means the core loop works reliably before large-scale content creation.

## Phase 1 — Vertical slice

Deliver a polished, playable introduction that covers the city prologue, forest escape, shelter, first resource loop, first night, and dawn.

Include:

- Core UI.
- Audio cues.
- Initial monster encounter.
- Working multiplayer.
- Mobile usability.
- Tested fail and recovery conditions.

The vertical slice should test whether the game is fun, not merely whether the code runs.

## Phase 2 — Campaign foundation

Build out Days 2–5 and the minimum required systems for progression, exploration, crafting, and the ending.

Only include the connected-light network or other major signature mechanics after design review and prototype testing support them.

## Phase 3 — Quality, progression, and replayability

Improve:

- Balance.
- Save reliability.
- Performance.
- Cooperative play.
- Accessibility.
- Replay modifiers.
- Cosmetics and achievements, where justified.
- Testing coverage.
- Telemetry.

## Phase 4 — Post-launch content

Plan future updates only after the core experience works.

Potential updates include additional map areas, monster behaviors, optional encounters, campaign variations, cosmetics, and seasonal content.

Do not promise a content cadence that the team cannot sustain.

For every phase, specify dependencies, deliverables, exit criteria, risks, and estimated effort using relative sizing rather than invented calendar certainty.

---

# 17. Required Final Deliverables

Before declaring the documentation task complete, create and validate the actual files.

Minimum deliverables:

1. A documentation index and project-status report.
2. A consistent game vision and design-pillar document.
3. Separate Day 0, Day 1, Day 2, Day 3, Day 4, and Day 5 documents.
4. Core gameplay and campaign documentation.
5. Detailed monster, fire, resources, base-building, matchmaking, and progression specifications.
6. A technical architecture and recommended folder structure.
7. Server authority, networking, and exploit-prevention specifications.
8. Data models, persistence, UI, performance, and testing specifications.
9. Market research and a differentiation strategy, with unverifiable claims identified.
10. A structured idea taxonomy and generation protocol.
11. A persistent database containing 10,000 valid, distinct candidate ideas, with an auditable count and quality report.
12. A detailed top-100 research shortlist.
13. A top-30 selection document.
14. A weighted and reasoned top-10 recommendation document.
15. A compatibility matrix explaining how recommended mechanics interact.
16. A decision log and unresolved-questions register.
17. A prototype and implementation roadmap.
18. A QA plan and definition of done.

If the full 10,000-idea requirement cannot be completed because of tool or time constraints, create the repository, complete the highest-value design documents first, persist all work completed, and record the exact remaining batch range. Never misrepresent partial completion.

Do not leave the idea-research work as a hypothetical procedure. Generate the candidates and validate them to the extent the environment allows.

---

# 18. Final Quality Audit

After creating the documents, perform a consistency audit.

Check that:

- The six campaign documents tell one coherent story.
- Day 0 transitions correctly into Day 1.
- Day 1 teaches the actual core loop.
- Days 2–5 introduce mechanics at a sensible pace.
- The proposed ending is supported by the preceding mechanics.
- Monster behavior is defined consistently.
- Every fire and light rule has one authoritative specification.
- Server authority is consistent across gameplay systems.
- Resource costs and inventory rules agree.
- Player death and disconnection do not produce contradictory behavior.
- Every major mechanic has acceptance criteria.
- Proposed numerical values are labeled correctly.
- No unverified external claim is treated as fact.
- The idea catalog has unique IDs and valid fields.
- The catalog does not inflate its count using duplicates.
- The top ten are supported by the selection criteria.
- Implementation dependencies are documented.
- Unapproved ideas remain proposals.
- The documentation can be navigated by a fresh AI coding agent.

Run mechanical validation scripts if the environment supports them.

Report unresolved contradictions rather than concealing them.

---

# 19. How to Work

Execute this task in the following order:

**Step 1:** Inspect the source GDD, repository, and available tools.

**Step 2:** Create the documentation index, status report, source-of-truth register, vision, design pillars, and campaign overview.

**Step 3:** Write the detailed Day 0–Day 5 documents.

**Step 4:** Write core system specifications and technical architecture.

**Step 5:** Write testing, security, analytics, production, and implementation planning documents.

**Step 6:** Establish the research taxonomy and candidate-scoring protocol.

**Step 7:** Generate, save, deduplicate, and validate the idea-bank batches until 10,000 valid candidate records exist or a real environment limitation prevents completion.

**Step 8:** Evaluate combinations, produce the top 100, narrow them to the top 30, and prepare the final top-ten recommendations.

**Step 9:** Perform the cross-document consistency audit and correct contradictions.

**Step 10:** Update the repository index with direct links to every important document.

**Step 11:** Produce a final completion report listing files created, files validated, the exact idea count, remaining issues, key design assumptions, and the next recommended development task.

Do not implement the entire game or generate thousands of lines of unrelated game code as part of this task.

Do not halt after writing a plan when the required documents can actually be created.

Do not claim completion for deliverables that were not generated or verified.

Work persistently, preserve intermediate results, and prioritize consistency over superficial volume.

# Final Mission

The objective is not simply to create a large pile of documentation or 10,000 random mechanics.

The objective is to create a **single, reliable game-development knowledge base** that lets future AI agents understand the project, design features without contradicting one another, implement mechanics against explicit specifications, test their work, and improve the game without destroying its identity.

The final game should be recognizable for its own original monster, distinctive survival decisions, cooperative tension, memorable encounters, and satisfying campaign—not merely because it contains many features.

Build the knowledge base that makes that outcome possible.