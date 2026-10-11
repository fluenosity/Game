# Glossary — Project: Undecided

> **Purpose:** Shared vocabulary for all documentation. Use these terms consistently.
> **Last updated:** 2026-10-11

---

## Game Concepts

| Term | Definition |
|------|-----------|
| **Session** | A single game instance containing 1–5 players, isolated from other sessions. Created when players enter a tent in the lobby. |
| **Campaign** | The full Day 0–Day 5 experience within one session. A complete playthrough from cutscene to escape/failure. |
| **Run** | Synonym for campaign. One complete attempt from start to finish. |
| **Day** | A full day/night cycle within the campaign. Numbered Day 0 (prologue) through Day 5 (escape). |
| **Daytime** | The period of each day when the sun is up, the forest is lit, and the monster is less active. Players gather resources. |
| **Nightfall** | The transition period between daytime and night. Gradual darkening. Urgency to return to shelter. |
| **Night** | The dangerous period. The monster actively hunts. Fire is the primary protection. |
| **Dawn** | The transition from night to the next day's morning. The monster retreats. Players survive. |

## Locations

| Term | Definition |
|------|-----------|
| **Lobby** | The Roblox spawn area where players choose their session size by entering tents. |
| **Tent** | One of 5 structures in the lobby, each representing a different session capacity (1–5 players). |
| **City** | The ruined urban area shown in the Day 0 cutscene. Players do not freely explore it (it's a cinematic set piece). |
| **Forest** | The main gameplay environment. Contains trees, resource nodes, landmarks, and dangers. |
| **Shelter** | The player's home base — a small fenced yard in the forest with a sofa, table, and campfire spot. |
| **Campfire Spot** | The designated location within the shelter where players place wood and light fire. Visible stone fire pit. |
| **Resource Node** | A harvestable object in the forest (tree, scrap pile, etc.) that yields materials when interacted with. |

## Characters & Entities

| Term | Definition |
|------|-----------|
| **Player** | A human participant controlling a character in-game. |
| **Monster** | The primary antagonist. A large creature that fears fire and hunts players in darkness. Name TBD. |
| **Wandering Trader** | An NPC that visits the player's camp, offering trades (materials for upgrades/fuel). |

## Resources & Items

| Term | Definition |
|------|-----------|
| **Wood** | The primary resource. Gathered by chopping trees. Used as campfire fuel and basic crafting. |
| **Fuel** | Any material that can be burned in the campfire to maintain fire (wood is the default fuel). |
| **Scrap** | General term for salvageable materials found in the forest (metal, plastic, rope, etc.). |
| **Metal Scrap** | Salvaged metal pieces. Used for shelter upgrades and crafting. |
| **Plastic** | Salvaged plastic. Used for crafting and trading. |
| **Rope** | Salvaged rope. Used for crafting and base reinforcement. |

## Fire & Light

| Term | Definition |
|------|-----------|
| **Campfire** | The main fire at the shelter's campfire spot. Can be upgraded through tiers. |
| **Fire Intensity** | How strong the campfire is currently burning. Affects protection radius. Depletes over time. |
| **Protection Radius** | The area around a fire source where the monster will not enter. Scales with fire intensity. |
| **Fire Tier** | The upgrade level of the campfire (e.g., Tier 1 = basic, Tier 3 = reinforced). Higher tiers = more capacity, bigger radius. |
| **Light Source** | Any object that emits light and potentially repels the monster (campfire, torch, lantern, etc.). |
| **Light Network** | `PROPOSED` A system of connected light sources forming a safe path between locations. |

## Mechanics

| Term | Definition |
|------|-----------|
| **Gathering** | The act of collecting resources from the environment (chopping trees, picking up scrap). |
| **Crafting** | Combining resources to create new items or upgrades. |
| **Trading** | Exchanging scrap materials with the wandering trader for better items. |
| **Base Upgrade** | Improving the shelter's walls, storage, or campfire through resources. |
| **Exploration** | Venturing away from the shelter into the forest to find resources, landmarks, or lore. |

## Technical

| Term | Definition |
|------|-----------|
| **Server** | The Roblox server instance running the game session. Authoritative for all gameplay state. |
| **Client** | The player's device (PC, phone, tablet). Handles input, rendering, and local presentation. |
| **RemoteEvent** | Roblox networking object for one-way server↔client communication. |
| **RemoteFunction** | Roblox networking object for request/response server↔client communication. |
| **DataStore** | Roblox's persistent data storage service for saving player progress. |
| **FSM** | Finite State Machine — a pattern used for monster AI, session lifecycle, day/night state, etc. |
| **FPP** | First-Person Perspective — the camera mode during gameplay. |
| **Luau** | Roblox's programming language (typed Lua variant). |
| **Replication** | The process of synchronizing game state between server and clients. |

## Status Tags

| Tag | Meaning |
|-----|---------|
| `EXISTING_CANON` | Confirmed by the original design document |
| `PROPOSED` | Recommended but not approved |
| `ASSUMPTION` | Temporary value; needs validation |
| `APPROVED` | Accepted by project owner |
| `IMPLEMENTED` | Verified in codebase |
| `VERIFIED` | Tested against implementation |
| `DEPRECATED` | Replaced by newer decision |
| `INITIAL_BALANCE_PROPOSAL` | Numerical value that needs playtesting |
