# Server Authority and Security — Project: Undecided

> **Status:** `PROPOSED`
> **Last updated:** 2026-10-11

---

## Trust Model

**Rule: NEVER trust the client.**

The client is responsible for:
- Capturing player input (movement, interactions, menu clicks).
- Rendering visuals (fire, monster, environment).
- Playing audio.
- Displaying UI.

The server is responsible for:
- ALL game state (HP, inventory, fire fuel, monster position, day/night, objectives).
- ALL validation (can this player chop this tree? Do they have enough wood?).
- ALL damage calculations.
- ALL resource grants.
- ALL progression updates.

---

## Remote Event Catalog

### Client → Server (Requests)

| Remote | Purpose | Parameters | Validation |
|--------|---------|-----------|-----------|
| `ChopTreeRequest` | Player wants to chop a tree | treeId | Tree exists, not already claimed, player in range (8 studs) |
| `CollectScrapRequest` | Player picks up scrap | nodeId | Node exists, not collected, player in range |
| `LightCampfireRequest` | Player lights/relights fire | — | Player has ≥2 wood, in range (6 studs), fire is unlit |
| `AddFuelRequest` | Player adds wood to fire | — | Player has wood, fire exists, in range |
| `UpgradeCampfireRequest` | Player upgrades fire tier | — | Player has materials, campfire at correct tier, in range |
| `BuildUpgradeRequest` | Player builds shelter upgrade | upgradeId | Player has materials, upgrade not already built |
| `CraftItemRequest` | Player crafts an item | recipeId | Workbench exists, player has ingredients |
| `TradeRequest` | Player makes a trade | tradeId | Trader present, trade available, player has items |
| `InteractSofaRequest` | Player sleeps | — | Night has ended, all objectives met |
| `RevivePlayerRequest` | Player revives teammate | targetPlayerId | Target is downed, requester is in range (6 studs) |
| `ActivateSignalRequest` | Player activates signal tower | — | All 3 components collected, player at tower |
| `EscapeRequest` | Player escapes | — | Signal activated, rescue arrived, player at rescue point |

### Server → Client (Updates)

| Remote | Purpose | Data |
|--------|---------|------|
| `GameStateUpdate` | Replicate game state | Phase, day, time, objectives |
| `FireStateUpdate` | Campfire state change | isLit, fuel%, tier, radius |
| `MonsterStateUpdate` | Monster position/state | Position, animState, audioTrigger |
| `InventoryUpdate` | Player inventory changed | Full inventory snapshot |
| `ObjectiveUpdate` | Objective changed | New objective text, completion status |
| `PlayerHealthUpdate` | HP changed | currentHP, maxHP, damageSource |
| `PlayerDiedEvent` | Player died | playerId, cause |
| `DayTransitionEvent` | New day started | dayNumber |
| `WarningEvent` | Nightfall/fuel warning | warningType, severity |

---

## Rate Limiting

| Remote | Max Rate | Per |
|--------|---------|-----|
| ChopTreeRequest | 1 per 4s | Player |
| CollectScrapRequest | 1 per 1s | Player |
| AddFuelRequest | 1 per 1s | Player |
| CraftItemRequest | 1 per 3s | Player |
| TradeRequest | 1 per 2s | Player |
| All other requests | 1 per 0.5s | Player |

Exceeding rate limits: silently reject the request. Log the violation. After 10 violations in 60s, kick the player.

---

## Exploit Threat Model

| Threat | Attack Vector | Mitigation |
|--------|-------------|-----------|
| Item duplication | Send ChopTreeRequest multiple times rapidly | Server marks tree as "claimed" on first valid request; reject duplicates |
| Fake resource grants | Client sends "give me 100 wood" | Server never grants items from client requests — only from validated actions |
| Speed hacking | Modified client moves faster | Server validates position changes; reject teleport-like movement |
| Fly hacking | Client disables gravity | Server validates Y-position against terrain |
| Campfire manipulation | Client sets fire to infinite fuel | Fuel is server-only state; client has no write access |
| Skip day/night | Client sends "make it dawn" | Day/night clock is server-only |
| Damage modification | Client says "monster hit me for 0 damage" | Damage is server-calculated; client is only informed |
| Rejoin exploit | Disconnect/rejoin to duplicate items | Save state on disconnect; restore exact state on rejoin |
| Trade exploit | Modify trade values client-side | All trade validation is server-side |

---

# Networking and Remotes

> See Remote Event Catalog above.

## Design Principles

1. **Minimize remote calls** — batch updates where possible.
2. **Use UnreliableRemoteEvents for frequent, non-critical updates** (monster position at 10Hz).
3. **Use RemoteEvents for critical one-shot actions** (chop tree, light fire, craft).
4. **Never use RemoteFunctions for client→server** (vulnerable to yielding attacks).
5. **Validate EVERYTHING server-side** — even if the UI prevents invalid actions, the server must still check.

---

# Persistence and Save Recovery

> **Status:** `PROPOSED`

---

## What Gets Saved

### Per-Player (DataStore)

| Field | Type | Default |
|-------|------|---------|
| campaignCompletions | number | 0 |
| loreItemsFound | {string} | {} |
| unlockedCosmetics | {string} | {} |
| achievementBadges | {string} | {} |
| totalNightsSurvived | number | 0 |
| bestCompletionTime | number | nil |
| settings | {table} | defaults |

### Per-Session (MemoryStore or in-memory) `PROPOSED`

| Field | Type | Notes |
|-------|------|-------|
| currentDay | number | 1–5 |
| playerInventories | {playerId: items} | Session-only |
| campfireState | table | Tier, fuel, lit status |
| shelterUpgrades | {string} | What's been built |
| collectedNodes | {nodeId} | Which resources have been gathered |
| signalComponents | {string} | Which components found |
| monsterState | table | Current AI state |

### Save Timing

- Player data saved on: campaign completion, achievement unlock, disconnect.
- `PROPOSED` Mid-campaign save (between days): save session state to allow resume.
- Use `DataStoreService:SetAsync()` with retry logic (3 attempts, exponential backoff).
- Use `game:BindToClose()` to save on server shutdown.

### Data Versioning

```lua
local SAVE_VERSION = 1
-- On load: check version, migrate if needed
-- On save: stamp current version
```

---

# Performance and Mobile

> **Status:** `PROPOSED`

---

## Performance Budgets

| Metric | PC Target | Mobile Target |
|--------|-----------|--------------|
| FPS | 60 | 30 |
| Draw calls | <200 | <100 |
| Triangle count | <500K | <200K |
| Active particles | <50 emitters | <20 emitters |
| Sound sources | <20 | <10 |
| Monster pathfinding | <5ms/calc | <5ms/calc |
| Server heartbeat | 60 Hz | 60 Hz |
| Client memory | <500 MB | <300 MB |
| Network (replication) | 10 Hz updates | 10 Hz updates |

## Mobile Optimization Strategies

- Use `StreamingEnabled` with tight streaming radius.
- Reduce particle counts and complexity on mobile.
- Use Level of Detail (LOD) for distant objects.
- Minimize shadow casting lights (campfire only).
- Reduce fog density on low-end devices.
- Use `workspace.SignalBehavior = Enum.SignalBehavior.Deferred` for performance.
- Test on a mid-range phone as the baseline device.

## Quality Settings `PROPOSED`

| Setting | Low (Mobile) | Medium | High (PC) |
|---------|-------------|--------|-----------|
| Shadows | Off | Simple | Full |
| Particles | Reduced (50%) | Normal | Full |
| Draw distance | 200 studs | 400 studs | 600 studs |
| Post-processing | Off | Basic | Full |
| Texture quality | Low | Medium | High |
| Ambient audio sources | 5 | 10 | 20 |
