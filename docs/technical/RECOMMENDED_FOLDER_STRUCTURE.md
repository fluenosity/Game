# Recommended Folder & Module Architecture — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Lead Systems Engineer  
> **Related Documents:** [ROBLOX_ARCHITECTURE.md](file:///i:/RobloxDev/docs/technical/ROBLOX_ARCHITECTURE.md), [TECHNICAL_OVERVIEW.md](file:///i:/RobloxDev/docs/technical/TECHNICAL_OVERVIEW.md)

---

## 1. Filesystem & Rojo Project Layout

The repository codebase resides in `Game/src` and maps to the Roblox DataModel using Rojo:

```text
Game/
├── default.project.json
├── rokit.toml
└── src/
    ├── server/                         --> ServerScriptService.Server
    │   ├── ServerInit.server.lua       --> Main bootstrapper
    │   ├── Services/                   --> Core backend services
    │   │   ├── SessionService.lua
    │   │   ├── CampaignService.lua
    │   │   ├── FireService.lua
    │   │   ├── LightNetworkService.lua
    │   │   ├── MonsterService.lua
    │   │   ├── GatheringService.lua
    │   │   ├── InventoryService.lua
    │   │   ├── TradingService.lua
    │   │   └── ProfileService.lua
    │   └── Components/                 --> Server CollectionService components
    │       ├── TreeComponent.lua
    │       └── ScrapNodeComponent.lua
    │
    ├── client/                         --> StarterPlayer.StarterPlayerScripts.Client
    │   ├── ClientInit.client.lua       --> Client bootstrapper
    │   ├── MainMenu.client.lua         --> Splash screen & menu
    │   ├── Controllers/                --> Client visual & input logic
    │   │   ├── InputController.lua
    │   │   ├── UIController.lua
    │   │   ├── CameraController.lua
    │   │   ├── FireFXController.lua
    │   │   ├── LightNetworkFXController.lua
    │   │   ├── MonsterFXController.lua
    │   │   └── AudioController.lua
    │   └── UI/                         --> Declarative HUD components & frames
    │       ├── HUD.lua
    │       ├── CampfireEmblem.lua
    │       ├── FuelMeter.lua
    │       ├── InventoryModal.lua
    │       └── DebriefScreen.lua
    │
    └── shared/                         --> ReplicatedStorage.Shared
        ├── Config/                     --> Tunable balance numbers
        │   ├── BalanceConfig.lua
        │   ├── ItemConfig.lua
        │   ├── CraftingRecipes.lua
        │   └── MonsterBalance.lua
        ├── Types/                      --> Luau type definition contracts
        │   ├── GameStateTypes.lua
        │   ├── ItemTypes.lua
        │   └── NetworkEventTypes.lua
        └── Utils/                      --> Reusable pure functions
            ├── Signal.lua
            ├── MathUtils.lua
            └── RaycastUtils.lua
```

---

## 2. Standard Service Module Blueprint

Every service in `src/server/Services/` must adhere strictly to this design template:

```lua
--!strict
local FireService = {}
FireService.__index = FireService

-- Dependencies
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BalanceConfig = require(ReplicatedStorage.Shared.Config.BalanceConfig)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)

-- Events emitted
FireService.FuelDepleted = Signal.new()
FireService.TierUpgraded = Signal.new()

-- Internal State
local currentFuel = 100.0
local currentTier = 1

function FireService.Init()
    -- Register remotes, bind connections, initialize state
end

function FireService.Start()
    -- Start loops, timers, or background simulation
end

function FireService.AddFuel(player: Player, fuelAmount: number): boolean
    -- 1. Validate inputs & player distance
    -- 2. Modify state atomically
    -- 3. Replicate attribute or fire event
    return true
end

return FireService
```

### Module Boundary Rules: What a Service Must NEVER Do
1. **Never Trust Client Arguments:** A service must never accept a raw `amountToAdd` or `newHealth` parameter directly from a client remote event.
2. **Never Call Client Functions Blocking:** Never invoke client `RemoteFunction` calls synchronously.
3. **Never Render FX:** Services must never create client-side particle emitters, tween camera, or play sounds directly; they replicate state or fire remote signals for clients to handle.
4. **Never Direct Cross-Service Circular Dependency:** If `ServiceA` requires `ServiceB`, `ServiceB` must not directly require `ServiceA`. Decouple via `Signal` events or an injected mediator.

---

## 3. Acceptance Criteria

- [ ] **AC-FOLD-01:** All scripts load strictly through `ServerInit` and `ClientInit` order-of-execution bootstrappers.
- [ ] **AC-FOLD-02:** Zero circular dependency warnings appear in studio runtime output.
- [ ] **AC-FOLD-03:** Client scripts never directly require modules located in `ServerScriptService` or `ServerStorage`.
