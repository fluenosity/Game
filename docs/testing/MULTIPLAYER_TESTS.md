# Multiplayer & Concurrency Test Suite — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **QA Lead:** Multiplayer Network Test Lead  
> **Related Documents:** [TEST_STRATEGY.md](file:///i:/RobloxDev/docs/testing/TEST_STRATEGY.md), [COOPERATION_AND_PARTIES.md](file:///i:/RobloxDev/docs/systems/COOPERATION_AND_PARTIES.md)

---

## 1. Test Suite Overview

Multiplayer survival horror tests must verify that race conditions, concurrent network interactions, and sudden disconnects never desynchronize game state or corrupt party progress.

---

## 2. Test Case Registry

### TC-MP-01: 5-Player Lobby Party Assembly
- **Preconditions:** Server running in lobby mode with 5 tents.
- **Action:** 5 distinct player accounts enter Tent #5 simultaneously.
- **Expected Result:**
  - Tent occupancy counter increments from 1/5 to 5/5.
  - 5-second launch countdown aborts into immediate match launch.
  - All 5 players spawn synchronously in the ruined city prologue.
- **Status:** PASS

### TC-MP-02: Concurrent Resource Contention
- **Preconditions:** Single tree node exists with 2 Wood remaining.
- **Action:** Player A and Player B start chopping the tree at the exact same frame.
- **Expected Result:**
  - Player A finishes channel first by 10ms; receives 2 Wood.
  - Tree node is destroyed.
  - Player B's channel cancels with notification: "Resource Depleted". Zero duplicated wood granted.
- **Status:** PASS

### TC-MP-03: Simultaneous Campfire Stoking (Mutex Test)
- **Preconditions:** Campfire is at 90% fuel (capacity: 100%).
- **Action:** Player A and Player B both click "Add Fuel" (+20% fuel each) at the same millisecond.
- **Expected Result:**
  - Server processes Player A first: Fuel reaches 100% (clamped to max).
  - Server processes Player B: Fuel remains at 100%; Player B's wood is refunded or rejected without loss.
  - Total fuel never exceeds 100.0%.
- **Status:** PASS

### TC-MP-04: Co-op Downed Triage & Revival
- **Preconditions:** 3 players present; Player A is downed by The Hollow outside the safe zone.
- **Action:** Player B ignites a flare to push The Hollow back; Player C holds Revive on Player A for 4.0 seconds.
- **Expected Result:**
  - The Hollow is stunned by the flare and retreats 25 studs.
  - Player C completes revive channel.
  - Player A stands up with 40% HP restored.
- **Status:** PASS

### TC-MP-05: Critical Item Disconnect Failover
- **Preconditions:** Player A holds the Signal Tower Battery (essential quest item); Day 5 active.
- **Action:** Player A disconnects abruptly (Alt-F4 / process kill).
- **Expected Result:**
  - Server detects disconnect event within 1.0 second.
  - Battery is removed from Player A's session record and transferred into the Shelter Storage Trunk.
  - Notification banner appears for surviving players: "Player A disconnected. Carried items placed in shelter chest."
  - Surviving players can retrieve battery and complete escape.
- **Status:** PASS

### TC-MP-06: Player Mid-Match Reconnection
- **Preconditions:** Player A disconnects on Day 3; 120-second reservation window active.
- **Action:** Player A reconnects within 45 seconds from the Roblox menu.
- **Expected Result:**
  - Server recognizes reservation and admits Player A.
  - Player A spawns at the shelter sofa with matching current day state and lighting.
- **Status:** PASS
