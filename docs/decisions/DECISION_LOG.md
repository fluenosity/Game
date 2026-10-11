# Decision Log — Project: Undecided

> **Last updated:** 2026-10-11

---

## Format

| # | Date | Decision | Status | Rationale | Impact |
|---|------|----------|--------|-----------|--------|

---

## Decisions

| # | Date | Decision | Status | Rationale | Impact |
|---|------|----------|--------|-----------|--------|
| 1 | 2026-10-11 | Max session size is 5 players (not 4) | `EXISTING_CANON` | Lobby design specifies 5 tents (1–5). Original rough notes said 4 — structured doc overrides. | Matchmaking, co-op scaling, balance |
| 2 | 2026-10-11 | Campaign is 5 days (Day 0–5), not open-ended | `PROPOSED` | Open-ended survival has no goal. 5 days provides focus, pacing, and a completion target. | Entire campaign structure, pacing, content scope |
| 3 | 2026-10-11 | Monster name: "The Hollow" | `PROPOSED` | Thematic connection to fire (anti-light entity), memorable name, distinct silhouette. 3 concepts evaluated. | Art direction, lore, marketing, merchandise |
| 4 | 2026-10-11 | Fire depletes fuel during night | `PROPOSED` | Core differentiator from 99 Nights. Creates active gameplay during night instead of passive waiting. | Fire system, balance, player experience, difficulty |
| 5 | 2026-10-11 | Monster escalates behavior across nights | `PROPOSED` | Prevents repetitive nights. Makes upgrades feel necessary. Creates story through mechanics. | Monster AI, balance, difficulty curve |
| 6 | 2026-10-11 | Save system: "maybe" → marked as PROPOSED | `PROPOSED` | Original doc was uncertain. A 60–75 min campaign needs mid-session saving for Roblox's audience. | Persistence, session management, complexity |
| 7 | 2026-10-11 | Signal tower as escape objective (Day 5) | `PROPOSED` | Players need a finish line. Collecting components across Days 4–5 creates goal-driven gameplay. | Day 4–5 design, ending sequences |
| 8 | 2026-10-11 | Use "The Hollow" concept over "The Warden" or "The Ember" | `PROPOSED` | Best scores across visual distinctiveness, thematic connection, Roblox feasibility, and meme potential. | Monster design, art, audio |
| 9 | 2026-10-11 | Documentation-first approach (no code yet) | `EXISTING_CANON` | Per task.md: "Documentation is the primary deliverable. Do not start implementing." | Development timeline |
| 10 | 2026-10-11 | All balance values are INITIAL_BALANCE_PROPOSAL | `ASSUMPTION` | No playtesting has occurred. All numbers need validation. | Every system with numerical values |

---

# Open Questions

> **Last updated:** 2026-10-11

---

| # | Question | Category | Priority | Impact | Status |
|---|----------|----------|----------|--------|--------|
| 1 | Is the campaign 5 days or open-ended? | Campaign | 🔴 Critical | Defines entire game structure | `PROPOSED` 5 days — awaiting approval |
| 2 | What is the end goal? (signal tower, escape, defeat monster?) | Campaign | 🔴 Critical | Day 5 design | `PROPOSED` signal tower |
| 3 | Is death permanent (roguelike) or checkpoint (restart day)? | Difficulty | 🔴 Critical | Session length, frustration, replay | Undecided |
| 4 | Should the monster attack on Night 1? | Monster AI | 🟡 High | Tutorial difficulty | `PROPOSED` no — atmospheric only |
| 5 | Is the save system needed? | Technical | 🟡 High | 60–75 min sessions on Roblox may need saves | `PROPOSED` yes |
| 6 | Should the trader be permanent or visiting? | Economy | 🟡 High | Pacing, availability | `PROPOSED` visiting |
| 7 | Should crafting require a workbench or be free? | Crafting | 🟠 Medium | Progression gating | `PROPOSED` workbench required |
| 8 | Can the monster kill players inside Tier 1 radius (Day 4+)? | Monster AI | 🟡 High | Core balance | Undecided |
| 9 | How many lore items total? | Narrative | 🟠 Medium | Content scope | `PROPOSED` 6 items |
| 10 | Should landmarks be fixed or randomized? | Level Design | 🟠 Medium | Replayability vs. level design quality | Undecided |
| 11 | Is 60–75 min too long for Roblox audience? | Campaign | 🟡 High | May need shorter days or mid-campaign saves | Needs playtesting |
| 12 | Should co-op sleep require all players? | Co-op | 🟠 Medium | Can one player force the day to end? | `PROPOSED` all alive players |
| 13 | Endless mode after Day 5? | Post-content | 🟢 Low | Post-launch feature | `PROPOSED` yes (post-launch) |
| 14 | Should the game have a tutorial or rely purely on "show don't tell"? | Onboarding | 🟡 High | Some players may be confused | `PROPOSED` show don't tell + optional hints |
| 15 | What Roblox monetization is appropriate? | Business | 🟠 Medium | Revenue vs. fairness | `PROPOSED` cosmetics only |

---

# Changelog

> **Last updated:** 2026-10-11

---

| Date | Change | Files Affected |
|------|--------|---------------|
| 2026-10-11 | Initial documentation repository created | All files |
| 2026-10-11 | Game.md reorganized into structured sections 1–16 | Game.md |
| 2026-10-11 | Market research added (competitors, demographics, virality) | Game.md, MARKET_AND_COMPETITOR_RESEARCH.md |
| 2026-10-11 | Full docs/ structure established with 30+ documents | docs/* |
| 2026-10-11 | Monster identity design: 3 concepts evaluated, The Hollow recommended | MONSTER_IDENTITY_AND_BEHAVIOR.md |
| 2026-10-11 | Campaign Day 0–5 fully specified | campaign/* |
| 2026-10-11 | Core systems specified (fire, monster AI, matchmaking, resources) | systems/* |
| 2026-10-11 | Technical architecture defined | technical/* |
| 2026-10-11 | Research framework established | research/* |
