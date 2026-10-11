# Gameplay Balance — Project: Undecided

> **Status:** All values are `INITIAL_BALANCE_PROPOSAL` unless noted otherwise.
> **Last updated:** 2026-10-11
> **Rule:** No value in this document is final until validated through playtesting.

---

## Balance Philosophy

1. **Day 1 should be easy.** A first-time player must succeed. Tune for generous margins.
2. **Each day should be slightly harder than the last** — through new challenges, not just inflated numbers.
3. **Solo must be viable.** Don't balance only for 5-player teams.
4. **Resources should feel scarce but not impossible.** Players should worry about running out — but a smart player should always have enough.
5. **The monster should feel dangerous but fair.** Players should understand WHY they died and how to do better.
6. **Mobile and PC should feel equally playable.** Don't give PC an inherent advantage through precision-dependent mechanics.

---

## Time Values

| Parameter | Value | Rationale | Affects |
|-----------|-------|-----------|---------|
| Day 1 daytime duration | 300s (5 min) | Enough for shelter discovery + 2 tree chops with margin | Gathering pressure, exploration window |
| Day 1 night duration | 180s (3 min) | Short first night, not overwhelming | Fire consumption, monster exposure |
| Day 2 daytime duration | 360s (6 min) | Slightly more time for upgrades | Preparation depth |
| Day 2 night duration | 240s (4 min) | Longer night = more fuel pressure | Fire depletion stress |
| Day 3 daytime duration | 420s (7 min) | Extended exploration range | Scavenging, discovery |
| Day 3 night duration | 300s (5 min) | Monster is more active | Sustained fear |
| Day 4 daytime duration | 360s (6 min) | Shorter day creates urgency | Preparation pressure |
| Day 4 night duration | 360s (6 min) | Longest non-final night | Escalation, resource drain |
| Day 5 daytime duration | 420s (7 min) | Final preparations | Escape objective |
| Day 5 night duration | 480s (8 min) | Climactic final stand | Ultimate survival test |
| Nightfall warning time | 60s before night | Player needs time to return | Urgency cue |
| Dawn transition | 10s | Brief, feels earned | Emotional relief |

### Why These Values

- **Days get shorter** toward the end → more pressure, less prep time.
- **Nights get longer** → more fuel consumed, more monster encounters.
- **Total session ~60–75 min** → long for Roblox but appropriate for horror survival.

---

## Fire Values

| Parameter | Value | Rationale | Affects |
|-----------|-------|-----------|---------|
| Campfire Tier 1 protection radius | 15 studs | Covers the basic shelter area | Safe zone size |
| Campfire Tier 2 protection radius | 22 studs | Noticeable improvement | Upgrade value |
| Campfire Tier 3 protection radius | 30 studs | Comfortable but not excessive | Late-game safety |
| Campfire Tier 4 protection radius | 40 studs | `PROPOSED` Final tier | Endgame safety |
| Fuel consumption rate (Tier 1) | 1 wood / 60s | ~3 wood per Day 1 night | Resource demand |
| Fuel consumption rate (Tier 2) | 1 wood / 50s | Higher tier burns faster | Upgrade tradeoff |
| Fuel consumption rate (Tier 3) | 1 wood / 45s | | Scarcity pressure |
| Fuel consumption rate (Tier 4) | 1 wood / 40s | | Maximum burn rate |
| Max fuel capacity (Tier 1) | 5 wood | Enough for one night + margin | Storage limit |
| Max fuel capacity (Tier 2) | 8 wood | | Longer buffer |
| Max fuel capacity (Tier 3) | 12 wood | | Strategic stockpiling |
| Max fuel capacity (Tier 4) | 16 wood | | Endgame capacity |
| Fire ignition time | 3s | Hold-to-light interaction | Input feel |
| Fire extinguish threshold | 0 fuel | Fire goes out when empty | Failure condition |
| Fire warning threshold | 20% fuel remaining | UI warning + flickering visual | Player alert |

### Fire Balance Notes

- **Tier 1 on Day 1:** Player chops 2 trees, gets ~4 wood. Night 1 needs ~3 wood (180s / 60s). Margin of 1 wood. Tight but achievable.
- **Higher tiers burn faster** — this is intentional. Bigger fire = more protection but MORE fuel needed. This is the core tradeoff.
- **Fire going out = extreme danger.** Not instant death, but the monster can now enter the shelter.

---

## Resource Values

| Parameter | Value | Rationale | Affects |
|-----------|-------|-----------|---------|
| Wood per tree | 2 | Simple, predictable | Gathering efficiency |
| Trees available Day 1 | 3 (2 required) | One extra for margin | First-day safety net |
| Trees available Day 2+ | 5–8 per area | Enough for fire + upgrades | Daily supply |
| Tree respawn | Next day (dawn) | Trees regrow each morning | Sustainability |
| Chop time per tree | 5s (hold interaction) | Not tedious, not instant | Pacing, mobile-friendly |
| Scrap nodes per area (Day 3+) | 3–5 | Exploration reward | Crafting/trading supply |
| Scrap per node | 1–2 items | Random variety | Inventory decisions |
| Player carry capacity | 12 slots | Enough for meaningful hauls | Exploration tradeoffs |
| Wood stack size | 4 per slot | | Efficient wood carrying |
| Scrap stack size | 2 per slot | Scrap is bulkier | Carry decisions |

### Resource Balance Notes

- **Day 1 is deliberately simple:** 2 trees = 4 wood = enough for one night. No complex inventory management.
- **Day 3+ creates carry decisions:** Player can carry ~12 items. Wood stacks to 4, scrap to 2. Going further = more stuff but more trip time.
- **Tree respawn prevents softlocks:** Players can never permanently run out of wood.

---

## Monster Values

| Parameter | Value | Rationale | Affects |
|-----------|-------|-----------|---------|
| Monster detection range (visual) | 80 studs | Can see players at distance | Chase initiation |
| Monster detection range (audio) | 40 studs | Hears running/chopping | `PROPOSED` sound mechanic |
| Monster movement speed (patrol) | 8 studs/s | Slow, deliberate wandering | Atmosphere |
| Monster movement speed (chase) | 18 studs/s | Faster than player sprint | Chase lethality |
| Player walk speed | 12 studs/s | | Base movement |
| Player sprint speed | 20 studs/s | Slightly faster than monster chase | Escape possibility |
| Sprint duration | 5s | Limited stamina | Can't sprint forever |
| Sprint cooldown | 8s | Recovery time | Strategic sprinting |
| Monster fire avoidance radius | Protection radius + 5 studs | Stays further from strong fires | Fire effectiveness |
| Monster attack damage | 50 HP | One-hit at half health | Danger level |
| Monster attack cooldown | 3s | Time between attacks | Survival window |
| Player max HP | 100 HP | | Standard health |
| Monster retreat after fire exposure | 10s | Runs away after fire deters it | Relief window |

### Monster Balance Notes

- **Player sprint (20) > Monster chase (18)** — but sprint is LIMITED (5s). Player can outrun the monster briefly but not indefinitely. This creates chase tension without guaranteed death.
- **Monster attacks deal 50 damage** — players survive 2 hits. First hit = urgent warning. Second hit = death. Fair but punishing.
- **Fire avoidance is absolute** — the monster will NEVER enter a lit fire's radius. This is the core safety guarantee. (Until Day 4+ escalation, `PROPOSED`.)

---

## Upgrade Costs

| Upgrade | Cost | Available | Effect |
|---------|------|-----------|--------|
| Campfire Tier 1 → Tier 2 | 6 wood + 2 metal scrap | Day 2+ | +7 stud radius, faster consumption |
| Campfire Tier 2 → Tier 3 | 10 wood + 4 metal + 2 rope | Day 3+ | +8 stud radius |
| Campfire Tier 3 → Tier 4 | 15 wood + 6 metal + 4 plastic + 2 rope | Day 4+ | +10 stud radius |
| Basic wall repair | 4 wood + 2 metal | Day 2+ | `PROPOSED` Slows monster approach |
| Storage box | 6 wood + 2 plastic | Day 3+ | +8 storage slots |
| Reinforced fence | 8 metal + 4 rope | Day 3+ | `PROPOSED` Delays monster entry |

### Upgrade Balance Notes

- Costs scale with day — early upgrades are cheap (wood only), later ones require scrap.
- Players must choose: spend resources on upgrades or keep them as fuel/supplies.
- Every upgrade has a clear, immediate gameplay benefit.

---

## Matchmaking Values

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Matchmaking wait timer (2–5 player tents) | 60s | Long enough for friends to join, short enough not to frustrate |
| Solo tent wait time | 0s (instant) | No reason to wait |
| Min players to start (multi tent) | 1 (when timer expires) | Don't force players to wait forever |
| Max session size | 5 | Per design doc |

---

## Co-op Scaling

| Parameter | Solo | 2 Players | 3 Players | 4 Players | 5 Players |
|-----------|------|-----------|-----------|-----------|-----------|
| Trees available | Base | +25% | +40% | +50% | +60% |
| Scrap nodes | Base | +20% | +35% | +45% | +55% |
| Monster aggression | Base | +10% | +20% | +30% | +40% |
| Night duration | Base | +0% | +5% | +10% | +15% |
| Fire consumption | Base | +0% | +10% | +15% | +20% |

### Co-op Scaling Notes

- **More players = more resources available BUT harder monster and faster fire consumption.**
- The game should NOT become trivially easy with 5 players.
- More players = more things to manage, not just "more hands."

---

## Testing Protocol for Balance

For each value in this document:

1. **Test with extreme values first** — double it, halve it. Does the game break?
2. **Test solo AND 5-player** — both must feel balanced.
3. **Test on mobile** — timing-critical values must be achievable on touch controls.
4. **Record player behavior** — are players running out of time? Resources? Or having too much?
5. **Adjust ONE value at a time** — never change multiple values simultaneously.
6. **Document every change** — what was changed, why, what effect it had.

---

## Unresolved Balance Questions

| # | Question | Dependencies |
|---|----------|-------------|
| 1 | Are 5-minute days long enough for exploration? | Map size, resource placement |
| 2 | Is 3-minute Night 1 too short to feel scary? | Monster behavior, sound design |
| 3 | Should fire consumption scale with protection radius? | Fire system implementation |
| 4 | Is 60-second matchmaking timer right for Roblox? | Player behavior data |
| 5 | Should monster speed increase each night? | Monster AI, difficulty curve |
| 6 | Is 12-slot inventory too generous or too tight? | Crafting recipes, resource variety |
