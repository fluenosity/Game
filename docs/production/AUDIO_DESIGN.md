# Audio Design Specification — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Production Lead:** Audio Director & Sound Designer  
> **Related Documents:** [ART_DIRECTION.md](file:///i:/RobloxDev/docs/production/ART_DIRECTION.md), [AUDIO_AND_LIGHTING_PIPELINE.md](file:///i:/RobloxDev/docs/technical/AUDIO_AND_LIGHTING_PIPELINE.md)

---

## 1. Audio Direction & Horror Sound Philosophy

In *Project: Undecided*, audio is the primary sensory tool for suspense. Horror thrives in what players *cannot* see. The sound design follows the principle of **layered contrast**:
- **Day:** Organic, naturalistic, calming (gentle pine wind, distant birds, flowing water).
- **Dusk:** Abrupt silencing of birds; mechanical warning siren echoes from the city.
- **Night:** Oppressive silence punctured by wood crackles, eerie clicking sounds, and close breathing.

---

## 2. Complete Sound Effect Catalog

### 2.1 Environmental & Campfire Audio
| Sound Name | Trigger / State | Acoustic Quality | Attenuation Max Distance |
|------------|-----------------|------------------|--------------------------|
| `Env_DayWind_Loop` | Daytime | Soft breeze rustling through pine needles | 2D Global |
| `Env_DuskSiren_OneShot` | Dusk transition (18:00) | Distant air-raid warning horn from ruined city | 2D Global |
| `Env_NightAmbiance_Loop`| Nighttime | Low subsonic drone (40 Hz), faint distant twig snaps | 2D Global |
| `Fire_Roaring_Loop` | Campfire > 75% fuel | Satisfying, crackling flame with deep warm roar | 35 studs |
| `Fire_Medium_Loop` | Campfire 25%–75% fuel | Standard gentle campfire crackle | 25 studs |
| `Fire_Dying_Loop` | Campfire < 25% fuel | Sparse popping embers, hissing ash, dying wheeze | 15 studs |
| `Fire_Extinguished` | Campfire hits 0% fuel | Sudden sharp sizzle followed by absolute dead silence | 40 studs |

### 2.2 The Monster ("The Hollow") Sound Language
| Sound Name | AI State | Audio Description | Attenuation Distance |
|------------|----------|-------------------|----------------------|
| `Monster_Breathing` | Stalking | Wet, hollow inhaling sound like an empty cavern | 25 studs |
| `Monster_Clicking` | Searching / Probing | Rhythmic dry chitinous throat clicks (echolocation) | 40 studs |
| `Monster_Footstep` | Moving | Heavy, muffled thuds displacing forest dirt | 30 studs |
| `Monster_AlertRoar` | Spotting player | Piercing, unearthly screech combining lion & steam vent | 85 studs (Global ducking) |
| `Monster_LightStun`| Hit by flare / fire | Agonized high-pitched hiss, sharp recoil squeal | 60 studs |
| `Monster_Retreat` | Fleeing | Distant rustling of heavy branches snapping in retreat | 50 studs |

### 2.3 Player & Interaction Audio
| Sound Name | Action | Description |
|------------|--------|-------------|
| `Act_ChopTree` | Chopping tree channel | Crisp hatchet strike biting into hardwood with wood chips |
| `Act_ScrapPickup`| Picking up metal/plastic | Metallic rattle / plastic crunch clink |
| `Act_Heartbeat_Loop` | Player HP < 30% | Deep bass heartbeat accelerating in tempo |
| `Act_ReviveChannel`| Reviving downed player | Rapid bandaging friction accompanied by relief sigh |

---

## 3. Dynamic Reverb Zones

Roblox `ReverbSoundEffect` parameters mapped to physical zones:
- **Open Forest:** `ReverbType = Wooded`, DecayTime = 1.2s (warm, natural absorption).
- **Shelter Courtyard:** `ReverbType = StoneCorridor`, DecayTime = 0.8s (slight slapback against corrugated metal walls).
- **Collapsed Overpass (North):** `ReverbType = ConcreteCourtyard`, DecayTime = 2.4s (echoing, hollow reverb).

---

## 4. Acceptance Criteria

- [ ] **AC-SND-01:** Campfire audio crossfades smoothly between Roaring, Medium, and Dying loops as fuel decreases.
- [ ] **AC-SND-02:** Monster spotting roar triggers priority ducking on ambient loops within 50ms.
- [ ] **AC-SND-03:** Entering the Overpass zone applies correct concrete reverb to player footstep audio.
