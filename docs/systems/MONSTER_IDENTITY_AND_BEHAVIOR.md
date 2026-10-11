# Monster Identity and Behavior — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11
> **Design pillar:** The Monster Is Memorable

---

## Design Goal

Create a monster that players **remember, fear, discuss, and share**. It should be as recognizable as "The Deer" (99 Nights) or the entities in DOORS — but entirely original.

---

## Monster Concept Candidates

### Concept A: "The Hollow" `PROPOSED`

**Visual:** A tall, gaunt, humanoid figure with elongated limbs. Its body is made of a dark, smoke-like substance that shifts and reforms. Where a face should be, there's a cavity — a hollow void that seems to absorb light. Its "eyes" are faint embers deep inside the hollow, like dying coals.

**Silhouette:** Unmistakable — tall, thin, arms too long, head slightly tilted. Visible from far away.

**Behavioral identity:** The Hollow doesn't just hunt — it WATCHES. It stands motionless at the edge of the light, tilting its head, studying. Then it moves. Its movement is wrong — too smooth, like it glides instead of walks.

**Audio identity:** No roaring. Instead: a deep, resonant humming (like wind through an empty building), the sound of embers cooling, and a distinctive "hollow" echo when it's close — like a voice in an empty room.

**Why it works:** The Hollow is the ANTI-fire. It absorbs light. It is darkness given form. Fire is its opposite — which is why it fears it. This creates a thematic connection between the monster and the game's core mechanic.

### Concept B: "The Warden" `PROPOSED`

**Visual:** A massive, quadrupedal creature — like a bear crossed with a wolf, but wrong. Its body is covered in bark-like armor (it was once part of the forest). Its eyes glow a sickly green. Roots trail from its limbs.

**Silhouette:** Low, wide, heavy. Distinct from any humanoid shape.

**Behavioral identity:** The Warden is territorial. It doesn't just hunt — it guards. The forest is ITS domain, and the players are intruders. It patrols like a guard, marks territory with scratch marks, and gets angrier as players take more from the forest.

**Audio identity:** Deep growling, snapping of wood, the crack of tree bark. When angry: a roar that shakes the screen.

**Why it works:** Ties the monster to the environment. The more resources players take (chopping trees = destroying the Warden's forest), the angrier it gets. This creates a natural escalation tied to gameplay.

### Concept C: "The Ember" `PROPOSED`

**Visual:** A shapeless, flickering darkness — like a shadow with depth. It doesn't have a fixed form; it shifts and flows like smoke. Only visible when there's a light source nearby — against the darkness, it's invisible. The only way to see it is by the way it BLOCKS light.

**Silhouette:** None consistent — changes shape. Sometimes tall, sometimes low, sometimes spread thin.

**Behavioral identity:** The Ember is the fire's shadow. Where there's light, it exists at the edge. Where there's no light, it IS the darkness. It can't be seen in pure dark — only at the boundary between light and shadow. This makes the fire both protection AND the only way to see the threat.

**Audio identity:** Whispering. Not words — just the texture of whispers. Increases in volume as it approaches.

**Why it works:** Unique visual concept (visible only at light boundaries). Creates a terrifying paradox: you need light to be safe, but light is also the only thing that reveals the monster watching you.

---

## Recommended Design: The Hollow `PROPOSED`

**Rationale:**

| Criterion | The Hollow | The Warden | The Ember |
|-----------|-----------|-----------|----------|
| Visual distinctiveness | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Roblox feasibility | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ (hard to render) |
| Silhouette readability | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ (no fixed shape) |
| Thematic connection to fire | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Meme/share potential | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Horror effectiveness | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Mobile readability | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

**The Hollow wins** because:
1. Its design directly connects to the fire mechanic (anti-light entity).
2. Its silhouette is instantly recognizable — even on mobile, even at a distance.
3. "The Hollow" is a distinctive, memorable name.
4. Its watching behavior creates sustained dread, not just jumpscare moments.
5. It's technically feasible in Roblox (humanoid rig with custom mesh + particle effects).

---

## The Hollow — Detailed Design

### Visual Specifications

| Aspect | Description |
|--------|-------------|
| Height | ~2.5x player height (imposing but not absurdly large) |
| Proportions | Elongated arms (reach ground level), thin torso, normal legs |
| Material | Dark, semi-transparent mesh with smoke particle overlay |
| Head | Hollow cavity where a face would be. Faint ember-like glow deep inside. |
| Eyes | Two dim orange points inside the head cavity |
| Movement | Smooth gliding motion (no visible footsteps — feet obscured by ground smoke) |
| Close-up detail | Hairline cracks across the body that glow faintly orange (like cooling lava) |
| Distance appearance | A tall, thin black silhouette against the night sky or treeline |

### Audio Specifications

| Context | Sound |
|---------|-------|
| Distant patrol | Low, resonant humming — like wind through ruins |
| Approaching | Humming intensifies + soft ember crackling |
| Testing the light | Breathing-like sound — inhaling (as if tasting the light) |
| Near the player | Hollow echo — like being inside an empty cavern |
| Retreating | Sound fades + a distinct "extinguish" hiss (like water on hot coals) |
| Attacking | Sharp, sudden shriek — the only loud sound it makes |
| Dawn retreat | Extended wail that fades into the distance |

### Behavioral Quirks

| Behavior | Description | Purpose |
|----------|-------------|---------|
| Head tilt | Tilts head 45° when observing players | Makes it feel curious and intelligent |
| Shadow extension | Its shadow stretches toward players (even when fire should block it) | Constant subtle threat |
| Ember flicker | The embers in its face flare when the campfire is low | Reacts to fire state |
| Stillness | Stands completely motionless for 10–30s during TEST state | Unnerving — is it still there? |
| Wrong movement | Moves in a slightly wrong way (too smooth, occasional stutter) | Uncanny valley horror |

### Lore Connection `PROPOSED`

**What is The Hollow?**

The Hollow was once part of the city — a guardian spirit or energy that protected the community. When the city was destroyed (by a disaster, experiment, or corruption), the guardian was twisted into something that consumes light instead of protecting it.

- The hollow face = the loss of identity.
- The ember eyes = the remnant of what it once was.
- Its fear of fire = an echo of its former purpose (it was once MADE of fire/light).
- The lore items reveal this origin across Days 3–5.

**This creates sympathy alongside fear** — the monster is tragic, not just evil. Players who discover the full lore understand why the fire both repels and fascinates it.

---

## Acceptance Criteria

- [ ] The monster is visually distinct from any existing Roblox horror creature
- [ ] Its silhouette is recognizable at 50+ studs distance
- [ ] Players describe the monster to friends after playing (it's memorable)
- [ ] The audio design creates dread before the monster is visible
- [ ] The behavioral quirks (head tilt, stillness, smooth movement) are noticeable
- [ ] The lore connection enriches the experience without being required
- [ ] The design is feasible to implement in Roblox with acceptable performance
- [ ] The name "The Hollow" feels right and is not already taken by a major game
