# Match Lifecycle & State Machines — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Session Orchestration Lead  
> **Related Documents:** [SESSION_MATCHMAKING.md](file:///i:/RobloxDev/docs/systems/SESSION_MATCHMAKING.md), [DAY_NIGHT_CYCLE.md](file:///i:/RobloxDev/docs/systems/DAY_NIGHT_CYCLE.md), [TECHNICAL_OVERVIEW.md](file:///i:/RobloxDev/docs/technical/TECHNICAL_OVERVIEW.md)

---

## 1. Global Match Lifecycle FSM

The match lifecycle coordinates server initialization, lobby matchmaking, the 5-day survival progression, and game teardown. The entire lifecycle is governed by an authoritative server Finite State Machine (FSM):

```text
 ┌──────────────────────┐
 │  WAITING_FOR_PLAYERS │◄── (Lobby tent occupancy check)
 └──────────┬───────────┘
            │ Party full OR timer expires (Solo: Instant)
            ▼
 ┌──────────────────────┐
 │   PREPARING_SESSION  │──► (Allocate ReservedServer / Teleport if multi-place)
 └──────────┬───────────┘
            │ Assets preloaded, players spawned
            ▼
 ┌──────────────────────┐
 │       PROLOGUE       │──► (Day 0: City ruins cutscene & forest escape)
 └──────────┬───────────┘
            │ Players reach shelter gate OR skip timeout
            ▼
 ┌──────────────────────┐
 │       DAY_LOOP       │◄───┐
 └──────────┬───────────┘    │
            │ Advance Day    │ Repeat Days 1–5
            ▼                │
   [Dawn / Sleep Check] ─────┘
            │
            ├─ All Players Dead / Fire Extinguished ──► [CAMPAIGN_FAILED]
            │
            └─ Day 5 Escape Transport Boarded ────────► [CAMPAIGN_SUCCESS]
                                                              │
                                                              ▼
                                                    ┌──────────────────┐
                                                    │ DEBRIEF_&_CLEANUP│
                                                    └──────────────────┘
```

---

## 2. State Specification Table

| State Name | Entry Conditions | Exit Conditions | Timeout / Guard | Fallback on Timeout |
|------------|------------------|-----------------|-----------------|---------------------|
| `WAITING_FOR_PLAYERS` | Server booted, lobby tent created | Party hits max (1–5) OR countdown reaches 0 | 60s max wait for partial party; 0s for Solo tent | Launches with current partial team |
| `PREPARING_SESSION` | Party locked | All client character models streamed and loaded | 15s max loading gate | Force spawn loaded players; spectate late joiners |
| `PROLOGUE` | Session prepared | Day 0 cinematic finishes OR players reach forest fence | 90s hard limit on cutscene | Force teleport to Day 1 forest starting point |
| `DAY_LOOP: DAYTIME` | Dawn triggers / Sleep interaction | Daytime clock reaches zero (Dusk) | 180s–220s (player-scaled) | Transition automatically to Dusk warnings |
| `DAY_LOOP: DUSK` | Daytime clock reaches 0 | Dusk transition (30s) expires | 30s | Transition to Nighttime |
| `DAY_LOOP: NIGHT` | Dusk finishes | Night clock reaches 0 (Dawn) | 90s–120s | Trigger Dawn |
| `DAY_LOOP: DAWN` | Night timer reaches 0 & monster retreats | Players interact with sofa to Sleep | 60s optional scavenging | Force sleep & transition to next day |
| `CAMPAIGN_SUCCESS` | Extraction transport departs at Day 5 | Debrief stats confirmed, badges awarded | 45s debrief modal | Teleport party back to lobby |
| `CAMPAIGN_FAILED` | All players dead OR fire out in complete dark | Defeat cutscene ends | 30s | Teleport party back to lobby |
| `CLEANUP` | Post-game completed | Session data stored to DataStores | 10s | Server closes / recycle instance |

---

## 3. Idempotent State Transitions

To ensure a network hiccup or rapid duplicate remote does not trigger multiple state advancements:

```lua
-- Authoritative state machine guard
local MatchState = {
    Current = "WAITING_FOR_PLAYERS",
    IsTransitioning = false
}

function MatchState.TransitionTo(newState: string): boolean
    if MatchState.IsTransitioning then
        warn("Ignored concurrent state transition attempt to:", newState)
        return false
    end
    
    if not ValidTransitions[MatchState.Current][newState] then
        error(string.format("Illegal transition: %s -> %s", MatchState.Current, newState))
        return false
    end
    
    MatchState.IsTransitioning = true
    
    -- Execute exit hook
    OnStateExit(MatchState.Current)
    
    MatchState.Current = newState
    Workspace:SetAttribute("CurrentMatchState", newState)
    
    -- Execute enter hook
    OnStateEnter(newState)
    
    MatchState.IsTransitioning = false
    return true
end
```

---

## 4. Acceptance Criteria

- [ ] **AC-LIFE-01:** Entering solo tent triggers immediate transition to `PREPARING_SESSION` within 0.1s.
- [ ] **AC-LIFE-02:** Entering a 4-player tent starts a 60-second countdown; filling all 4 slots transitions immediately.
- [ ] **AC-LIFE-03:** Disconnecting party leader does not abort match progression; session leadership migrates to next player.
- [ ] **AC-LIFE-04:** State transitions are verified to be strictly idempotent with zero duplicate day advancement calls.
