# Roblox Technical Architecture — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Principal Roblox Architect  
> **Related Documents:** [TECHNICAL_OVERVIEW.md](file:///i:/RobloxDev/docs/technical/TECHNICAL_OVERVIEW.md), [RECOMMENDED_FOLDER_STRUCTURE.md](file:///i:/RobloxDev/docs/technical/RECOMMENDED_FOLDER_STRUCTURE.md), [SERVER_AUTHORITY_AND_SECURITY.md](file:///i:/RobloxDev/docs/technical/SERVER_AUTHORITY_AND_SECURITY.md)

---

## 1. Architectural Philosophy & Engine Model

*Project: Undecided* is engineered around strict **Service-Controller Architecture** implemented in native **Luau**. The architecture enforces a clean separation of concerns:
- **Server:** Sole authority over all gameplay simulation, timers, health, inventory, resource nodes, monster pathfinding, and save profiles.
- **Client:** Responsible for local user input, prediction-friendly visual feedback, audio synthesis, camera manipulation, and UI rendering.
- **Shared:** Immutable configuration dictionaries, data contracts, mathematical utilities, and network event definitions.

```text
┌────────────────────────────────────────────────────────┐
│                   SERVER RUNTIME                       │
│  [ServerInit] ──► Orchestrates Services                │
│  ├── SessionService        (Match lifecycle & parties) │
│  ├── CampaignService       (Day/Night FSM & objectives)│
│  ├── FireLightService      (Fuel, radius, nodes graph) │
│  ├── MonsterService        (AI decision loop & path)   │
│  ├── InventoryService      (Transactions & validation) │
│  └── ProfileService        (DataStore persistence)     │
└────────────┬─────────────────────────────▲─────────────┘
             │ Replicates State             │ Requests Action
             ▼ (RemoteEvents / Attributes)  │ (RemoteEvents)
┌───────────────────────────────────────────┴────────────┐
│                   CLIENT RUNTIME                       │
│  [ClientInit] ──► Orchestrates Controllers             │
│  ├── InputController       (Touch/Mouse/Gamepad map)   │
│  ├── UIController          (Roact/Fusion HUD, menus)   │
│  ├── FireFXController      (Tweening lights, embers)   │
│  ├── AudioAtmosphereController (Dynamic spatial sound) │
│  └── MonsterFXController   (Local animation & roar)    │
└────────────────────────────────────────────────────────┘
```

---

## 2. Toolchain & Development Stack

- **Version Control & Build:** Rojo 7.x (`default.project.json`) mapping filesystem directories into Roblox Studio DataModel.
- **Package & Tool Manager:** Rokit (`rokit.toml`) managing Selene (linter), StyLua (code formatter), and Wally (package manager).
- **Type Checking:** Luau strict mode (`--!strict`) enforced on all shared and service interfaces.
- **Third-Party Libraries:**
  - `ProfileService` by loleris for transactional, session-locked persistence.
  - `Promise` by evaera for asynchronous networking and asset loading.
  - `Signal` / `GoodSignal` for high-performance intra-process event dispatching.

---

## 3. StreamingEnabled & Physics Ownership

### StreamingEnabled Configuration
- **Enabled:** `Workspace.StreamingEnabled = true` (Mandatory for mobile memory budgets under 4GB).
- **StreamingMinRadius:** 96 studs (guarantees shelter, campfire, and immediate perimeter are always loaded).
- **StreamingTargetRadius:** 384 studs.
- **StreamOutBehavior:** `LowMemory` to evict distant terrain and trees on budget phones.
- **Persistent Parts:** The central Campfire, Shelter fence anchors, and Signal Tower are tagged with `ModelStreamingMode.Persistent` to prevent streaming eviction glitches.

### Network Ownership
- **Players:** Client owns their local Character HumanoidRootPart physics.
- **Monster (The Hollow):** Server explicitly retains network ownership (`MonsterRoot:SetNetworkOwner(nil)`). The client is NEVER granted network ownership over the monster to prevent desync manipulation or freeze exploits.
- **Dropped Items:** Server retains network ownership; physics anchors after 1.5 seconds to conserve server physics cycles.

---

## 4. Replication Paradigm: Attributes vs RemoteEvents

To minimize network packet overhead:
1. **Low-Frequency Static / State Data:** Replicated via **Roblox Attributes** on ReplicatedStorage or workspace models (e.g., `Campfire:SetAttribute("FuelPercent", 0.75)`, `Workspace:SetAttribute("CurrentDay", 2)`). Clients listen via `:GetAttributeChangedSignal()`.
2. **High-Frequency Discrete Events:** Transmitted via **RemoteEvents** (e.g., `MonsterRoar`, `PlayerTookDamage`, `CampfireStokedBurst`).
3. **Player Requests:** Strict one-way `RemoteEvent` fires (Client -> Server) with server validation and response via state replication. Avoid blocking `RemoteFunction` calls to prevent client-induced thread hanging.

---

## 5. Acceptance Criteria

- [ ] **AC-ARCH-01:** Rojo syncs files cleanly without namespace collisions in ReplicatedStorage, ServerScriptService, or StarterPlayerScripts.
- [ ] **AC-ARCH-02:** Strict Luau type annotations pass Selene linting across shared contracts.
- [ ] **AC-ARCH-03:** Monster network owner is verified to be `nil` (Server-owned) upon spawn.
- [ ] **AC-ARCH-04:** Disconnecting and reconnecting clients seamlessly read current Attributes without missing state.
