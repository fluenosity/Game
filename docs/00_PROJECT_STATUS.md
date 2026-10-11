# Project Status — Project: Undecided

> **Last updated:** 2026-10-11
> **Phase:** Pre-production / Documentation
> **Implementation status:** No code exists yet

---

## Current State

### What Exists

| Item | Status | Location |
|------|--------|----------|
| Game concept document | ✅ Complete | `Game.md` |
| Task specification | ✅ Complete | `task.md` |
| Documentation repository | 🔄 In progress | `docs/` |
| Roblox Studio project | ❌ Not started | — |
| Game code (Luau) | ❌ Not started | — |
| Assets (models, textures) | ❌ Not started | — |
| Audio assets | ❌ Not started | — |
| Playtesting | ❌ Not started | — |

### What's Been Decided (EXISTING_CANON)

These are explicitly stated in the original game design document:

1. The game is a survival horror experience on Roblox.
2. 1–5 players per session (solo and co-op).
3. Lobby uses 5 tents for session-size selection.
4. Friends entering the same tent are placed together.
5. Sessions start when full or when a timer expires (instant for solo).
6. Opening cutscene shows a ruined city and a monster that fears fire.
7. Players escape to a forest and find a fenced shelter.
8. Shelter contains: old sofa, table, visible campfire spot.
9. Day 1: find shelter → chop 2 trees → return before nightfall → light campfire → survive.
10. Day 2: gather more wood → upgrade campfire → larger safe zone.
11. Day 3+: scavenge metal/plastic/rope → trade with wandering trader → upgrade base.
12. First-person perspective (FPP) gameplay.
13. Day/night cycle drives the survival loop.

### What's Proposed (Not Yet Approved)

These are recommendations from analysis, not confirmed design:

- 5-day campaign with a defined ending (signal tower / escape)
- Monster identity (name, backstory, adaptive behavior)
- Sound-based detection system
- Fire depletion mechanic (active feeding required)
- Connected light network
- Asymmetric co-op roles
- Permadeath / roguelike meta-progression
- Lore clues scattered in the forest
- Multiple endings
- Save system
- Battle pass / cosmetic progression

### Known Gaps

| Gap | Priority | Notes |
|-----|----------|-------|
| No monster design (name, appearance, behavior) | 🔴 Critical | Core to the game's identity |
| No defined end goal | 🔴 Critical | Players need a finish line |
| No fire mechanics specification | 🔴 Critical | Central mechanic has no rules |
| No mobile input design | 🟡 High | 60% of Roblox players are mobile |
| No retention systems | 🟡 High | Players need reasons to return |
| No lore or story details | 🟡 High | Key differentiator |
| No sound design direction | 🟡 High | Critical for horror atmosphere |
| No crafting recipe definitions | 🟠 Medium | Needed for Day 3+ |
| No trading economy balance | 🟠 Medium | Trader needs defined prices |
| No performance budget | 🟠 Medium | Must run on mobile |

### Contradictions Found

| Issue | Details | Resolution |
|-------|---------|------------|
| Player count: 4 vs 5 | Original rough notes say "max 4 players" but structured doc says 5 tents (1–5 players) | **Resolved:** Use 5 as per the structured lobby design. The rough notes were an early draft. |
| Campaign length: undefined vs 30 nights vs open-ended | Different sections suggest different approaches | **Unresolved:** Needs project owner decision. Recommended: 5-night campaign (PROPOSED). |

---

## Next Steps

1. Complete core documentation repository.
2. Get project owner approval on proposed features (especially campaign length, monster design, end goal).
3. Establish the idea research bank.
4. Begin Phase 0 prototype after documentation review.
