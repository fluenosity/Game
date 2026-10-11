# Phase 0 Implementation Plan: Foundation & Core Prototype — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Lead:** Lead Gameplay Programmer & Technical Director  
> **Related Documents:** [IMPLEMENTATION_ROADMAP.md](file:///i:/RobloxDev/docs/implementation/IMPLEMENTATION_ROADMAP.md), [DEFINITION_OF_DONE.md](file:///i:/RobloxDev/docs/implementation/DEFINITION_OF_DONE.md)

---

## 1. Phase 0 Objective: "The Survival Loop Proving Ground"

The singular objective of Phase 0 is to validate the moment-to-moment survival gameplay loop in a minimal, graybox test environment before writing complex campaign content or building detailed 3D art:

```text
[Gather Wood] ──► [Stoke Campfire] ──► [Survive Night] ──► [Monster Repelled] ──► [Reach Dawn]
```

If this basic 5-minute loop is not tense, intuitive, and fun in graybox, no amount of graphics or cutscenes will save the game.

---

## 2. Scope & Inclusions

### Included in Phase 0
1. **Graybox Arena:** Flat 256×256 stud terrain with a fenced square shelter, a stone fire pit, and 12 graybox tree cylinders.
2. **First-Person Controls:** Basic WASD/Touch movement with locked first-person camera.
3. **Resource Interaction:** Proximity prompt on tree cylinders (4.0s hold channel) that yields +2 Wood to a simple 3-slot inventory.
4. **Authoritative Campfire:** Fire pit that consumes 2 Wood to ignite, drains fuel at 0.20/s, and projects an 18-stud light radius.
5. **Basic Monster Agent:** Simple humanoid character model with basic pathfinding that pursues players in darkness and stops/prowls at the light perimeter.
6. **Day/Night Cycle:** 90s daytime, 15s dusk, 60s night, 15s dawn clock cycle.
7. **Multiplayer Smoke Test:** 2 players surviving together in the same session.

### Explicitly Excluded from Phase 0
- Cutscenes and prologue sequence (Day 0).
- Advanced crafting, base upgrades, and wandering trader.
- Custom 3D character rigs, high-res textures, or complex audio mixes.
- Global persistence, DataStores, or cosmetic monetization.

---

## 3. Technical Deliverables & Architecture

- `src/server/Services/FireService.lua`
- `src/server/Services/GatheringService.lua`
- `src/server/Services/MonsterService.lua`
- `src/server/Services/CampaignService.lua` (barebones Day/Night timer)
- `src/client/Controllers/InputController.lua`
- `src/client/Controllers/HUDController.lua` (basic fuel & HP bars)

---

## 4. Phase Exit Criteria (Gate to Phase 1)

- [ ] **EX-00-1:** A solo player can spawn, chop 2 trees, light the campfire before nightfall, and survive Night 1.
- [ ] **EX-00-2:** The monster approaches the shelter at night, attempts to reach the player, and is visibly held at bay by the fire light.
- [ ] **EX-00-3:** Letting the fire go out results in the monster entering the shelter and downing the player.
- [ ] **EX-00-4:** Surviving until 06:00 triggers the dawn state and clears the test.
- [ ] **EX-00-5:** All interactions validated authoritatively by the server with zero client-side cheating possible.
