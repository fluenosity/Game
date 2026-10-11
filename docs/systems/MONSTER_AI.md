# Monster AI — Project: Undecided

> **Status:** `EXISTING_CANON` (fears fire, hunts in darkness) + `PROPOSED` (detailed behavior, FSM, escalation)
> **Last updated:** 2026-10-11
> **Design pillar:** The Monster Is Memorable

---

## Overview

The monster is the game's primary antagonist. It hunts players in darkness and fears fire. Its behavior escalates across the 5-night campaign, from atmospheric presence (Night 1) to intelligent aggressor (Night 5).

---

## Core Rules

1. `EXISTING_CANON` The monster fears fire.
2. `EXISTING_CANON` The monster hunts when there's no light nearby.
3. `PROPOSED` The monster's behavior is server-authoritative — the client only sees the result.
4. `PROPOSED` The monster can never be killed by the player (it is a force of nature, not an enemy to defeat).
5. `PROPOSED` The monster should feel INTELLIGENT, not random.

---

## Finite State Machine

```
                    ┌──────────┐
            ┌──────→│ DORMANT  │←──── (Dawn)
            │       └────┬─────┘
            │            │ (Night begins)
            │       ┌────▼─────┐
            │       │  PATROL  │←──────────────┐
            │       └────┬─────┘               │
            │            │ (Player detected     │
            │            │  or timer)           │
            │       ┌────▼─────┐               │
            │       │ APPROACH │               │
            │       └────┬─────┘               │
            │            │                     │
            │       ┌────▼─────┐          ┌────┴─────┐
            │       │   TEST   │─────────→│ RETREAT  │
            │       └────┬─────┘          └──────────┘
            │            │ (Fire out or
            │            │  Tier 1 on Day 4+)
            │       ┌────▼─────┐
            │       │  HUNT    │
            │       └────┬─────┘
            │            │ (Player in range)
            │       ┌────▼─────┐
            │       │  ATTACK  │
            │       └────┬─────┘
            │            │ (Fire relit or
            │            │  attack complete)
            └────────────┘
```

---

## State Definitions

### DORMANT
- **Active:** Daytime only.
- **Behavior:** Monster is not in the play area. Not visible, not audible.
- **Entry:** Dawn signal fires.
- **Exit:** Night begins → PATROL.
- **Server:** Monster instance is either despawned or moved far from players.

### PATROL
- **Active:** Night.
- **Behavior:** Walks a circuit around the shelter at a distance.
- **Distance:** Night 1: ~50 studs. Night 2: ~40. Night 3: ~35. Night 4: ~30. Night 5: ~25.
- **Speed:** `INITIAL_BALANCE_PROPOSAL` 8 studs/s.
- **Sounds:** Distant footsteps, branch snaps, breathing.
- **Visibility:** Occasionally visible as a silhouette at edge of light.
- **Exit:** Timer-based (every 60–90s) → APPROACH. Or player-triggered (loud noise) → APPROACH.

### APPROACH
- **Active:** Night.
- **Behavior:** Moves directly toward the shelter / protection radius edge.
- **Speed:** `INITIAL_BALANCE_PROPOSAL` 12 studs/s.
- **Sounds:** Closer footsteps, growling. Audio gets louder.
- **Exit:** Reaches protection radius edge → TEST. Or fire is strong → RETREAT.

### TEST
- **Active:** Night 2+.
- **Behavior:** Pauses at the edge of the protection radius. Observes.
- **Duration:** Night 2: 10s. Night 3: 15s. Night 4: 30s. Night 5: 45s.
- **Night 4+:** `PROPOSED` Briefly steps INTO Tier 1 radius (5–10s).
- **Sounds:** Close breathing, sniffing, scraping.
- **Visual:** Partially visible — face or limbs at the edge of the light.
- **Exit:** → RETREAT (if fire is Tier 2+). → HUNT (if fire is Tier 1 on Day 4+ or fire is out).

### RETREAT
- **Active:** Any time.
- **Behavior:** Backs away from the fire. Returns to patrol distance.
- **Speed:** 10 studs/s.
- **Cooldown:** `INITIAL_BALANCE_PROPOSAL` 30s before next APPROACH.
- **Exit:** → PATROL (after cooldown).

### HUNT
- **Active:** When fire is out or severely weakened.
- **Behavior:** Enters the shelter perimeter. Moves toward players.
- **Speed:** 14 studs/s.
- **Sounds:** Heavy breathing, rapid footsteps, aggressive growling.
- **Exit:** → ATTACK (player in melee range). → RETREAT (fire relit with Tier 2+ strength).

### ATTACK
- **Active:** Player is within melee range AND fire is out/weak.
- **Behavior:** Lunges at player. Deals 50 damage.
- **Cooldown:** 3s between attacks.
- **Exit:** → HUNT (if player alive and fire still out). → RETREAT (fire relit). → PATROL (target dead).

### DAWN_RETREAT
- **Active:** Dawn signal.
- **Behavior:** Dramatic retreat. Screams, runs into deep forest.
- **Speed:** 25 studs/s (fastest movement).
- **Visual:** Full body briefly visible during retreat.
- **Exit:** → DORMANT.

---

## Escalation Across Days

| Parameter | Night 1 | Night 2 | Night 3 | Night 4 | Night 5 |
|-----------|---------|---------|---------|---------|---------|
| Patrol distance | 50 studs | 40 | 35 | 30 | 25 |
| Approach frequency | 1–2/night | 2–3 | 3–4 | 4–5 | Continuous |
| Test duration | N/A | 10s | 15s | 30s | 45s |
| Enters Tier 1 radius | No | No | No | Yes (5s) | Yes (10s) |
| Fence interaction | No | No | Rattles | Breaks (if unrepaired) | Destroys |
| Attacks if fire out | No (N1 lenient) | Yes | Yes | Yes | Yes |
| Speed (chase) | N/A | 18 st/s | 18 st/s | 20 st/s | 22 st/s |

---

## Detection Systems

### Visual Detection
- **Range:** 80 studs in direct line of sight.
- **Blocked by:** Walls, dense trees, terrain.
- **Result:** If player is visible AND outside protection radius → APPROACH or HUNT.

### Audio Detection `PROPOSED`
- **Range:** 40 studs.
- **Triggers:** Running (20 studs), chopping trees (30 studs), building (25 studs).
- **Not blocked by:** Walls (sound travels through).
- **Result:** Monster investigates the sound source.
- **Purpose:** Makes daytime activities have risk/reward considerations.

### Fire Detection
- **Range:** Protection radius + 5 studs (avoidance buffer).
- **Behavior:** Monster will not willingly enter this range (except Day 4+ Tier 1 override).
- **Fire out detection:** Server notifies monster AI immediately when fire reaches 0 fuel.

---

## Multiplayer Target Selection

When multiple players are in the session:

| Scenario | Target Priority |
|----------|----------------|
| All players in protection radius | No target — PATROL/TEST only |
| One player outside radius | That player |
| Multiple players outside radius | Closest player |
| Player making the most noise | `PROPOSED` Higher priority target |
| Downed/dead player | Ignore — target living players |

---

## Pathfinding

- Use Roblox `PathfindingService` for navigation.
- Monster should navigate around obstacles, not through them.
- **Stuck detection:** If monster hasn't moved >2 studs in 5 seconds, teleport to nearest valid patrol point (invisible to player — behind a tree or in fog).
- **Performance:** Pathfinding recalculates every 2s (not every frame).
- **Fallback:** If pathfinding fails 3 times, monster retreats to a safe spawn point and re-enters PATROL.

---

## Sound Design Integration

| State | Sound Type | Volume | Direction |
|-------|-----------|--------|-----------|
| PATROL | Distant footsteps, branches | Low | Moves with monster (spatial audio) |
| APPROACH | Louder footsteps, growling | Medium | Directional — player can tell where it's coming from |
| TEST | Close breathing, sniffing | High | Very close, localized |
| HUNT | Heavy breathing, rapid steps | High | Directional, fast |
| ATTACK | Roar / screech | Maximum | Centered |
| RETREAT | Fading footsteps | Decreasing | Moving away |
| DAWN_RETREAT | Scream + running | High → silent | Away from player |

---

## Technical Notes

- Monster AI runs entirely on the server.
- Client receives monster position, animation state, and audio triggers via replication.
- Server updates monster state every 0.1s (10Hz).
- Client interpolates between updates for smooth visual movement.
- Never trust client input regarding monster position or state.
- All damage calculations are server-side.

---

## Acceptance Criteria

- [ ] The monster never enters the protection radius of a Tier 2+ fire (except Day 5 FINAL_PUSH)
- [ ] The monster's behavior is noticeably different each night
- [ ] Players feel the monster is intelligent, not random
- [ ] The monster's sounds create genuine fear (tested with playtesters)
- [ ] Pathfinding works without the monster getting stuck
- [ ] Monster targets the correct player in multiplayer
- [ ] Monster behavior is consistent across solo and co-op
- [ ] Day 1's monster is atmospheric only (no attacks)
- [ ] Day 5's monster is the most aggressive encounter in the game
