# Crafting and Upgrades — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## Crafting System

Requires: Workbench (built at shelter, costs 4 Wood + 3 Metal Scrap).

### Recipes

| Recipe | Ingredients | Result | Effect |
|--------|------------|--------|--------|
| Torch | 1 Wood + 1 Rope | Portable light (6 stud radius, 120s) | Exploration safety |
| Barricade | 3 Wood + 2 Metal | Placeable wall (50 HP) | Monster path blocking |
| Premium Fuel | 2 Wood + 1 Plastic | 1 unit burns 2x slower | Efficient fire fuel |
| Bandage | 2 Rope + 1 Plastic | Heals 30 HP | Health recovery |
| Emergency Flare | 2 Metal + 1 Plastic + 1 Rope | Instant relight + monster push | Emergency defense |

### Crafting Rules

- Interaction: approach workbench → crafting menu opens → select recipe → Hold E for 3s.
- Server validates ingredients, deducts them, grants crafted item.
- Crafting takes real time (3s) — player is locked in animation.
- All recipes visible from Day 3+ (even if player can't afford them — shows goals).

---

# Trading and Economy — Project: Undecided

> **Status:** `EXISTING_CANON` (trading concept) + `PROPOSED` (specifics)

---

## Wandering Trader

`EXISTING_CANON` A trader visits the player's camp to exchange scrap for better materials.

### Visit Schedule

| Day | Arrives | Duration | Stock |
|-----|---------|----------|-------|
| Day 3 | Mid-morning | 120s | Basic trades |
| Day 4 | Mid-morning | 120s | Advanced trades |
| Day 5 | Early morning | 90s | Emergency supplies |

### Trade Interface

- Approach trader → "Trade" prompt → trading panel opens.
- Left side: what player gives. Right side: what player gets.
- Confirm button. Server validates both sides.
- Trader stock is session-wide (if one player buys an item, it's gone for all).

### Pricing Principles

- Trades should feel FAIR, not exploitative.
- Every trade should be a meaningful choice (not an obvious best deal).
- The trader is helpful but not essential — players CAN survive without trading.
