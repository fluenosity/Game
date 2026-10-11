# Meta-Progression System — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **System Owner:** Progression & Monetization Lead  
> **Related Documents:** [ENDINGS_AND_EXTRACTION.md](file:///i:/RobloxDev/docs/systems/ENDINGS_AND_EXTRACTION.md), [DECISION_LOG.md](file:///i:/RobloxDev/docs/decisions/DECISION_LOG.md), [SERVER_AUTHORITY_AND_SECURITY.md](file:///i:/RobloxDev/docs/technical/SERVER_AUTHORITY_AND_SECURITY.md)

---

## 1. System Vision & Ethical Progression Manifesto

*Project: Undecided* adheres strictly to an **anti-pay-to-win design philosophy**. Survival horror depends entirely on vulnerability, uncertainty, and earned mastery. 

### Core Tenets
1. **Zero Pay-to-Win:** No player can purchase damage boosts, infinite fire fuel, instant revive tokens, or monster immunity for Robux.
2. **Horizontal & Cosmetic Meta:** Progression rewards mastery with cosmetic expression, ambient customizations, prestige badges, and challenge modifiers.
3. **Purely Earnable Currency:** "Embers" are earned exclusively by playing the game (surviving nights, completing lore discoveries, reviving friends).

---

## 2. Meta-Currency: "Embers" Economy

### How Embers are Earned
- **Surviving Night 1:** 20 Embers
- **Surviving Night 2:** 30 Embers
- **Surviving Night 3:** 45 Embers
- **Surviving Night 4:** 60 Embers
- **Surviving Night 5 & Escaping:** 100 Embers
- **Full 5-Day Campaign Clear:** +100 Bonus Embers
- **First Time Lore Discovery:** 15 Embers per clue
- **Co-op Team MVP (Most Revives / Stoked Fuel):** 25 Bonus Embers

*Average earnings per complete winning run (60 mins): ~380 Embers.*

---

## 3. Unlockable Catalog (Cosmetics & Customizations)

| Category | Item Name | Ember Cost | Description / Visual Effect |
|----------|-----------|------------|-----------------------------|
| **Flame Styles** | Classic Hearth Flame | Default (Free) | Warm orange-yellow natural wood fire |
| | Soul Ember (Azure Flame) | 500 Embers | Deep cobalt flame with floating mystical blue sparks |
| | Emerald Hearth | 800 Embers | Forest-green mystical flame, crackles with pine aroma |
| | Golden Aurora Flame | 1,500 Embers | Shimmering white-gold incandescent flame |
| **Shelter Decor** | Weathered Plaque | 250 Embers | Custom wood carved sign above shelter gate displaying party name |
| | Vintage Gramophone | 750 Embers | Cosmetic prop on shelter table; plays crackling 1940s jazz during day |
| | Survivor's Bunk Quilt | 400 Embers | Replaces ragged sofa texture with warm patchwork quilt |
| **Survivor Titles**| "The Firekeeper" | 300 Embers | Displayed above player avatar in lobby and HUD |
| | "Shadow Walker" | 600 Embers | Awarded for surviving 3 nights without taking monster damage |
| | "Sole Survivor" | 1,000 Embers | Awarded for escaping as the last living player in a 5-player party |
| **Challenge Modifiers**| "Blackout Mode" | Free Unlock (beat Day 5 once) | Unlocks optional lobby modifier: 50% fire light radius, +50% Ember rewards |

---

## 4. DataStore Schema & Persistence Architecture

```json
{
  "SchemaVersion": 1,
  "PlayerId": 12345678,
  "TotalRuns": 14,
  "Wins": 6,
  "Embers": 1420,
  "Inventory": {
    "Flames": ["ClassicHearth", "SoulEmber"],
    "Decor": ["VintageGramophone"],
    "Titles": ["Firekeeper"]
  },
  "Equipped": {
    "Flame": "SoulEmber",
    "Decor": "VintageGramophone",
    "Title": "Firekeeper"
  },
  "LoreCluesFound": [1, 2, 4, 5],
  "LastSavedTimestamp": 1791682400
}
```

### Save Safety & Idempotency
- **Session Lock:** ProfileService / MemoryStore session locking pattern to prevent multi-server duplicate spending or rollbacks.
- **Auto-Save:** Saves on campaign completion, lobby purchase, and player disconnect.
- **Data Loss Mitigation:** Retry budget of 5 exponential backoff attempts on DataStore errors before logging to analytics.

---

## 5. Acceptance Criteria

- [ ] **AC-META-01:** Completing a run credits the exact earned Embers to the player's profile DataStore.
- [ ] **AC-META-02:** Equipping "Soul Ember" dynamically applies blue point lights and particle emitter colors to the campfire on session start.
- [ ] **AC-META-03:** Cosmetic changes provide zero mechanical advantages (light radius and fuel consumption remain strictly identical to default).
- [ ] **AC-META-04:** Attempting to buy an item without enough Embers fails safely on the server with zero data corruption.
