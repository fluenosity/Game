# Cooperation and Parties System — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **System Owner:** Multiplayer Design & Co-op Lead  
> **Related Documents:** [SESSION_MATCHMAKING.md](file:///i:/RobloxDev/docs/systems/SESSION_MATCHMAKING.md), [PLAYER_HEALTH_AND_DEATH.md](file:///i:/RobloxDev/docs/systems/PLAYER_HEALTH_AND_DEATH.md), [MONSTER_AI.md](file:///i:/RobloxDev/docs/systems/MONSTER_AI.md)

---

## 1. System Vision & Party Scaling

*Project: Undecided* is engineered to support **1 to 5 players seamlessly**. The experience must feel intense and lonely for a solo player, while delivering frantic, coordinated dread for a full party of five friends.

### Co-op Dynamic Scaling Matrix

| Metric | 1 Player (Solo) | 2–3 Players | 4–5 Players (Full Party) |
|--------|-----------------|-------------|--------------------------|
| **Base Campfire Fuel Burn** | 0.15 fuel/sec | 0.20 fuel/sec | 0.26 fuel/sec |
| **Wood Yield per Tree** | 3 wood | 2 wood | 2 wood |
| **Daytime Length** | 220 seconds | 200 seconds | 180 seconds |
| **Nighttime Length** | 90 seconds | 100 seconds | 120 seconds |
| **Monster Max Health / Stun Threshold** | Stunned by 1 flare | Stunned by 2 flares | Stunned by 3 flares |
| **Monster Stalkers** | 1 Hollow entity | 1 Hollow entity | 1 Hollow entity + 2 Shadow Stalker Minions (Day 4+) |
| **Resource Nodes Spawned** | 60% density | 100% density | 140% density |

*(All tuning values marked `INITIAL_BALANCE_PROPOSAL`)*

---

## 2. Downed State & Revival Mechanics

When a player's HP reaches 0, they do not die instantly unless killed by an unmitigated monster execute in complete darkness.

```text
[Healthy HP] ──Damage──► [Downed / Bleeding Out] ──Revived──► [Injured State (40% HP)]
                                   │
                           Bleedout Timer (45s)
                           or Monster Execute
                                   ▼
                            [Eliminated / Spectating]
```

### Revival Rules
1. **Bleedout Duration:** 45 seconds (`INITIAL_BALANCE_PROPOSAL`). Downed player can crawl slowly (4 studs/sec) toward the campfire.
2. **Revive Action:** An active teammate holds interaction key / button for 4.0 seconds while within 6 studs of the downed player.
3. **Revive Interruption:** Taking damage immediately cancels the revive channel.
4. **Bandage Boost:** Using a First Aid Bandage reduces revive channel time to 1.5 seconds and restores 70% HP.
5. **Solo Protection:** In solo mode, a downed player with an active Campfire above 50% fuel self-revives once per day with a "Will to Survive" second-chance mechanic.

---

## 3. Communication & Contextual Ping System

Because over 60% of Roblox players are on mobile or console without active voice chat, a fast, one-tap **Contextual Ping System** is critical:

- **Controls:** Middle Mouse Click (PC), Screen Reticle Tap (Mobile), Right Bumper (Controller).
- **Contextual Types:**
  - **Tree / Scrap Node:** *"Gather here!"* (Green waypoint icon).
  - **Campfire Low Fuel:** *"Fuel needed!"* (Amber flame icon).
  - **The Hollow Sighting:** *"Monster spotted!"* (Red danger eye icon, accompanied by a sharp warning chime).
  - **Downed Player:** Automatic pulsing red emergency cross beacon with distance indicator in studs.

---

## 4. Organic Team Roles (Emergent, No Rigid Classes)

Rather than forcing restrictive RPG classes, roles emerge naturally through player choices and gear:

1. **The Firekeeper (Stoker):** Remains close to the shelter, monitors fuel meters, operates the workbench, and fortifies the perimeter fences.
2. **The Forest Scout:** Equips light footwear/stamina gear, maps outer landmark nodes, and marks high-value salvage for the haulers.
3. **The Hauler:** Carries high-capacity backpacks, retrieves wood and metal in coordinated convoys.
4. **The Vanguard:** Holds flares and torches, escorts haulers, and creates light barriers when the monster probes the perimeter.

---

## 5. Acceptance Criteria

- [ ] **AC-COOP-01:** Scaling correctly adjusts tree wood yield and fuel consumption based on session player count upon day start.
- [ ] **AC-COOP-02:** Downed players can crawl toward the shelter and receive revives from teammates.
- [ ] **AC-COOP-03:** Pinging a monster alerts all party members with spatial audio and a visible HUD indicator.
- [ ] **AC-COOP-04:** In solo sessions, the single player can complete all objectives without feeling penalized by multi-person puzzle gates.
