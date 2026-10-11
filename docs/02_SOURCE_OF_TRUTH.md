# Source of Truth Register — Project: Undecided

> **Purpose:** Central register of every design decision and its current status.
> **Rule:** If this document disagrees with any other document, THIS document is authoritative.
> **Last updated:** 2026-10-11

---

## Status Definitions

| Status | Meaning |
|--------|---------|
| `EXISTING_CANON` | Explicitly specified in the original Game.md design document |
| `PROPOSED` | Recommendation that has NOT been approved by the project owner |
| `ASSUMPTION` | Temporary value used to continue design work; needs validation |
| `APPROVED` | Proposal explicitly accepted by the project owner |
| `IMPLEMENTED` | Verified in the actual codebase |
| `VERIFIED` | Tested against implementation or authoritative source |
| `DEPRECATED` | Previously used but replaced by a documented decision |

---

## Game Identity

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| Platform is Roblox | `EXISTING_CANON` | Game.md | — |
| Genre is survival horror | `EXISTING_CANON` | Game.md | — |
| 1–5 players per session | `EXISTING_CANON` | Game.md | Original notes said max 4; lobby design says 5. Using 5. |
| Solo play is supported | `EXISTING_CANON` | Game.md | — |
| Co-op play is supported | `EXISTING_CANON` | Game.md | — |
| Working title: "Project: Undecided" | `ASSUMPTION` | task.md | No official name approved |
| 5-day campaign structure | `PROPOSED` | Analysis | Original doc had open-ended days |
| Finite end goal (escape/signal) | `PROPOSED` | Analysis | No end goal in original doc |

## Lobby & Matchmaking

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| Lobby has 5 tents (1–5 players) | `EXISTING_CANON` | Game.md | — |
| Each tent has a visible capacity sign | `EXISTING_CANON` | Game.md | — |
| Friends in same tent → same session | `EXISTING_CANON` | Game.md | — |
| Different tents → never mixed | `EXISTING_CANON` | Game.md | — |
| 1-player tent starts immediately | `EXISTING_CANON` | Game.md | — |
| 2–5 player tents have a waiting timer | `EXISTING_CANON` | Game.md | — |
| Timer expiry starts with current players | `EXISTING_CANON` | Game.md | — |
| Waiting timer duration | `ASSUMPTION` | — | 60 seconds assumed; needs tuning |

## Cutscene & Prologue (Day 0)

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| Opening cutscene shows ruined city | `EXISTING_CANON` | Game.md | — |
| City has broken buildings, crashed cars, fires, debris | `EXISTING_CANON` | Game.md | — |
| People running in fear (optional) | `EXISTING_CANON` | Game.md | "If possible" |
| Monster appears from behind a building | `EXISTING_CANON` | Game.md | — |
| Monster sees fire and runs away | `EXISTING_CANON` | Game.md | — |
| No dialogue in cutscene | `EXISTING_CANON` | Game.md | "Without any dialogue or explanation" |
| Cutscene is 10–15 seconds | `EXISTING_CANON` | Game.md | — |
| Cutscene is cinematic and slightly scary | `EXISTING_CANON` | Game.md | — |
| Skip controls for cutscene | `PROPOSED` | task.md | Needed for replay |

## Day 1 — First Survival

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| Day 1 starts with short escape cutscene | `EXISTING_CANON` | Game.md | Character running to forest |
| Camera switches to FPP after cutscene | `EXISTING_CANON` | Game.md | — |
| First task: find shelter via clear path | `EXISTING_CANON` | Game.md | One path, no puzzles |
| Shelter is a fenced yard (chain-link fence) | `EXISTING_CANON` | Game.md | — |
| Shelter contains: old sofa, table, campfire spot | `EXISTING_CANON` | Game.md | — |
| Campfire spot is immediately obvious | `EXISTING_CANON` | Game.md | Circular stone pit |
| Second task: chop 2 trees for wood | `EXISTING_CANON` | Game.md | — |
| Return to shelter before nightfall | `EXISTING_CANON` | Game.md | — |
| Light campfire with collected wood | `EXISTING_CANON` | Game.md | — |
| Monster fears fire (protection) | `EXISTING_CANON` | Game.md | — |
| Day 1 ends: player sleeps on sofa | `EXISTING_CANON` | Game.md | — |
| Screen fades to black → "DAY 2" | `EXISTING_CANON` | Game.md | — |
| Day 1 is simple introduction, no complex mechanics | `EXISTING_CANON` | Game.md | — |

## Day 2

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| Morning wood gathering (daily routine) | `EXISTING_CANON` | Game.md | — |
| Upgrade campfire to stronger flames | `EXISTING_CANON` | Game.md | — |
| Bigger fire = larger safe zone | `EXISTING_CANON` | Game.md | — |
| Fire depletion mechanic (actively feed fire) | `PROPOSED` | Analysis | Not in original doc |
| Fuel types (different materials) | `PROPOSED` | task.md | — |
| Weather effects on fire | `PROPOSED` | task.md | — |

## Day 3+

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| Scavenge forest for metal, plastic, rope | `EXISTING_CANON` | Game.md | — |
| Sell scrap to wandering trader | `EXISTING_CANON` | Game.md | — |
| Trade for better campfire material | `EXISTING_CANON` | Game.md | — |
| Upgrade base (walls, storage) | `EXISTING_CANON` | Game.md | — |
| Crafting system | `PROPOSED` | task.md | Original only mentions trading |
| Connected light network | `PROPOSED` | task.md | — |

## Monster

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| A monster exists that hunts players | `EXISTING_CANON` | Game.md | — |
| Monster fears fire | `EXISTING_CANON` | Game.md | — |
| Monster hunts when no light nearby | `EXISTING_CANON` | Game.md | — |
| Monster name / identity | `PROPOSED` | Analysis | No name in original doc |
| Monster learns from player behavior | `PROPOSED` | Analysis | — |
| Sound-based detection | `PROPOSED` | Analysis | — |
| Multiple monster types | `PROPOSED` | task.md | — |

## Progression & Retention

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| Save system | `PROPOSED` | Game.md | "We can maybe add" — not confirmed |
| Daily login rewards | `PROPOSED` | Analysis | — |
| Cosmetic unlocks | `PROPOSED` | Analysis | — |
| Leaderboards | `PROPOSED` | Analysis | — |
| Battle pass | `PROPOSED` | Analysis | — |
| Achievement badges | `PROPOSED` | Analysis | — |
| Multiple endings | `PROPOSED` | Analysis | — |

## Technical

| Decision | Status | Source | Notes |
|----------|--------|--------|-------|
| Must run on mobile | `EXISTING_CANON` | task.md | ~60% of Roblox players |
| Must support controllers | `PROPOSED` | task.md | "Where practical" |
| Server-authoritative gameplay | `PROPOSED` | task.md | Standard Roblox best practice |
| Luau programming language | `ASSUMPTION` | — | Standard for Roblox |

---

## Conflict Resolution Log

| # | Conflict | Resolution | Date |
|---|----------|------------|------|
| 1 | Max players: 4 (rough notes) vs 5 (lobby design) | Use 5 — lobby design is the structured, later version | 2026-10-11 |
| 2 | Campaign length: undefined | Propose 5-day structure; awaiting approval | 2026-10-11 |
| 3 | Save system: "maybe" vs needed | Mark as PROPOSED until owner decides | 2026-10-11 |
