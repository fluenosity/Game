# Accessibility & Onboarding Specification — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** UX Lead & Accessibility Specialist  
> **Related Documents:** [DAY_01_FIRST_SURVIVAL.md](file:///i:/RobloxDev/docs/campaign/DAY_01_FIRST_SURVIVAL.md), [UI_AND_INPUT_ARCHITECTURE.md](file:///i:/RobloxDev/docs/technical/UI_AND_INPUT_ARCHITECTURE.md)

---

## 1. Onboarding Philosophy: "Show, Don't Stop"

First-time players on Roblox quickly leave games that bombard them with unskippable text walls or freeze gameplay. *Project: Undecided* uses **organic contextual onboarding**:
- Zero intrusive tutorial pop-ups that lock player controls.
- Environmental breadcrumbs (broken wire path leads to shelter; smoke column marks campfire).
- Minimalist, dynamic objective banners that automatically advance upon completing actions.

### Day 1 Step-by-Step Onboarding Funnel
1. **Spawn:** Flee down dirt trail toward visible forest smoke column (10s).
2. **Discover Shelter:** Step inside fence (`Objective Complete: Reach Shelter`).
3. **Prompt Gathering:** Highlight nearby fallen timber (`Objective: Chop 2 Trees [0/2]`).
4. **Light Fire:** Return to pit with wood (`Objective: Light Campfire before Nightfall`).
5. **Survive:** Stand within the warm glow as the monster circles outside the boundary.

---

## 2. Accessibility Features & Settings

Accessible under `Settings Menu -> Accessibility`:

### 2.1 Motion & Comfort Settings
- **Camera Head Bob:** Slider from 0% (Disabled) to 100% (Full Immersion). Prevents motion sickness.
- **Screen Shake Reduction:** Toggle to disable traumatic explosion / hit trauma shakes.
- **Field of View (FoV):** Slider from 70 to 110 degrees.

### 2.2 Visual & Color Accessibility
- **Colorblind Palettes:** Preset shaders for **Deuteranopia**, **Protanopia**, and **Tritanopia**.
  - Adjusts fuel meter colors (swapping green/red to high-contrast cyan/magenta).
  - Adjusts monster eye glow and reticle danger indicators.
- **UI Text Scaling:** Options for `Small`, `Medium`, `Large` (+25% font size).

### 2.3 Audio & Closed Captions
- **Directional Sound Subtitles:** Visual subtitles at bottom-center of screen with spatial arrows:
  - `◄ [Wet Breathing - Left]`
  - `▲ [Twig Snapping - Ahead]`
  - `► [Monster Roar - Right]`
- Essential for deaf players, hard-of-hearing players, or mobile users playing without headphones.

---

## 3. Acceptance Criteria

- [ ] **AC-ACC-01:** Disabling camera head bob completely zeroes procedural camera offsets while walking.
- [ ] **AC-ACC-02:** Enabling closed captions renders directional audio alerts with accurate left/right spatial panning.
- [ ] **AC-ACC-03:** Day 1 tutorial seamlessly advances without ever halting player movement or locking inputs.
