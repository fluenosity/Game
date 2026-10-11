# Monster AI Technical Design — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** AI & Gameplay Systems Architect  
> **Related Documents:** [MONSTER_AI.md](file:///i:/RobloxDev/docs/systems/MONSTER_AI.md), [MONSTER_IDENTITY_AND_BEHAVIOR.md](file:///i:/RobloxDev/docs/systems/MONSTER_IDENTITY_AND_BEHAVIOR.md), [LIGHT_NETWORK.md](file:///i:/RobloxDev/docs/systems/LIGHT_NETWORK.md)

---

## 1. Technical Objectives & Constraints

The monster ("The Hollow") must feel intelligent, relentless, and terrifying without causing server frame drops or consuming excessive pathfinding budgets on Roblox servers.

### Core Technical Directives
1. **Server-Side Authority:** Monster decisions, targets, animations states, and hit registration occur 100% on the server.
2. **Client-Side Presentation:** Footstep particles, local audio roar, screen distortion, and eye ember glows interpolate locally.
3. **Pathfinding Budgeting:** Maximum 2 `PathfindingService:CreatePath()` calculations per second.

---

## 2. AI Architecture: Hierarchical Finite State Machine (HFSM)

```text
 ┌────────────────────────────────────────────────────────┐
 │                      GLOBAL STATE                      │
 │   [INACTIVE] (Daytime) ──Dusk Trigger──► [ACTIVE]      │
 └────────────────────────────┬───────────────────────────┘
                              ▼
 ┌────────────────────────────────────────────────────────┐
 │                   ACTIVE COMBAT HFSM                   │
 │                                                        │
 │  ┌──────────┐    Suspicious Noise     ┌─────────────┐  │
 │  │ STALKING ├────────────────────────►│ INVESTIGATE │  │
 │  └────┬─────┘                         └──────┬──────┘  │
 │       │ Visual Sight                         │ Player  │
 │       │ (outside light)                      │ Spotted │
 │       ▼                                      ▼         │
 │  ┌──────────┐      Inside Safe Light  ┌─────────────┐  │
 │  │ CHASE    ├────────────────────────►│ REPELLED /  │  │
 │  └────┬─────┘                         │ PROBING     │  │
 │       │ Within 7 studs                └──────┬──────┘  │
 │       ▼                                      │ Stunned │
 │  ┌──────────┐    3 Consecutive Stuns         │ / Dawn  │
 │  │ ATTACK   │◄───────────────────────────────┘         │
 │  └────┬─────┘                                          │
 │       ▼                                                │
 │  ┌──────────┐                                          │
 │  │ RETREAT  │──► (Fade into shadows, 15s cooldown)     │
 │  └──────────┘                                          │
 └────────────────────────────────────────────────────────┘
```

---

## 3. Sensory Perception Architecture

### 3.1 Visual Perception Cone
- **Field of View (FoV):** 110 degrees forward facing.
- **Sight Distance:** 
  - In pitch darkness: 70 studs.
  - In campfire light boundary: 25 studs (The Hollow is blinded by direct illumination).
- **Raycast Visibility:** `Workspace:Raycast()` from Monster Head to Player HumanoidRootPart ignoring foliage and transparent glass.

### 3.2 Auditory Noise Listener
Instead of continuous distance loops, players emit discrete **Noise Events** via a central `NoiseService`:

```lua
-- Noise event contract
export type NoiseEvent = {
    Position: Vector3,
    Loudness: number,       -- studs radius
    Source: "Sprint" | "ChopTree" | "BreakFence" | "Gunshot" | "Radio",
}
```
- **Hearing Sensitivity:**
  - Sprinting: 25 studs radius.
  - Chopping Tree: 60 studs radius.
  - Radio / Signal Tower: 120 studs radius.
- If `(Noise.Position - Monster.Position).Magnitude <= Noise.Loudness`, monster transitions from `STALKING` to `INVESTIGATE`.

---

## 4. Light Avoidance & Pathfinding Modifier System

### Dynamic Navmesh Costs
The Hollow navigates using Roblox `PathfindingService`. All active light sources (Campfire, Lanterns, Flares) carry invisible spherical parts tagged with `PathfindingModifier`:
- **Modifier Label:** `"RepellingLight"`
- **Agent Parameters:**
```lua
local agentParameters = {
    AgentRadius = 3.0,
    AgentHeight = 7.0,
    AgentCanJump = false,
    Costs = {
        RepellingLight = math.huge -- Completely impassable!
    }
}
```
- If a player stands inside the light, the pathfinder reports `NoPath`, forcing the monster into `PROBING` (circling the boundary).

---

## 5. Stuck Detection & Anti-Exploit Recovery

If players attempt to cheese the monster on roofs or glitched geometry:
1. **Position Delta Check:** Every 2.0 seconds during `CHASE`, the server verifies the monster has moved at least 3.0 studs.
2. **Stuck Trigger:** If monster fails movement check for 4 consecutive seconds:
   - Plays shadow-dissolve particle effect (`MonsterShadowFade`).
   - Teleports to the nearest valid navigation node 40 studs away out of player line-of-sight.
   - Re-evaluates target.

---

## 6. Acceptance Criteria

- [ ] **AC-MONAI-01:** Monster pathfinding strictly respects `RepellingLight` modifiers and never steps inside an active Campfire radius.
- [ ] **AC-MONAI-02:** Chopping a tree within 60 studs triggers an immediate investigation path toward the sound origin.
- [ ] **AC-MONAI-03:** Monster stuck detection cleanly re-paths or shadow-teleports within 4.0 seconds without freezing the server.
- [ ] **AC-MONAI-04:** Hit registration verifies distance <= 8.5 studs on server before applying damage.
