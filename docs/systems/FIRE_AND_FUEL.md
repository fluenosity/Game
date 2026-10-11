# Fire and Fuel System — Project: Undecided

> **Status:** `EXISTING_CANON` (fire as protection) + `PROPOSED` (fuel depletion, tiers, mechanics)
> **Last updated:** 2026-10-11
> **Design pillar:** Fire Is Life

---

## Overview

Fire is the single most important mechanic in the game. It is the player's ONLY defense against the monster. The fire system governs campfire state, fuel consumption, protection radius, upgrades, and the light that keeps players alive.

---

## Core Rules

1. `EXISTING_CANON` Fire scares the monster away.
2. `EXISTING_CANON` The campfire is at a designated spot in the shelter.
3. `PROPOSED` Fire is a DEPLETING resource — it consumes fuel and can go out.
4. `PROPOSED` Players must actively feed the fire during the night.
5. `PROPOSED` Fire can be upgraded through tiers for larger protection and capacity.

---

## Campfire State Machine

```
UNLIT → IGNITING → BURNING → LOW_FUEL → CRITICAL → EXTINGUISHED
                      ↑                                    │
                      └────────── (Relight) ───────────────┘
```

| State | Description | Visual | Audio |
|-------|-------------|--------|-------|
| `UNLIT` | No fire. No protection. | Dark pit with ashes | Silence |
| `IGNITING` | Player is lighting the fire (3s hold) | Sparks, smoke | Match strike |
| `BURNING` | Active fire. Full protection. | Strong flames, warm light | Crackling |
| `LOW_FUEL` | <35% fuel remaining | Smaller flames, flickering | Weakened crackling |
| `CRITICAL` | <20% fuel remaining | Tiny flames, rapid flickering | Sputtering, warning tone |
| `EXTINGUISHED` | 0 fuel. No protection. | Smoke, embers, no flame | Hissing, silence |

---

## Fuel System

### Fuel as a Resource

| Parameter | Value | Status |
|-----------|-------|--------|
| Fuel unit | 1 Wood = 1 fuel unit | `PROPOSED` |
| Premium fuel | 1 Premium Fuel = 2 fuel units (burns 2x slower) | `PROPOSED` |
| Consumption rate (Tier 1) | 1 unit per 60s | `INITIAL_BALANCE_PROPOSAL` |
| Consumption rate (Tier 2) | 1 unit per 50s | `INITIAL_BALANCE_PROPOSAL` |
| Consumption rate (Tier 3) | 1 unit per 45s | `INITIAL_BALANCE_PROPOSAL` |
| Consumption rate (Tier 4) | 1 unit per 40s | `INITIAL_BALANCE_PROPOSAL` |
| Fuel consumption active | Night only (daytime does NOT consume fuel) | `PROPOSED` |

### Adding Fuel

- Player approaches campfire with wood in inventory.
- Interaction prompt: **"Add Wood" (Hold E, 1.5s)**
- Each interaction adds 1 wood from inventory → 1 fuel unit.
- Can add fuel at any time (day or night, fire lit or unlit).
- Server validates: player has wood, campfire exists, player is within range (6 studs).

### Fuel Display

- **UI:** Fuel gauge bar near the campfire (visible when within 15 studs).
- **Color:** Green (>50%) → Yellow (35–50%) → Orange (20–35%) → Red (<20%).
- **Flashing:** Red gauge flashes when CRITICAL.
- **Number:** Shows "X/Y" (current fuel / max capacity).

---

## Protection Radius

The protection radius is the area around the campfire where the monster will NOT enter.

| Tier | Radius | Max Fuel Capacity | Upgrade Cost |
|------|--------|-------------------|-------------|
| Tier 1 (Basic) | 15 studs | 5 | Free (starting campfire) |
| Tier 2 | 22 studs | 8 | 6 Wood + 2 Metal Scrap |
| Tier 3 | 30 studs | 12 | 10 Wood + 4 Metal + 2 Rope |
| Tier 4 | 40 studs | 16 | 15 Wood + 6 Metal + 4 Plastic + 2 Rope |

### Protection Radius Rules

- The radius is a **perfect circle** centered on the campfire.
- Inside the radius: safe from the monster (Nights 1–3). `PROPOSED` Day 4+: Tier 1 may not be safe.
- On the exact boundary: **outside** (exclusive boundary — must be strictly inside).
- The radius **only exists while the fire is BURNING or LOW_FUEL**. When EXTINGUISHED, radius = 0.
- `PROPOSED` The radius visually pulses/shrinks as fuel decreases — a CRITICAL fire has a visibly smaller radius.
- Server is authoritative for radius calculation. Client renders the visual.

### Protection Radius Scaling with Fuel `PROPOSED`

| Fuel Level | Effective Radius |
|------------|-----------------|
| 100–50% | Full radius (e.g., 15 studs for Tier 1) |
| 50–35% | 90% of full radius |
| 35–20% | 75% of full radius |
| 20–1% | 60% of full radius |
| 0% | 0 studs (no protection) |

This creates a visual shrinking effect — the safe zone literally contracts as fuel runs low.

---

## Campfire Upgrades

### Upgrade Process

1. Player approaches campfire with required materials in inventory.
2. Prompt: **"Upgrade Campfire (Tier X) — [cost list]"**
3. Hold interaction for 5 seconds.
4. Server validates materials, deducts them, upgrades the campfire.
5. Visual: fire structure changes (larger pit, better containment, brighter flame).
6. Audio: construction sound, fire intensifies.

### Upgrade Effects

| Aspect | Tier 1 → 2 | Tier 2 → 3 | Tier 3 → 4 |
|--------|-----------|-----------|-----------|
| Radius | +7 studs | +8 studs | +10 studs |
| Capacity | +3 fuel | +4 fuel | +4 fuel |
| Visual | Larger flames, stone ring | Metal-reinforced pit | Full fire station |
| Burn rate | Slightly faster | Faster | Fastest |

### Upgrade Tradeoff

Higher tiers provide more protection BUT consume fuel faster. This is intentional:
- Tier 1: Small but efficient.
- Tier 4: Massive safe zone but EATS fuel.
- Players must balance safety vs. sustainability.

---

## Ignition & Relighting

### First Ignition (Day 1)

- Requires: ≥2 Wood in inventory.
- Interaction: "Light Campfire" (Hold E, 3s).
- Deducts 2 wood → sets fuel to 2.
- Fire enters BURNING state.

### Relighting (After Extinction)

- Requires: ≥2 Wood in inventory.
- Interaction: "Relight Campfire" (Hold E, 5s) — slower than first light.
- `PROPOSED` During relight, the player is VULNERABLE (animation lock, can't move).
- Deducts 2 wood → sets fuel to 2.
- Fire enters BURNING state.
- Protection radius restores immediately.

### Emergency Relight `PROPOSED`

- Emergency Flare item (from trader): instant relight, no hold time, no wood cost.
- Single use.
- Creates a brief flash that pushes the monster back 20 studs.

---

## Portable Light Sources `PROPOSED`

| Item | Radius | Duration | Fuel | Source |
|------|--------|----------|------|--------|
| Torch | 6 studs | 120s | N/A (self-contained) | Crafted (1 Wood + 1 Rope) |
| Lantern | 8 studs | 300s | Requires oil/fuel | `PROPOSED` (Day 4+) |
| Emergency Flare | 10 studs | 30s | N/A (one-shot) | Trader |

Portable lights create small protection radii. They can be placed on the ground or carried.

### Light Network `PROPOSED`

If multiple light sources are active, their radii are independent — they do NOT merge. A gap between two radii is still dangerous.

`PROPOSED` Future mechanic: connecting light sources with rope or wire to create a continuous safe path. This is a major proposed system that requires separate detailed design (see LIGHT_NETWORK.md).

---

## Technical Implementation

### Server-Side State

```lua
-- CampfireState (server-authoritative)
{
    tier = 1,           -- 1-4
    fuel = 0,           -- current fuel units (float)
    maxFuel = 5,        -- capacity at current tier
    burnRate = 1/60,    -- fuel consumed per second
    isLit = false,      -- BURNING or LOW_FUEL = true
    protectionRadius = 15,  -- current effective radius (studs)
    position = Vector3  -- world position
}
```

### Fuel Tick (Server)

Every server heartbeat (0.1s):
1. If `isLit` and time is night: `fuel -= burnRate * dt`
2. If `fuel <= 0`: set `isLit = false`, set `protectionRadius = 0`, fire `FireExtinguished` event.
3. Calculate effective radius based on fuel percentage.
4. Replicate state to clients.

### Client-Side Rendering

- Client receives: `isLit`, `fuel/maxFuel` ratio, `protectionRadius`, `tier`.
- Client renders: flame particles (scaled by fuel %), light intensity, ground glow, fuel gauge UI.
- Client does NOT make protection decisions — that's server-side monster AI.

### Validation Rules

| Action | Server Validates |
|--------|-----------------|
| Add Wood | Player has wood, is within range, campfire exists |
| Light/Relight | Player has ≥2 wood, is within range, fire is UNLIT/EXTINGUISHED |
| Upgrade | Player has required materials, campfire is correct tier |

Prevent: adding wood the player doesn't have, upgrading without materials, remote exploitation of fuel values.

---

## Acceptance Criteria

- [ ] Fire visibly and audibly changes across BURNING → LOW_FUEL → CRITICAL → EXTINGUISHED
- [ ] Fuel gauge is accurate and easy to read (including on mobile)
- [ ] Adding wood to the fire feels responsive (≤200ms feedback)
- [ ] Protection radius visually shrinks as fuel decreases
- [ ] The monster respects the protection radius at all times (except documented escalation)
- [ ] Fire going out creates genuine panic (audio, visual, immediate monster response)
- [ ] Relighting is possible but stressful (5s vulnerability window)
- [ ] Upgrade decision is meaningful (bigger radius but faster consumption)
- [ ] All fire operations are server-authoritative
- [ ] Mobile players can add wood during night without input issues
