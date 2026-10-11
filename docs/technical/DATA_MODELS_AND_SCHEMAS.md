# Data Models & Schemas — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Data Architect & Systems Engineer  
> **Related Documents:** [PERSISTENCE_AND_SAVE_RECOVERY.md](file:///i:/RobloxDev/docs/technical/PERSISTENCE_AND_SAVE_RECOVERY.md), [INVENTORY_AND_ITEM_RULES.md](file:///i:/RobloxDev/docs/systems/INVENTORY_AND_ITEM_RULES.md)

---

## 1. Schema Overview

All shared game contracts are defined with strict Luau types (`--!strict`) in `ReplicatedStorage.Shared.Types`. This ensures IDE autocomplete, compile-time type validation, and zero runtime shape errors.

---

## 2. Core Luau Schemas

### 2.1 Player Persistent Profile Schema (`ProfileService`)
```lua
export type PlayerProfile = {
    SchemaVersion: number,
    UserId: number,
    Embers: number,
    TotalRuns: number,
    Wins: number,
    UnlockedCosmetics: {
        Flames: { string },
        Decor: { string },
        Titles: { string },
    },
    EquippedCosmetics: {
        Flame: string,
        Decor: string,
        Title: string,
    },
    LoreCluesFound: { [number]: boolean },
    Settings: {
        CameraSensitivity: number,
        HapticsEnabled: boolean,
        MasterVolume: number,
        SFXVolume: number,
        MusicVolume: number,
    },
    LastSavedTimestamp: number,
}
```

### 2.2 Active Session Runtime State Schema
```lua
export type SessionState = {
    SessionId: string,
    PlayerCount: number,
    ActivePlayers: { [number]: PlayerSessionData },
    CurrentDay: number,               -- 0 to 5
    TimeOfDay: number,                -- 0.0 to 24.0 (hours)
    Phase: "Prologue" | "Day" | "Dusk" | "Night" | "Dawn" | "Ended",
    Campfire: CampfireState,
    ShelterUpgrades: { [string]: boolean },
    LightNetworkNodes: { [string]: NetworkNodeState },
    SignalTowerProgress: {
        HasBattery: boolean,
        HasTransmitter: boolean,
        HasFuelCell: boolean,
        IsActivated: boolean,
    },
}

export type PlayerSessionData = {
    UserId: number,
    Health: number,
    MaxHealth: number,
    IsDowned: boolean,
    BleedoutTimer: number,
    Inventory: { [number]: InventorySlot }, -- Slots 1 to 9
}

export type CampfireState = {
    FuelAmount: number,               -- 0.0 to 100.0
    MaxFuel: number,                  -- 100.0 (Tier 1), 150.0 (Tier 2), 200.0 (Tier 3)
    BurnRatePerSec: number,
    ProtectionRadius: number,         -- studs
    Tier: number,                     -- 1, 2, 3
    IsLit: boolean,
}
```

### 2.3 Item & Inventory Schema
```lua
export type ItemId = number

export type ItemDefinition = {
    Id: ItemId,
    Key: string,                      -- e.g. "Wood", "MetalScrap", "Bandage"
    DisplayName: string,
    MaxStack: number,
    Category: "Fuel" | "Scrap" | "Tool" | "Medical" | "Quest",
    FuelValue: number?,               -- for fuel items
    Weight: number,
    ModelAssetId: string?,
}

export type InventorySlot = {
    SlotIndex: number,                -- 1 to 9
    ItemId: ItemId,
    Quantity: number,
}
```

### 2.4 Light Network Node Schema
```lua
export type NetworkNodeType = "Relay" | "PerimeterLantern" | "TripwireFlare"

export type NetworkNodeState = {
    NodeId: string,
    NodeType: NetworkNodeType,
    Position: Vector3,
    Health: number,
    MaxHealth: number,
    ParentNodeId: string?,            -- Id of upstream node in the graph
    IsPowered: boolean,
    ProtectionRadius: number,
}
```

### 2.5 Monster AI State Schema
```lua
export type MonsterAIContext = {
    CurrentState: "Inactive" | "Stalking" | "Probing" | "Chasing" | "Attacking" | "Retreating" | "Fleeing",
    TargetPlayer: Player?,
    TargetPosition: Vector3?,
    AggressionLevel: number,          -- 1 to 5 (escalates by day)
    LastLightStunTime: number,
    StunCountThisNight: number,
    CurrentHealth: number,
}
```

---

## 3. Schema Evolution & Versioning Strategy

- Any change to `PlayerProfile` increments `SchemaVersion`.
- `ProfileService.Migrate()` handles field defaults:
  - If `profile.SchemaVersion == 1` and moving to `2`: automatically populates newly added fields without wiping historical Embers or unlocks.
- All DataStore writes undergo strict validation against `ProfileTypeValidator` before invoking `:SetAsync()`.

---

## 4. Acceptance Criteria

- [ ] **AC-DATA-01:** Luau strict typing passes cleanly across all contract modules.
- [ ] **AC-DATA-02:** Profile migration adds missing fields safely on legacy profile loads.
- [ ] **AC-DATA-03:** Invalid schema structures sent to `ProfileService` fail validation and throw descriptive error logs rather than corrupting user data.
