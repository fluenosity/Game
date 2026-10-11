# Definition of Done (DoD) — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Authority:** Technical Lead, Game Director & QA Lead  
> **Related Documents:** [QA_AND_ACCEPTANCE_CRITERIA.md](file:///i:/RobloxDev/docs/production/QA_AND_ACCEPTANCE_CRITERIA.md), [ROBLOX_ARCHITECTURE.md](file:///i:/RobloxDev/docs/technical/ROBLOX_ARCHITECTURE.md)

---

## 1. Purpose & Standards

A task, script, or gameplay system is NOT considered "Done" simply because code has been written or a feature seems to work in Studio. To guarantee studio-wide maintainability and future AI agent compatibility, every deliverable must satisfy this non-negotiable **Definition of Done (DoD)** checklist.

---

## 2. The Universal DoD Checklist

### 2.1 Design & Balance Alignment
- [ ] Conforms strictly to the 4 Design Pillars (Show Don't Tell, Fire is Life, Earned Survival, Ethical Design).
- [ ] Zero undocumented magic numbers: all tuning values reside in `ReplicatedStorage.Shared.Config` with marked statuses (`INITIAL_BALANCE_PROPOSAL`).
- [ ] Traceable to a documented system specification or campaign day requirement.

### 2.2 Server Authority & Exploit Prevention
- [ ] 100% server authority over game state (HP, inventory, fuel, monster damage, timers).
- [ ] All remote events validate player distance (<= 8.5 studs), alive state, and inventory prerequisites.
- [ ] Rate limiting implemented via token bucket to prevent packet flooding.
- [ ] Concurrent actions protected by atomic transaction mutexes (zero item duping).

### 2.3 Cross-Platform & Mobile Optimization
- [ ] Operates seamlessly on Touchscreen Mobile, Mouse/Keyboard, and Gamepad.
- [ ] Mobile touch targets meet minimum 48×48 dp standard; UI respects notch safe areas.
- [ ] Runs within hardware budgets: >= 30 FPS and < 900 MB RAM on budget test hardware.

### 2.4 Code Quality & Luau Standards
- [ ] Written in strict Luau mode (`--!strict`) with explicit type signatures for all public functions.
- [ ] Passes Selene linter rules and StyLua formatting standards.
- [ ] Follows Service-Controller architecture; zero circular module dependencies.
- [ ] All asynchronous promises and connections include proper disconnection/cleanup handlers.

### 2.5 Verification & QA Acceptance
- [ ] Explicit test cases defined in `docs/testing/` with verifiable pass criteria.
- [ ] Tested in multiplayer emulation (solo AND 5-player configurations).
- [ ] Disconnect and reconnect edge cases tested with zero state corruption.
- [ ] Zero P0 (Blocker) or P1 (Critical) bugs introduced.
