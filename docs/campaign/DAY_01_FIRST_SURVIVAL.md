# Day 1 — First Survival

> **Status:** `EXISTING_CANON`
> **Last updated:** 2026-10-11
> **Design pillar:** Show, Don't Tell + Fire Is Life

---

## 1. Document Metadata

| Field | Value |
|-------|-------|
| Day | 1 |
| Type | Full gameplay day (daytime + night) |
| Duration | `INITIAL_BALANCE_PROPOSAL` ~8–10 minutes real-time |
| Status | `EXISTING_CANON` (core flow), `PROPOSED` (numerical values, edge cases) |
| Depends on | Day 0 completion or skip |
| Leads to | Day 2 — Fire and Preparation |

---

## 2. Purpose & Intended Emotion

### Purpose

Teach the entire core gameplay loop in its simplest, most forgiving form:

**Find shelter → Gather wood → Return before nightfall → Light campfire → Survive the night**

Day 1 is the tutorial. Every mechanic introduced here must work flawlessly. The player must succeed on their first attempt.

### Target Emotions

| Phase | Emotion |
|-------|---------|
| Morning (forest arrival) | Curiosity, mild anxiety |
| Finding shelter | Relief, comfort |
| Chopping trees | Competence, purpose |
| Nightfall warning | Urgency, first real tension |
| Lighting the campfire | Accomplishment |
| First night | Fear, vulnerability, alertness |
| Dawn | Relief, pride ("I survived") |

---

## 3. Narrative Context

The player has just witnessed (or skipped) the destruction of a city and a monster that fears fire. They are now in a forest. They don't know where to go. They see a path.

**What the player knows:**
- A monster exists.
- Fire scares it.
- They need to survive.

**What the player discovers during Day 1:**
- There's a shelter in the forest.
- Trees can be chopped for wood.
- Wood fuels the campfire.
- The campfire keeps the monster away.
- Night is dangerous; day is safe.

---

## 4. Player Starting Conditions

| Parameter | Value |
|-----------|-------|
| Health | 100 (full) |
| Inventory | Empty |
| Position | Forest entrance (after Day 0 transition) |
| Camera | First-Person Perspective (FPP) |
| Controls | Fully enabled |
| Time of day | Early morning (bright, safe) |
| Shelter state | Undiscovered |
| Campfire state | Unlit, Tier 1 |

---

## 5. Prerequisites

- Day 0 cutscene completed or skipped.
- Player has transitioned to the forest map.
- Forest environment is loaded.

---

## 6. Primary Objective

**Survive the first night by finding shelter, gathering wood, and lighting the campfire.**

Displayed as sequential sub-objectives:
1. "Find shelter" → shown at start.
2. "Collect wood" → shown after entering shelter.
3. "Return to shelter" → shown at nightfall warning.
4. "Light the campfire" → shown when at campfire spot with wood.

---

## 7. Optional Objectives

None on Day 1. Keep it focused. Optional exploration and discovery start on Day 2–3.

---

## 8. Step-by-Step Gameplay Flow

### Step 1: Forest Arrival (0:00–0:30)

**Context:** The player is standing at the forest entrance. It's morning. Bright, dappled sunlight through the trees.

**What the player sees:**
- A forest stretching ahead.
- `EXISTING_CANON` "Only one clear path leading towards" the shelter.
- Trees, undergrowth, natural sounds.
- No enemies, no threats, no timer.

**What the player does:**
- Begins walking along the path.
- Gets familiar with movement controls (WASD / virtual joystick).
- Looks around (mouse / touch-drag).

**UI:** Objective appears: **"Find shelter"** (top-left, fades after 5s).

### Step 2: Shelter Discovery (0:30–1:30)

**Context:** Following the path, the player arrives at the shelter.

**What the player sees:**
- `EXISTING_CANON` "A small, basic yard surrounded by a metal mesh fence, similar to a chain-link fence."
- `EXISTING_CANON` "Abandoned and slightly damaged, but still usable."
- Inside the yard:
  - `EXISTING_CANON` "An old, broken sofa where the player can sleep."
  - `EXISTING_CANON` "A simple table."
  - `EXISTING_CANON` "A clearly visible, designated campfire spot" — circular stone fire pit with ashes.
- An entry point (gate or gap in the fence).

**What the player does:**
- Enters the shelter through the gate.
- Looks around the yard.
- Notices the campfire spot (it should be the most visually prominent object).

**UI:** Objective updates: **"Collect wood"** (after player enters shelter area).

### Step 3: Learning Interaction — Examining the Campfire (1:30–2:00)

**Context:** The player approaches the campfire spot.

**What the player sees:**
- A proximity prompt: "Light Campfire" (but grayed out / showing "Requires: Wood x2").
- This teaches: you need wood before you can light the fire.

**What the player does:**
- Approaches campfire spot.
- Sees they need wood.
- Turns to leave the shelter and find trees.

### Step 4: Gathering Wood (2:00–4:30)

**Context:** The player leaves the shelter to find trees to chop.

**What the player sees:**
- `EXISTING_CANON` "Two trees that can be chopped down" are clearly marked (slightly different from background trees — maybe a subtle glow, a different size, or an interaction prompt appears when close).
- `EXISTING_CANON` There are actually 3 choppable trees (2 required + 1 safety margin), per balance doc.
- Other background trees are decoration and NOT interactive.

**What the player does:**
- Approaches a choppable tree.
- Sees proximity prompt: **"Chop" (Hold E / Hold button)**.
- Holds the interaction for 5 seconds. Tree-chopping animation plays.
- Tree falls / breaks. Player receives **2 wood** per tree.
- Repeats for the second tree. Now has **4 wood**.
- Carries wood back to shelter.

**Audio:** Chopping sounds, tree cracking, wood collection *thunk*.
**Visual:** Wood appears in inventory strip (bottom of screen).

### Step 5: Lighting the Campfire (4:30–5:30)

**Context:** The player returns to the shelter with 4 wood.

**What the player sees:**
- The campfire spot now shows: **"Light Campfire" (Hold E / Hold button)** — active, not grayed out.
- The sky is still daytime but afternoon. The player has time.

**What the player does:**
- Approaches campfire spot.
- Holds interaction for 3 seconds.
- The campfire ignites. Flames appear. Warm light spreads.
- The protection radius becomes visible (subtle ground glow or particle boundary).

**Audio:** Match strike, fire whoosh, crackling flames.
**Visual:** Fire particles, warm light, visible safe zone edge.
**Player emotion:** Accomplishment, safety.

### Step 6: Nightfall Warning (5:00–5:30)

`INITIAL_BALANCE_PROPOSAL` At 60 seconds before night:

**What the player sees:**
- The sky darkens noticeably. Orange sunset colors.
- UI warning: **"Night is approaching. Stay near the fire."**
- Audio: Subtle tension chord. Distant rumble.

If the player is still outside the shelter, urgency increases:
- UI becomes more prominent.
- Audio cues intensify.
- The forest grows darker and more ominous.

### Step 7: Night Falls (5:30–8:30)

**Context:** Night begins. The campfire is the only light source.

**What the player sees:**
- Complete darkness beyond the campfire's protection radius.
- The fire is bright and warm — the safe zone is clear.
- Beyond the light: **nothing is visible**.
- `PROPOSED` Sounds emerge from the darkness: footsteps, breathing, branches breaking.
- `PROPOSED` Occasionally, the monster's silhouette is glimpsed at the edge of the light.
- The monster circles the shelter but never enters the protection radius.

**What the player does:**
- Stays within the protection radius.
- `PROPOSED` On Day 1, fire consumption is minimal — the fire stays lit through the night with the initial fuel.
- Watches, listens, and survives.

**What the monster does (Day 1 behavior):**
- Patrols at a distance.
- Approaches the edge of the protection radius but does not enter.
- Makes sounds: footsteps, growls, branch snaps.
- `PROPOSED` Briefly visible as a silhouette 1–2 times during the night.
- Does NOT attack on Night 1 (introduction only).
- Retreats at dawn.

**Player emotion:** Fear, vulnerability, helplessness (in a good way), curiosity about the monster.

### Step 8: Dawn & Day 1 End (8:30–10:00)

**Context:** Night ends. Dawn breaks.

**What the player sees:**
- The sky lightens. Sunrise colors.
- Monster sounds fade away.
- The forest becomes visible again.
- Ambient nature sounds return (birds, wind).

**What the player does:**
- `EXISTING_CANON` "The player sits or lies down on the old sofa and falls asleep."
- Interaction prompt near the sofa: **"Sleep"**
- Player holds interaction → character lies down.
- `EXISTING_CANON` "The screen fades to black."
- Text appears: **"DAY 2"**
- Player wakes up on the sofa. Day 2 morning begins.

---

## 9. Time-of-Day Timeline

| Real Time | Game Time | Event |
|-----------|-----------|-------|
| 0:00 | Early morning | Player spawns in forest |
| 0:30 | Morning | Shelter discovered |
| 2:00 | Mid-morning | Wood gathering begins |
| 4:30 | Afternoon | Return to shelter, light fire |
| 5:00 | Late afternoon | Nightfall warning (60s before night) |
| 5:30 | Dusk → Night | Night begins, monster active |
| 8:30 | Night → Dawn | Night ends, monster retreats |
| 9:00 | Dawn | Player sleeps, fade to black |
| 9:30 | — | "DAY 2" displayed |

All times are `INITIAL_BALANCE_PROPOSAL`.

---

## 10. Locations, Landmarks, Level Design

### Forest Path (Start → Shelter)

| Aspect | Requirement |
|--------|------------|
| Length | ~30 seconds of walking |
| Complexity | Straight/gentle curve — ONE path, no branches |
| Visibility | Shelter should be partially visible from the start |
| Ambience | Birds, rustling leaves, dappled sunlight |
| Props | Fallen logs, mushrooms, rocks — decorative only |

### Shelter

| Aspect | Requirement |
|--------|------------|
| Size | ~20x20 stud yard |
| Fence | Chain-link / metal mesh, partially damaged |
| Entry | One clear gate/opening |
| Campfire spot | Center of yard, stone fire pit, most prominent object |
| Sofa | Against one wall, clearly interactable |
| Table | Near sofa, decorative (no function on Day 1) |
| Lighting | Well-lit during day, campfire-only at night |

### Choppable Tree Area

| Aspect | Requirement |
|--------|------------|
| Distance from shelter | 15–30 seconds of walking |
| Tree count | 3 choppable trees (2 required + 1 spare) |
| Visibility | Trees should be distinguishable from background foliage |
| Navigation | Clear path from shelter to trees and back |

---

## 11. Resources & Numerical Values

| Resource | Source | Quantity | Used For |
|----------|--------|----------|----------|
| Wood | Choppable tree | 2 per tree | Campfire fuel |
| Available trees | Forest near shelter | 3 total | Day 1 supply |
| Total available wood | — | 6 (from 3 trees) | — |
| Wood needed to light fire | Campfire spot | 2 minimum | Ignition |
| Wood consumed Night 1 | Campfire | ~3 (180s ÷ 60s/wood) | Fuel |
| Surplus wood | — | ~1–3 depending on trees chopped | Carry to Day 2 |

All values `INITIAL_BALANCE_PROPOSAL`.

---

## 12. Monster Behavior (Day 1)

The monster on Night 1 is **introductory** — scary but not lethal.

| State | Behavior | Transition |
|-------|----------|-----------|
| **DORMANT** | Not present during daytime | → PATROL when night begins |
| **PATROL** | Circles the shelter at a distance (~50 studs) | → APPROACH randomly 1–2 times per night |
| **APPROACH** | Moves closer to the protection radius edge (~20 studs) | → RETREAT after 10–15 seconds |
| **RETREAT** | Backs away from the fire's light | → PATROL |
| **DAWN_RETREAT** | Flees the area when dawn begins | → DORMANT |

**Day 1 restrictions:**
- The monster does NOT enter the protection radius.
- The monster does NOT attack the player.
- The monster is primarily atmospheric — sounds and brief glimpses.
- Its purpose is to make the player AFRAID, not to kill them.

---

## 13. UI Messages, Audio, Visual Feedback

### UI Elements Active on Day 1

| Element | Position | Content |
|---------|----------|---------|
| Objective text | Top-left | Sequential objectives (find shelter, collect wood, etc.) |
| Inventory strip | Bottom-center | Shows wood count |
| Interaction prompt | Center-bottom | "Chop" / "Light Campfire" / "Sleep" (proximity-based) |
| Day indicator | Top-right | "DAY 1" (shown at start) |
| Nightfall warning | Center | "Night is approaching. Stay near the fire." |

### Audio Cues

| Event | Sound |
|-------|-------|
| Forest ambient | Birds, wind, rustling |
| Approaching shelter | Subtle positive tone (discovery) |
| Tree chopping | Axe hits, wood cracking |
| Wood collected | Pickup *thunk* |
| Fire lit | Match strike, fire whoosh |
| Nightfall warning | Low tension chord |
| Night ambient | Silence, then monster sounds |
| Monster patrol | Distant footsteps, branch snaps |
| Monster approach | Closer footsteps, growling |
| Dawn | Birds return, tension releases |
| Sleep | Calm, fading ambient |

---

## 14. Multiplayer Behavior

| Scenario | Behavior |
|----------|----------|
| Multiple players arrive | All spawn at forest entrance simultaneously |
| Shelter discovery | First player to enter triggers objective update for all |
| Wood gathering | Each player chops independently; trees are shared resources |
| Campfire lighting | Any player can light the fire if they have wood |
| Wood contribution | Any player can add wood to the campfire |
| Night survival | All players must stay within protection radius |
| Sleeping | `PROPOSED` All alive players must choose "Sleep" to end the day |
| One player explores while another lights fire | Allowed — cooperative division of labor |

### Resource Sharing

- Trees are shared — if Player A chops a tree, it's gone for everyone.
- Scale: In co-op, more trees spawn (see Gameplay Balance doc, co-op scaling).
- Wood added to the campfire benefits all players.

---

## 15. Solo Player Behavior

Identical to multiplayer except:
- No resource scaling (base values).
- Player must do all tasks alone.
- Sleep interaction ends the day immediately (no waiting for others).
- Monster behavior is slightly less aggressive (base difficulty).

---

## 16. Mobile & Controller Considerations

| Action | PC | Mobile | Controller |
|--------|-----|--------|-----------|
| Move | WASD | Left virtual joystick | Left stick |
| Look | Mouse | Right-side touch-drag | Right stick |
| Chop tree | Hold E near tree | Hold on-screen button | Hold A/X |
| Light fire | Hold E near campfire | Hold on-screen button | Hold A/X |
| Sleep | Hold E near sofa | Hold on-screen button | Hold A/X |
| Sprint | Hold Shift | Sprint button | Hold LB/L1 |

**Mobile-specific:**
- Interaction prompts must be large (44x44 min).
- Inventory strip must not overlap with movement joystick.
- Chop interaction: hold-to-chop is more natural than rapid tapping on mobile.

---

## 17. Accessibility

- Subtitles for all audio cues: "[Footsteps nearby]" "[Fire crackling]" "[Growling in distance]"
- Objective text is readable (min 14pt equivalent).
- Campfire safe zone has a visible boundary (not just light — use a ground effect).
- Color-blind: safe zone boundary uses both color AND a pattern/shape.
- Reduced motion: disable head bob, minimal camera shake.

---

## 18. Success & Failure Conditions

| Condition | Result |
|-----------|--------|
| Player lights campfire and survives night | ✅ Day 1 complete → transition to Day 2 |
| Player doesn't light campfire before night | ❌ Monster attacks → death (but Day 1 monster is lenient) |
| Player dies | `PROPOSED` Restart Day 1 (solo) or teammate revival (co-op) |
| Player runs out of available trees | Should not happen (3 trees available, 2 needed) |

### Day 1 Safety Net

Day 1 is intentionally easy. If the player has ANY trouble:
- There are 3 trees (only 2 needed).
- The nightfall warning comes early (60s).
- The path to shelter is unmissable.
- The campfire spot is obvious.
- Night 1 is short (3 minutes).
- The monster does not attack on Night 1 (atmospheric only).

**If players routinely fail Day 1, the game has a fundamental onboarding problem that must be fixed.**

---

## 19. Death, Disconnect, Recovery

| Scenario | Solo | Co-op |
|----------|------|-------|
| Player dies from monster | Restart Day 1 | `PROPOSED` Teammate can revive within 30s |
| Player disconnects | Session ends | Session continues without them |
| Player reconnects | `PROPOSED` Rejoin if session still active | Rejoin at current state |
| All co-op players die | — | Session ends, return to lobby |

---

## 20. Edge Cases & Exploits

| Edge Case | Handling |
|-----------|---------|
| Player tries to run past shelter deeper into forest | `PROPOSED` Invisible boundary or fallen trees block further exploration on Day 1 |
| Player chops all 3 trees but doesn't return | Nightfall warning urges return; monster is lenient on Day 1 |
| Player drops wood | Wood persists on ground; player can pick it back up |
| Player puts ALL wood in fire immediately | Fire doesn't consume fuel during daytime — fuel is only consumed at night |
| Two players try to chop the same tree | First interaction claims the tree; second player sees "Already being chopped" |
| Player tries to sleep during daytime | Prompt only appears at night after surviving |
| Player stands exactly on protection radius edge | Inside = safe, outside = vulnerable. Boundary is server-authoritative. |

---

## 21. Interactions with Other Systems

| System | Interaction |
|--------|------------|
| Day/Night Cycle | Day 1 morning starts after Day 0 transition; night triggers monster spawn |
| Fire System | Campfire is initialized at Tier 1; first ignition; basic fuel consumption |
| Monster AI | Night 1 patrol behavior (introductory, non-lethal) |
| Inventory | First items (wood) enter player inventory |
| Gathering | First tree-chopping interaction |
| Player Health | Player starts at full health; monster does NOT damage on Night 1 |
| Session Matchmaking | Session is fully active; Day 1 is the first gameplay state |

---

## 22. Required Assets

| Asset | Type | Priority |
|-------|------|----------|
| Forest environment (path section) | 3D scene | High |
| Shelter yard (fence, gate, ground) | 3D model | High |
| Old sofa | 3D model | High |
| Table | 3D model | Medium |
| Campfire spot (stone fire pit) | 3D model | High |
| Campfire flames (Tier 1) | Particle system | High |
| Protection radius visual | Ground decal / particles | High |
| Choppable tree (3 instances) | 3D model + destruction | High |
| Background trees (non-interactive) | 3D models | Medium |
| Wood item (inventory icon + world model) | 2D sprite + 3D model | High |
| Forest ambient audio | Audio | High |
| Night ambient audio | Audio | High |
| Tree chop sound | Audio | High |
| Fire sound | Audio | High |
| Monster patrol sounds (footsteps, breathing, growling) | Audio | High |
| Nightfall warning sound | Audio | Medium |
| Dawn sound (birds returning) | Audio | Medium |
| "DAY 2" text display | UI element | Medium |

---

## 23. Implementation Dependencies

| Dependency | Required For |
|-----------|-------------|
| FPP camera system | Player perspective |
| Movement controller | WASD / joystick |
| Proximity prompt system | Interaction with trees, fire, sofa |
| Inventory system (basic) | Carrying wood |
| Day/night cycle state machine | Time progression |
| Fire system (Tier 1 ignition) | Campfire mechanic |
| Monster AI (patrol state only) | Night atmosphere |
| Protection radius system | Safe zone |
| Audio manager | Ambient and event sounds |
| UI framework | Objectives, inventory strip, warnings |
| Sleep/transition system | Day end sequence |

---

## 24. Technical Implementation Notes

- **Tree chopping:** Server validates the chop. Client sends `ChopRequest(treeId)`. Server checks: tree exists, tree not already being chopped, player is within interaction range (8 studs `ASSUMPTION`). Server depletes tree HP over 5s. On destruction, server grants wood to player inventory.
- **Campfire ignition:** Server validates: player has ≥2 wood, player is within interaction range of campfire spot. Server deducts wood, sets campfire state to LIT, begins fuel timer.
- **Protection radius:** Server-authoritative circle centered on campfire. Monster AI checks distance to campfire — if within protection radius + avoidance buffer, monster transitions to RETREAT state.
- **Day/night transition:** Server controls a single `TimeOfDay` value. At threshold, server fires `NightStarted` event. Monster AI listens for this event. At dawn threshold, server fires `DawnStarted`.
- **Sleep interaction:** Server validates: time is post-dawn, campfire is lit (was lit during night), player is near sofa. If all conditions met (all players in co-op), server transitions to Day 2.

---

## 25. Acceptance Criteria

- [ ] A first-time player can find the shelter within 60 seconds of starting Day 1
- [ ] A first-time player can chop a tree and collect wood without confusion
- [ ] The campfire interaction is immediately understandable
- [ ] The player survives Night 1 on their first attempt (assuming they followed basic objectives)
- [ ] The monster is heard and glimpsed during Night 1 but does not attack
- [ ] The player feels genuine tension during the first night
- [ ] The "DAY 2" transition feels smooth and earned
- [ ] All interactions work correctly on mobile (touch controls)
- [ ] All interactions work in 5-player co-op without conflicts
- [ ] The total Day 1 experience takes ~8–10 minutes

---

## 26. QA Test Cases

| # | Test | Expected Result |
|---|------|----------------|
| 1 | Walk along path from spawn | Reach shelter within 30–60s |
| 2 | Approach campfire without wood | Prompt shows "Requires: Wood x2" (grayed out) |
| 3 | Chop first tree | 5s hold interaction, receive 2 wood |
| 4 | Chop second tree | Receive 2 more wood (4 total) |
| 5 | Return to campfire with 4 wood | "Light Campfire" prompt is active |
| 6 | Light campfire | 3s hold, fire ignites, protection radius appears |
| 7 | Wait for night | Sky darkens, monster sounds begin |
| 8 | Stay inside protection radius all night | Survive — no damage taken |
| 9 | Step outside protection radius at night | `PROPOSED` Monster approaches (Day 1: warning only, no attack) |
| 10 | Wait for dawn after surviving night | Sky brightens, monster retreats |
| 11 | Interact with sofa at dawn | "Sleep" prompt appears, fade to black, "DAY 2" |
| 12 | Two players chop the same tree simultaneously | First claim wins; second gets "Already being chopped" |
| 13 | Solo mobile playthrough | Complete Day 1 using only touch controls |
| 14 | 5-player co-op playthrough | All players can complete Day 1 together |

---

## 27. Analytics Events

| Event | Data | Purpose |
|-------|------|---------|
| `day1_started` | session_id, player_count | Track Day 1 starts |
| `shelter_found` | player_id, time_elapsed | How long to find shelter? |
| `first_tree_chopped` | player_id, time_elapsed | Gathering tutorial completion |
| `campfire_lit` | session_id, time_elapsed, wood_count | Fire system engagement |
| `night1_started` | session_id | Night phase tracking |
| `night1_survived` | session_id, player_count | Success rate |
| `day1_failed` | session_id, cause | What went wrong? |
| `day1_completed` | session_id, total_time, wood_remaining | Overall Day 1 metrics |
| `player_left_protection_radius` | player_id, duration | Risk-taking behavior |

---

## 28. Unresolved Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | Should the monster attack on Night 1 if player leaves fire? | Safety vs. early consequence |
| 2 | Should Day 1 have a "soft fail" (monster chases but doesn't kill)? | Tutorial leniency |
| 3 | How visible should the monster be on Night 1? (sounds only? silhouette? close-up?) | Horror intensity |
| 4 | Should co-op players be able to revive dead teammates on Day 1? | Co-op rules |
| 5 | Should there be a third optional task (e.g., find a lore note near the trees)? | Pacing vs. overload |
| 6 | Can the player explore beyond the tree area on Day 1? | Exploration boundary |

---

## 29. Changes That Would Invalidate This Day

- Removing the shelter concept.
- Changing gathering from tree chopping to something else.
- Removing fire as a protection mechanic.
- Changing from FPP to third-person.
- Making Day 1 non-survivable by design (intentional first-night death).
- Removing the day/night cycle.
