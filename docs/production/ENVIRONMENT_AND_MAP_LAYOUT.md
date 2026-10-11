# Environment & Map Layout Specification — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** Level Design Lead & Environment Artist  
> **Related Documents:** [ART_DIRECTION.md](file:///i:/RobloxDev/docs/production/ART_DIRECTION.md), [DAY_05_SIGNAL_AND_ESCAPE.md](file:///i:/RobloxDev/docs/campaign/DAY_05_SIGNAL_AND_ESCAPE.md)

---

## 1. Spatial World Map Overview

The playable world of *Project: Undecided* is a compact, highly dense 512×512 stud forest basin bordered by impenetrable cliff walls and a collapsed highway overpass. The central hub is the **Fenced Shelter**, ensuring players always have a clear mental anchor.

```text
 ┌─────────────────────────────────────────────────────────────┐
 │                NORTH: Collapsed Highway Overpass             │
 │                      (Metal scrap caches)                   │
 │                                                             │
 │   WEST: Overgrown Outpost           EAST: Abandoned Mill    │
 │   (Batteries, plastic, rope)        (Dense hardwood lumber) │
 │                                                             │
 │                 ┌───────────────────────┐                   │
 │                 │  SHELTER COMPOUND     │                   │
 │                 │  - Campfire Core      │                   │
 │                 │  - Old Sofa & Table   │                   │
 │                 │  - Damaged Fence Gate │                   │
 │                 └───────────────────────┘                   │
 │                                                             │
 │               SOUTH-WEST: Pine Forest Dense Thicket         │
 │               SOUTH-EAST: Signal Hill & Radio Tower (Day 5) │
 └─────────────────────────────────────────────────────────────┘
```

---

## 2. Landmark Zones & Scavenge Archetypes

| Zone Name | Distance from Shelter | Key Resources Found | Visual Landmark Cues | Threat Level |
|-----------|-----------------------|---------------------|----------------------|--------------|
| **Shelter Compound** | 0 studs (Center) | Initial deadfall sticks | Damaged wire fence, old sofa, stone campfire pit | Safe (When lit) |
| **Pine Forest Ring** | 30–80 studs | Common wood logs | Towering pine trees, mossy rocks, winding dirt trails | Low |
| **Abandoned Lumber Mill** | 120 studs (East) | Dry Hardwood, nails, timber | Corrugated metal sheds, rusted circular saw bench | Moderate |
| **Overgrown Outpost** | 140 studs (West) | Plastic scrap, medical cloth | Overgrown field tents, overturned research crates | Moderate |
| **Collapsed Overpass** | 160 studs (North) | Heavy metal scrap, wire | Smashed concrete pillars, suspended truck chassis | High |
| **Signal Hill & Tower** | 180 studs (South-East) | Escape transmitter terminal | Tall steel lattice radio tower with blinking red beacon | Extreme (Day 5 only) |

---

## 3. Level Design Traversal Timing

- **Player Sprint Speed:** 16 studs/sec.
- **Shelter to Outer Perimeter Traversal Time:** ~10–12 seconds sprint.
- **Round-Trip Gathering Run:** 30–45 seconds.
- **Level Design Principle:** The map is deliberately sized so a player caught at the outer edge at nightfall has a desperate 10-second sprint back to the campfire while hearing the monster's approach.

---

## 4. Collision, Boundaries & Foliage Density

1. **Map Boundaries:** Steep natural rock cliffs with invisible collision volumes (`CanCollide = true`, `CanQuery = false`) to prevent players from climbing out of bounds.
2. **Foliage Density:** Maximum 140 choppable tree models within the active streaming radius. Dense background trees use non-interactive backdrop meshes with combined collision.
3. **Lighting Sightlines:** The Signal Tower blinking red light is visible from all exterior areas to provide a constant navigational compass heading.

---

## 5. Acceptance Criteria

- [ ] **AC-MAP-01:** Running from the central campfire to the collapsed overpass takes under 14 seconds at sprint speed.
- [ ] **AC-MAP-02:** Players cannot bypass boundary cliffs using jumping or physics glitches.
- [ ] **AC-MAP-03:** Red beacon on the Signal Tower is visible through the forest trees from at least 150 studs away.
