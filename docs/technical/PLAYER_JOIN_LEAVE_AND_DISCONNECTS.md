# Player Join, Leave & Disconnect Lifecycle — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Session Engineering & Networking Lead  
> **Related Documents:** [MATCH_LIFECYCLE_AND_STATE_MACHINES.md](file:///i:/RobloxDev/docs/technical/MATCH_LIFECYCLE_AND_STATE_MACHINES.md), [SERVER_AUTHORITY_AND_SECURITY.md](file:///i:/RobloxDev/docs/technical/SERVER_AUTHORITY_AND_SECURITY.md), [COOPERATION_AND_PARTIES.md](file:///i:/RobloxDev/docs/systems/COOPERATION_AND_PARTIES.md)

---

## 1. System Philosophy & Objectives

In multiplayer survival horror, network drops and crashes are inevitable. A robust multiplayer architecture must guarantee:
1. **Zero Softlocks:** A disconnected player carrying the only Tower Battery or remaining wood must never prevent their surviving teammates from finishing the campaign.
2. **Graceful Reconnection:** Legitimate crashes or quick mobile reconnects should allow players to rejoin their ongoing party.
3. **Anti-Combat Logging:** Players cannot avoid death by Alt-F4 / closing the app when The Hollow attacks.

---

## 2. Player Join States

```text
[Player Connects to Server]
              │
    Is Game in Lobby Phase?
    ├─ YES ──► Assign to Lobby Tent (1–5 selection)
    │
    └─ NO (Match Already Running)
              │
       Is Player in Session Reservation List?
       ├─ YES (Rejoining Member) ──► Rehydrate Session State & Spawn at Shelter
       │
       └─ NO (Late Random Joiner)
              ├─ Campaign Open Slot? ──► Spawn in Spectator / Wait for Next Day Dawn
              └─ Campaign Full/Closed ──► Teleport back to Main Lobby
```

---

## 3. Disconnect Handling Matrix Across Match Phases

| Match Phase | Disconnect Event | Game Engine Response | Item & Inventory Handling |
|-------------|------------------|----------------------|---------------------------|
| **Lobby Tent** | Player leaves tent or server | Frees tent slot; resets countdown timer if team drops below full | None |
| **Prologue (Day 0)** | Player disconnects during cutscene | Cinematic continues for remaining players; if all leave, session cancels | None |
| **Daytime (Gathering)** | Player disconnects while in forest | Character despawns after 5.0s combat-log grace period | Carried quest items & wood deposited directly into Shelter Storage Trunk. If trunk full, drops at shelter doorway. |
| **Nighttime (Defense)** | Player disconnects during monster attack | Character remains vulnerable in world for 10.0s (Anti-Combat Log). Monster can down them. | If eliminated, drops items in place; if survives 10s, items transfer to shelter trunk. |
| **Downed / Bleedout** | Player disconnects while bleeding out | Immediate death state recorded. Items drop at current position. | Items drop at bleedout coordinates. |
| **Extraction (Day 5)** | Player disconnects during final escape | Remaining players continue extraction. Disconnected player earns partial completion credit if they spent ≥80% of session active. | Quest items already installed at tower. |

---

## 4. Reconnection & Rejoining Policy

- **Session Reservation Window:** 120 seconds (`INITIAL_BALANCE_PROPOSAL`).
- When a player disconnects, `SessionService` reserves their party slot for 2 minutes.
- If the player relaunches Roblox and enters the experience, the lobby automatically detects their active reservation via `MemoryStoreService` and prompts:
  > *"Your party is still surviving in Day 3! [ Rejoin Session ] or [ Abandon Party ]"*
- **Rehydration:**
  - Upon rejoining, the player spawns inside the fenced shelter near the sofa with 50% HP.
  - Carried inventory is restored from their assigned slot in the shelter trunk.

---

## 5. Party Leader Disconnect & Migration

In *Project: Undecided*, party leadership is purely an administrative role (controlling lobby tent start timers):
1. If the Party Leader disconnects, the server migrates leadership to the player with the longest active session duration.
2. In-game voting (e.g. initiating campaign sleep or difficult mutator choices) uses a simple majority poll (`>50% of living players`), meaning a missing leader can never stall game progress.

---

## 6. Acceptance Criteria

- [ ] **AC-DISC-01:** Disconnecting while carrying a quest item safely transfers the item into the Shelter Storage Trunk within 1.0 second.
- [ ] **AC-DISC-02:** Rejoining within 120 seconds returns the player to the active session without resetting the day or fire state.
- [ ] **AC-DISC-03:** Disconnecting while being targeted by the monster leaves the character model in world for 10 seconds to prevent combat logging.
- [ ] **AC-DISC-04:** If all 5 players disconnect, the server cleanly releases Profile locks and shuts down the instance within 30 seconds.
