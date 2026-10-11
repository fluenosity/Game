# Lore and Story — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11
> **Design pillar:** Show, Don't Tell

---

## Storytelling Approach

The game tells its story through **environment, objects, and discovery** — never through dialogue, exposition dumps, or mandatory reading. Players who explore find pieces of a mystery. Players who don't explore still enjoy the survival gameplay.

---

## Lore Timeline (What Actually Happened) `PROPOSED`

| Event | When | What Happened |
|-------|------|--------------|
| The City Thrived | Years ago | A small city existed at the edge of the forest. Prosperous, safe. |
| The Discovery | Months ago | Researchers/workers disturbed something deep in the forest — an ancient presence. |
| The Corruption | Weeks ago | The presence — once a guardian of the forest — was twisted by the disturbance. It became The Hollow. |
| The Attacks | Days ago | The Hollow attacked the city at night. Residents discovered it feared fire. |
| The Evacuation | Days ago | Most residents fled. Some were lost. The city was abandoned. |
| The Player Arrives | Day 0 | The player witnesses the aftermath and escapes to the forest. |

---

## Lore Items (Discoverable)

| # | Item | Location | Day | Content |
|---|------|----------|-----|---------|
| 1 | Torn Journal Page | Near choppable trees | Day 2 (optional) | *"Something is wrong in the forest. The trees are darker. At night, I hear breathing."* |
| 2 | Scratched Warning | Shelter fence | Day 3 | *"KEEP THE FIRE LIT. Don't let it go below half."* |
| 3 | Researcher's Note | Abandoned campsite | Day 3 | *"Day 14. The fire keeps it away but it's getting smarter. It watched us last night."* |
| 4 | Child's Drawing | Ruined shack | Day 4 | A crayon drawing of a tall dark figure with ember eyes. A fire between it and stick-figure people. |
| 5 | Final Recording | Signal tower area | Day 4–5 | *"We dug too deep. We woke something that was meant to sleep. It was a guardian once. Now it's hollow."* |
| 6 | Old Photograph | Monster clearing | Day 5 | A faded photo of the city with a faint, luminous figure standing protectively over it — The Hollow before corruption. |

### Lore Collection Rules

- Lore items are optional — never required for survival or progression.
- Items are picked up like scrap (tap to collect).
- Collected items go to a "Journal" section in the menu.
- `PROPOSED` Collecting all 6 unlocks the Lore Ending (Ending E).
- Lore items are in fixed positions (not randomized) — players can share locations.

---

## The Hollow's Origin `PROPOSED`

The Hollow was once the forest's guardian spirit — a being of warm light that protected the boundary between civilization and wilderness. When researchers disturbed the deep forest (mining, excavation, or an experiment), the guardian was corrupted. Its light inverted to darkness. Its protection became predation.

**Why it fears fire:** Fire is an echo of what The Hollow once was. The campfire's light triggers a memory of its original purpose. It recoils not from pain but from recognition — a fragment of what it lost.

**Why this matters for gameplay:** The monster isn't evil — it's tragic. Players who discover the lore feel empathy alongside fear. This emotional complexity makes the game memorable.

---

## Environmental Storytelling

Beyond collectible items, the environment itself tells the story:

| Location | Story Element |
|----------|--------------|
| City ruins (cutscene) | Recent destruction — this happened DAYS ago, not years |
| Forest path scratches | Someone else fled this way before the player |
| Shelter condition | Previous occupant maintained it, then left suddenly |
| Abandoned campsite | Someone survived for ~2 weeks before disappearing |
| Ruined shack | A family hid here — children's items, makeshift beds |
| Monster clearing | The forest is damaged — trees are blackened, ground is scarred |
| Signal tower | Someone tried to call for help before — they didn't finish |

---

# Endings and Extraction

> **Status:** `PROPOSED`

---

## Ending Summary

| Ending | Trigger | Tone | Reward |
|--------|---------|------|--------|
| A: Full Escape | All players reach rescue point | Triumphant | Completion badge, XP, cosmetic |
| B: Partial Escape | Some players escape, others die | Bittersweet | Reduced badge, XP |
| C: Sacrifice | One player stays behind for others | Heroic | Special sacrifice badge |
| D: Total Failure | All players die Night 5 | Devastating | None — retry option |
| E: Lore Ending | All 6 lore items collected + escape | Emotional, revelatory | Exclusive cosmetic + lore badge |

See [DAY_05_SIGNAL_AND_ESCAPE.md](../campaign/DAY_05_SIGNAL_AND_ESCAPE.md) for detailed ending sequences.

---

# Meta Progression

> **Status:** `PROPOSED`

---

## What Persists Between Sessions

| Item | Persists? | Storage |
|------|-----------|---------|
| Cosmetic unlocks (skins, effects) | ✅ Yes | DataStore (player) |
| Achievement badges | ✅ Yes | DataStore (player) |
| Lore journal entries | ✅ Yes | DataStore (player) |
| Campaign completion count | ✅ Yes | DataStore (player) |
| In-game resources (wood, scrap) | ❌ No | Session only |
| Shelter upgrades | ❌ No | Session only |
| Campfire tier | ❌ No | Session only |
| Signal components | ❌ No | Session only |

### Unlockables `PROPOSED`

| Unlock | How Earned | Type |
|--------|-----------|------|
| "Survivor" title | Complete campaign once | Cosmetic |
| Campfire skin: Blue Flame | Complete campaign in under 50 minutes | Cosmetic |
| Monster tracker cosmetic | Find all lore items | Cosmetic |
| "Sacrifice" badge | Use Ending C | Achievement |
| Difficulty modifiers | Complete campaign once | Gameplay |
| Speedrun timer | Complete campaign once | Feature |
| Challenge mode: No Upgrades | Complete campaign twice | Gameplay |

---

# Difficulty and Replayability

> **Status:** `PROPOSED`

---

## Difficulty Modifiers (Post-Completion)

| Modifier | Effect | Unlocked |
|----------|--------|----------|
| Normal | Default experience | Always |
| Extended Nights | Night duration +50% | After 1 completion |
| Scarce Resources | 50% fewer resource nodes | After 1 completion |
| Aggressive Hollow | Monster Day 4+ behavior from Day 2 | After 2 completions |
| No Trader | Wandering trader doesn't appear | After 2 completions |
| Ironman | No restarts — one death = campaign over | After 3 completions |

## Replay Value

- Different co-op strategies (who guards, who scouts).
- Different upgrade paths (fire focus vs. base focus vs. crafting focus).
- Lore hunting (find all items).
- Speedrunning (completion timer).
- Difficulty modifiers.
- Different endings to experience.
- Leaderboards (fastest completion, most nights survived).
