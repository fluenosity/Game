# Day 3 — Scavenging and Discovery

> **Status:** `EXISTING_CANON` (scavenging, trading, base upgrades) + `PROPOSED` (crafting, lore, landmarks)
> **Last updated:** 2026-10-11
> **Design pillar:** Every Decision Matters

---

## 1. Document Metadata

| Field | Value |
|-------|-------|
| Day | 3 |
| Type | Full gameplay day — exploration-focused |
| Duration | `INITIAL_BALANCE_PROPOSAL` ~12–15 minutes real-time |
| Status | `EXISTING_CANON` (scavenging, trading) + `PROPOSED` (crafting, lore, landmarks) |
| Depends on | Day 2 completion |
| Leads to | Day 4 — Darkness and Escalation |

---

## 2. Purpose & Intended Emotion

### Purpose

Expand the game world beyond the shelter and trees. Introduce new resources, a trader, crafting/upgrades, and environmental storytelling. This is the **exploration peak** of the campaign.

Day 3 asks: "How far are you willing to go for better supplies?"

### Target Emotions

| Phase | Emotion |
|-------|---------|
| Morning | Curiosity ("What else is out there?") |
| Finding scrap | Excitement, discovery |
| Exploring landmarks | Wonder, unease |
| Meeting trader | Relief, strategic thinking |
| Deciding what to trade | Tension (tradeoffs) |
| Carrying loot back | Greed vs. safety anxiety |
| Night 3 | Justified fear (better prepared but night is longer) |

---

## 3. Narrative Context

The player has mastered fire management. They know the basic loop. Now the forest opens up — there's more to find than trees. Abandoned objects, scrap materials, and signs that someone was here before.

`EXISTING_CANON` "While finding wood you also find some useful things in forest like maybe metal, plastic" and "sell them to a guy to trade for better campfire material."

---

## 4. Player Starting Conditions

| Parameter | Value |
|-----------|-------|
| Health | 100 |
| Inventory | Remaining wood/items from Day 2 |
| Campfire state | Extinguished (post-night). Tier 1 or Reinforced. |
| Shelter | Tier 1 |
| Time of day | Early morning |

---

## 5–6. Prerequisites & Objectives

**Primary:**
1. "Explore the forest" → shown at dawn.
2. "Find useful materials" → after leaving shelter.
3. "Upgrade your shelter" → when returning with scrap.
4. "Survive the night" → at nightfall.

**Optional:**
- Find a lore item (torn journal page, scratched symbol).
- Discover a landmark (abandoned campsite, ruined shack).
- Trade with the wandering trader.

---

## 7. New Mechanics Introduced

### 7.1 Scrap Resources

`EXISTING_CANON` Players can find metal scraps, plastic, rope in the forest.

| Resource | Where Found | Stack Size | Uses |
|----------|-------------|-----------|------|
| Metal Scrap | Debris piles, wrecked objects | 2 per slot | Fire upgrades, shelter walls |
| Plastic | Scattered containers, bags | 2 per slot | Crafting, storage |
| Rope | Hanging from trees, in crates | 2 per slot | Crafting, reinforcement |

**Spawn rules:**
- `INITIAL_BALANCE_PROPOSAL` 8–12 scrap nodes in the forest on Day 3.
- Nodes are spread across different areas — some close, some far.
- Each node yields 1–2 items (randomized type).
- Nodes do NOT respawn within the same day. They respawn on dawn of the next day.

### 7.2 Wandering Trader

`EXISTING_CANON` A trader visits the camp.

| Aspect | Design |
|--------|--------|
| Arrival | `PROPOSED` Arrives mid-morning Day 3 at the shelter |
| Duration | Stays for ~2 minutes of real time, then leaves |
| Visual | Hooded NPC with a backpack and lantern |
| Audio | Arrival announced by a bell/chime sound |
| UI | Trading interface opens when interacting |

**Trade offerings (Day 3):**

| Player Gives | Player Gets | Purpose |
|-------------|-------------|---------|
| 3 Metal Scrap | 1 Premium Fuel (burns 2x slower) | Better fire efficiency |
| 2 Plastic + 1 Rope | 1 Torch (portable light, 120s duration) | `PROPOSED` Exploration safety |
| 4 Metal Scrap + 2 Rope | Campfire Tier 2 Upgrade Kit | Full upgrade without wood cost |
| 2 of any scrap | 3 Wood | Emergency fuel supply |

**Trader rules:**
- Trading is optional — never required to survive.
- Trader has limited stock per visit.
- Prices are fixed (no haggling).
- Server validates all trades (prevents duplication).
- `PROPOSED` Trader visits again on Day 4 with different/better offerings.

### 7.3 Shelter Upgrades

`EXISTING_CANON` "Upgrade base — walls, storage."

| Upgrade | Cost | Effect | Status |
|---------|------|--------|--------|
| Campfire Tier 2 | 6 Wood + 2 Metal Scrap | Radius 15 → 22 studs, capacity 5 → 8 | `PROPOSED` |
| Storage Box | 6 Wood + 2 Plastic | +8 storage slots (persist between nights) | `PROPOSED` |
| Fence Repair | 4 Metal Scrap + 2 Rope | `PROPOSED` Cosmetic + small delay on monster entry | `PROPOSED` |
| Workbench | 4 Wood + 3 Metal Scrap | Enables crafting recipes | `PROPOSED` |

### 7.4 Crafting `PROPOSED`

If the Workbench is built, basic crafting becomes available:

| Recipe | Cost | Result | Effect |
|--------|------|--------|--------|
| Torch | 1 Wood + 1 Rope | Portable light source | 120s burn time, small protection radius |
| Barricade | 3 Wood + 2 Metal | Placeable wall section | Slows monster approach |
| Better Fuel | 2 Wood + 1 Plastic | Premium fuel bundle | Burns 2x slower in campfire |

---

## 8. Step-by-Step Gameplay Flow

### Step 1: Morning — Expanded World (0:00–1:00)

- Player wakes. "DAY 3" displayed.
- `PROPOSED` The forest feels subtly different — new paths visible, distant landmarks noticeable.
- Objective: "Explore the forest."

### Step 2: Gathering + Scavenging (1:00–5:00)

- Player chops trees for wood (routine from Days 1–2).
- **New:** Player discovers scrap nodes scattered in the forest.
- Scrap nodes have proximity prompts: "Collect Metal Scrap" / "Collect Plastic" / "Collect Rope."
- Collection is instant (tap/click) — faster than chopping trees.
- Player must decide: fill inventory with wood (fuel) or scrap (upgrades)?

**Carry capacity tension:**
- 12 inventory slots total.
- Wood stacks to 4 per slot. Scrap stacks to 2.
- A full inventory of wood = lots of fuel but no upgrades.
- A mixed inventory = some fuel + some upgrades.
- **This is the core decision of Day 3.**

### Step 3: Landmark Discovery (2:00–5:00, exploration-dependent)

`PROPOSED` Players who explore further discover:

**Landmark A: Abandoned Campsite** (60s from shelter)
- An old campfire (long extinguished), a torn tent, scattered supplies.
- 2–3 scrap nodes nearby.
- `PROPOSED` A torn journal page on the ground — first lore item.
- Lore text: *"Day 14. The fire keeps it away but it's getting smarter. It watched us last night. Not from the trees — from ABOVE."*

**Landmark B: Ruined Shack** (90s from shelter)
- A small wooden structure, half-collapsed.
- Inside: scrap nodes + a special item (e.g., a lantern or extra rope).
- More scratches on the walls. A crude drawing of the monster.
- **Risk:** Further from shelter = less time to return.

### Step 4: Trader Visit (3:00–5:00)

- `PROPOSED` The trader arrives mid-morning (bell chime).
- Player returns to shelter to trade.
- Trading interface shows available exchanges.
- Player makes trade decisions based on what they found.

### Step 5: Upgrade & Prepare (5:00–7:00)

- Player spends gathered resources on upgrades.
- Fuels the campfire for the night.
- **Decision matrix:**

| Strategy | Benefit | Risk |
|----------|---------|------|
| Upgrade campfire to Tier 2 | Bigger safe zone, more capacity | Less fuel for tonight |
| Build storage box | Keep excess items for Day 4 | Costs wood that could be fuel |
| Build workbench + craft torches | Portable light for Night 3/4 | Material investment |
| Hoard all wood as fuel | Guaranteed fire all night | No upgrades, no progress |

### Step 6: Night 3 (7:00–12:00)

**Night 3 differences:**

| Aspect | Night 2 | Night 3 |
|--------|---------|---------|
| Duration | 240s | 300s (5 min) |
| Monster approaches | 2–3 times | 3–4 times |
| Monster behavior | Test boundary | `PROPOSED` Circles faster, approaches from different angles |
| `PROPOSED` Sound variety | Growling, footsteps | + scratching at fence, rattling |
| Fire management | Active | Active (longer night = more fuel needed) |
| `PROPOSED` Torch use | N/A | Player can place torches for secondary light |

### Step 7: Dawn & Sleep (12:00–15:00)

- Dawn. Monster retreats.
- Player sleeps → "DAY 4"
- Any items in storage box persist.

---

## 9–12. Timeline, Locations, Resources, Monster

See sections above (integrated into gameplay flow).

**Monster Night 3 state machine additions:**

| State | New Behavior |
|-------|-------------|
| PATROL | `PROPOSED` Moves at varying speeds, less predictable |
| APPROACH | Comes from different directions each time |
| TEST | `PROPOSED` Pushes slightly into the light (but still retreats) |
| FENCE_INTERACT | `PROPOSED` Rattles the fence — audio/visual scare |
| HUNT | Activates if fire goes out (same as Night 2) |

---

## 13–17. UI, Audio, Multiplayer, Solo, Mobile

**New UI:** Trading interface, crafting menu (if workbench built), scrap resource icons in inventory.

**Co-op Day 3:** Natural division — one player explores/scavenges while another guards shelter and trades. Co-op shines here because the exploration range is large.

**Mobile:** Trading and crafting interfaces must be touch-friendly — large buttons, clear costs, confirmation prompts.

---

## 18. Success & Failure

| Condition | Result |
|-----------|--------|
| Survive Night 3 | ✅ Day 3 complete |
| Fire goes out (no relight) | ❌ Death/restart |
| Player doesn't explore/trade | ✅ Still survivable but harder on Day 4 |

---

## 25. Acceptance Criteria

- [ ] Scrap resources are discoverable without explicit waypoints
- [ ] Carry capacity creates real inventory decisions
- [ ] Trading feels fair and optional
- [ ] At least one landmark provides a "wow" discovery moment
- [ ] The lore item is intriguing without being essential
- [ ] Night 3 is noticeably harder than Night 2
- [ ] Players who didn't upgrade can still survive (harder, but possible)
- [ ] The exploration/return timing creates genuine risk/reward tension

---

## 28. Unresolved Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | Should the trader be a permanent camp resident or a visitor? | World design, pacing |
| 2 | Is crafting necessary on Day 3 or should it wait for Day 4? | Mechanic pacing |
| 3 | How many lore items total? What do they collectively reveal? | Narrative scope |
| 4 | Should landmarks be randomized or fixed positions? | Replayability vs. level design |
| 5 | Can players store items between days without a storage box? | Economy balance |
