# Day/Night Cycle — Project: Undecided

> **Status:** `EXISTING_CANON` (concept) + `PROPOSED` (timing, mechanics)
> **Last updated:** 2026-10-11

---

## Overview

The day/night cycle is the primary pacing mechanism. It creates urgency during the day (limited gathering time) and fear at night (monster is active). A single server-authoritative clock drives all time-dependent systems.

---

## Time States

```
DAWN → MORNING → AFTERNOON → DUSK → NIGHT → DAWN
```

| State | Sky | Lighting | Monster | Player Activity |
|-------|-----|----------|---------|----------------|
| DAWN | Brightening, sunrise colors | Increasing | Retreating | Wake up, assess |
| MORNING | Bright, clear | Full daylight | Dormant | Gather, explore |
| AFTERNOON | Warm, slightly lower sun | Warm daylight | Dormant | Prepare, upgrade |
| DUSK | Darkening, orange/red | Decreasing rapidly | Waking | Return to shelter |
| NIGHT | Black sky, stars/moon | Minimal (fire only) | Active (all states) | Survive, manage fire |

---

## Timing Per Day

| Day | Daytime (Dawn→Dusk) | Night (Dusk→Dawn) | Total |
|-----|--------------------|--------------------|-------|
| Day 1 | 300s (5 min) | 180s (3 min) | 480s (8 min) |
| Day 2 | 360s (6 min) | 240s (4 min) | 600s (10 min) |
| Day 3 | 420s (7 min) | 300s (5 min) | 720s (12 min) |
| Day 4 | 360s (6 min) | 360s (6 min) | 720s (12 min) |
| Day 5 | 420s (7 min) | 480s (8 min) | 900s (15 min) |

All values `INITIAL_BALANCE_PROPOSAL`.

---

## Warnings

| Warning | Timing | UI | Audio |
|---------|--------|-----|-------|
| Afternoon hint | 120s before night | Subtle sky color shift | None |
| Nightfall warning | 60s before night | "Night is approaching" text | Low tension chord |
| Urgent warning | 30s before night | Flashing text, darkening sky | Intensifying tone |
| Night started | 0s | No text — darkness is the signal | Monster sounds begin |

---

## Technical

- Single `GameClock` module on the server tracks `elapsedTime` and current `phase`.
- Server fires events: `DawnStarted`, `MorningStarted`, `AfternoonStarted`, `DuskWarning`, `NightStarted`.
- All other systems (monster AI, fire consumption, lighting) subscribe to these events.
- Client receives the current phase and time-to-next-phase for UI and sky rendering.
- Sky is driven by `Lighting.ClockTime` or `Lighting.TimeOfDay` mapped from the game clock.
- The clock NEVER pauses unless all players are in a menu/cutscene (server decision).
