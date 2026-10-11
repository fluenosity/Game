# Connected Light Network System — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **System Owner:** Systems Designer / Technical Architect  
> **Related Documents:** [FIRE_AND_FUEL.md](file:///i:/RobloxDev/docs/systems/FIRE_AND_FUEL.md), [DAY_04_DARKNESS_AND_ESCALATION.md](file:///i:/RobloxDev/docs/campaign/DAY_04_DARKNESS_AND_ESCALATION.md), [MONSTER_AI.md](file:///i:/RobloxDev/docs/systems/MONSTER_AI.md)

---

## 1. System Vision & Purpose

The **Connected Light Network** is an advanced mid-to-late campaign survival system introduced in Day 4. Rather than confining 1–5 players to a single shrinking circle around the central campfire, the light network enables survivors to construct and link **Ember Lanterns** and **Light Relays** to form illuminated corridors across dangerous forest zones.

### Core Player Fantasy
- Transitioning from passive hunkering at the fire to active territorial expansion.
- Team-based power-grid engineering under terrifying time and monster pressure.
- Strategic tension: "Do we burn fuel locally at the shelter, or route it outward to secure the path to the Signal Tower?"

---

## 2. Definitive Network Rules: What "Connected" Means

To prevent ambiguity and exploits, "connection" is strictly defined by deterministic server rules:

```text
Campfire (Core Source) ──[Line of Sight ≤ 35 studs]──► Relay Post A ──[Line of Sight ≤ 35 studs]──► Relay Post B
                                                               │
                                                               └──[Line of Sight ≤ 25 studs]──► Perimeter Lantern
```

1. **Root Source Requirement:** Every network must originate from an active Tier 2+ Campfire. If the campfire goes out, all connected nodes extinguish within 2.0 seconds.
2. **Maximum Link Distance:**
   - Campfire to Relay: 35 studs (`INITIAL_BALANCE_PROPOSAL`).
   - Relay to Relay: 35 studs (`INITIAL_BALANCE_PROPOSAL`).
   - Relay to Wall Lantern / Trap Light: 25 studs (`INITIAL_BALANCE_PROPOSAL`).
3. **Line of Sight (LoS):** A direct raycast check between node origins with no opaque map obstacles (trees, boulders, metal walls). If foliage or falling debris blocks the line, the link breaks.
4. **No Loop Exploit:** Connecting nodes in a closed loop does not multiply fuel efficiency or light intensity. Graph connectivity is evaluated via BFS (Breadth-First Search) rooted at the Campfire.
5. **No Isolated Power:** A lantern placed beyond link range acts as an unpowered, inactive prop until connected.

---

## 3. Node Types and Costs

| Node Type | Crafting / Placement Cost | Fuel Draw | Effective Protection Radius | Durability / Health |
|-----------|---------------------------|-----------|-----------------------------|---------------------|
| **Primary Campfire (Root)** | Core Shelter Object | Base rate (0.2 fuel/s) | 16–30 studs (tier dependent) | Invulnerable |
| **Relay Post** | 3 Wood, 2 Metal Scrap, 1 Rope | +0.05 fuel/s from root | 6 studs (pathway beacon) | 100 HP (destructible) |
| **Perimeter Lantern** | 2 Metal Scrap, 1 Plastic, 1 Glass | +0.08 fuel/s from root | 14 studs (defensive pocket) | 150 HP (destructible) |
| **Tripwire Flash Flare** | 1 Metal Scrap, 2 Plastic, 1 Rope | 0 (Single-use consumable) | 20 studs burst (3.5s flash) | Triggered upon contact |

---

## 4. Monster Interaction & Counterplay

The Hollow (the monster) is repelled by light, but as campaign days escalate, it actively seeks vulnerabilities in the grid:

1. **Light Avoidance:** The Hollow cannot enter the protective radius of any powered node while its intensity is above 20%.
2. **Sabotage Behavior (Day 4+):** If a Relay Post is isolated from players (no player within 20 studs), The Hollow can lash out from the shadows, dealing 35 damage per swipe to the Relay Post to sever the connection.
3. **Power Surge Flicker:** During heavy wind or rain events, individual relay lights flicker (0.5s off-cycles). The Hollow uses these micro-flickers to advance closer to the boundary without entering the safe zone.
4. **Counter-Sabotage:** Players can repair damaged Relays (cost: 1 Metal Scrap, 4-second interaction) and defend lines using Flare Sticks or Firebrand Torches.

---

## 5. Technical Architecture & Replication

### Server Authority
- **`LightNetworkService`** (Server Script): Maintains the node graph, performs LoS raycasts on placement, updates fuel consumption deltas on the central campfire, and calculates damage to nodes.
- **Tick Interval:** Graph validation runs every 1.0 second; fuel consumption updates every 0.5 seconds.
- **Pathfinding Avoidance:** Nodes generate dynamic `PathfindingModifier` volumes with an extreme cost (`PassThrough = false` or `Cost = 1000`) for monster agents.

### Client Presentation
- Clients receive lightweight state packets via `NetworkLightUpdated` RemoteEvent containing: `{ NodeId, IsActive, HealthPercent, Intensity }`.
- Client `LightController` handles tweening `PointLight.Brightness`, particle embers, and atmospheric volumetric fog local to the player's camera.

---

## 6. Edge Cases & Anti-Abuse Measures

| Exploit / Edge Case | Risk | Server Enforcement |
|---------------------|------|--------------------|
| **Placement Clipping** | Placing relays inside rocks or terrain to create invincible safe zones | Server raycasts from player to placement point AND verifies node bounding box is 100% in empty air. |
| **Overlapping Spam** | Stacking 10 relays in one spot to drain or break monster pathfinding | Minimum spacing of 10 studs enforced between adjacent nodes. |
| **Distant Placement Request** | Exploiter firing remote to place a node 500 studs away | Server rejects if `(PlayerPosition - NodePosition).Magnitude > 12 studs`. |
| **Infinite Grid Extinction** | Disconnecting the root causes lag spike | Graph traversal uses depth limit of 8 hops. Extinguishing is batched across frames. |

---

## 7. Acceptance Criteria & Verification

- [ ] **AC-LN-01:** Placing a Relay within 35 studs and clear LoS of the Campfire lights up within 0.2s and expands player safety.
- [ ] **AC-LN-02:** Obstructing the ray between Campfire and Relay immediately cuts power to downstream nodes.
- [ ] **AC-LN-03:** When Campfire fuel hits 0, all network nodes turn off and monster navigation costs reset to normal walkable terrain.
- [ ] **AC-LN-04:** Mobile interface displays a clear placement holographic preview with green/red valid connection indicator.
