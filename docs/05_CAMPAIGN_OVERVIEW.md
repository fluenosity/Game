# Campaign Overview — Project: Undecided

> **Status:** `EXISTING_CANON` (Days 0–3 concept) + `PROPOSED` (Days 4–5, structure, pacing)
> **Last updated:** 2026-10-11

---

## Campaign Structure

**`PROPOSED`** — The campaign spans **6 phases** (Day 0 prologue + 5 playable days/nights). This provides a focused, completable experience rather than open-ended survival.

```
DAY 0          DAY 1           DAY 2            DAY 3              DAY 4              DAY 5
PROLOGUE  →  FIRST SURVIVAL → FIRE & PREP  →  SCAVENGE & DISCOVER → DARKNESS & ESCALATION → SIGNAL & ESCAPE
(Cutscene)   (Learn the loop) (Deepen fire)  (Expand the world)   (Everything changes)    (Final stand)
```

---

## Day-by-Day Summary

### Day 0 — Prologue: The City Falls

**Status:** `EXISTING_CANON`

| Aspect | Detail |
|--------|--------|
| **Duration** | 10–15 second cutscene + short escape sequence |
| **Gameplay** | None (cinematic) or minimal escape running |
| **Purpose** | Introduce the monster, establish fire = safety, create atmosphere |
| **Player learns** | The city is destroyed. A monster exists. It fears fire. I need to run. |
| **Key moment** | Monster sees fire on a building, recoils, and flees |
| **Ends when** | Player reaches the forest / transitions to Day 1 |

**Detailed spec:** [campaign/DAY_00_PROLOGUE.md](./campaign/DAY_00_PROLOGUE.md)

---

### Day 1 — First Survival

**Status:** `EXISTING_CANON`

| Aspect | Detail |
|--------|--------|
| **Duration** | `ASSUMPTION` ~8–10 minutes real-time |
| **Gameplay** | Explore → find shelter → chop 2 trees → return → light fire → survive night |
| **Purpose** | Teach the complete core loop in its simplest form |
| **Player learns** | How to move, interact, gather wood, find the shelter, light the campfire, survive |
| **New mechanics** | Movement, interaction, gathering, campfire lighting, day/night cycle, monster presence |
| **Key moment** | First time seeing/hearing the monster at night while huddled by the campfire |
| **Ends when** | Player survives the night and sleeps on the sofa → fade to black → "DAY 2" |

**Detailed spec:** [campaign/DAY_01_FIRST_SURVIVAL.md](./campaign/DAY_01_FIRST_SURVIVAL.md)

---

### Day 2 — Fire and Preparation

**Status:** `EXISTING_CANON` (wood gathering, fire upgrade) + `PROPOSED` (fuel management, depletion)

| Aspect | Detail |
|--------|--------|
| **Duration** | `ASSUMPTION` ~10–12 minutes real-time |
| **Gameplay** | Gather more wood → upgrade campfire → manage fuel through the night |
| **Purpose** | Introduce preparation depth and meaningful resource decisions |
| **Player learns** | Fire is not permanent — it needs fuel. Better fire = bigger safe zone. Preparation matters. |
| **New mechanics** | Fire upgrading, fuel consumption (`PROPOSED`), fire intensity, protection radius scaling |
| **Key moment** | `PROPOSED` The fire flickers and nearly dies during the night — player must feed it |
| **Ends when** | Player survives Night 2 → "DAY 3" |

**Detailed spec:** [campaign/DAY_02_FIRE_AND_PREPARATION.md](./campaign/DAY_02_FIRE_AND_PREPARATION.md)

---

### Day 3 — Scavenging and Discovery

**Status:** `EXISTING_CANON` (scavenging, trading, base upgrades) + `PROPOSED` (crafting, lore)

| Aspect | Detail |
|--------|--------|
| **Duration** | `ASSUMPTION` ~12–15 minutes real-time |
| **Gameplay** | Gather wood + scavenge scrap (metal, plastic, rope) → trade with trader → upgrade base |
| **Purpose** | Expand the world beyond the shelter; give players reasons to explore further |
| **Player learns** | There's more in the forest than trees. Trading exists. The shelter can be improved. |
| **New mechanics** | Scrap materials, different resource types, wandering trader, base upgrades, crafting (`PROPOSED`) |
| **Key moment** | First time finding a landmark or lore clue deep in the forest |
| **Ends when** | Player survives Night 3 → "DAY 4" |

**Detailed spec:** [campaign/DAY_03_SCAVENGING_AND_DISCOVERY.md](./campaign/DAY_03_SCAVENGING_AND_DISCOVERY.md)

---

### Day 4 — Darkness and Escalation

**Status:** `PROPOSED`

| Aspect | Detail |
|--------|--------|
| **Duration** | `ASSUMPTION` ~12–15 minutes real-time |
| **Gameplay** | The monster changes behavior. Previous strategies may not be sufficient. Major preparation needed. |
| **Purpose** | Disrupt player confidence. Make them feel the rules are shifting. |
| **Player learns** | The monster is adapting. Small fires may not be enough. I need to think differently. |
| **New mechanics** | `PROPOSED` Monster learns/escalates, fire vulnerability events, new threats, expanded exploration |
| **Key moment** | The monster does something it has never done before (e.g., approaches despite fire, tests weak points) |
| **Ends when** | Player survives Night 4 → "DAY 5" |

**Detailed spec:** [campaign/DAY_04_DARKNESS_AND_ESCALATION.md](./campaign/DAY_04_DARKNESS_AND_ESCALATION.md)

---

### Day 5 — The Signal and Escape

**Status:** `PROPOSED`

| Aspect | Detail |
|--------|--------|
| **Duration** | `ASSUMPTION` ~15–20 minutes real-time |
| **Gameplay** | Discover the escape objective → gather final components → build/activate signal → survive final night → escape |
| **Purpose** | Provide a satisfying conclusion. Make the player feel their progress mattered. |
| **Player learns** | There IS a way out. Everything I've built leads to this. |
| **New mechanics** | `PROPOSED` Signal tower / escape device, final defense event, ending sequence |
| **Key moment** | The final night — the most intense monster encounter — while defending the signal |
| **Ends when** | Signal activated → escape sequence → ending screen → rewards → return to lobby |

**Detailed spec:** [campaign/DAY_05_SIGNAL_AND_ESCAPE.md](./campaign/DAY_05_SIGNAL_AND_ESCAPE.md)

---

## Pacing and Difficulty Curve

```
Intensity
    │
  5 │                                                    ╭──╮ Day 5
    │                                               ╭───╯  │ Final Stand
  4 │                                          ╭───╯       │
    │                              Day 4  ╭───╯            │
  3 │                         ╭──────────╯                 │
    │              Day 3 ╭───╯                             │
  2 │         ╭─────────╯                                  │
    │  Day 2 ╭╯                                            │
  1 │  ╭────╯                                              │
    │ Day 1                                                │
  0 ├─╯────────────────────────────────────────────────────┤
    Day 0  Day 1   Day 2    Day 3     Day 4      Day 5
```

### Pacing Rules

1. **Each day must introduce exactly ONE new major mechanic** — never two at once.
2. **Each night must be harder than the last** — but through new challenges, not just higher numbers.
3. **Day 1 must be completable by any player on their first try** — it's a tutorial.
4. **Day 3 is the "exploration peak"** — widest world, most discovery.
5. **Day 4 is the "disruption"** — everything the player thought they knew gets challenged.
6. **Day 5 is the "climax"** — the most intense, but also the most rewarding.

---

## Mechanic Introduction Timeline

| Day | New Mechanics Introduced | Previously Learned Mechanics Used |
|-----|-------------------------|----------------------------------|
| Day 0 | Monster visual, fire = safety (passive) | None |
| Day 1 | Movement, gathering, campfire, shelter, day/night | Monster fear of fire |
| Day 2 | Fire upgrades, fuel management | Gathering, campfire, day/night |
| Day 3 | Scrap types, trading, crafting, base upgrades, exploration | Everything from Days 1–2 |
| Day 4 | Monster escalation, new threats, advanced defense | Everything from Days 1–3 |
| Day 5 | Escape objective, final event | Everything from Days 1–4 |

---

## Session Timing Estimates

| Day | Daytime | Night | Total (est.) |
|-----|---------|-------|-------------|
| Day 0 | — | — | ~1–2 min (cutscene + escape) |
| Day 1 | ~5 min | ~3 min | ~8–10 min |
| Day 2 | ~6 min | ~4 min | ~10–12 min |
| Day 3 | ~8 min | ~5 min | ~12–15 min |
| Day 4 | ~7 min | ~6 min | ~12–15 min |
| Day 5 | ~8 min | ~8 min | ~15–20 min |
| **Total** | | | **~60–75 min** |

> **`ASSUMPTION`** All timing values are `INITIAL_BALANCE_PROPOSAL` and need playtesting. The total campaign should feel like a complete session in ~60–75 minutes. This is long for Roblox — consider checkpoint saving.

---

## Campaign Failure & Retry

| Scenario | Behavior |
|----------|----------|
| Player dies (solo) | `PROPOSED` Restart current day OR full campaign restart (TBD) |
| All players die (co-op) | `PROPOSED` Session ends → results screen → return to lobby |
| Player disconnects | `PROPOSED` If save system: can rejoin or continue later. If no save: session continues without them. |
| Campaign completed | Results screen → rewards → option to replay with modifiers or return to lobby |

---

## Unresolved Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| 1 | Is the campaign 5 days or open-ended? | Defines the entire game structure | `PROPOSED` 5 days — awaiting approval |
| 2 | What is the end goal? (signal tower, escape, defeat monster?) | Defines Day 5 design | `PROPOSED` signal tower — awaiting approval |
| 3 | Is death permanent (roguelike) or checkpoint-based? | Defines difficulty and session length | Undecided |
| 4 | Should the campaign be replayable with modifiers? | Affects longevity and replay value | `PROPOSED` yes |
| 5 | Is 60–75 minutes too long for the target Roblox audience? | May need to shorten days or add mid-campaign saves | Needs playtesting |
