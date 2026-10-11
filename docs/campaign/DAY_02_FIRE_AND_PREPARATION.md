# Day 2 — Fire and Preparation

> **Status:** `EXISTING_CANON` (wood gathering, fire upgrade) + `PROPOSED` (fuel depletion, weather, detailed mechanics)
> **Last updated:** 2026-10-11
> **Design pillar:** Fire Is Life

---

## 1. Document Metadata

| Field | Value |
|-------|-------|
| Day | 2 |
| Type | Full gameplay day (daytime + night) |
| Duration | `INITIAL_BALANCE_PROPOSAL` ~10–12 minutes real-time |
| Status | `EXISTING_CANON` (core), `PROPOSED` (fuel depletion, fire tiers) |
| Depends on | Day 1 completion |
| Leads to | Day 3 — Scavenging and Discovery |

---

## 2. Purpose & Intended Emotion

### Purpose

Deepen the fire mechanic from "light it and forget it" to **an active, resource-consuming system** that demands attention. Introduce upgrades and preparation as meaningful gameplay.

Day 2 answers: "You survived one night. Can you survive a HARDER one?"

### Target Emotions

| Phase | Emotion |
|-------|---------|
| Morning | Growing confidence ("I know how this works") |
| Gathering | Purpose, efficiency |
| Upgrading fire | Pride, competence |
| Nightfall | Heightened anxiety (Night 2 is longer) |
| Fire flickering mid-night | Panic ("It's going out!") |
| Feeding the fire | Relief, active engagement |
| Dawn | Accomplishment ("That was harder but I did it") |

---

## 3. Narrative Context

The player survived their first night. They now understand the basics: shelter, wood, fire, monster. But Night 1 was gentle — the monster barely approached, the fire lasted through the night easily.

Day 2 teaches the player that **fire is not permanent**. It burns fuel. It can go out. And when it goes out, you die.

---

## 4. Player Starting Conditions

| Parameter | Value |
|-----------|-------|
| Health | 100 (full — healed during sleep) |
| Inventory | Remaining wood from Day 1 (0–3 wood typically) |
| Position | Shelter (woke up on sofa) |
| Campfire state | Extinguished (fuel consumed overnight) |
| Shelter state | Tier 1 (no upgrades yet) |
| Time of day | Early morning |

---

## 5. Prerequisites

- Day 1 completed successfully.
- Player has the shelter, campfire spot (Tier 1).

---

## 6. Primary Objective

**Gather enough wood to upgrade the campfire AND fuel it through a longer night.**

Sub-objectives:
1. "Gather wood" → shown at dawn.
2. "Upgrade the campfire" → shown when player has ≥6 wood + 2 metal scrap OR when approaching campfire.
3. "Keep the fire burning" → shown at nightfall.

---

## 7. Optional Objectives

- `PROPOSED` Explore slightly further from the shelter to find a small cache of extra resources.
- `PROPOSED` Discover the first environmental hint (e.g., old scratches on trees, a torn piece of fabric).

---

## 8. Step-by-Step Gameplay Flow

### Step 1: Morning — Wake Up (0:00–0:30)

- Player wakes on the sofa. "DAY 2" is displayed.
- The campfire is out (embers, smoke, no flame). The morning is bright and safe.
- Inventory shows whatever wood carried over from Day 1.
- `EXISTING_CANON` "Chop wood → upgrade campfire to stronger flames."

**UI:** Objective: **"Gather wood"**

### Step 2: Expanded Gathering (0:30–4:00)

**What's new vs. Day 1:**
- `INITIAL_BALANCE_PROPOSAL` More choppable trees available (5–8 in the area).
- Trees are spread slightly further from the shelter — exploration range grows.
- `PROPOSED` The player may notice **scrap objects** in the distance (metal glinting, plastic debris) but cannot yet interact with them — foreshadowing Day 3.

**What the player does:**
- Chops trees. Each yields 2 wood (same as Day 1).
- Needs to gather significantly more wood: fuel for a longer night + upgrade cost.
- **Target:** ~8–12 wood (depending on upgrade choice).

**Resource budget (Day 2):**

| Need | Wood Cost |
|------|-----------|
| Fire upgrade (Tier 1 → 2) | 6 wood + 2 metal scrap `PROPOSED` |
| Night 2 fuel (~240s at 1 wood/50s) | ~5 wood |
| **Total needed** | ~11 wood (or ~5 if skipping upgrade) |
| Available from trees (5–8 trees × 2 wood) | 10–16 wood |
| Carried from Day 1 | 0–3 wood |

The player has enough resources but must gather actively — no coasting.

### Step 3: Fire Upgrade Decision (3:00–4:30)

**`PROPOSED` Key Decision:** The player approaches the campfire and sees:

> **"Upgrade Campfire (Tier 2)"**
> Cost: 6 Wood + 2 Metal Scrap
> Effect: Protection radius 15 → 22 studs. Fuel capacity 5 → 8.

**Problem:** The player doesn't have metal scrap yet (that comes Day 3).

**Alternative upgrade path (Day 2 only):**

> **"Reinforce Campfire"**
> Cost: 6 Wood
> Effect: Protection radius stays 15 studs. Fuel capacity 5 → 7. Burn rate slightly slower.

This gives the player a meaningful choice:
- Spend 6 wood on upgrading → less fuel for tonight but better long-term.
- Keep all wood as fuel → safer tonight but no improvement.

### Step 4: Afternoon — Preparation (4:00–5:30)

- Player loads wood into the campfire.
- `PROPOSED` The campfire UI shows a fuel gauge: current fuel / max capacity.
- Player can see exactly how much fuel they have and estimate if it's enough.
- The sky begins its afternoon shift.

### Step 5: Nightfall Warning (5:30–6:00)

- `EXISTING_CANON` Same warning system as Day 1.
- "Night is approaching. Stay near the fire."
- Slightly more urgent audio — the player now KNOWS what's coming.

### Step 6: Night 2 — Active Fire Management (6:00–10:00)

**What's different from Night 1:**

| Aspect | Night 1 | Night 2 |
|--------|---------|---------|
| Duration | 180s (3 min) | 240s (4 min) — 33% longer |
| Fire consumption | Minimal / none | `PROPOSED` 1 wood per 50s |
| Fire can go out | No (scripted safety) | **Yes** — runs out of fuel |
| Monster behavior | Patrol only, no attacks | Patrol + approach, `PROPOSED` first attack if outside radius |
| Player action required | Passive (just wait) | **Active** (must feed fire when fuel drops) |

**The Critical Moment — Fire Flickering:**

At ~20% fuel remaining:
- The fire visually flickers — flames shrink, light dims.
- Audio: fire sputters, less crackling.
- UI: fuel gauge flashes red/orange.
- `PROPOSED` Warning text: **"The fire is dying!"**

The player must approach the campfire and add wood:
- Interaction prompt: **"Add Wood" (Hold E)**
- Each wood added extends the burn.

**If the fire goes out:**
- Protection radius drops to 0.
- The monster can now approach and attack.
- This is likely death unless the player immediately relights.
- Relighting requires 2 wood and 5 seconds — extremely tense.

### Step 7: Monster Behavior — Night 2

| State | Behavior | Change from Night 1 |
|-------|----------|-------------------|
| PATROL | Circles at ~40 studs (closer than Night 1's ~50) | More visible, more audible |
| APPROACH | Moves to protection edge 2–3 times per night | More frequent |
| TEST | `PROPOSED` Briefly reaches a limb toward the light boundary | New — shows intelligence |
| RETREAT | Backs away after testing | Same |
| HUNT | `PROPOSED` If fire goes out, enters the shelter area | New — lethal |

### Step 8: Dawn & Day 2 End (10:00–12:00)

- Dawn breaks. Monster retreats.
- Player can sleep on sofa → "DAY 3" transition.
- Remaining fuel carries over (if any).

---

## 9. Time-of-Day Timeline

| Real Time | Game Time | Event |
|-----------|-----------|-------|
| 0:00 | Dawn | "DAY 2" — player wakes |
| 0:30 | Morning | Gathering begins |
| 4:00 | Afternoon | Upgrade decision, preparation |
| 5:30 | Late afternoon | Nightfall warning |
| 6:00 | Night begins | Monster active, fire consuming fuel |
| ~8:00 | Mid-night | `PROPOSED` Fire low — player must refuel |
| 10:00 | Dawn approaches | Night ends |
| 10:30 | Dawn | Sleep available |
| ~12:00 | — | "DAY 3" |

---

## 10. Locations, Landmarks, Level Design

### Expanded Tree Area

| Aspect | Requirement |
|--------|------------|
| Trees available | 5–8 choppable trees |
| Spread | Wider area than Day 1 — some trees 30–60 seconds from shelter |
| New visual hints | `PROPOSED` Distant scrap piles visible but not interactable |
| Navigation | Still relatively easy to find way back to shelter |

### Shelter (Day 2 State)

| Aspect | Change from Day 1 |
|--------|-------------------|
| Campfire | Now has visible fuel gauge overlay |
| Upgrade prompt | Visible when approaching campfire with enough resources |
| Table | `PROPOSED` Has a small note or scratched symbol — first lore hint |

---

## 11. Resources & Numerical Values

| Resource | Source | Quantity | Used For |
|----------|--------|----------|----------|
| Wood | Choppable trees | 2 per tree | Fuel + upgrade |
| Trees available | Expanded area | 5–8 | Day 2 supply |
| Total available wood | — | 10–16 + carryover | — |
| Reinforce upgrade cost | — | 6 wood | Campfire improvement |
| Night 2 fuel needed | — | ~5 wood (240s / 50s) | Night survival |

---

## 12. Monster Behavior (Day 2)

| State | Entry Condition | Behavior | Exit |
|-------|----------------|----------|------|
| DORMANT | Daytime | Not present | → PATROL at nightfall |
| PATROL | Night begins | Circles at ~40 studs | → APPROACH (timed) |
| APPROACH | Every ~60–90s | Moves to radius edge | → TEST or → RETREAT |
| TEST | `PROPOSED` At radius edge | Reaches toward light, pauses | → RETREAT (always on Day 2) |
| RETREAT | After test/approach | Backs away 20+ studs | → PATROL |
| HUNT | Fire goes out | Enters shelter, attacks player | → RETREAT (if fire relit) |
| DAWN_RETREAT | Dawn signal | Flees area | → DORMANT |

---

## 13. UI Messages, Audio, Visual Feedback

### New UI Elements (Day 2)

| Element | Description |
|---------|-------------|
| Fuel gauge | Bar near campfire showing current fuel / max capacity |
| Fuel warning | Flashing indicator when fuel < 20% |
| Upgrade prompt | "Reinforce Campfire — 6 Wood" with cost breakdown |
| "Add Wood" interaction | Hold-to-add wood to campfire |

### New Audio (Day 2)

| Event | Sound |
|-------|-------|
| Fire sputtering (low fuel) | Weakened crackling, intermittent |
| Fire warning | Subtle alarm tone |
| Adding wood to fire | Wood thunk + fire flare |
| Monster testing the boundary | Scraping, sniffing, close breathing |
| Upgrade complete | Satisfying construction sound |

---

## 14–17. Multiplayer, Solo, Mobile, Accessibility

Same framework as Day 1 with additions:
- **Co-op:** Players can divide labor — one gathers while another guards fire at night.
- **Co-op fire management:** Any player can add wood to the campfire.
- **Solo:** Player must manage fire alone — more stressful (intentional).
- **Mobile:** "Add Wood" interaction must be easily accessible during night (dedicated button near campfire).
- **Accessibility:** Fuel warning uses both visual (flashing) and audio (tone) cues.

---

## 18. Success & Failure Conditions

| Condition | Result |
|-----------|--------|
| Fire stays lit all night → player sleeps | ✅ Day 2 complete |
| Fire goes out → player relights before monster attacks | ✅ Survived (barely) |
| Fire goes out → monster kills player | ❌ Death (solo: restart Day 2, co-op: teammate revive) |
| Player doesn't gather enough wood | ❌ Fire goes out mid-night |

---

## 19–21. Death/Disconnect, Edge Cases, System Interactions

- Death restarts Day 2 (solo) or allows teammate revival (co-op).
- If player adds ALL wood at once, fire burns longer but they can't add more later — resource commitment.
- If player never upgrades the campfire, the game is harder but still possible.
- Fire system interacts with monster AI — protection radius is checked server-side.

---

## 22–24. Assets, Dependencies, Technical Notes

**New assets needed:**
- Fuel gauge UI element
- Fire flickering particle state (low fuel)
- "Add Wood" interaction animation
- Campfire upgrade visual (Tier 1 → reinforced)
- Monster "testing" animation (reaching toward light)

**Key technical:** Fire fuel is a server-side float that decrements each tick. Client receives fuel percentage for UI. "Add Wood" is a validated RemoteEvent (server checks inventory, deducts wood, increments fuel).

---

## 25. Acceptance Criteria

- [ ] Player understands that fire consumes fuel (not obvious on Day 1)
- [ ] The fire visibly and audibly flickers when low on fuel
- [ ] Adding wood to the fire is intuitive and responsive
- [ ] The upgrade decision feels meaningful (not an obvious choice)
- [ ] Night 2 feels harder than Night 1 (longer, more monster activity, active fire management)
- [ ] The monster's "testing" behavior feels intelligent and scary
- [ ] If the fire goes out, the monster enters — creating a genuine crisis
- [ ] Solo and co-op both work (co-op allows division of fire duty)

---

## 26–29. QA, Analytics, Questions, Invalidators

**Key QA:** Test fire going out mid-night → monster enters → player relights → monster retreats. This sequence must work flawlessly.

**Key analytics:** Track how many players let the fire go out on Night 2. If >50% fail, fuel consumption is too aggressive.

**Unresolved:**
1. Should the upgrade require metal scrap (forcing Day 3) or just wood (available Day 2)?
2. Should there be a "last-resort" match/lighter item to relight instantly?
3. How many times should the monster "test" the boundary per night?
