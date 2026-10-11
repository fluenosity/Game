# Test Strategy — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## Testing Philosophy

1. **Test the experience, not just the code.** A feature that works but isn't fun has failed.
2. **Test solo AND co-op.** Every feature must work with 1 player and 5 players.
3. **Test mobile AND PC.** If it doesn't work on a phone, it doesn't ship.
4. **Test exploits actively.** Assume players will try to cheat. Design for it.
5. **Test edge cases.** Disconnects, crashes, full inventories, empty fuel — plan for all of them.

---

## Core Gameplay Tests

| # | Test | Expected Result | Priority |
|---|------|----------------|----------|
| 1 | New player finds shelter on Day 1 | Arrives within 60s of starting | 🔴 |
| 2 | Player chops tree and receives wood | 2 wood per tree, 5s interaction | 🔴 |
| 3 | Player lights campfire with 2+ wood | Fire ignites, radius appears | 🔴 |
| 4 | Fire consumes fuel during night | Fuel gauge decreases over time | 🔴 |
| 5 | Fire goes out when fuel reaches 0 | Protection radius drops to 0, monster can enter | 🔴 |
| 6 | Player adds wood to fire during night | Fuel increases, fire strengthens | 🔴 |
| 7 | Monster avoids protection radius | Never enters radius (Nights 1–3, Tier 2+) | 🔴 |
| 8 | Monster attacks player outside radius | 50 damage per hit, 3s cooldown | 🔴 |
| 9 | Player survives night → can sleep at dawn | "Sleep" prompt on sofa, fade to next day | 🔴 |
| 10 | Day counter advances correctly | Day 1 → Day 2 → Day 3 → Day 4 → Day 5 | 🔴 |
| 11 | Player collects scrap on Day 3+ | Instant pickup, correct item added to inventory | 🟡 |
| 12 | Campfire upgrade works | Materials deducted, tier advances, radius increases | 🟡 |
| 13 | Trader appears and trades work | Correct items exchanged, stock depleted | 🟡 |
| 14 | Signal tower activation (Day 5) | All 3 components required, activation sequence works | 🟡 |
| 15 | Campaign ending triggers correctly | Correct ending based on scenario | 🟡 |

---

## Multiplayer Tests

| # | Test | Expected Result | Priority |
|---|------|----------------|----------|
| 1 | 2 players enter same tent | Same session, both teleported | 🔴 |
| 2 | Players in different tents | Different sessions, never mixed | 🔴 |
| 3 | Player disconnects mid-game | Session continues for others | 🔴 |
| 4 | All players disconnect | Session cleans up | 🔴 |
| 5 | Player rejoins after disconnect | Returns to current game state | 🟡 |
| 6 | Two players chop same tree | First claim wins, second rejected | 🟡 |
| 7 | Co-op revival | Downed player revived by teammate within 30s | 🟡 |
| 8 | All players must sleep to advance | Day doesn't advance until all alive players sleep | 🟡 |
| 9 | 5 players in session | All systems work at max capacity | 🟡 |
| 10 | Party leader leaves | Session continues, no special treatment | 🟠 |

---

## Exploit & Abuse Tests

| # | Test | Expected Result | Priority |
|---|------|----------------|----------|
| 1 | Spam ChopTreeRequest 100x | Only 1 chop processed, others rejected | 🔴 |
| 2 | Send fake "give item" remote | Rejected, logged, rate-limited | 🔴 |
| 3 | Modify client-side fuel value | Server ignores, uses authoritative value | 🔴 |
| 4 | Speed hack (modified WalkSpeed) | Server detects abnormal movement, rejects | 🟡 |
| 5 | Disconnect during trade | Trade cancelled, no items lost or duplicated | 🟡 |
| 6 | Rejoin to duplicate inventory | Exact state restored, no duplication | 🟡 |
| 7 | Skip night via client | Rejected — day/night is server-controlled | 🟡 |
| 8 | AFK in co-op (do nothing) | `PROPOSED` AFK kick after 3 minutes | 🟠 |

---

## Device Compatibility Matrix

| Device | OS | Controls | FPS Target | Test Status |
|--------|-----|---------|-----------|-------------|
| Gaming PC | Windows | KB+Mouse | 60 | ⬜ Not tested |
| Mid-range PC | Windows | KB+Mouse | 60 | ⬜ Not tested |
| MacBook | macOS | KB+Mouse | 60 | ⬜ Not tested |
| iPhone 13+ | iOS | Touch | 30 | ⬜ Not tested |
| iPhone 11 | iOS | Touch | 30 | ⬜ Not tested |
| Samsung Galaxy S21+ | Android | Touch | 30 | ⬜ Not tested |
| Samsung Galaxy A52 (mid-range) | Android | Touch | 30 | ⬜ Not tested |
| iPad | iPadOS | Touch | 30 | ⬜ Not tested |
| Xbox controller | Console/PC | Controller | 60 | ⬜ Not tested |

---

## Playtest Plan

### Phase 0 (Prototype)
- **Testers:** Dev team (2–3 people)
- **Focus:** Does the core loop work? Is chopping→fire→survive fun?
- **Duration:** 15 min per session
- **Feedback:** Verbal, noted in shared doc

### Phase 1 (Vertical Slice)
- **Testers:** Dev team + 5–10 friends
- **Focus:** Is Day 0 + Day 1 engaging? Is onboarding clear? Does mobile work?
- **Duration:** 30 min per session
- **Feedback:** Survey form + recorded sessions

### Phase 2 (Full Campaign)
- **Testers:** 20–50 external testers (Discord community)
- **Focus:** Full campaign pacing, difficulty curve, co-op balance
- **Duration:** 60–75 min per session
- **Feedback:** Analytics data + post-game survey

### Phase 3 (Pre-Launch)
- **Testers:** 100+ public beta testers
- **Focus:** Exploits, performance, retention, fun
- **Duration:** Multiple sessions
- **Feedback:** Analytics + bug reports + retention data
