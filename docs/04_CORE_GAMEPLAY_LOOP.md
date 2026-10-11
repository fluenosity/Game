# Core Gameplay Loop — Project: Undecided

> **Status:** `EXISTING_CANON` (basic loop) + `PROPOSED` (detailed mechanics)
> **Last updated:** 2026-10-11

---

## The Fundamental Loop

Every day in the campaign follows this cycle:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   DAWN ──→ EXPLORE & GATHER ──→ PREPARE & BUILD ──→        │
│                                                             │
│   ──→ NIGHTFALL WARNING ──→ RETURN TO SHELTER ──→           │
│                                                             │
│   ──→ LIGHT FIRE ──→ SURVIVE THE NIGHT ──→ DAWN            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Phase 1: DAWN (Morning)
- The player wakes up at the shelter.
- The day counter advances (displayed on screen).
- The environment is bright and safe.
- The monster has retreated.
- **Player emotion:** Relief, safety, planning.

### Phase 2: EXPLORE & GATHER (Daytime)
- The player leaves the shelter to collect resources.
- **Day 1:** Chop trees for wood.
- **Day 2+:** Chop trees AND scavenge for scrap materials.
- **Day 3+:** Discover new areas, landmarks, lore clues.
- The further you go, the more you find — but the longer the return trip.
- **Player emotion:** Curiosity, greed, risk assessment.

### Phase 3: PREPARE & BUILD (Daytime → Afternoon)
- Return to shelter with gathered resources.
- Upgrade campfire, build shelter improvements, craft items.
- Trade with the wandering trader (when available).
- Decide: spend resources now or save for later?
- **Player emotion:** Competence, strategic thinking.

### Phase 4: NIGHTFALL WARNING (Late Afternoon)
- The sky begins to darken.
- Audio and visual cues warn the player.
- On-screen objective: "Return to shelter."
- Urgency increases — the monster becomes active soon.
- **Player emotion:** Urgency, anxiety, time pressure.

### Phase 5: RETURN TO SHELTER (Dusk)
- Race back to the shelter before full darkness.
- Use collected fuel to light/feed the campfire.
- Make final preparations.
- **Player emotion:** Tension, relief (if made it), panic (if late).

### Phase 6: LIGHT FIRE & SURVIVE THE NIGHT (Night)
- The campfire burns — creating a protection radius.
- `PROPOSED` The fire slowly depletes fuel. Players may need to add wood mid-night.
- The monster circles outside the safe zone, testing defenses.
- `PROPOSED` Sound cues indicate monster proximity and behavior.
- Players must stay within the protection radius.
- **Player emotion:** Fear, vulnerability, dread, alertness.

### Phase 7: DAWN (Next Morning)
- The night ends. The player survived.
- The monster retreats.
- The loop restarts with new possibilities.
- **Player emotion:** Accomplishment, relief, anticipation.

---

## Loop Expansion Across Days

The core loop stays the same, but each day adds complexity:

| Day | New Element Added | Core Loop Change |
|-----|------------------|-----------------|
| Day 0 | Cutscene, escape | No gameplay loop — narrative setup |
| Day 1 | Shelter, wood, campfire | Full loop introduced (simplest form) |
| Day 2 | Fire upgrades, fuel management | Loop adds PREPARATION depth |
| Day 3 | Scavenging, trading, crafting | Loop adds EXPLORATION breadth |
| Day 4 | Escalated threats, new mechanics | Loop adds SURVIVAL complexity |
| Day 5 | Escape objective | Loop adds a GOAL / endpoint |

### Key Principle: The Loop Never Changes, The Stakes Do

Players always do the same thing: gather, prepare, survive. But WHAT they gather, HOW they prepare, and WHAT they survive against escalates.

---

## Resource Flow

```
FOREST                    SHELTER                   NIGHT
┌──────────┐             ┌──────────────┐          ┌──────────────┐
│ Trees    ├──wood──────→│ Campfire     │──fire───→│ Protection   │
│          │             │              │          │ radius       │
│ Scrap    ├──materials─→│ Crafting     │──items──→│ Better       │
│ piles    │             │ station      │          │ defense      │
│          │             │              │          │              │
│ Trader   │←──scrap────→│ Upgrades     │──walls──→│ Safer        │
│ (visits) │──goods─────→│              │          │ shelter      │
└──────────┘             └──────────────┘          └──────────────┘
```

---

## Risk/Reward Tension

The core tension is between **safety** and **greed**:

| Behavior | Reward | Risk |
|----------|--------|------|
| Stay near shelter | Safe, predictable | Fewer resources, slower progression |
| Explore deeper into forest | More resources, rare materials, lore | Farther from shelter, may not return in time |
| Hoard wood for fire | Guaranteed survival tonight | No upgrades, no progress |
| Spend wood on upgrades | Better long-term survival | Less fuel tonight, higher danger |
| Trade all scrap | Better items now | Nothing to trade tomorrow |
| Save scrap | Options for later | Weaker tonight |

**There is no objectively correct strategy.** Different player styles (cautious vs. aggressive, solo vs. team) should each be viable but create different experiences.

---

## Failure States

| Failure | Cause | Recovery |
|---------|-------|----------|
| Fire goes out | Ran out of fuel | `PROPOSED` Emergency mechanic (e.g., last-resort matches, emergency wood) or death |
| Caught by monster | Outside protection radius at night | Death → revival by teammate (co-op) or restart |
| Didn't return in time | Explored too far, misjudged time | Sprint mechanic, but the monster may already be active |
| All players dead | TPK (Total Party Kill) | Session failure → return to lobby, can retry |
| Session timeout | Server limit reached | Save progress (if system exists) → continue later |

---

## Multiplayer Loop Differences

| Aspect | Solo | Co-op (2–5 players) |
|--------|------|---------------------|
| Gathering | All tasks on one player | Can split: one gathers, one builds |
| Fire management | Player alone manages fuel | Can assign a "fire-keeper" |
| Exploration | Must always return alone | One player can scout while others defend |
| Monster encounters | All attention on one player | Monster must choose targets; creates cooperative panic |
| Death | Immediate run failure (or checkpoint) | Teammates can revive or continue without you |
| Decision-making | All choices are yours | Group must agree or negotiate |

---

## Loop Validation Criteria

A successful implementation of the core loop must pass these tests:

- [ ] A new player can complete Day 1's loop on their first attempt without external help
- [ ] The loop feels different on Day 3 compared to Day 1 (not just "more of the same")
- [ ] Players experience at least one moment of genuine tension each night
- [ ] There is never a night where the player feels "completely safe with nothing to worry about"
- [ ] Solo and co-op both feel complete (neither feels like a lesser version)
- [ ] Mobile players can complete the full loop without input frustration
- [ ] The time between "interesting decisions" is never longer than 30 seconds
