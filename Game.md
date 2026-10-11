# 🎮 Game Design Document — Survival Horror (Roblox)

---

## 1. Game Overview

- **Genre:** Survival Horror
- **Platform:** Roblox
- **Players:** 1–5 (solo or co-op)
- **Core Theme:** A monster terrorizes a ruined city. The only thing it fears is **fire**. Players must escape to a forest, find shelter, and survive night after night by gathering resources, building campfires, and upgrading their base.

---

## 2. Lobby — How to Choose a Session

When players join the game, they spawn in a basic Roblox-style lobby with **5 tents**, each representing a different session size: 1, 2, 3, 4, or 5 players.

- Each tent has a clear sign showing its player capacity.
- Players choose their preferred session by entering the corresponding tent.

| Tent | Capacity |
|------|----------|
| 1-player tent | Solo session |
| 2-player tent | Up to 2 players |
| 3-player tent | Up to 3 players |
| 4-player tent | Up to 4 players |
| 5-player tent | Up to 5 players |

### Rules

- Friends who enter the same tent together are placed in the **same session**.
- Players in different tents are **never** mixed into the same session.
- The maximum number of players in any session is **5**.

---

## 3. How a Session Starts

- **1-player tent:** The session starts **immediately** when one player enters.
- **2-player tent:** Starts when 2 players join, or when the waiting timer ends.
- **3-player tent:** Starts when 3 players join, or when the waiting timer ends.
- **4-player tent:** Starts when 4 players join, or when the waiting timer ends.
- **5-player tent:** Starts when 5 players join, or when the waiting timer ends.

> If the timer ends before the tent reaches full capacity, the players already waiting start their session without waiting for more players.

Friends who enter the same tent together are always placed in the same session. Each session starts separately from the others.

---

## 4. Opening Cutscene (10–15 seconds)

This is the **first thing players see** when their session begins.

### Setting

A small city in complete ruins — broken buildings, cars crashed into walls, debris scattered across the streets, fires burning in some areas. If possible, include people running around in fear for realism; otherwise the destruction alone is enough.

### What Happens

1. The camera shows the destroyed, chaotic city.
2. A **huge monster suddenly appears from behind a building**.
3. It looks around the city and notices a **massive fire** burning on a nearby building.
4. The monster becomes **frightened** by the fire and immediately runs away, disappearing behind the buildings.

### Purpose

- Introduce the monster.
- Establish the dark, chaotic atmosphere.
- Show the player — without any dialogue — that **the monster is afraid of fire**. This is the player's first survival clue.

> The cutscene should feel cinematic, slightly scary, and easy to understand.

---

## 5. Day 1

### 5.1 Opening Scene — Escape to the Forest

Day 1 begins with a short cutscene showing the player character running desperately towards a forest to escape. After the scene ends, the camera switches to **first-person perspective (FPP)** and the player gains full control.

### 5.2 First Task — Find Shelter

- The player's first objective is to find a shelter in the forest.
- There is **only one clear path** leading to it — no puzzles, no confusing routes.
- The entire sequence happens during **daytime** with enough natural light.

### 5.3 The Shelter

The shelter is a small, abandoned yard surrounded by a **metal mesh / chain-link fence**. It feels damaged but usable as a temporary safe place.

**Contents of the yard:**

| Item | Purpose |
|------|---------|
| Old, broken sofa | Player sleeps here to end the day |
| Simple table | Basic furniture |
| Campfire spot | Clearly visible fire pit (circular stones / ashes) where the player burns wood |

> The campfire location must be **immediately obvious** when the player enters the yard. No searching required.

### 5.4 Second Task — Collect Wood

- After finding the shelter, the player must walk into the forest to collect firewood.
- Find **2 trees** that can be chopped down, break them, and carry the wood back to the shelter.
- Keep this simple — trees are easy to locate, and the purpose of the wood (lighting the campfire) is clear.

### 5.5 Nightfall — Return to Shelter

- As the sun sets, the environment gradually **darkens**, creating urgency.
- The player must return to the shelter **before nightfall** and use the wood to light the campfire.
- The fire is the player's **main protection** — the monster fears fire.
- A clear on-screen objective reminds the player to return as night approaches.
- The player should have **enough time** to complete everything without feeling rushed on Day 1.

### 5.6 End of Day 1

1. The player successfully lights the campfire and survives the night.
2. The player sits or lies on the old sofa and falls asleep.
3. The screen **fades to black**.
4. The player wakes up on the same sofa — the game displays **"DAY 2"**.

> **Day 1 Gameplay Loop:** Find shelter → Collect 2 trees of wood → Return before nightfall → Light campfire → Survive until morning.
>
> Day 1 acts as a **simple introduction** to the core gameplay — no complicated mechanics, difficult exploration, or unnecessary challenges.

---

## 6. Day 2

### Morning

- The player must go out and **chop more wood**.
- The collected wood is used to **upgrade the campfire** to stronger, larger flames.
- A bigger fire creates a **larger safe zone** around the shelter.

> *(Morning wood-gathering is a daily routine that repeats every day.)*

### Night

- The upgraded campfire provides better protection.
- The monster may come closer or behave more aggressively than Day 1 — raising the stakes.

---

## 7. Day 3 and Beyond

### Morning

- Chop wood (daily routine continues).
- **New mechanic:** The player can now **scavenge the forest** for useful materials:
  - Metal scraps
  - Plastic
  - Rope
  - Other salvageable items

### Trading

- A **wandering trader** visits the player's camp.
- Players can **sell scrap items** to the trader in exchange for:
  - Better campfire fuel
  - Base upgrade parts (walls, storage, etc.)

### Upgrades

- **Campfire upgrades** — stronger fire, longer burn time, larger safe zone.
- **Base upgrades** — better walls, storage containers, expanded shelter area.

> The gameplay loop expands each day: gather → scavenge → trade → upgrade → survive the night.

---

## 8. Market Research & Current Landscape (2025–2026)

### Genre Health

Survival horror is **one of the strongest genres on Roblox right now**. The top games in this space consistently pull millions of concurrent players. Trending titles that prove the demand:

| Game | What It Does Well | Peak / Scale |
|------|-------------------|-------------|
| **DOORS** | Polish, sound-based gameplay, trial-and-error design | Billions of visits, pillar of the genre |
| **The Mimic** | Deep lore, Japanese folklore, immersive storytelling | Top horror experience, massive YouTube/TikTok presence |
| **Pressure** | Dark, intense survival, high-quality production | Consistently ranked alongside DOORS |
| **Apeirophobia** | Liminal space horror, exploration + puzzles | Trending "eerie atmosphere" niche |
| **99 Nights in the Forest** | Forest survival, campfire, base defense, co-op | **14.2 million peak concurrent players**, billions of visits |
| **3008** | Open-world survival in infinite IKEA, base building at night | Massive and long-running hit |
| **Dandy's World** | Mascot horror, teamwork-focused survival | Trending co-op horror |

### What's Working in 2026

The most successful horror games have moved beyond simple jumpscares. Trending titles now prioritize:

- **Clear survival mechanics** — limited resources, hunger, fire management
- **Teamwork / co-op** — designed for friend groups, social tension
- **Atmosphere & sound design** — lighting, audio cues create real tension
- **Narrative & lore** — mystery, backstory, things players can theorize about
- **Low-friction entry** — players understand the game within 10 seconds
- **Frequent updates** — new content every 2–4 weeks keeps players returning

### Roblox Player Demographics

| Age Group | % of Players |
|-----------|-------------|
| Under 13 | 35% |
| 13–17 | 38% |
| 18+ | 27% |

- Over **50% of users are 13+**, and the 17–24 segment is the fastest growing.
- ~60% of Roblox players are on **mobile** — games MUST run well on phones.
- Horror is popular across all age groups, but should avoid excessive gore (focus on atmosphere instead).

---

## 9. Direct Competitor — 99 Nights in the Forest

> ⚠️ **This is the game's biggest threat.** The core concept is nearly identical.

### Side-by-Side Comparison

| Feature | 99 Nights in the Forest | Our Game |
|---------|------------------------|----------|
| Forest survival + campfire | ✅ | ✅ |
| Monster fears fire | ✅ (the "Deer") | ✅ |
| Day/night cycle | ✅ | ✅ |
| Resource gathering (wood, metal) | ✅ | ✅ |
| Base building / upgrading | ✅ | ✅ |
| Co-op multiplayer | ✅ | ✅ |
| Clear end goal (99 nights + rescue children) | ✅ | ❌ Missing |
| Named, iconic monster | ✅ ("The Deer") | ❌ Missing |
| Lore / backstory | ✅ | ❌ Missing |
| Peak concurrent players | **14.2 million** | — |
| Lifetime visits | **Billions** | — |

### What This Means

If we launch the game as-is, players will likely call it a **"99 Nights clone"** and leave. The genre is proven (14.2M peak proves players WANT this), but we **must** have our own identity.

---

## 10. What the Game Currently Lacks

### 10.1 No Unique Hook

There is currently no mechanic that a player can't already get from 99 Nights in the Forest. The game needs **one signature mechanic** that belongs to it alone.

### 10.2 No End Goal

99 Nights has "survive 99 nights + rescue 4 children." Our game has… survive indefinitely? Players need a **finish line** or a clear reason to keep playing.

### 10.3 No "Shareable Moment"

The #1 driver of Roblox virality is TikTok/YouTube clips. What moment in this game would someone record and post? Jump scares? A crazy chase? A wild base? Right now there's nothing that screams "I NEED to clip this."

### 10.4 No Monster Identity

The "Deer" from 99 Nights is iconic — players recognize it, fear it, meme about it. Our monster has no name, no unique design, no memorable behavior. It needs an **identity**.

### 10.5 No Mobile Optimization Plan

~60% of Roblox players are on mobile. First-person survival with tree chopping needs to feel good on a phone touchscreen. This must be considered from the start.

### 10.6 No Retention Systems

No daily rewards, no unlockables, no progression that carries between sessions. Players finish one run and have no reason to come back.

### 10.7 No Update / Content Plan

Games that blow up on Roblox drop updates every 2–4 weeks. One-and-done games die fast. We need a roadmap for post-launch content.

---

## 11. Differentiation Strategy — How to Make It Unique

These are ideas to separate this game from 99 Nights and everything else on Roblox:

### 11.1 Unique Mechanics (Pick at least 2–3)

| Idea | Description | Why It's Unique |
|------|-------------|----------------|
| **Fire is alive** | The campfire is a depleting resource — it slowly dies through the night. Players must actively feed it wood mid-night, not just "set and forget." | Most games let you be safe once you light the fire. This adds constant tension. |
| **The monster learns** | Each night the monster gets braver — tolerates small fires, finds new routes, tests your defenses. | Forces upgrades to feel *necessary*, not optional. Escalating, adaptive threat. |
| **Sound-based detection** | Chopping wood, running, or building makes noise that attracts the monster — even during daytime. | Makes every action a risk/reward decision. Very few Roblox games do this. |
| **Permadeath / roguelike** | If you die, you restart from Day 1 but keep some meta-progression (blueprints, skills unlocked). | Creates real stakes. Pressure on Roblox proved this model works. |
| **Fire attracts OTHER threats** | While fire keeps the main monster away, it attracts smaller creatures (moths, fire spirits, scavengers) that try to steal your resources. | Adds a dilemma — fire is both protection AND a risk. |
| **Asymmetric co-op roles** | Players choose roles: Builder, Scout, Fire-Keeper, Fighter. Each has unique abilities. | Makes co-op meaningful instead of "4 people doing the same thing." |

### 11.2 Story & Lore

- **Give the monster a name and backstory** — what is it? Where did it come from? Why does it fear fire?
- **Scatter clues in the forest** — notes, recordings, drawings left by previous survivors that reveal the story piece by piece.
- **Hidden ending** — if players collect all clues and survive long enough, they discover the truth and can choose to fight or escape.
- **Why this matters:** The Mimic became massive because of its lore. Players make YouTube theory videos = free marketing.

### 11.3 Clear End Goal

Options:

| End Goal | Description |
|----------|-------------|
| **Survive X nights** | "Survive 30 nights and build a signal fire to call for rescue." Clear, achievable. |
| **Defeat the monster** | After enough upgrades, players can craft a weapon or trap to confront the monster in a final boss fight. |
| **Escape the forest** | Build a vehicle, clear a path, or find a hidden exit. The forest is a prison, not just a setting. |
| **Multiple endings** | Different outcomes based on choices — escape alone, save everyone, discover the truth, or become the monster. |

### 11.4 "Clip-Worthy" Moments

Design specific moments that players will want to record:

- **Near-death fire mechanic** — the campfire flickers and almost dies while the monster circles closer. Visual and audio tension.
- **Chase sequences** — if caught outside at night, a scripted escape run with obstacles and close calls.
- **Base destruction events** — a special night where the monster attacks the base directly and players must defend.
- **Jump scare moments** — rare, unpredictable encounters during daytime scavenging.

---

## 12. Virality & Marketing Plan

### 12.1 Pre-Launch (4–6 weeks before release)

- [ ] Create TikTok / YouTube Shorts account for the game
- [ ] Post behind-the-scenes dev clips: monster design, map flyovers, fire mechanics
- [ ] Build a Discord server and invite early testers
- [ ] Contact 3–5 Roblox micro-influencers for launch-day playthroughs
- [ ] Design a high-quality, eye-catching game thumbnail and icon (A/B test multiple versions)

### 12.2 Launch Day

- [ ] Coordinate a simultaneous player spike (influencers + Discord + social media all go live at the same time)
- [ ] A big initial spike tells the Roblox algorithm to promote the game organically
- [ ] Have a launch-day event or bonus (exclusive item, double resources, etc.)

### 12.3 Post-Launch

- [ ] Drop updates every **2–4 weeks** (new items, new nights, new threats, seasonal events)
- [ ] Respond to player feedback fast — fix bugs within days, not weeks
- [ ] Track retention using Roblox **Creator Analytics** — find where players drop off and fix it
- [ ] Create "shareable" update content for TikTok with each patch

### 12.4 The TikTok Test

> **Ask yourself:** "Is there a 15-second clip from this game that would get 100K views on TikTok?"
>
> If the answer is no, add something that makes it yes.

---

## 13. Retention & Progression Systems

To keep players coming back:

| System | Description |
|--------|-------------|
| **Daily login rewards** | Small bonuses for returning each day (extra wood, rare materials, cosmetics) |
| **Achievement badges** | "Survived 10 nights", "Built max-level base", "Defeated the monster" |
| **Cosmetic unlocks** | Skins, campfire styles, shelter decorations earned through gameplay |
| **Leaderboards** | "Most nights survived", "Fastest Day 30 clear", "Most resources collected" |
| **Season pass / battle pass** | Optional progression track with free + premium tiers (Roblox standard) |
| **Meta-progression** | Even after a run ends, keep some unlocks — blueprints, skill points, cosmetic items |

---

## 14. Mobile Optimization Notes

Since ~60% of Roblox players are on mobile:

- [ ] Design UI for **touchscreen** — large buttons, clear icons, no tiny text
- [ ] Simplify tree chopping to **tap-and-hold** or **auto-chop when near a tree**
- [ ] Ensure the game runs at **stable 30+ FPS** on mid-range phones
- [ ] Minimize particle effects and lighting complexity on lower-end devices
- [ ] Test all mechanics on mobile **before** PC — mobile is the primary platform

---

## 15. Future Ideas & Roadmap

### Phase 1 — Core Game (Launch)
- [ ] Lobby with tent session system
- [ ] Opening cutscene
- [ ] Day 1–5 gameplay loop (shelter, wood, campfire, survival)
- [ ] Basic monster AI
- [ ] Basic trading with wandering trader
- [ ] Save system

### Phase 2 — Content Update 1 (2–3 weeks post-launch)
- [ ] Days 6–15 content (new resources, new crafting recipes)
- [ ] Monster behavior escalation (learns, adapts)
- [ ] Lore items scattered in forest (notes, drawings)
- [ ] 2–3 new base upgrade tiers
- [ ] Bug fixes from launch feedback

### Phase 3 — Content Update 2 (5–6 weeks post-launch)
- [ ] Days 16–30 content
- [ ] New threat types (smaller creatures attracted to fire)
- [ ] Co-op role system (Builder, Scout, Fire-Keeper, Fighter)
- [ ] Endgame goal implementation (signal fire rescue / boss fight)
- [ ] Seasonal event (Halloween / winter theme)

### Phase 4 — Endgame & Polish (8–10 weeks post-launch)
- [ ] Multiple endings based on player choices
- [ ] Full lore reveal
- [ ] Cosmetic shop / battle pass
- [ ] Leaderboards
- [ ] Community-requested features

---

## 16. Final Verdict & Key Takeaways

| Factor | Rating | Notes |
|--------|--------|-------|
| Genre demand | ⭐⭐⭐⭐⭐ | Survival horror is BOOMING on Roblox right now |
| Current uniqueness | ⭐⭐ | Too similar to 99 Nights in the Forest as-is |
| Will people try it? | ⭐⭐⭐ | Yes if marketed well, but they won't stay without a hook |
| Will it boom? | ⭐⭐ | Not as-is — needs differentiation + marketing + content plan |
| Potential if improved | ⭐⭐⭐⭐ | The foundation is solid. With the right hook, it can absolutely work |

### The One-Line Pitch We Need

> *"The fire is dying. The monster is learning. How many nights can you last?"*

This turns it from a generic building game into a **tension game** — which is what performs best in Roblox horror.

### Top 3 Priorities Before Building

1. **Pick a unique hook** — choose 2–3 mechanics from Section 11.1 that no competitor has
2. **Name and design the monster** — give it an identity players will remember and fear
3. **Define the end goal** — what are players working toward? Give them a finish line
