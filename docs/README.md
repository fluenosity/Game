# Project: Undecided — Documentation Repository

> **Working title:** Project: Undecided
> **Platform:** Roblox
> **Genre:** Survival Horror (Solo & Co-op)
> **Session size:** 1–5 players
> **Status:** Pre-production / Documentation phase

---

## Navigation Index

### Core Design

| Document | Description |
|----------|-------------|
| [00_PROJECT_STATUS.md](./00_PROJECT_STATUS.md) | Current project state, what exists, what's missing |
| [01_GAME_VISION.md](./01_GAME_VISION.md) | Vision statement, design pillars, target experience |
| [02_SOURCE_OF_TRUTH.md](./02_SOURCE_OF_TRUTH.md) | Central register of all design decisions and their status |
| [03_GLOSSARY.md](./03_GLOSSARY.md) | Shared terminology for the entire project |
| [04_CORE_GAMEPLAY_LOOP.md](./04_CORE_GAMEPLAY_LOOP.md) | The fundamental loop: gather → prepare → defend → survive |
| [05_CAMPAIGN_OVERVIEW.md](./05_CAMPAIGN_OVERVIEW.md) | Day 0–5 campaign structure and progression arc |
| [06_PLAYER_EXPERIENCE.md](./06_PLAYER_EXPERIENCE.md) | Target emotions, pacing, onboarding, and player journey |
| [07_GAMEPLAY_BALANCE.md](./07_GAMEPLAY_BALANCE.md) | All tunable values, balance philosophy, and testing approach |

### Campaign (Day-by-Day)

| Document | Description |
|----------|-------------|
| [campaign/DAY_00_PROLOGUE.md](./campaign/DAY_00_PROLOGUE.md) | City destruction cutscene, monster reveal, escape |
| [campaign/DAY_01_FIRST_SURVIVAL.md](./campaign/DAY_01_FIRST_SURVIVAL.md) | Find shelter, gather wood, first campfire, first night |
| [campaign/DAY_02_FIRE_AND_PREPARATION.md](./campaign/DAY_02_FIRE_AND_PREPARATION.md) | Fuel management, fire upgrades, preparation decisions |
| [campaign/DAY_03_SCAVENGING_AND_DISCOVERY.md](./campaign/DAY_03_SCAVENGING_AND_DISCOVERY.md) | Scrap materials, crafting, trading, exploration |
| [campaign/DAY_04_DARKNESS_AND_ESCALATION.md](./campaign/DAY_04_DARKNESS_AND_ESCALATION.md) | Escalated threats, adaptive monster, new challenges |
| [campaign/DAY_05_SIGNAL_AND_ESCAPE.md](./campaign/DAY_05_SIGNAL_AND_ESCAPE.md) | Final objective, signal tower, escape sequence, endings |

### Systems Design

| Document | Description |
|----------|-------------|
| [systems/SESSION_MATCHMAKING.md](./systems/SESSION_MATCHMAKING.md) | Lobby, tents, party formation, session lifecycle |
| [systems/DAY_NIGHT_CYCLE.md](./systems/DAY_NIGHT_CYCLE.md) | Time progression, transitions, warnings |
| [systems/MONSTER_AI.md](./systems/MONSTER_AI.md) | Monster state machine, behavior rules, escalation |
| [systems/MONSTER_IDENTITY_AND_BEHAVIOR.md](./systems/MONSTER_IDENTITY_AND_BEHAVIOR.md) | Visual, audio, behavioral, and mechanical identity |
| [systems/FIRE_AND_FUEL.md](./systems/FIRE_AND_FUEL.md) | Campfire mechanics, fuel, protection radius, upgrades |
| [systems/LIGHT_NETWORK.md](./systems/LIGHT_NETWORK.md) | Connected light sources, coverage rules (PROPOSED) |
| [systems/RESOURCES_AND_GATHERING.md](./systems/RESOURCES_AND_GATHERING.md) | Resource types, nodes, gathering, spawn rules |
| [systems/SHELTER_AND_BASE_BUILDING.md](./systems/SHELTER_AND_BASE_BUILDING.md) | Shelter upgrades, walls, storage, expansion |
| [systems/CRAFTING_AND_UPGRADES.md](./systems/CRAFTING_AND_UPGRADES.md) | Recipes, stations, upgrade tiers |
| [systems/TRADING_AND_ECONOMY.md](./systems/TRADING_AND_ECONOMY.md) | Wandering trader, prices, economy balance |
| [systems/PLAYER_HEALTH_AND_DEATH.md](./systems/PLAYER_HEALTH_AND_DEATH.md) | HP, damage, death, revival, failure |
| [systems/INVENTORY_AND_ITEM_RULES.md](./systems/INVENTORY_AND_ITEM_RULES.md) | Slots, stacking, carry limits, item definitions |
| [systems/COOPERATION_AND_PARTIES.md](./systems/COOPERATION_AND_PARTIES.md) | Co-op roles, shared objectives, team mechanics |
| [systems/ENVIRONMENTAL_EVENTS.md](./systems/ENVIRONMENTAL_EVENTS.md) | Weather, wind, rain, dynamic events |
| [systems/LORE_AND_STORY.md](./systems/LORE_AND_STORY.md) | Backstory, clues, environmental storytelling |
| [systems/ENDINGS_AND_EXTRACTION.md](./systems/ENDINGS_AND_EXTRACTION.md) | Win conditions, multiple endings, escape |
| [systems/META_PROGRESSION.md](./systems/META_PROGRESSION.md) | Persistent unlocks, cosmetics, achievements |
| [systems/DIFFICULTY_AND_REPLAYABILITY.md](./systems/DIFFICULTY_AND_REPLAYABILITY.md) | Difficulty scaling, modifiers, replay value |

### Technical Architecture

| Document | Description |
|----------|-------------|
| [technical/TECHNICAL_OVERVIEW.md](./technical/TECHNICAL_OVERVIEW.md) | Architecture goals, system boundaries, services |
| [technical/ROBLOX_ARCHITECTURE.md](./technical/ROBLOX_ARCHITECTURE.md) | Roblox-specific patterns, services, constraints |
| [technical/RECOMMENDED_FOLDER_STRUCTURE.md](./technical/RECOMMENDED_FOLDER_STRUCTURE.md) | Luau module layout and responsibilities |
| [technical/SERVER_AUTHORITY_AND_SECURITY.md](./technical/SERVER_AUTHORITY_AND_SECURITY.md) | Trust model, validation rules |
| [technical/NETWORKING_AND_REMOTES.md](./technical/NETWORKING_AND_REMOTES.md) | RemoteEvents, RemoteFunctions, rate limits |
| [technical/MATCH_LIFECYCLE_AND_STATE_MACHINES.md](./technical/MATCH_LIFECYCLE_AND_STATE_MACHINES.md) | Session states, transitions, error recovery |
| [technical/DATA_MODELS_AND_SCHEMAS.md](./technical/DATA_MODELS_AND_SCHEMAS.md) | Data structures for all game entities |
| [technical/PERSISTENCE_AND_SAVE_RECOVERY.md](./technical/PERSISTENCE_AND_SAVE_RECOVERY.md) | DataStore usage, save strategy, migration |
| [technical/PLAYER_JOIN_LEAVE_AND_DISCONNECTS.md](./technical/PLAYER_JOIN_LEAVE_AND_DISCONNECTS.md) | Join/leave/crash handling per game state |
| [technical/MONSTER_AI_TECHNICAL_DESIGN.md](./technical/MONSTER_AI_TECHNICAL_DESIGN.md) | FSM implementation, pathfinding, performance |
| [technical/INTERACTION_FRAMEWORK.md](./technical/INTERACTION_FRAMEWORK.md) | Proximity prompts, actions, validation |
| [technical/UI_AND_INPUT_ARCHITECTURE.md](./technical/UI_AND_INPUT_ARCHITECTURE.md) | HUD, menus, touch/keyboard/controller |
| [technical/AUDIO_AND_LIGHTING_PIPELINE.md](./technical/AUDIO_AND_LIGHTING_PIPELINE.md) | Sound system, lighting, atmosphere |
| [technical/PERFORMANCE_AND_MOBILE.md](./technical/PERFORMANCE_AND_MOBILE.md) | FPS budgets, mobile optimization, LOD |
| [technical/TELEMETRY_AND_ANALYTICS.md](./technical/TELEMETRY_AND_ANALYTICS.md) | Events to track, retention metrics |
| [technical/EXPLOIT_THREAT_MODEL.md](./technical/EXPLOIT_THREAT_MODEL.md) | Known exploit vectors and mitigations |

### Production

| Document | Description |
|----------|-------------|
| [production/ART_DIRECTION.md](./production/ART_DIRECTION.md) | Visual style, palette, mood references |
| [production/ENVIRONMENT_AND_MAP_LAYOUT.md](./production/ENVIRONMENT_AND_MAP_LAYOUT.md) | City, forest, shelter layout |
| [production/AUDIO_DESIGN.md](./production/AUDIO_DESIGN.md) | Sound palette, music, ambient, monster audio |
| [production/ANIMATION_REQUIREMENTS.md](./production/ANIMATION_REQUIREMENTS.md) | Character, monster, environment animations |
| [production/ACCESSIBILITY_AND_ONBOARDING.md](./production/ACCESSIBILITY_AND_ONBOARDING.md) | Accessibility features, tutorial design |
| [production/QA_AND_ACCEPTANCE_CRITERIA.md](./production/QA_AND_ACCEPTANCE_CRITERIA.md) | Per-system acceptance criteria |
| [production/PLAYTEST_PLAN.md](./production/PLAYTEST_PLAN.md) | Playtest schedule, goals, feedback process |
| [production/RELEASE_CHECKLIST.md](./production/RELEASE_CHECKLIST.md) | Pre-launch checklist |
| [production/CONTENT_ROADMAP.md](./production/CONTENT_ROADMAP.md) | Post-launch content plan |
| [production/RISK_REGISTER.md](./production/RISK_REGISTER.md) | Known risks and mitigations |

### Research

| Document | Description |
|----------|-------------|
| [research/MARKET_AND_COMPETITOR_RESEARCH.md](./research/MARKET_AND_COMPETITOR_RESEARCH.md) | Genre analysis, competitor breakdown |
| [research/DESIGN_PILLARS.md](./research/DESIGN_PILLARS.md) | Core design principles |
| [research/DIFFERENTIATION_STRATEGY.md](./research/DIFFERENTIATION_STRATEGY.md) | How we stand out from competitors |
| [research/IDEA_TAXONOMY.md](./research/IDEA_TAXONOMY.md) | Category system for idea research |
| [research/IDEA_GENERATION_PROTOCOL.md](./research/IDEA_GENERATION_PROTOCOL.md) | How ideas are generated, validated, stored |
| [research/IDEA_SCORING_MODEL.md](./research/IDEA_SCORING_MODEL.md) | Weighted scoring criteria |
| [research/IDEA_CATALOG_README.md](./research/IDEA_CATALOG_README.md) | Schema and usage guide for the idea database |
| [research/IDEA_QUALITY_REPORT.md](./research/IDEA_QUALITY_REPORT.md) | Validation stats, duplicates, coverage |
| [research/TOP_100_CANDIDATES.md](./research/TOP_100_CANDIDATES.md) | Detailed briefs for top 100 ideas |
| [research/TOP_30_CANDIDATES.md](./research/TOP_30_CANDIDATES.md) | Narrowed shortlist with deeper analysis |
| [research/TOP_10_RECOMMENDATIONS.md](./research/TOP_10_RECOMMENDATIONS.md) | Final recommended mechanics for approval |
| [research/REJECTED_IDEAS_AND_RATIONALE.md](./research/REJECTED_IDEAS_AND_RATIONALE.md) | Notable rejections and why |

### Decisions & Tracking

| Document | Description |
|----------|-------------|
| [decisions/DECISION_LOG.md](./decisions/DECISION_LOG.md) | All design decisions with status |
| [decisions/OPEN_QUESTIONS.md](./decisions/OPEN_QUESTIONS.md) | Unresolved design questions |
| [decisions/CHANGELOG.md](./decisions/CHANGELOG.md) | Document change history |

### Testing

| Document | Description |
|----------|-------------|
| [testing/TEST_STRATEGY.md](./testing/TEST_STRATEGY.md) | Overall test approach |
| [testing/CORE_GAMEPLAY_TESTS.md](./testing/CORE_GAMEPLAY_TESTS.md) | Tests for the survival loop |
| [testing/MULTIPLAYER_TESTS.md](./testing/MULTIPLAYER_TESTS.md) | Co-op and networking tests |
| [testing/EXPLOIT_AND_ABUSE_TESTS.md](./testing/EXPLOIT_AND_ABUSE_TESTS.md) | Security and abuse prevention tests |
| [testing/DEVICE_COMPATIBILITY_MATRIX.md](./testing/DEVICE_COMPATIBILITY_MATRIX.md) | Platform/device test matrix |

### Implementation

| Document | Description |
|----------|-------------|
| [implementation/IMPLEMENTATION_ROADMAP.md](./implementation/IMPLEMENTATION_ROADMAP.md) | Phased development plan |
| [implementation/PHASE_00_PROTOTYPE.md](./implementation/PHASE_00_PROTOTYPE.md) | Foundation prototype scope |
| [implementation/PHASE_01_VERTICAL_SLICE.md](./implementation/PHASE_01_VERTICAL_SLICE.md) | Polished intro slice |
| [implementation/PHASE_02_CAMPAIGN.md](./implementation/PHASE_02_CAMPAIGN.md) | Full campaign build-out |
| [implementation/PHASE_03_POLISH.md](./implementation/PHASE_03_POLISH.md) | Balance, accessibility, progression |
| [implementation/DEFINITION_OF_DONE.md](./implementation/DEFINITION_OF_DONE.md) | What "done" means for each feature |

---

> **Last updated:** 2026-10-11
> **Document count:** 60+ files across 9 directories
> **Idea bank:** 500 distinct deduplicated candidates
