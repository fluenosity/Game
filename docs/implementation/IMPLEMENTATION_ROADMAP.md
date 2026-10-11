# Implementation Roadmap — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## Phases

### Phase 0 — Foundation Prototype

**Goal:** Prove the core loop works — one complete survival night.

**Scope:**
- [ ] Minimal forest map (flat terrain, placeholder trees)
- [ ] Player FPP movement
- [ ] 3 choppable trees (hold-to-chop interaction)
- [ ] Basic campfire (light/unlit, no fuel system)
- [ ] Day/night state machine (basic clock)
- [ ] One monster (patrol + flee from fire)
- [ ] Protection radius (circle check)
- [ ] One complete night cycle

**Exit criteria:** A player can chop trees, light a campfire, and survive one night with a monster that avoids the fire.

**Estimated effort:** S–M (1–2 weeks for a small team)

---

### Phase 1 — Vertical Slice

**Goal:** A polished, playable introduction (Day 0 + Day 1).

**Scope:**
- [ ] City cutscene (simplified)
- [ ] Forest environment (quality pass)
- [ ] Shelter with sofa, table, campfire spot
- [ ] Full Day 1 gameplay flow
- [ ] Fuel consumption system
- [ ] Monster AI (patrol, approach, test, retreat)
- [ ] Core UI (HUD, objectives, inventory strip, fuel gauge)
- [ ] Audio (ambient, fire, monster sounds)
- [ ] Working multiplayer (2-player minimum)
- [ ] Mobile controls (tested on phone)
- [ ] Basic matchmaking (1 and 2 player tents)
- [ ] Tested fail and recovery conditions

**Exit criteria:** The game is FUN, not just functional. A playtester says "I want to play more."

**Estimated effort:** M–L (3–5 weeks)

---

### Phase 2 — Campaign Foundation

**Goal:** Full Day 1–5 experience with all core systems.

**Scope:**
- [ ] Days 2–5 content
- [ ] Scrap resources + gathering
- [ ] Trading system (wandering trader)
- [ ] Crafting system (workbench + recipes)
- [ ] Shelter upgrades (all tiers)
- [ ] Monster escalation (per-day behavior)
- [ ] Signal tower objective (Day 4–5)
- [ ] Multiple endings
- [ ] Full monster identity (The Hollow)
- [ ] Lore items (5+ scattered notes)
- [ ] Environmental landmarks
- [ ] All 5 tent matchmaking
- [ ] Save system (if approved)
- [ ] Co-op features (revival, shared objectives)

**Exit criteria:** A full 60–75 minute campaign from lobby to ending.

**Estimated effort:** L–XL (6–10 weeks)

---

### Phase 3 — Quality & Polish

**Goal:** Ship-quality experience.

**Scope:**
- [ ] Balance tuning (from playtesting data)
- [ ] Mobile optimization (30 FPS target)
- [ ] Audio polish (spatial audio, music)
- [ ] Visual polish (lighting, particles, fog)
- [ ] Accessibility features
- [ ] Achievement badges
- [ ] Cosmetic unlocks (earned through play)
- [ ] Leaderboards
- [ ] Analytics / telemetry
- [ ] Bug fixing
- [ ] Anti-exploit measures
- [ ] QA test pass

**Exit criteria:** Ready for public release. No critical bugs. Mobile and PC both playable.

**Estimated effort:** M–L (3–5 weeks)

---

### Phase 4 — Post-Launch

**Goal:** Sustain and grow the player base.

**Scope:**
- [ ] Content updates every 2–4 weeks
- [ ] New monster behaviors
- [ ] New exploration areas
- [ ] Seasonal events
- [ ] Community feedback integration
- [ ] Battle pass / cosmetic progression (if approved)
- [ ] Difficulty modifiers / challenge runs
- [ ] Endless mode (post-Day 5)

---

## Definition of Done

A feature is "done" when:

1. ✅ It works correctly on PC (keyboard + mouse)
2. ✅ It works correctly on mobile (touch controls)
3. ✅ It works in solo play
4. ✅ It works in 5-player co-op
5. ✅ Server validates all critical actions
6. ✅ No known exploits for the feature
7. ✅ UI is readable on a 5.5" phone screen
8. ✅ Performance is within budget (30+ FPS mobile)
9. ✅ Audio feedback exists for the action
10. ✅ Acceptance criteria from the design doc are met
