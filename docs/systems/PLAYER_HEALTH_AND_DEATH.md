# Player Health and Death — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## Health System

| Parameter | Value | Status |
|-----------|-------|--------|
| Max HP | 100 | `INITIAL_BALANCE_PROPOSAL` |
| Starting HP (each day) | 100 (full heal on sleep) | `PROPOSED` |
| Monster attack damage | 50 | `INITIAL_BALANCE_PROPOSAL` |
| Hits to die | 2 | Derived |
| HP regen | None (heal via bandage or sleep only) | `PROPOSED` |
| Bandage heal | 30 HP | `INITIAL_BALANCE_PROPOSAL` |

---

## Death

### Solo Death

| Scenario | Behavior |
|----------|----------|
| Player dies Night 1 | Restart Day 1 (lenient — shouldn't happen) |
| Player dies Night 2–5 | `PROPOSED` Restart current day with inventory from dawn |
| All retries exhausted | `PROPOSED` Campaign failure → return to lobby |

### Co-op Death

| Scenario | Behavior |
|----------|----------|
| One player dies | `PROPOSED` 30s revival window — teammate holds E near body |
| Revival succeeds | Player revives with 30 HP, brief invulnerability (3s) |
| Revival timer expires | Player is out for the rest of the night. Revives at dawn with full HP. |
| All players die | Campaign failure → results screen → return to lobby |

---

## Damage Sources

| Source | Damage | Condition |
|--------|--------|-----------|
| Monster attack | 50 HP | Player outside protection radius, monster in ATTACK state |
| `PROPOSED` Fall damage | 10–25 HP | Falling from height (if terrain supports it) |
| `PROPOSED` Environmental | 5–10 HP | Specific hazards on Day 4+ |

---

## Health UI

- HP bar: top-left corner, horizontal bar.
- Color: Green (>60%) → Yellow (30–60%) → Red (<30%).
- Damage flash: screen edges flash red on hit.
- Death: screen goes gray, camera drops, "You died" text.
- Revival prompt (co-op): "Hold E to revive [PlayerName]" near downed player.

---

# Inventory and Item Rules

> **Status:** `PROPOSED`

---

## Inventory

| Parameter | Value |
|-----------|-------|
| Player slots | 12 |
| Storage box slots | 8 per box (max 2 boxes) |
| Wood stack size | 4 per slot |
| Scrap stack size | 2 per slot |
| Unique items | 1 per slot (signal components, flares) |
| Crafted items stack size | 2 per slot (torches, bandages) |

### Inventory Rules

- Inventory is player-specific (each player has their own 12 slots).
- Storage boxes are shared (any player can deposit/withdraw).
- Items can be dropped on the ground (persist until next dawn or pickup).
- `PROPOSED` Items dropped outside the shelter area despawn at dawn.
- Full inventory: "Inventory full" message, cannot pick up new items.
- Server-authoritative: all inventory changes validated server-side.

---

# Cooperation and Parties

> **Status:** `PROPOSED`

---

## Co-op Roles `PROPOSED`

Not enforced classes — emergent roles based on how players choose to divide tasks:

| Role | Activities | Ideal For |
|------|-----------|-----------|
| Gatherer | Chops trees, collects scrap | Fast, efficient explorer |
| Builder | Upgrades shelter, crafts items | Strategic planner |
| Fire-Keeper | Manages campfire fuel at night | Watchful, reactive |
| Scout | Explores far landmarks, finds lore | Risk-taker |
| Defender | Places barricades, watches for monster | Alert, responsive |

### Shared Objectives

- All players share the same campaign objectives.
- Any player can complete any objective.
- Campfire fuel benefits all players.
- Shelter upgrades benefit all players.
- Signal components can be collected by any player.

### Communication

- Roblox text chat (built-in).
- `PROPOSED` Ping system: tap a location to place a visible marker for teammates.
- `PROPOSED` Quick emote: "Help!" / "Come here" / "Danger" / "I found something" buttons.
