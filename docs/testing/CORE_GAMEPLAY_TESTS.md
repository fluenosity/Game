# Core Gameplay Test Suite — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **QA Lead:** Gameplay Verification Specialist  
> **Related Documents:** [TEST_STRATEGY.md](file:///i:/RobloxDev/docs/testing/TEST_STRATEGY.md), [04_CORE_GAMEPLAY_LOOP.md](file:///i:/RobloxDev/docs/04_CORE_GAMEPLAY_LOOP.md)

---

## 1. Test Suite Overview

This test suite covers the fundamental moment-to-moment survival mechanics of *Project: Undecided*. Every test is deterministic, repeatable, and must pass before gameplay builds are promoted.

---

## 2. Test Case Registry

### TC-CG-01: Shelter Discovery & Onboarding Guidance
- **Preconditions:** Fresh session started, Day 1 begins.
- **Action:** Player navigates down dirt path following smoke column.
- **Expected Result:**
  - Stepping past shelter fence gate marks objective "Reach Shelter" as Complete.
  - HUD displays next objective: "Chop 2 Trees [0/2]".
  - Compass marker points to nearest choppable tree.
- **Status:** PASS

### TC-CG-02: Resource Gathering (Wood Chopping)
- **Preconditions:** Player has stone hatchet equipped in slot 1; stands within 8 studs of valid tree node.
- **Action:** Hold interact button (`E` / Touch / Gamepad `X`) for 4.0 seconds.
- **Expected Result:**
  - Circular channel progress bar completes smoothly.
  - Tree plays cracking sound and fells.
  - Player inventory increments by +2 Wood.
  - Server verifies distance <= 8.5 studs and hatchet possession.
- **Status:** PASS

### TC-CG-03: Campfire Ignition
- **Preconditions:** Campfire is unlit; player has >= 2 Wood in inventory; stands within 6 studs of pit.
- **Action:** Hold interact on fire pit for 2.5 seconds.
- **Expected Result:**
  - 2 Wood deducted from inventory.
  - Flame ignites, point light expands to 18 studs radius.
  - `CampfireStateUpdated` remote fires; HUD fuel meter appears at 50%.
- **Status:** PASS

### TC-CG-04: Fuel Consumption & Extinction Curve
- **Preconditions:** Night arrives (20:00); Campfire is lit with 50% fuel.
- **Action:** No players add wood for 90 seconds.
- **Expected Result:**
  - Fuel decreases steadily at 0.20 fuel/sec.
  - Light radius shrinks proportionally from 18 studs down to 0.
  - At 0% fuel, flame extinguishes, audio cuts, and monster enters compound unimpeded.
- **Status:** PASS

### TC-CG-05: Monster Light Repulsion
- **Preconditions:** Campfire active above 30% fuel; Night 1 active; player stands within light circle.
- **Action:** The Hollow spawns and approaches player.
- **Expected Result:**
  - The Hollow stops at light perimeter boundary (approx. 18 studs from fire).
  - Monster plays growling/probing animation, pacing along the perimeter.
  - Monster deals 0 damage to player while player remains within illumination.
- **Status:** PASS

### TC-CG-06: Monster Strike in Darkness
- **Preconditions:** Nighttime; player steps beyond campfire safe zone (> 22 studs away).
- **Action:** The Hollow spots player and enters `CHASE`.
- **Expected Result:**
  - Monster charges at sprint speed (22 studs/s).
  - Claw attack lands when distance <= 7 studs, dealing 50 damage and triggering flinch screen shake.
- **Status:** PASS

### TC-CG-07: Dawn Survival & Sleep Advance
- **Preconditions:** Players survive until in-game clock reaches 06:00 (Dawn).
- **Action:** The Hollow shrieks and retreats; player interacts with the old sofa.
- **Expected Result:**
  - Screen fades to black with text: "Night 1 Survived".
  - Audio plays rooster/morning ambient birds.
  - In-game clock advances to Day 2 (08:00); HP regenerates to full.
- **Status:** PASS

### TC-CG-08: Signal Tower Escape Extraction (Day 5)
- **Preconditions:** Day 5 dawn; all 3 quest parts installed at tower.
- **Action:** Living players enter the evacuation transport zone.
- **Expected Result:**
  - Boarding timer reaches 0.
  - Victory cutscene triggers for all party members.
  - Campaign clear badge and Embers awarded in DataStore.
- **Status:** PASS
