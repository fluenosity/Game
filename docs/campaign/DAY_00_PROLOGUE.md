# Day 0 — Prologue: The City Falls

> **Status:** `EXISTING_CANON` (core concept) + `PROPOSED` (detailed beats, timing, technical)
> **Last updated:** 2026-10-11
> **Design pillar:** Show, Don't Tell

---

## 1. Document Metadata

| Field | Value |
|-------|-------|
| Day | 0 (Prologue) |
| Type | Non-interactive cutscene + optional escape sequence |
| Duration | 10–15 seconds cutscene + ~30–60s escape (`PROPOSED`) |
| Status | `EXISTING_CANON` (concept), `PROPOSED` (implementation details) |
| Depends on | Session matchmaking complete, all players loaded |
| Leads to | Day 1 — First Survival |

---

## 2. Purpose & Intended Emotion

### Purpose

Establish the entire game's premise in under 20 seconds without a single word of dialogue:
1. The world is destroyed.
2. A terrifying monster exists.
3. Fire is the monster's weakness.
4. You must escape.

### Target Emotions

| Phase | Emotion |
|-------|---------|
| City reveal | Awe, unease |
| Monster appearance | Shock, fear |
| Monster retreating from fire | Realization ("fire = safety") |
| Escape sequence | Urgency, desperation |

---

## 3. Narrative Context

The player has no backstory. They wake up in a ruined city. They don't know why. They don't know what happened. All they see is destruction and a monster. The story begins in media res.

**What the player should understand after Day 0:**
- Something terrible happened to this city.
- There is a monster.
- The monster is afraid of fire.
- I need to get out of here.

**What the player should NOT know yet:**
- What the monster is.
- Why it fears fire.
- What destroyed the city.
- Where they're going.
- Whether they're alone.

---

## 4. Player Starting Conditions

| Parameter | Value |
|-----------|-------|
| Health | 100 (full) |
| Inventory | Empty |
| Position | Inside the ruined city (cinematic start point) |
| Camera | Cinematic (scripted, not player-controlled) |
| Controls | Disabled during cutscene; enabled during escape |

---

## 5. Prerequisites

- Session has started (all expected players are loaded or timeout expired).
- Game world has finished loading.
- All players are at the designated spawn point.

---

## 6. Primary Objective

**Survive the city and escape to the forest.**

This objective is implicit — shown through the cutscene, not through a text prompt.

---

## 7. Optional Objectives

None on Day 0. This is purely introduction.

---

## 8. Step-by-Step Gameplay Flow

### Beat 1: City Reveal (0s–4s)

- Camera slowly pans across a devastated city.
- Broken buildings, overturned cars, scattered debris, small fires burning.
- `EXISTING_CANON` "If possible, include people running around in fear."
- Distant sounds: crumbling, wind, faint alarms.
- The camera moves forward through the destruction.

**Player action:** None. Watching.
**Audio:** Low rumble, wind, distant crashes. No music.

### Beat 2: Monster Appearance (4s–8s)

- The camera rounds a corner or looks past a building.
- `EXISTING_CANON` "A huge monster suddenly appears from behind a building."
- The monster is partially obscured — silhouette and mass visible, full detail unclear.
- It pauses. Looks around the city. Seems to be searching.

**Player action:** None. Watching.
**Audio:** Deep, guttural sound. Vibration. Ground impact if the monster is large.

### Beat 3: Fire Reaction (8s–12s)

- `EXISTING_CANON` The monster "notices a massive fire burning on a nearby building."
- The monster turns toward the fire.
- `EXISTING_CANON` "As soon as the monster sees the fire, it becomes frightened and immediately runs away."
- The monster recoils — physically pulls back, turns, and flees behind buildings.
- The fire is prominently visible — unmistakably what caused the reaction.

**Player action:** None. Watching.
**Audio:** Monster screech/hiss on seeing fire. Retreating footsteps.

### Beat 4: Transition (12s–15s)

- Brief pause. The fire crackles. Silence.
- Camera begins to move — either following the player character or transitioning to gameplay view.
- `PROPOSED` Text appears briefly: no words, just the game logo or a visual transition.

### Beat 5: Escape Sequence (15s–75s) `PROPOSED`

Two options for implementation:

**Option A: Fully Scripted (Simpler)**
- The camera follows the player character running through the city and into the forest.
- No player input. Pure cinematic.
- ~15–30 seconds of running footage.
- Camera smoothly transitions to FPP as the character enters the forest.

**Option B: Interactive Escape (Better but Harder)**
- After the cutscene, the player gains control (FPP).
- They are in a linear corridor of ruined city streets leading to the forest.
- No combat, no complex navigation — just run forward.
- Scripted events happen around them (buildings collapse, fires flare).
- The monster may be glimpsed in the distance but never attacks.
- Player reaches the forest edge → Day 1 begins.

**Recommendation:** Start with Option A for prototype. Evaluate Option B for vertical slice.

---

## 9. Time-of-Day Timeline

| Time | Real Seconds | Event |
|------|-------------|-------|
| 0s | Cutscene start | City reveal |
| 4s | Monster appears | Behind building |
| 8s | Fire reaction | Monster sees fire |
| 12s | Monster flees | Runs away |
| 15s | Cutscene ends | Transition begins |
| 15–75s | Escape sequence | `PROPOSED` Player runs to forest |
| End | Day 1 begins | FPP gameplay starts |

All timestamps are `INITIAL_BALANCE_PROPOSAL`.

---

## 10. Locations & Level Design

### City (Cutscene Environment)

| Element | Requirement |
|---------|------------|
| Buildings | 3–5 damaged structures visible. Don't need interiors. |
| Vehicles | 2–3 crashed/overturned cars |
| Debris | Scattered rubble, broken glass, papers |
| Fires | 2–3 small fires + 1 large fire (on a building — the one the monster reacts to) |
| People | `EXISTING_CANON` Optional. If included, 3–5 NPCs running in fear. |
| Monster spawn point | Behind a large building, positioned so it's dramatically revealed |
| Lighting | Overcast, smoky, orange tones from fires |

**Performance note:** This is a cinematic set. It doesn't need to be a full city — just enough to fill the camera frame convincingly. Use fog/smoke to hide boundaries.

### Forest Edge (Transition)

| Element | Requirement |
|---------|------------|
| Tree line | Clear visual boundary between city and forest |
| Path | One obvious route from city to forest |
| Lighting change | City (orange/smoky) → Forest (green/natural) |

---

## 11. Resources & Numerical Values

None. Day 0 has no resource gathering.

---

## 12. Monster Behavior

| State | Behavior |
|-------|----------|
| Initial | Not visible. Behind building. |
| Appearance | Steps out from behind building. Looks around. |
| Fire reaction | Sees the large fire. Recoils. Flees. |
| After retreat | Not seen again during Day 0. |

**Note:** The monster is NOT a threat during Day 0. It is being introduced as a concept, not as immediate danger. The fear comes from its SIZE and PRESENCE, not from any attack.

---

## 13. UI Messages, Audio, Visual Feedback

### UI

- No HUD during cutscene.
- `PROPOSED` Skip button appears after 3 seconds (small, corner of screen).
- No objective text until Day 1 begins.

### Audio

| Moment | Sound |
|--------|-------|
| City reveal | Low ambient drone, wind, distant crashes |
| Monster appearance | Deep impact sound, ground shake |
| Monster seeing fire | High-pitched screech/hiss |
| Monster fleeing | Heavy retreating footsteps |
| Fire | Crackling, roaring |
| Transition to forest | Sounds fade, replaced by nature ambience |

### Visual

| Effect | Description |
|--------|-------------|
| Camera movement | Smooth, cinematic pans. No abrupt cuts. |
| Monster reveal | Dramatic framing — monster fills a portion of the screen |
| Fire glow | Bright, warm, contrasting with the dark destruction |
| Smoke/particles | Atmospheric, helps sell the destruction |
| Screen shake | Very subtle during monster appearance |

---

## 14. Multiplayer Behavior

| Scenario | Behavior |
|----------|----------|
| All players loaded | Cutscene plays simultaneously for all players |
| Camera ownership | Server controls cutscene camera for all clients |
| Player models | Not visible during cutscene (camera is cinematic, not attached to a character) |
| Chat | Disabled during cutscene |
| Movement | Disabled during cutscene |

---

## 15. Solo Player Behavior

Identical to multiplayer. The cutscene is the same regardless of player count.

---

## 16. Mobile & Controller Considerations

- Cutscene is passive — no input required.
- Skip button must be large enough for touch (minimum 44x44 pixels).
- Camera movements must not cause motion sickness on mobile.
- Reduced particle effects on low-end devices.

---

## 17. Accessibility

- `PROPOSED` Subtitles for audio descriptions: "[Distant rumbling]" "[Monster roars]" "[Fire crackling]"
- `PROPOSED` Audio description track option: narrates what's happening on screen.
- Skip button always available after 3 seconds.

---

## 18. Success & Failure Conditions

| Condition | Result |
|-----------|--------|
| Cutscene completes normally | → Transition to Day 1 |
| Player skips cutscene | → Immediate transition to Day 1 |
| Loading failure | → Retry loading. If persistent, return to lobby with error message. |

There is no failure state in Day 0. The player cannot die or lose.

---

## 19. Death, Disconnect, Recovery

| Scenario | Behavior |
|----------|----------|
| Player disconnects during cutscene | Session continues for remaining players. Disconnected player cannot rejoin cutscene (it's too short). |
| All players disconnect | Session is cleaned up. |
| Server crash | Session lost. Players return to lobby. No data to save (nothing has happened yet). |

---

## 20. Edge Cases & Exploits

| Edge Case | Handling |
|-----------|---------|
| Player spams skip button | Skip triggers once, subsequent presses ignored |
| Player tries to move during cutscene | Input is disabled during cinematic |
| Very slow loading (mobile) | Wait for all players to load before starting. Timeout after 30s → start without slow loader. |
| Player joins late (after cutscene) | They skip cutscene and spawn at the Day 1 start point |

---

## 21. Interactions with Other Systems

| System | Interaction |
|--------|------------|
| Session Matchmaking | Must complete before cutscene starts |
| Day/Night Cycle | Day 0 is not part of the cycle — it's a one-time event |
| Monster AI | Monster is scripted during cutscene, not using AI |
| Player State | Player is invulnerable and input-locked |
| Audio System | Cutscene has its own audio sequence |
| Camera System | Cutscene camera overrides player camera |

---

## 22. Required Assets

| Asset | Type | Priority |
|-------|------|----------|
| City environment (simplified) | 3D model/scene | High |
| Destroyed buildings (3–5) | 3D models | High |
| Crashed vehicles (2–3) | 3D models | Medium |
| Debris/rubble | Particles/models | Medium |
| Fire effect (large, building-scale) | Particle system | High |
| Fire effect (small, scattered) | Particle system | Medium |
| Monster model (silhouette-quality minimum) | 3D model + rig | High |
| Monster animations (appear, react, flee) | Animations | High |
| Running NPCs (optional) | 3D models + animations | Low |
| Smoke/atmospheric effects | Particles | Medium |
| Ambient audio (city destruction) | Audio | High |
| Monster sound effects | Audio | High |
| Fire audio | Audio | High |
| Transition audio (city → forest) | Audio | Medium |

---

## 23. Implementation Dependencies

| Dependency | Required For |
|-----------|-------------|
| Cinematic camera system | Scripted camera movements |
| Input lock system | Disabling player controls |
| Audio sequencer | Timed sound playback |
| Scene loading | City environment |
| Player teleport/spawn | Transition to Day 1 |
| Skip handler | Skip button functionality |

---

## 24. Technical Implementation Notes

- **Camera:** Use `TweenService` or a custom interpolation system for smooth camera movements. Pre-define camera keyframes as CFrame values.
- **Input lock:** Set `UserInputService` mouse/keyboard enabled to false during cutscene. Re-enable on transition.
- **Monster:** The cutscene monster can be a scripted animation sequence, not the full AI system. A simple `AnimationController` with pre-built clips.
- **Skip:** When any player presses skip, that player's camera transitions immediately. In co-op, individual skip (each player skips for themselves, not the group).
- **Performance:** The city scene should be streaming-enabled. Use `StreamingEnabled` with appropriate streaming radius. Preload critical assets.
- **Fallback:** If the cutscene fails to load, skip directly to Day 1 with a brief text: "You escaped the city. Something is hunting you."

---

## 25. Acceptance Criteria

- [ ] The cutscene plays from start to finish without errors on PC and mobile.
- [ ] The monster appears dramatically and is visually intimidating.
- [ ] The fire is clearly the cause of the monster's retreat.
- [ ] A first-time player understands that fire = safety after watching.
- [ ] The skip button works and transitions cleanly to Day 1.
- [ ] The cutscene does not exceed 20 seconds (excluding escape sequence).
- [ ] All players see the same cutscene simultaneously in multiplayer.
- [ ] Audio plays correctly and enhances the experience.
- [ ] FPS stays above 30 on target mobile devices during the cutscene.
- [ ] The transition to Day 1 is smooth (no loading screen, no jarring cut).

---

## 26. QA Test Cases

| # | Test | Expected Result |
|---|------|----------------|
| 1 | Start a solo session | Cutscene plays, transitions to Day 1 |
| 2 | Start a 3-player session | All 3 see the same cutscene simultaneously |
| 3 | Skip cutscene immediately | Player transitions to Day 1 without errors |
| 4 | One player skips, others don't | Skipper transitions; others continue watching |
| 5 | Player disconnects during cutscene | Session continues for remaining players |
| 6 | All players disconnect | Session cleans up properly |
| 7 | Run on low-end mobile device | Cutscene runs at ≥30 FPS |
| 8 | Ask a tester "what did you learn?" | They mention the monster and fire |

---

## 27. Analytics Events

| Event | Data | Purpose |
|-------|------|---------|
| `cutscene_started` | session_id, player_count | Track session starts |
| `cutscene_skipped` | session_id, player_id, skip_time | How quickly do players skip? |
| `cutscene_completed` | session_id, player_id | Track full views |
| `day0_to_day1_transition` | session_id, transition_time | Measure loading |

---

## 28. Unresolved Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | Scripted escape (Option A) or interactive escape (Option B)? | Affects development time and player engagement |
| 2 | Should the cutscene be skippable on first playthrough? | Pacing vs. player freedom |
| 3 | Should co-op skip require all players or individual? | Social dynamics |
| 4 | How detailed does the city need to be? | Art scope and performance |
| 5 | Should the monster model in the cutscene be the final game model? | Asset dependency |

---

## 29. Changes That Would Invalidate This Day

- Removing the city setting from the game concept.
- Making the monster NOT fear fire.
- Changing the game to start directly in the forest with no introduction.
- Removing the cutscene entirely.
- Changing the game from first-person to third-person (would affect transition).
