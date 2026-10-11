# Art Direction — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## Visual Style

**Semi-realistic Roblox horror** — not cartoony, not hyper-realistic. A dark, atmospheric world that feels grounded but works within Roblox's engine.

### Color Palette

| Context | Colors | Mood |
|---------|--------|------|
| Daytime forest | Deep greens, warm browns, dappled gold sunlight | Safe, natural, inviting |
| Dusk | Orange, amber, darkening purple | Urgency, transition, warning |
| Night (no fire) | Near-black, deep blue-grey | Terror, void, vulnerability |
| Campfire light | Warm orange-yellow, soft amber glow | Safety, comfort, warmth |
| The Hollow | Pure black with faint ember-orange cracks | Dread, anti-light, corruption |
| City ruins (cutscene) | Grey, charcoal, smoke-stained orange | Devastation, chaos, fear |
| Dawn | Soft gold, gentle pink, light blue | Relief, hope, earned safety |

### Lighting Principles

1. **Daytime:** Natural, warm. The forest should feel beautiful — players should WANT to explore.
2. **Night:** Almost entirely dark. Only the campfire provides light. The contrast between warm fire and cold darkness is the core visual.
3. **The Hollow:** Should be DARKER than the darkness — a void that moves.
4. **Fire:** The most important visual element. Must look and feel warm, alive, dynamic.

### Key Visual References

- The Forest (game) — forest atmosphere, base building aesthetic
- Don't Starve — fire as the only light source at night, darkness as danger
- Liminal spaces — the unease of abandoned, empty structures
- Studio Ghibli's darker works — atmospheric dread without gore

---

# Audio Design

> **Status:** `PROPOSED`

---

## Audio Philosophy

Sound is the PRIMARY horror tool. The player should HEAR the monster before they see it.

### Audio Layers

| Layer | Purpose | Examples |
|-------|---------|---------|
| Ambient (day) | Safety, nature | Birds, wind, rustling leaves, distant water |
| Ambient (night) | Tension, isolation | Silence, distant wind, occasional creak |
| Fire | Comfort, life | Crackling, popping, warm roar |
| Monster (distant) | Awareness, dread | Low humming, branch snaps, far footsteps |
| Monster (close) | Fear, urgency | Close breathing, scraping, hollow echo |
| Monster (attack) | Shock | Sharp screech (the ONLY loud monster sound) |
| UI/feedback | Clarity | Pickup sounds, warning tones, objective chimes |
| Music | Emotion | Minimal — used sparingly for key moments |

### Music Usage

- **Day 0 cutscene:** Brief, impactful score (20s).
- **Day 1 morning:** No music (let nature sounds speak).
- **Night 1:** No music (let silence and monster sounds create fear).
- **Night 5 final stand:** Building tension music.
- **Escape sequence:** Triumphant theme.
- **Death:** Silence. No dramatic music. Just... nothing.

### The Hollow's Sound Identity

| Behavior | Sound | Volume |
|----------|-------|--------|
| Distant patrol | Low resonant hum | Quiet (builds atmosphere) |
| Approaching | Hum intensifies + soft ember crackle | Medium |
| Testing light | Inhaling sound (breathing the light) | Close, intimate |
| Near player | Hollow cave echo effect on all sounds | Unsettling |
| Attack | Single sharp shriek | Loud (only loud sound) |
| Retreat | Extinguishing hiss (water on hot coals) | Fading |
| Dawn retreat | Wailing cry that fades to silence | Dramatic |

---

# Environment and Map Layout

> **Status:** `PROPOSED`

---

## World Layout

```
                    ┌────────────────────────┐
                    │    DEEP FOREST          │
                    │  (Day 4-5 exploration)  │
                    │                        │
                    │  [SIGNAL TOWER]        │
                    │  [MONSTER CLEARING]    │
                    │                        │
              ┌─────┤                        ├─────┐
              │     │  [RUINED SHACK]        │     │
              │     │  Landmark B            │     │
              │     └────────┬───────────────┘     │
              │              │                     │
              │     ┌────────▼───────────────┐     │
              │     │   MID FOREST           │     │
              │     │  (Day 3 exploration)   │     │
              │     │                        │     │
              │     │  [ABANDONED CAMPSITE]  │     │
              │     │  Landmark A            │     │
              │     │  Scrap nodes           │     │
              │     └────────┬───────────────┘     │
              │              │                     │
              │     ┌────────▼───────────────┐     │
              │     │   NEAR FOREST          │     │
              │     │  (Day 1-2 area)        │     │
              │     │                        │     │
              │     │  [CHOPPABLE TREES]     │     │
              │     │  (3-8 depending on day)│     │
              │     └────────┬───────────────┘     │
              │              │                     │
              │     ┌────────▼───────────────┐     │
              │     │      SHELTER           │     │
              │     │  [CAMPFIRE] [SOFA]     │     │
              │     │  [TABLE] [STORAGE]     │     │
              │     │  (chain-link fence)    │     │
              │     └────────┬───────────────┘     │
              │              │                     │
              │     ┌────────▼───────────────┐     │
              │     │   FOREST ENTRANCE      │     │
              │     │  (Player spawn Day 1)  │     │
              │     └────────┬───────────────┘     │
              │              │                     │
              └──────────────┼─────────────────────┘
                             │
                    ┌────────▼───────────────┐
                    │    CITY RUINS           │
                    │  (Day 0 cutscene only)  │
                    │  NOT explorable         │
                    └────────────────────────┘
```

### Travel Times (Walking)

| From | To | Time |
|------|----|------|
| Forest entrance | Shelter | ~30s |
| Shelter | Near forest (trees) | ~15–30s |
| Shelter | Abandoned campsite | ~60s |
| Shelter | Ruined shack | ~90s |
| Shelter | Signal tower | ~120s |
| Shelter | Monster clearing | ~150s |

---

# Risk Register

> **Status:** `PROPOSED`

---

| # | Risk | Probability | Impact | Mitigation |
|---|------|------------|--------|-----------|
| 1 | "99 Nights clone" perception | High | 🔴 Critical | Prioritize differentiators: The Hollow, fire depletion, 5-day campaign |
| 2 | Game is too long for Roblox audience (60–75 min) | Medium | 🟡 High | Add save system, shorten days if playtesting shows drop-off |
| 3 | Mobile performance issues | Medium | 🟡 High | Optimize early, test on mid-range phones, reduce particles |
| 4 | Monster pathfinding failures | Medium | 🟠 Medium | Stuck detection, teleport fallback, thorough testing |
| 5 | Exploit/cheating ruins co-op | Medium | 🟡 High | Server-authoritative everything, rate limiting, logging |
| 6 | Fire mechanic is frustrating, not fun | Low–Med | 🔴 Critical | Playtest extensively, tune fuel rates, add emergency items |
| 7 | Cutscene loading issues on mobile | Medium | 🟠 Medium | Streaming, fallback text, preloading |
| 8 | Save system DataStore failures | Low | 🟡 High | Retry logic, backups, graceful degradation |
| 9 | Content creation pace unsustainable | Medium | 🟠 Medium | Plan realistic update schedule, modular content |
| 10 | Players don't understand the game (bad onboarding) | Low–Med | 🔴 Critical | Extensive Day 1 playtesting, clear objectives |
