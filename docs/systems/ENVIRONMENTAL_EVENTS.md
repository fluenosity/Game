# Environmental Events System — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **System Owner:** Atmosphere & World Systems Lead  
> **Related Documents:** [DAY_NIGHT_CYCLE.md](file:///i:/RobloxDev/docs/systems/DAY_NIGHT_CYCLE.md), [FIRE_AND_FUEL.md](file:///i:/RobloxDev/docs/systems/FIRE_AND_FUEL.md), [MONSTER_AI.md](file:///i:/RobloxDev/docs/systems/MONSTER_AI.md)

---

## 1. System Vision & Purpose

In *Project: Undecided*, the environment is not a passive decorative skybox. Dynamic weather and atmospheric anomalies act as active antagonists that interact directly with the game's core survival pillars: **Fire, Vision, Sound, and Threat.**

A sudden midnight rainstorm transforms an orderly base defense into a panicked struggle to shield the embers.

---

## 2. Event Types & Gameplay Impact

| Event | Occurrence Window | Atmospheric Presentation | Gameplay Effects | Player Counterplay |
|-------|-------------------|--------------------------|------------------|---------------------|
| **Clear Night (Baseline)** | Day 1, Day 2 | Starry dark sky, quiet wind | Baseline fuel burn; monster footsteps audible at 45 studs | Standard campfire maintenance |
| **Sudden Rainstorm** | Day 2 (Dusk) & Day 4 | Heavy downpour, rolling thunder, water ripples | Fuel burns **1.5× faster**; unroofed fires lose 15% radius; torches extinguished if exposed | Construct shelter canopy / roof upgrade; burn Dry Hardwood |
| **Dense Ash Fog** | Day 3 & Day 5 (Morning) | Low hanging grey fog, volumetric particle haze | Player visibility drops to 18 studs; monster footsteps muffled; silhouette shadows appear closer | Use beacon lanterns; stay in auditory range of team |
| **Howling Gale Winds** | Day 3 (Night) | Trees sway aggressively, whistling wind audio | Campfire flame bends and flickers (radius pulses ±20%); footstep sounds masked | Build windbreak fence panels; position players on windward side |
| **Eclipse / Blood Dusk** | Day 5 (Escape Night) | Deep crimson sky, red moonlight, ominous hum | Night arrives 30s earlier; monster aggression +30%; light network flickers | Maximum campfire fortification; flares and batteries ready |

*(All rates marked `INITIAL_BALANCE_PROPOSAL`)*

---

## 3. Interaction with Base Building & Structures

Environmental hazards give real mechanical necessity to shelter improvements:

1. **Tin Roof Canopy Upgrade:**
   - Prevents the rainstorm penalty from affecting the primary campfire entirely.
   - Rain audio changes dynamically from open splashing to satisfying metallic pitter-patter above the players' heads.
2. **Reinforced Fence Windbreaks:**
   - Prevents howling gale winds from causing campfire radius fluctuations within the shelter courtyard.
3. **Drainage Trench:**
   - Prevents ground flooding around the shelter during heavy downpours, preserving footstep sprint speeds.

---

## 4. Audio Propagation & Sensor Modifications

```text
[Sound Source (Chop Tree / Footstep)]
                │
         Weather Modifier Applied
     ├─ Rain: Dampens high frequencies, reduces hearing range by 30%
     ├─ Wind: Masks quiet sounds, monster can sneak within 15 studs undetected
     └─ Fog: Distorts directional audio panning (phantom echoes)
                │
    [Monster Sensor Hearing Distance]
```

---

## 5. Technical Implementation & Synchronization

- **Server-Side Authority:** `EnvironmentService` rolls weather states based on campaign day parameters at daybreak. Weather state is a single replicated enum: `WeatherType: Clear | Rain | Fog | Gale | Eclipse`.
- **Client Presentation:**
  - Tweening `Lighting.Atmosphere`, `Lighting.FogEnd`, `Lighting.ColorCorrection`.
  - Audio crossfading of ambient looping sound effects in `SoundService`.
  - Particle emitters attached to local player camera for rain/ash particles to ensure zero performance overhead on mobile.

---

## 6. Acceptance Criteria

- [ ] **AC-ENV-01:** Rain weather visibly dampens lighting and accelerates campfire fuel burn rate by exactly 1.5× on the server.
- [ ] **AC-ENV-02:** Constructing the shelter roof immediately cancels the rain fuel penalty.
- [ ] **AC-ENV-03:** Fog transitions smoothly over 15 seconds without sudden visual popping or mobile FPS dips below 30.
- [ ] **AC-ENV-04:** Gale winds cause dynamic directional flickering of campfire point lights synchronized across all clients.
