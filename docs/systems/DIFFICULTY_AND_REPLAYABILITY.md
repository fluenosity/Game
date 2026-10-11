# Difficulty and Replayability System — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **System Owner:** Game Systems & Retention Lead  
> **Related Documents:** [CAMPAIGN_OVERVIEW.md](file:///i:/RobloxDev/docs/05_CAMPAIGN_OVERVIEW.md), [META_PROGRESSION.md](file:///i:/RobloxDev/docs/systems/META_PROGRESSION.md), [COOPERATION_AND_PARTIES.md](file:///i:/RobloxDev/docs/systems/COOPERATION_AND_PARTIES.md)

---

## 1. System Vision & Replay Value

While casual players seek to conquer the 5-day escape narrative once, dedicated horror and survival fans demand escalating replay value. The **Difficulty and Replayability System** provides multiple layers of challenge, procedural variability, and challenge mutators without dividing the core matchmaking community.

---

## 2. Difficulty Tiers

| Mode | Target Audience | Key Mechanical Changes | Ember Multiplier | Permadeath? |
|------|-----------------|------------------------|------------------|-------------|
| **Standard Mode** | First-time players, casual co-op | Baseline stats; 1 second-chance self revive in solo; down timer 45s; generous scrap spawns | 1.0× | No (Downed revive active) |
| **Nightfall Hardcore** | Experienced survivalists | Fuel burn rate +25%; down timer 20s; Monster movement speed +15%; no health regeneration | 1.75× | Yes (Dead players spectate until party escapes or dies) |
| **Nightmare / Eclipse** | Hardcore streamers & squads | Pitch black nights; monster tracks blood trails of injured players; random light flickers; resources -30% | 2.5× | Yes |
| **Solo Endurance** | Single-player purists | Tailored solo wood yields; slower monster recovery from flares; shorter night duration | 1.2× | 1 Free revive per campaign run |

*(Tuning values marked `INITIAL_BALANCE_PROPOSAL`)*

---

## 3. Challenge Mutators (Custom Lobby Modifiers)

Parties who have cleared the campaign once can toggle optional mutators in the lobby tent prior to session launch:

1. **"Voracious Flame":** The campfire burns fuel 50% faster, but flares burn twice as bright.
2. **"Silent Stalker":** The Hollow produces zero ambient growls or breathing sounds; only breaking twigs and visual silhouettes warn of its approach.
3. **"Scarcity Protocol":** Trees yield only 1 wood instead of 2. Forages must prioritize debris and deadfall.
4. **"Broken Radio":** No HUD indicators or day timer; players must track time by looking at the sun and listening to dusk sirens.
5. **"Fragile Shelters":** Shelter perimeter fences can be broken through by monster charges if not reinforced with metal.

---

## 4. Procedural Map Seed Variations

To ensure each 5-day campaign feels distinct:
- **Seed-Driven Node Layout:** At session initialization, the server generates resource cluster coordinates based on a numeric seed (`math.randomseed`).
- **Scrap Landmark Variants:** Scavenge landmarks rotate across 4 archetypes (Collapsed Highway Overpass, Abandoned Lumber Mill, Overgrown Research Outpost, Derelict Ranger Tower).
- **Audio Dynamic Shifts:** The order and frequency of night ambiance events are randomized to prevent rote memorization of jump moments.

---

## 5. Weekly Community Expeditions & Leaderboards

- **Weekly Seed:** Every Monday, a fixed seed and set of 3 active mutators are published globally.
- **Fair Leaderboards:**
  - Metric: Fastest Campaign Clear Time (minutes/seconds) & Lowest Fuel Wasted.
  - Verification: Server-authoritative run validation logs to prevent injected cheat scores.
- **Weekly Participation Reward:** Exclusive weekly ribbon badge and 150 bonus Embers for completing the expedition.

---

## 6. Acceptance Criteria

- [ ] **AC-DIFF-01:** Selecting Hardcore Mode in the lobby tent applies verified increased fuel burn and monster speed modifiers across all 5 days.
- [ ] **AC-DIFF-02:** When mutators are enabled, the debrief screen correctly computes and awards the multiplied Ember payout.
- [ ] **AC-DIFF-03:** Procedural seed variations ensure wood and scrap nodes spawn in non-identical positions across consecutive runs.
- [ ] **AC-DIFF-04:** Downed players in Hardcore cannot be revived once the 20-second bleedout expires.
