# Shelter and Base Building — Project: Undecided

> **Status:** `EXISTING_CANON` (shelter concept, upgrades) + `PROPOSED` (specifics)
> **Last updated:** 2026-10-11

---

## Shelter Design

`EXISTING_CANON` The shelter is a small yard surrounded by a metal mesh/chain-link fence. Contains an old sofa, a table, and a visible campfire spot.

### Layout

```
    ┌──────────────────────────────┐
    │         FENCE (chain-link)    │
    │                              │
    │   [TABLE]      [CAMPFIRE]    │
    │                  (center)    │
    │                              │
    │   [SOFA]     [STORAGE]       │
    │              (Day 3+)        │
    │                              │
    │   ═══ GATE (entry) ═══      │
    └──────────────────────────────┘
```

Approximate size: 20x20 studs.

---

## Upgrade System

| Upgrade | Cost | Day Available | Effect | Status |
|---------|------|--------------|--------|--------|
| Campfire Tier 2 | 6 Wood + 2 Metal | Day 2–3 | Radius 15→22, capacity 5→8 | `PROPOSED` |
| Campfire Tier 3 | 10 Wood + 4 Metal + 2 Rope | Day 3–4 | Radius 22→30, capacity 8→12 | `PROPOSED` |
| Campfire Tier 4 | 15 Wood + 6 Metal + 4 Plastic + 2 Rope | Day 4–5 | Radius 30→40, capacity 12→16 | `PROPOSED` |
| Storage Box | 6 Wood + 2 Plastic | Day 3+ | +8 storage slots (persist between days) | `PROPOSED` |
| Fence Repair | 4 Metal + 2 Rope | Day 3+ | Delays monster breach by 30s on Night 4+ | `PROPOSED` |
| Workbench | 4 Wood + 3 Metal | Day 3+ | Enables crafting recipes | `PROPOSED` |
| Reinforced Fence | 8 Metal + 4 Rope | Day 4+ | Monster cannot breach fence | `PROPOSED` |
| Barricade (placeable) | 3 Wood + 2 Metal | Day 3+ | Placed on ground, blocks monster path | `PROPOSED` |

### Upgrade Rules

- Only one upgrade can be built at a time (5s interaction per upgrade).
- Upgrades are permanent within the session (don't reset between days).
- Campfire upgrades are sequential (Tier 1→2→3→4, cannot skip).
- Other upgrades can be built in any order.
- Server validates all upgrade transactions.

---

## Storage System `PROPOSED`

Without a Storage Box, items left on the ground at the shelter persist between days but may be limited.

With a Storage Box:
- 8 additional slots per box.
- Items placed in storage persist between days.
- Maximum 2 storage boxes per session.
- Items in storage are shared among all players in the session.
