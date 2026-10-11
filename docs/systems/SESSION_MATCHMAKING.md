# Session Matchmaking — Project: Undecided

> **Status:** `EXISTING_CANON`
> **Last updated:** 2026-10-11

---

## Overview

Players join the game and spawn in a lobby. They choose their session size by entering one of 5 tents. The matchmaking system creates isolated sessions based on tent choice.

---

## Lobby Design

`EXISTING_CANON`

- 5 tents in the lobby, each labeled with player capacity (1–5).
- Each tent has a clear, visible sign showing its capacity.
- Players enter a tent to queue for that session size.

---

## Session Lifecycle State Machine

```
LOBBY → WAITING_IN_TENT → SESSION_STARTING → LOADING → PROLOGUE → DAY_LOOP → END → CLEANUP
```

| State | Description | Transition |
|-------|-------------|-----------|
| `LOBBY` | Player is in the lobby, has not entered a tent | → `WAITING_IN_TENT` (player enters tent) |
| `WAITING_IN_TENT` | Player is in a tent, waiting for others or timer | → `SESSION_STARTING` (tent full OR timer expires) |
| `SESSION_STARTING` | Session is being created (reserved server) | → `LOADING` (server ready) |
| `LOADING` | Players teleport to session server, assets load | → `PROLOGUE` (all loaded or timeout) |
| `PROLOGUE` | Day 0 cutscene plays | → `DAY_LOOP` (cutscene ends) |
| `DAY_LOOP` | Days 1–5 cycle | → `END` (campaign complete or all dead) |
| `END` | Results screen, rewards | → `CLEANUP` (players leave) |
| `CLEANUP` | Session server shuts down | — |

---

## Matchmaking Rules

### Tent Selection
- `EXISTING_CANON` Players choose a tent by physically walking into it.
- `EXISTING_CANON` "If friends enter the same tent together, they should be placed in the same session."
- `EXISTING_CANON` "Players choosing different tents must not be mixed into the same session."

### Session Start Conditions

| Tent | Start Condition |
|------|----------------|
| 1-player | `EXISTING_CANON` Immediately when player enters |
| 2-player | `EXISTING_CANON` When 2 join OR timer expires |
| 3-player | `EXISTING_CANON` When 3 join OR timer expires |
| 4-player | `EXISTING_CANON` When 4 join OR timer expires |
| 5-player | `EXISTING_CANON` When 5 join OR timer expires |

### Timer
- `INITIAL_BALANCE_PROPOSAL` 60 seconds for 2–5 player tents.
- `EXISTING_CANON` "If the timer ends before the tent reaches full capacity, the players already waiting can start their session."
- Solo tent has no timer (instant start).

### Party/Friend Grouping
- Friends in the same tent → same session (use Roblox social graph or manual party system).
- `PROPOSED` Party system: one player creates a party code, others enter it to join the same tent queue.

---

## Session Isolation

- Each session runs on a separate Roblox reserved server (`TeleportService:ReserveServer()`).
- Sessions are completely isolated — no cross-session interaction.
- Maximum 5 players per session server.

---

## Error Handling

| Error | Response |
|-------|----------|
| Teleport fails | Retry 2 times, then return player to lobby with error message |
| Server creation fails | Return all queued players to lobby |
| Player disconnects in tent queue | Remove from queue, adjust count |
| Player disconnects during teleport | Other players continue; session adjusts player count |
| Reserved server crash | Session lost; players return to lobby |

---

## Rejoin Policy

`PROPOSED`

| Scenario | Behavior |
|----------|----------|
| Player disconnects during Day 1–5 | Can rejoin if session is still active (within 5 minutes) |
| Player disconnects, session ends | Cannot rejoin — session is cleaned up |
| Player intentionally leaves | Same as disconnect — can rejoin within window |
| Session is full (5 players) when rejoin attempted | Rejoin replaces the disconnected player's slot |

---

## Implementation Notes

- Use `TeleportService:ReserveServer()` for session creation.
- Use `TeleportService:TeleportToPrivateServer()` for player transport.
- Store session metadata in `MemoryStoreService` (session ID, player list, state).
- Lobby server handles tent queues and party grouping.
- Session server handles gameplay (Days 0–5).
- Validate player count server-side — never trust client-reported counts.

---

## Acceptance Criteria

- [ ] A solo player enters the 1-player tent and immediately starts a session
- [ ] 3 friends enter the 3-player tent and are placed in the same session
- [ ] Timer expires with 2/4 players in the 4-player tent — session starts with 2
- [ ] Players in different tents are NEVER in the same session
- [ ] Teleport failures retry and fall back gracefully
- [ ] Disconnected players can rejoin within the window
