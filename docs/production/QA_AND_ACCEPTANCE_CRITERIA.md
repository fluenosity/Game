# QA & Acceptance Criteria Framework — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** Quality Assurance Lead  
> **Related Documents:** [TEST_STRATEGY.md](file:///i:/RobloxDev/docs/testing/TEST_STRATEGY.md), [DEFINITION_OF_DONE.md](file:///i:/RobloxDev/docs/implementation/DEFINITION_OF_DONE.md)

---

## 1. QA Testing Methodology

Quality Assurance ensures that *Project: Undecided* meets strict stability, balance, and horror tension standards prior to every internal milestone and public release.

### Testing Pillars
1. **Automated Smoke Tests:** Luau unit tests for balance configs, data migrations, and rate-limit modules.
2. **Multiplayer Emulation:** Testing 1-player, 2-player, and 5-player sessions in Roblox Studio local server emulation.
3. **Hardware Matrix Testing:** Real-device validation across low-end mobile (Android/iOS), PC, and gamepads.
4. **Chaos Testing:** Abrupt network drops, rapid clicking, spamming remotes, and mid-animation disconnections.

---

## 2. Bug Severity Classification Matrix

| Severity | Definition | SLA / Gate | Example |
|----------|------------|------------|---------|
| **P0 - Blocker** | Game crashes, data loss, progression softlock, complete inability to survive night | Immediate fix; blocks all builds | Campfire cannot be lit; server crashes on day transition |
| **P1 - Critical** | Severe gameplay imbalance, exploit allowing infinite resources, broken monster AI | Fix before next milestone release | Monster clips through active fire; dupe bug in inventory |
| **P2 - Major** | Visual or audio glitches, broken animations, minor UI scaling misalignment | Fix before vertical slice / beta | Footstep sounds don't play on mud; text clips on iPhone 8 |
| **P3 - Minor** | Cosmetic defects, minor typos, subtle polish opportunities | Scheduled in polish sprint | Small crack in sofa texture; typo in lore note #3 |

---

## 3. System Acceptance Gates

Every game system must pass its formal acceptance gate before exiting development:

- **Campfire Gate:** Fuel drains accurately across all 5 days; extinction triggers monster breach; tier upgrades visually expand protection radius.
- **Monster AI Gate:** The Hollow reliably stalks, probes, and retreats without ever pathfinding inside active light or freezing permanently.
- **Save Profile Gate:** Profiles survive unexpected server crashes via `BindToClose` with zero lost Embers or corrupt inventories.
- **Mobile Gate:** 30 FPS minimum achieved on low-end test device with full touch control responsiveness.

---

## 4. Acceptance Criteria

- [ ] **AC-QA-01:** Zero P0 or P1 bugs exist in release-candidate staging branch.
- [ ] **AC-QA-02:** All automated Luau unit test suites pass with 100% success rate.
- [ ] **AC-QA-03:** 5-player multiplayer smoke test successfully completes Day 1 through Day 5 extraction without disconnect softlocks.
