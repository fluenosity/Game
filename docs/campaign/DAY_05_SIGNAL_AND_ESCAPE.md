# Day 5 — The Signal and Escape

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11
> **Design pillar:** All pillars converge — Fire Is Life, Monster Is Memorable, Every Decision Matters, Cooperative Tension, Show Don't Tell

---

## 1. Document Metadata

| Field | Value |
|-------|-------|
| Day | 5 (Final) |
| Type | Full gameplay day — climax and conclusion |
| Duration | `INITIAL_BALANCE_PROPOSAL` ~15–20 minutes real-time |
| Status | `PROPOSED` (entire day) |
| Depends on | Day 4 completion |
| Leads to | Campaign ending → results → lobby |

---

## 2. Purpose & Intended Emotion

### Purpose

Provide a satisfying, earned conclusion to the campaign. Everything the player has learned and built across 4 days leads to this moment: **activate the signal, survive the final night, and escape.**

### Target Emotions

| Phase | Emotion |
|-------|---------|
| Morning | Desperate hope ("Today we get out") |
| Finding the Radio Module | Triumph + dread ("Now I have to survive one more night") |
| Activating the signal | Anticipation, vulnerability |
| Final night | Pure terror (the most intense encounter) |
| Rescue arrival | Elation, relief |
| Escape | Triumph, catharsis |

---

## 3. Narrative Context

The player has the Battery Pack and Antenna Wire from Day 4. One component remains: the Radio Module. It's in the most dangerous part of the forest — near the monster's territory.

Today is the last day. Tonight is the last night. Everything comes down to this.

---

## 4. Player Starting Conditions

| Parameter | Value |
|-----------|-------|
| Health | 100 |
| Inventory | Items from Day 4 + storage + signal components (Battery, Antenna Wire) |
| Campfire | Tier 2–3 (depending on upgrades) |
| Shelter | Upgraded (fence, storage, workbench variations) |
| Signal progress | 2/3 components |
| Time of day | Early morning |

---

## 6. Primary Objective

1. "Find the Radio Module" → shown at dawn.
2. "Activate the signal tower" → after collecting all 3 components.
3. "Survive until rescue arrives" → at nightfall.
4. "Escape" → when rescue arrives at dawn.

---

## 8. Step-by-Step Gameplay Flow

### Step 1: Morning — Final Preparations (0:00–1:00)

- "DAY 5" appears. Different tone — music swell, sense of finality.
- `PROPOSED` A distant rumbling or flickering light hints at the signal tower location.
- Objective: **"Find the Radio Module."**

### Step 2: The Radio Module — Dangerous Retrieval (1:00–4:00)

The Radio Module is located at the **most dangerous point in the forest**:
- `PROPOSED` A clearing near the monster's daytime resting area.
- Signs of the monster everywhere: scratch marks, broken trees, dark stains.
- The module is inside a damaged vehicle or structure at the clearing's center.

**Key tension:** The player must approach a location that feels like the monster's territory. During daytime, the monster is dormant — but the atmosphere is terrifying.

`PROPOSED` Optional scare moment: as the player grabs the Radio Module, they hear the monster stir nearby — a distant growl, shifting earth. Not an attack, but a warning.

**Risk design:** 
- Fastest route = through dense forest, closer to monster signs.
- Safer route = longer path around the perimeter.
- In co-op, one player can scout while others carry resources.

### Step 3: Signal Tower Activation (4:00–6:00)

The player brings all 3 components to the signal tower:

| Component | Source |
|-----------|--------|
| Battery Pack | Day 4 — ruined shack |
| Antenna Wire | Day 4 — deep forest |
| Radio Module | Day 5 — monster clearing |

**Activation sequence:**
1. Place Battery Pack → interaction prompt, 3s hold.
2. Attach Antenna Wire → interaction prompt, 3s hold.
3. Install Radio Module → interaction prompt, 3s hold.
4. **"Activate Signal"** → final interaction, 5s hold.

The tower lights up. A radio signal beeps. A crackling voice: *"Signal received. Rescue en route. Hold your position until dawn."*

**What this means for the player:** You must survive ONE MORE NIGHT at the signal tower OR return to the shelter.

`PROPOSED` **Critical choice:** 
- Stay at the signal tower (exposed, but the tower has lights/fire) → rescue comes directly.
- Return to the shelter (familiar, better defenses) → rescue takes slightly longer.

### Step 4: Final Preparation (6:00–7:00)

- Whether at the tower or the shelter, the player prepares for the last night.
- All remaining fuel, torches, barricades deployed.
- `PROPOSED` The trader makes a final emergency visit with last-chance supplies.
- The sky darkens. Faster than before.
- Objective: **"Survive until rescue arrives."**

### Step 5: Night 5 — The Final Stand (7:00–15:00)

**Night 5 is 480 seconds (8 minutes real-time) — the longest night.**

This is the climax of the entire game. Everything escalates:

**Phase A: The Calm (0–60s)**
- Dead silence. No wind, no insects, no sounds.
- The fire crackles. The player waits.
- The longest 60 seconds of the game.

**Phase B: First Wave (60–180s)**
- The monster approaches — rapidly, aggressively.
- `PROPOSED` Multiple approach angles — it circles, looking for the weakest point.
- If at the shelter: it attacks the fence directly.
- If at the signal tower: it circles the tower's light range.
- The player must maintain fire, repair damage, and stay alive.

**Phase C: Fire Under Siege (180–300s)**
- `PROPOSED` The monster attempts to extinguish the fire.
- Possible methods: knocking fuel out, creating wind with its mass, throwing debris.
- The fire flickers dangerously. Player must continuously feed it.
- **This is the moment that creates TikTok clips** — the fire almost going out while the monster circles.

**Phase D: The Desperate Hour (300–420s)**
- `PROPOSED` A second, smaller threat appears (offspring? echo? shadow of the monster?).
- The player is fighting on two fronts.
- In co-op: players must split defense — one on the fire, one on the perimeter.
- Resources are running low. Every piece of wood matters.

**Phase E: Dawn Approaches (420–480s)**
- The sky begins to lighten — barely.
- The monster makes one FINAL aggressive push.
- `PROPOSED` It enters the protection radius — briefly, dramatically.
- The player must hold. Just hold.
- Dawn breaks. The monster screams and retreats — further than ever before, into the deep forest.

### Step 6: Rescue & Escape (15:00–18:00)

- Dawn is full. The monster is gone.
- A sound: helicopter blades / vehicle engine / another signal.
- `PROPOSED` A rescue vehicle appears at the forest edge or at the signal tower.
- The player approaches the rescue point.
- Interaction: **"Escape" (Hold E, 3s)**

**Escape Sequence:**
- The player boards the vehicle / enters the rescue zone.
- Camera pulls back — showing the forest, the shelter, the signal tower from above.
- The camera catches one last glimpse of the monster — watching from the treeline.
- Fade to black.

---

## 9. Endings `PROPOSED`

### Ending A: Full Escape (Default)

All players (or solo player) reach the rescue point.
- **Text:** "You survived."
- **Tone:** Triumphant. Earned.
- **Reward:** Campaign completion badge, XP, cosmetic unlock.

### Ending B: Partial Escape (Co-op)

Some players escape, some die.
- **Text:** "You escaped. Not everyone made it."
- **Tone:** Bittersweet.
- **Reward:** Completion badge (reduced), XP.

### Ending C: Sacrifice Ending (Co-op) `PROPOSED`

`PROPOSED` One player stays behind to keep the fire burning while others escape.
- **Text:** "One stayed behind so others could live."
- **Tone:** Heroic, emotional.
- **Reward:** Special badge for the sacrificed player.

### Ending D: Total Failure

All players die on Night 5.
- **Text:** "The fire went out."
- **Tone:** Devastating.
- **Result:** Return to lobby. Option to retry.

### Ending E: Lore Ending `PROPOSED`

If the player collected ALL lore items across the campaign:
- Additional cutscene revealing the monster's origin.
- `PROPOSED` The monster was once a guardian of the forest, corrupted by something in the city.
- The fire doesn't just scare it — fire is what the forest was before the corruption.
- **Text:** "Now you know the truth."
- **Reward:** Exclusive cosmetic + lore completion badge.

---

## 12. Monster Behavior (Night 5) — State Machine

| State | Entry | Behavior | Exit |
|-------|-------|----------|------|
| DORMANT | Day | Not present | → SILENT_STALK |
| SILENT_STALK | Night begins | Approaches silently, no sound for 60s | → AGGRESSIVE_APPROACH |
| AGGRESSIVE_APPROACH | After silence | Rapid, multi-angle approaches | → SIEGE |
| SIEGE | Reaches defenses | Attacks fence/barricades actively | → FIRE_ASSAULT |
| FIRE_ASSAULT | After breaching | `PROPOSED` Attempts to reduce fire (knock fuel, create wind) | → SUSTAINED_ATTACK |
| SUSTAINED_ATTACK | Fire weakened | Continuous pressure, short retreats, returns | → FINAL_PUSH |
| FINAL_PUSH | Last 60s of night | Most aggressive — enters radius briefly | → DAWN_RETREAT |
| DAWN_RETREAT | Dawn | Dramatic, screeching retreat into deep forest | → DORMANT |

---

## 18. Success & Failure

| Condition | Result |
|-----------|--------|
| Survive Night 5 + escape | ✅ Campaign complete — Ending A or C |
| Some players escape, others die | ✅ Partial — Ending B |
| All players die | ❌ Ending D — retry option |
| Survive Night 5 but don't activate signal | `PROPOSED` Survive but no rescue — can continue to Day 6 (endless mode?) |

---

## 22. Required Assets (New for Day 5)

| Asset | Type | Priority |
|-------|------|----------|
| Signal tower model | 3D | High |
| Radio Module item | 3D model + icon | High |
| Monster clearing environment | 3D scene | High |
| Rescue vehicle (helicopter/truck) | 3D model | High |
| Final night music/audio | Audio | High |
| Monster scream (dawn retreat) | Audio | High |
| Ending cutscene camera work | Cinematic | High |
| Ending text screens (A–E) | UI | Medium |
| "You Survived" results screen | UI | High |
| Lore ending cutscene | Cinematic | Low (post-launch) |

---

## 25. Acceptance Criteria

- [ ] The Radio Module retrieval feels tense and dangerous
- [ ] Signal tower activation feels like a milestone moment
- [ ] Night 5 is the most intense, frightening experience in the game
- [ ] The fire-under-siege mechanic creates genuine panic
- [ ] The final dawn feels earned and emotionally powerful
- [ ] The escape sequence is cinematic and satisfying
- [ ] All endings work correctly and feel appropriate
- [ ] Co-op teams experience genuine cooperative tension on Night 5
- [ ] A solo player can complete Day 5 (harder, but possible)
- [ ] The final monster glimpse in the escape cutscene is chilling

---

## 28. Unresolved Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | Signal tower vs. shelter — should the player have to choose where to defend? | Level design, strategy depth |
| 2 | Can the monster actually extinguish the fire, or just reduce it? | Core balance |
| 3 | Should there be a second creature on Night 5? | Scope, difficulty |
| 4 | Is the lore ending available on first playthrough or only on replay? | Replayability |
| 5 | What happens if the player activates the signal but goes back to sleep at shelter? | Edge case |
| 6 | Should the rescue be instant at dawn or require the player to reach a point? | Pacing |
| 7 | Endless mode after Day 5 — yes or no? | Post-campaign content |
