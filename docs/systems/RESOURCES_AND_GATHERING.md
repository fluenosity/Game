# Resources and Gathering — Project: Undecided

> **Status:** `EXISTING_CANON` (wood, scrap types) + `PROPOSED` (numerical values, spawn rules)
> **Last updated:** 2026-10-11

---

## Resource Types

| Resource | Category | Stack Size | Source | Available From |
|----------|----------|-----------|--------|---------------|
| Wood | Fuel / Crafting | 4 per slot | Choppable trees | Day 1 |
| Metal Scrap | Crafting / Trading | 2 per slot | Debris piles, wreckage | Day 3 |
| Plastic | Crafting / Trading | 2 per slot | Containers, bags | Day 3 |
| Rope | Crafting / Trading | 2 per slot | Trees, crates | Day 3 |
| Premium Fuel | Fuel | 2 per slot | Trader / crafting | Day 3 |
| Battery Pack | Signal component | 1 (unique) | Ruined shack | Day 4 |
| Antenna Wire | Signal component | 1 (unique) | Deep forest | Day 4 |
| Radio Module | Signal component | 1 (unique) | Monster clearing | Day 5 |

---

## Gathering Mechanics

### Tree Chopping

| Parameter | Value | Status |
|-----------|-------|--------|
| Interaction | Hold E / button for 5s | `INITIAL_BALANCE_PROPOSAL` |
| Yield | 2 Wood per tree | `INITIAL_BALANCE_PROPOSAL` |
| Range | 8 studs from tree | `ASSUMPTION` |
| Animation | Chopping motion (looping during hold) | `PROPOSED` |
| Audio | Axe hits, wood cracking, collection thunk | `PROPOSED` |
| Tree state after chop | Stump (non-interactive) | `PROPOSED` |
| Tree respawn | Next dawn | `PROPOSED` |
| Multiplayer | First player to start chopping claims the tree | `PROPOSED` |

### Scrap Collection

| Parameter | Value | Status |
|-----------|-------|--------|
| Interaction | Tap E / button (instant pickup) | `PROPOSED` |
| Yield | 1–2 random scrap items per node | `INITIAL_BALANCE_PROPOSAL` |
| Range | 6 studs from node | `ASSUMPTION` |
| Node types | Debris pile, wrecked object, container, hanging rope | `PROPOSED` |
| Node respawn | Next dawn | `PROPOSED` |

---

## Spawn Rules Per Day

| Day | Choppable Trees | Scrap Nodes | Special Items |
|-----|----------------|-------------|--------------|
| Day 1 | 3 | 0 | None |
| Day 2 | 5–8 | 0 (visible but non-interactive) | None |
| Day 3 | 5–8 | 8–12 | Lore items |
| Day 4 | 5–8 | 10–15 | Battery Pack, Antenna Wire |
| Day 5 | 5–8 | 10–15 | Radio Module |

All counts `INITIAL_BALANCE_PROPOSAL`. Scale with co-op player count (see Gameplay Balance).

---

## Server Authority

- Resource nodes are server-managed entities with unique IDs.
- Collection is validated server-side: node exists, node not already collected, player in range.
- Inventory changes are server-authoritative.
- Client sends `CollectRequest(nodeId)` → server validates → server grants items → client updates UI.
- Duplicate collection prevention: node state changes to "collected" on server immediately upon first valid request.
