# Endings and Extraction System — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **System Owner:** Narrative & Systems Lead  
> **Related Documents:** [DAY_05_SIGNAL_AND_ESCAPE.md](file:///i:/RobloxDev/docs/campaign/DAY_05_SIGNAL_AND_ESCAPE.md), [LORE_AND_STORY.md](file:///i:/RobloxDev/docs/systems/LORE_AND_STORY.md), [META_PROGRESSION.md](file:///i:/RobloxDev/docs/systems/META_PROGRESSION.md)

---

## 1. System Vision & Narrative Resolution

Unlike open-ended grind survival games that eventually peter out into boredom, *Project: Undecided* delivers a **climactic 5-day campaign arc**. Players fight toward a definitive, hard-won extraction point. 

The ending resolves the tension established in the Day 0 prologue, granting emotional payoff, social celebration, and distinct rewards based on team survival and decisions.

---

## 2. Ending Matrix & Triggers

| Ending Name | Type | Unlock Conditions | Narrative Outcome | Session Rewards |
|-------------|------|-------------------|-------------------|-----------------|
| **Ending A: "The Signal Evacuation"** | Standard Victory | Survive Night 5; activate Signal Tower with all 3 parts; at least 1 survivor boards the evacuation transport at dawn | A search-and-rescue military transport breaches the fog. Flares guide the survivors aboard as the forest falls away. | 100% Campaign Badge, 250 Embers, "Survivor" Title |
| **Ending B: "The Final Flame" (Heroic)** | Bittersweet Victory | All escape except one player who remains at the tower generator manually cranking the emergency spotlight | The remaining player holds off The Hollow in an epic blaze of light, ensuring their companions reach safety. | "Sacrificial Flame" Rare Badge, 400 Embers (for the martyr), Special Epilogue Cutscene |
| **Ending C: "Consumed by Ash"** | Campaign Failure | Campfire extinguishes completely on Night 5 OR all players wiped out before dawn | The campfire dies. Pitch-black shadows envelop the shelter. The Hollow's ember eyes flare in the dark. Silence. | 25 Embers (consolation), Failure recap screen with day/stat breakdown |
| **Ending D: "The Restored Guardian"** | Secret / Lore Victory | Collect 5 hidden ancient totems across Days 1–5; ignite the ancient shrine with sacred fire instead of calling the tower | The Hollow is not a mindless beast, but a forest spirit tormented by industrial pollution. Sacred fire purifies it, freeing the valley. | "Forest Peacemaker" Ultra-Rare Badge, Ancient Lantern Cosmetic Skin, True Lore Epilogue |

---

## 3. Extraction Sequence Gameplay Flow (Day 5 Dawn)

```text
[04:00 - Night 5 Peak] ──► Monster waves probe defense ──► Hold campfire above 20%
                                                                     │
[05:30 - Dawn Approaching] ──► Siren blares in distance ──► Radio Crackles: "ETA 60 SECONDS"
                                                                     │
[06:00 - Dawn Breaks] ──► Monster retreats into dense deep wood
                                                                     │
[Extraction Zone Opens] ──► Evac vehicle / landing pad active (90s boarding window)
                                                                     │
[Boarding & Escape] ──► All living players step into extraction zone ──► Victory Cutscene
```

---

## 4. Post-Campaign Stats & Debrief Screen

Upon session completion (win or loss), all players transition to the cinematic debrief screen showing:

- **Total Days Survived:** e.g., 5 / 5
- **Wood Chopped & Burned:** Team total
- **The Hollow Encounters Repelled:** Total flares & bright-light stuns
- **Teammates Revived:** Co-op medals awarded
- **Earned Meta-Currency (Embers):** Credited to Roblox player DataStore
- **Replay & Difficulty Select:** "Return to Lobby" or "Play Hardcore Mode" buttons

---

## 5. Disconnect & Late Extraction Edge Cases

1. **Player Dies During Final Boarding:** If 4 players survive and 1 player dies in the final dash, the 4 players can still extract. The dead player receives full completion credit as long as they remained spectating.
2. **Server Crash Protection:** Upon reaching Day 5 dawn, campaign completion is immediately staged in player session data before the cutscene plays, ensuring a server timeout during the cutscene still awards badges and unlocks.

---

## 6. Acceptance Criteria

- [ ] **AC-EXT-01:** Reaching 06:00 on Day 5 with the Signal Tower powered unlocks the extraction transport beacon within 2.0 seconds.
- [ ] **AC-EXT-02:** Stepping into the transport volume triggers the victory sequence and awards the campaign badge to all active and spectating party members.
- [ ] **AC-EXT-03:** If all players die before 06:00, the defeat sequence plays and returns the party cleanly to the main lobby without hanging.
