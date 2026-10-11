# Persistence & Save Recovery Architecture — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Database & Persistence Architect  
> **Related Documents:** [DATA_MODELS_AND_SCHEMAS.md](file:///i:/RobloxDev/docs/technical/DATA_MODELS_AND_SCHEMAS.md), [SERVER_AUTHORITY_AND_SECURITY.md](file:///i:/RobloxDev/docs/technical/SERVER_AUTHORITY_AND_SECURITY.md)

---

## 1. Persistence Scope: Session vs Account Data

To prevent exploitation and respect Roblox platform limits, data is strictly categorized into two tiers:

```text
┌──────────────────────────────────────┐     ┌──────────────────────────────────────┐
│        SESSION DATA (TRANSIENT)      │     │      ACCOUNT DATA (PERSISTENT)       │
│  - Current Day (Day 1–5)             │     │  - Earned Embers (Meta-Currency)     │
│  - Carried Wood, Scrap, Flares       │     │  - Unlocked Flame Styles & Skins     │
│  - Campfire Fuel & Shelter Upgrades  │     │  - Equipped Cosmetic Titles          │
│  - Session Health & Downed States    │     │  - Campaign Badges & Clear Stats     │
│  - Light Network Relays              │     │  - Discovered Lore Records           │
│  ► Destroyed when session ends       │     │  ► Saved to Global DataStores        │
└──────────────────────────────────────┘     └──────────────────────────────────────┘
```

> **Design Rationale:** Survival horror loses all tension if players retain infinite wood from previous runs. Each 5-day campaign run starts with empty pockets, ensuring the survival loop remains pure.

---

## 2. Session Locking Pattern (`ProfileService`)

To eliminate item-duplication exploits and race conditions when players quickly jump between servers:

1. **Lock on Load:** When a player joins a server, `ProfileService:LoadProfileAsync()` places a temporary session lease in global DataStore with a heartbeat timeout.
2. **Reject Concurrent Sessions:** If the player tries to connect to a second server simultaneously, the second server fails to acquire the lock and displays: *"Profile active on another server. Please wait 30 seconds."*
3. **Release on Leave:** When the player leaves or the server shuts down, the profile cleanly flushes pending writes and releases the session lock.
4. **Dead Server Force-Release:** If a Roblox server crashes without calling `:Release()`, the lock lease expires automatically after 60 seconds.

---

## 3. Roblox DataStore Request Budget Management

Roblox throttles DataStore calls per place instance:
- **Budget Rule:** `60 + (NumPlayers * 10)` requests per minute.
- **Write Policy:**
  - Zero periodic auto-saves for session inventory (since inventory is session-scoped).
  - Profile writes occur ONLY on:
    1. Player Join (Read Profile).
    2. Cosmetic purchase in lobby (Write Profile).
    3. Campaign End / Extraction (Write Profile with earned Embers).
    4. Player Leave / Server Shutdown via `BindToClose` (Flush Profile).
- **Batching:** Multiple badge unlocks and Ember grants at campaign conclusion are bundled into a single write payload.

---

## 4. Disaster Recovery & Error Handling

```lua
-- Save retry protocol with exponential backoff
local MAX_RETRIES = 5
local BASE_DELAY = 1.0 -- seconds

local function SafeSaveProfile(profile, retryCount)
    retryCount = retryCount or 0
    local success, err = pcall(function()
        profile:Save()
    end)
    
    if not success then
        if retryCount < MAX_RETRIES then
            local delayTime = BASE_DELAY * (2 ^ retryCount)
            task.wait(delayTime)
            return SafeSaveProfile(profile, retryCount + 1)
        else
            -- Log telemetry alert for failed write
            TelemetryService.LogError("DataStoreSaveFailed", {
                UserId = profile.Key,
                Error = tostring(err)
            })
            return false
        end
    end
    return true
end
```

### Server Shutdown (`BindToClose`) Protection
```lua
game:BindToClose(function()
    for _, profile in pairs(ActiveProfiles) do
        SafeSaveProfile(profile)
        profile:Release()
    end
end)
```

---

## 5. Acceptance Criteria

- [ ] **AC-SAVE-01:** Profile loads safely on join and releases lock on player disconnect.
- [ ] **AC-SAVE-02:** Attempting to join two servers simultaneously refuses profile access on the secondary instance without data corruption.
- [ ] **AC-SAVE-03:** In-game server crash flushes all pending profiles via `BindToClose` within the 30-second studio cutoff.
- [ ] **AC-SAVE-04:** Earned Embers are immediately available upon returning to the main menu lobby.
