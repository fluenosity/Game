# Player Experience — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## First-Time Player Journey

### Minute 0–2: The Hook (Day 0)

The player joins a session. Within seconds:
1. A cinematic shows a devastated city.
2. A massive monster appears — terrifying.
3. The monster sees fire — runs away.
4. **The player now knows the ONE rule:** fire = safety.

No text. No tutorial popup. No "Press X to continue." Pure visual storytelling.

**Success metric:** If you ask a player "what did you learn from the cutscene?" they should say "the monster is scared of fire."

### Minute 2–5: Discovery (Day 1 Morning)

The player gains control in the forest (FPP). They see:
- A clear path ahead (no confusion about where to go).
- Interaction prompt on trees: "Chop" (simple, obvious).
- A shelter visible at the end of the path.

No complex menus. No inventory screens. Just: walk, find, chop.

**Success metric:** The player finds the shelter and chops their first tree without any text tutorial.

### Minute 5–8: First Preparation

The player is at the shelter with wood. They see:
- A campfire spot with a clear "Light Fire" prompt.
- The sky is changing color — subtle urgency.

They light the fire. They feel prepared.

**Success metric:** The player lights the campfire before nightfall without being told to rush.

### Minute 8–10: First Night — The Emotional Peak

Night falls. The campfire glows. Beyond the light:
- Sounds in the darkness. Footsteps. Breathing.
- A distant silhouette moves between trees.
- The monster is out there. It's circling.

The player stays by the fire. Their heart rate elevates. They survive.

Dawn comes. "DAY 2" appears. **They did it.**

**Success metric:** The player felt genuine tension during the first night, not boredom.

---

## Emotional Design Targets

### Per-Night Emotional Arc

```
Preparation          Nightfall           Night                Dawn
(Confident)    →    (Anxious)    →    (Afraid)    →    (Relieved)
    │                   │                │                 │
    ▼                   ▼                ▼                 ▼
"I'm ready"      "Is this enough?"  "It's out there"  "I made it"
```

### Per-Campaign Emotional Arc

```
Day 0: SHOCK ────→ Day 1: VULNERABILITY ────→ Day 2: GROWING COMPETENCE
                                                         │
Day 5: TRIUMPH/LOSS ←──── Day 4: DREAD ←──── Day 3: EXPLORATION EXCITEMENT
```

---

## Onboarding Philosophy

### Rules

1. **Never use a text wall tutorial.** Players learn by doing.
2. **The environment IS the tutorial.** A single clear path = "go this way." Visible campfire spot = "put fire here."
3. **Fail gently on Day 1.** Give enough time, enough resources, and enough warnings. Day 1 failure should feel like "I made a mistake" not "the game cheated me."
4. **Introduce one thing at a time.** Never dump two new mechanics in the same 60-second window.
5. **Reward observation.** Players who pay attention to the cutscene understand fire faster. Players who explore further find more resources. Smart play is rewarded.

### Objective System

**`PROPOSED`**

Minimal, non-intrusive objective hints:

| Day | Objective Text | When Shown |
|-----|---------------|------------|
| Day 1 | "Find shelter" | After cutscene ends |
| Day 1 | "Collect wood" | After entering shelter |
| Day 1 | "Return to shelter" | When nightfall begins |
| Day 1 | "Light the campfire" | When at campfire spot with wood |
| Day 2 | "Gather more wood" | At dawn |
| Day 2 | "Upgrade the campfire" | When enough wood collected |
| Day 3 | "Explore the forest" | At dawn |
| Day 3 | "Find useful materials" | After leaving shelter |
| Day 4 | (context-dependent) | Based on new threats |
| Day 5 | "Find a way to escape" | At dawn |

**Display:** Small text in upper-left corner. Fades after 5 seconds. Can be re-read in a minimal menu. Never blocks gameplay.

---

## Camera & Perspective

| Aspect | Design |
|--------|--------|
| Default camera | First-Person Perspective (FPP) — `EXISTING_CANON` |
| Cutscene camera | Cinematic third-person, scripted movements |
| Transition | Smooth blend from cinematic to FPP after cutscene |
| FOV | `ASSUMPTION` 70° default, adjustable in settings |
| Head bob | `PROPOSED` Subtle, disable-able for comfort |
| Camera shake | `PROPOSED` On monster proximity (very subtle), disable-able |

---

## Horror Design Principles

### What Makes This Game Scary

| Technique | How We Use It |
|-----------|--------------|
| **Anticipation** | The player KNOWS the monster is coming. The dread of waiting is worse than the encounter. |
| **Sound** | Footsteps, breathing, branches breaking. The player hears the monster before they see it. |
| **Limited visibility** | At night, the player can only see within the fire's glow. Everything else is black. |
| **Silhouettes** | The monster is glimpsed as a shape between trees — never fully lit or shown up close (until it attacks). |
| **Resource pressure** | The fire is running low. There's not enough wood. The safe zone is shrinking. |
| **Isolation** | Even in co-op, players may be separated. Being alone in the dark is terrifying. |
| **Behavioral uncertainty** | The monster doesn't do the same thing every night. Players can't fully predict it. |

### What This Game Avoids

| Anti-pattern | Why We Avoid It |
|-------------|----------------|
| Constant jumpscares | They lose impact fast. One well-timed scare > ten random ones. |
| Excessive gore | Roblox audience includes under-13. Atmosphere > violence. |
| Unfair deaths | Players should feel responsible for failure, not cheated. |
| Loud constant noise | Audio fatigue destroys tension. Silence is more powerful. |
| Monster always visible | Mystery is scarier than a fully-revealed creature. |

---

## Accessibility Considerations

**`PROPOSED`**

| Feature | Description |
|---------|-------------|
| Subtitle system | All audio cues have optional text descriptions |
| Color-blind mode | UI elements use shapes + colors, not color alone |
| Reduced motion | Disable head bob, camera shake, screen effects |
| Audio descriptions | `PROPOSED` Optional audio cues for visual-only events |
| Adjustable text size | HUD text scales for readability |
| Remappable controls | PC keyboard bindings can be changed |
| Touch control sizing | Mobile buttons can be scaled |
| Difficulty options | `PROPOSED` Longer days, slower monster, more resources |

---

## Mobile Player Experience

### Constraints

- Smaller screen → UI must be larger, simpler
- Touch controls → actions must be tap/hold, not precision-based
- Lower performance → effects must scale down
- Shorter attention span → clear objectives, visible progress

### Mobile-Specific Design

| PC Action | Mobile Equivalent |
|-----------|------------------|
| WASD movement | Virtual joystick (left side) |
| Mouse look | Touch-drag (right side) |
| E to interact | Tap on-screen button OR tap on object |
| Click to chop | Hold interaction button |
| Inventory | Simplified strip at bottom of screen |
| Menu | Hamburger button (top-right) |

### Mobile Success Criteria

- [ ] Player can complete Day 1 on a mid-range phone without confusion
- [ ] All interaction prompts are readable on a 5.5" screen
- [ ] No action requires precision that touch controls can't provide
- [ ] FPS stays above 30 on target mobile devices
- [ ] The horror atmosphere is maintained (not ruined by bright UI)
