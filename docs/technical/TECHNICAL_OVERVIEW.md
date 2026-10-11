# Technical Overview — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## Architecture Goals

1. **Server-authoritative gameplay** — all game-critical state lives on the server.
2. **Clean client/server boundary** — clients handle input, rendering, audio; server handles logic, validation, state.
3. **Modular design** — each system (fire, monster, inventory, etc.) is an independent module with defined interfaces.
4. **Tunable values** — all balance numbers live in a centralized config, not scattered across scripts.
5. **Mobile-first performance** — design for the lowest target device, then enhance for PC.

---

## System Boundaries

```
┌─────────────────────────────────────────────────────┐
│                    SERVER                            │
│                                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Session  │ │ Campaign │ │ Day/Night│            │
│  │ Manager  │ │ Manager  │ │ Clock    │            │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘            │
│       │             │             │                  │
│  ┌────▼─────┐ ┌────▼─────┐ ┌────▼─────┐            │
│  │ Player   │ │ Monster  │ │ Fire     │            │
│  │ State    │ │ AI       │ │ System   │            │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘            │
│       │             │             │                  │
│  ┌────▼─────┐ ┌────▼─────┐ ┌────▼─────┐            │
│  │ Inventory│ │ Resource │ │ Shelter  │            │
│  │ Manager  │ │ Spawner  │ │ Manager  │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│                                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Crafting │ │ Trading  │ │ Save     │            │
│  │ System   │ │ System   │ │ System   │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│                                                     │
│  ┌──────────────────────────────────────┐           │
│  │      Networking (RemoteEvents)       │           │
│  └──────────────┬───────────────────────┘           │
└─────────────────┼───────────────────────────────────┘
                  │ (Replication)
┌─────────────────┼───────────────────────────────────┐
│                 │          CLIENT                    │
│  ┌──────────────▼───────────────────────┐           │
│  │      Network Handler                  │           │
│  └──────────────┬───────────────────────┘           │
│       ┌─────────┼─────────┐                         │
│  ┌────▼─────┐ ┌─▼────────┐ ┌──────────┐            │
│  │ Input    │ │ UI       │ │ Camera   │            │
│  │ Handler  │ │ Manager  │ │ Control  │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│                                                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │ Audio    │ │ Lighting │ │ Particle │            │
│  │ Manager  │ │ Manager  │ │ Manager  │            │
│  └──────────┘ └──────────┘ └──────────┘            │
└─────────────────────────────────────────────────────┘
```

---

## Proposed Roblox Services Used

| Service | Purpose |
|---------|---------|
| `TeleportService` | Session creation (ReserveServer), player transport |
| `DataStoreService` | Player progress persistence |
| `MemoryStoreService` | Session metadata, matchmaking queues |
| `PathfindingService` | Monster navigation |
| `TweenService` | Camera animations, UI transitions |
| `UserInputService` | Input detection (keyboard, mouse, touch) |
| `ContextActionService` | Context-sensitive controls |
| `RunService` | Game loop (Heartbeat for server, RenderStepped for client) |
| `ReplicatedStorage` | Shared modules, config, remote definitions |
| `ServerStorage` | Server-only modules and data |
| `StarterGui` | UI templates |
| `SoundService` | Audio management |
| `Lighting` | Day/night sky, atmosphere |
| `Players` | Player management, join/leave events |

---

## Recommended Folder Structure

```
game/
├── ServerScriptService/
│   ├── Main.server.lua              -- Entry point, initializes all server systems
│   ├── Systems/
│   │   ├── SessionManager.lua       -- Session lifecycle, player tracking
│   │   ├── CampaignManager.lua      -- Day progression, phase transitions
│   │   ├── DayNightClock.lua        -- Time management, events
│   │   ├── MonsterAI.lua            -- FSM, pathfinding, detection
│   │   ├── FireSystem.lua           -- Campfire state, fuel, protection radius
│   │   ├── ResourceSpawner.lua      -- Node placement, collection validation
│   │   ├── InventoryManager.lua     -- Player inventories, validation
│   │   ├── CraftingSystem.lua       -- Recipe validation, item creation
│   │   ├── TradingSystem.lua        -- Trader state, transaction validation
│   │   ├── ShelterManager.lua       -- Upgrade state, fence HP
│   │   ├── PlayerStateManager.lua   -- HP, death, revival
│   │   └── SaveSystem.lua           -- DataStore operations
│   └── Config/
│       ├── BalanceConfig.lua         -- ALL tunable numerical values
│       ├── ResourceConfig.lua        -- Resource definitions, recipes
│       ├── MonsterConfig.lua         -- Monster parameters per day
│       └── CampaignConfig.lua        -- Day timing, phase definitions
│
├── ReplicatedStorage/
│   ├── Shared/
│   │   ├── Types.lua                 -- Type definitions
│   │   ├── Enums.lua                 -- Game enums (states, phases, etc.)
│   │   ├── Constants.lua             -- Shared constants
│   │   └── Utils.lua                 -- Shared utility functions
│   ├── Remotes/
│   │   ├── RemoteDefinitions.lua     -- All RemoteEvent/Function declarations
│   │   └── RemoteValidation.lua      -- Shared validation logic
│   └── Assets/
│       └── (shared asset references)
│
├── StarterPlayerScripts/
│   ├── Main.client.lua               -- Entry point, initializes client systems
│   ├── Controllers/
│   │   ├── InputController.lua       -- Keyboard, mouse, touch, controller
│   │   ├── CameraController.lua      -- FPP camera, cutscene camera
│   │   ├── UIController.lua          -- HUD, menus, prompts
│   │   ├── AudioController.lua       -- Sound playback, spatial audio
│   │   ├── LightingController.lua    -- Day/night sky, fire visuals
│   │   └── InteractionController.lua -- Proximity prompts, hold-to-interact
│   └── UI/
│       ├── HUD.lua                   -- Health, fuel, inventory strip, objectives
│       ├── TradingUI.lua             -- Trading panel
│       ├── CraftingUI.lua            -- Crafting menu
│       └── EndScreen.lua             -- Results, rewards
│
├── StarterGui/
│   └── (UI ScreenGui templates)
│
├── ServerStorage/
│   └── (Server-only assets, monster model, etc.)
│
└── Workspace/
    ├── Map/
    │   ├── City/ (cutscene environment)
    │   ├── Forest/ (main gameplay area)
    │   └── Shelter/ (player base)
    └── Entities/
        ├── Monster/
        ├── Trader/
        └── ResourceNodes/
```

---

## Configuration Strategy

ALL tunable values live in `Config/BalanceConfig.lua`:

```lua
-- BalanceConfig.lua
return {
    -- Day/Night Timing
    Day1_DayDuration = 300,
    Day1_NightDuration = 180,
    NightfallWarningTime = 60,
    
    -- Fire
    Tier1_ProtectionRadius = 15,
    Tier1_MaxFuel = 5,
    Tier1_BurnRate = 1/60,
    
    -- Monster
    Night1_PatrolDistance = 50,
    Monster_PatrolSpeed = 8,
    Monster_ChaseSpeed = 18,
    Monster_AttackDamage = 50,
    
    -- Player
    Player_MaxHP = 100,
    Player_WalkSpeed = 12,
    Player_SprintSpeed = 20,
    Player_SprintDuration = 5,
    Player_InventorySlots = 12,
    
    -- Resources
    WoodPerTree = 2,
    ChopTime = 5,
    InteractionRange = 8,
    
    -- etc.
}
```

**Rule:** If a value appears in game code as a literal number, it's a bug. Everything goes through config.

---

## Error Handling

| Error Type | Response |
|-----------|----------|
| DataStore save failure | Retry 3 times with exponential backoff. Log error. Warn player. |
| Teleport failure | Retry 2 times. Return to lobby if persistent. |
| Monster pathfinding failure | Teleport monster to safe point. Log for debugging. |
| Invalid remote request | Reject silently. Log the attempt. Rate-limit the player. |
| Server crash | Session lost. Players return to lobby. |
| Client disconnect | Server continues without them. Rejoin window opens. |

---

## Performance Budgets `INITIAL_BALANCE_PROPOSAL`

| Metric | Target (PC) | Target (Mobile) |
|--------|-------------|----------------|
| FPS | 60 | 30 |
| Server heartbeat | 60 Hz | 60 Hz |
| Monster pathfinding | <5ms per calc | <5ms per calc |
| Replication updates | 10 Hz | 10 Hz |
| Memory (client) | <500 MB | <300 MB |
| Draw calls | <200 | <100 |
| Active particles | <50 emitters | <20 emitters |
