# Post-Launch Content Roadmap — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** Game Director & LiveOps Producer  
> **Related Documents:** [DIFFICULTY_AND_REPLAYABILITY.md](file:///i:/RobloxDev/docs/systems/DIFFICULTY_AND_REPLAYABILITY.md), [META_PROGRESSION.md](file:///i:/RobloxDev/docs/systems/META_PROGRESSION.md)

---

## 1. Roadmap Vision & Release Cadence

To maintain long-term engagement and retain players after their initial 5-day escape victory, *Project: Undecided* follows a sustainable live-service cadence that expands lore, difficulty modifiers, and cosmetic prestige without introducing predatory monetization or unsustainable crunch.

```text
Launch (v1.0) ──► Month 1: Replay & Hardcore ──► Month 3: Chapter 2 Expansion ──► Month 6: Community Expeditions
```

---

## 2. Release Milestones & Phase Schedule

### Launch: v1.0 — "The Forest Escape" (Baseline)
- Complete 5-day survival campaign (Day 0 through Day 5).
- Solo & 1–5 player cooperative matchmaking.
- Core monster: "The Hollow".
- Barter economy with Silas the Trader.
- Meta-progression store with initial 10 flame and title cosmetics.

### Update 1: v1.1 — "Nightfall & Mutators" (Launch + 4 Weeks)
- **Hardcore Permadeath Mode:** Stricter fuel burns, zero self-revives, distinct leaderboards.
- **Lobby Mutators:** 6 optional challenge mutators (Voracious Flame, Silent Stalker, etc.).
- **New Lore Records:** 5 hidden journal entries revealing the origins of the city evacuation.
- **Mobile Comfort Update:** Customizable touch button layouts.

### Update 2: v1.2 — "The Ancient Shrine" (Launch + 8 Weeks)
- **Secret Ending Unlocked:** Collecting ancient relics unlocks Ending D ("The Restored Guardian").
- **New Weather Type:** Dense Ash Fog with muffled acoustic propagation.
- **Shelter Customization:** Cosmetic workbench decor and survivor bunk quilts.

### Major Expansion: v2.0 — "Chapter 2: The Sunken Mines" (Launch + 16 Weeks)
- **New Playable Map Biome:** Subterranean abandoned coal mines accessible via cave entrance.
- **Secondary Threat:** "The Blind Burrower" — subterranean creature drawn to vibrations and light flickering.
- **New Fuel Mechanic:** Coal carts and methane ventilation hazards.
- **Campaign Branching:** Choose between Forest Signal Escape or Underground Railway Evacuation.

---

## 3. Seasonal Limited-Time Community Events

| Event Name | Window | Event Modifier | Exclusive Earnable Cosmetics |
|------------|--------|----------------|------------------------------|
| **Blood Moon Festival** | October (Halloween) | Crimson sky; all nights feature aggressive shadow stalker minions | "Jack-o'-Lantern Flame", "Grim Warden" Title |
| **Frostbitten Solstice**| December (Winter) | Snowstorms reduce campfire radius; freezing cold slows movement | "Glacial Blue Soul Flame", Frostbitten Coat Skin |
| **Solar Flare Eclipse**| April (Spring) | Extended night duration; double Embers earned | "Solar Corona Flame" (Radiant Gold) |

---

## 4. Acceptance Criteria

- [ ] **AC-ROAD-01:** Every planned update preserves backwards compatibility with existing player profile DataStores.
- [ ] **AC-ROAD-02:** Live events trigger automatically via synchronized UTC calendar timestamps without requiring emergency place republishes.
- [ ] **AC-ROAD-03:** Content additions undergo standard QA acceptance gates before staging to production.
