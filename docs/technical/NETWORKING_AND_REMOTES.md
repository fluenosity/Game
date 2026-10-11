# Networking and Remote Event Catalog — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Network & Security Lead  
> **Related Documents:** [SERVER_AUTHORITY_AND_SECURITY.md](file:///i:/RobloxDev/docs/technical/SERVER_AUTHORITY_AND_SECURITY.md), [EXPLOIT_THREAT_MODEL.md](file:///i:/RobloxDev/docs/technical/EXPLOIT_THREAT_MODEL.md)

---

## 1. Networking Principles

1. **Fire-and-Validate:** All client actions use one-way `RemoteEvent:FireServer()`.
2. **Rate-Limiting (Token Bucket):** Every client connection is metered by a token bucket algorithm to drop flood requests.
3. **Payload Compression:** Use compact numeric IDs and Booleans instead of nested descriptive dictionaries.
4. **Idempotency:** Repeating a packet due to network retries will not duplicate the outcome.

---

## 2. Remote Event Registry

All remotes are organized inside `ReplicatedStorage.Shared.Remotes`:

### 2.1 Client ──► Server (Actions & Requests)

| Remote Name | Payload Parameters | Strict Validation Rules | Rate Limit | Failure Response |
|-------------|--------------------|-------------------------|------------|------------------|
| `ChopTreeRequest` | `treeId: string` | Player alive, distance to tree <= 8 studs, player has hatchet, tree not depleted | 2 req / sec | Drop & log anomaly |
| `CollectScrapRequest` | `nodeId: string` | Player alive, distance <= 8 studs, node valid, inventory not full | 3 req / sec | Silent ignore |
| `AddFuelRequest` | `fuelItemType: number` | Player alive, distance to campfire <= 7 studs, player possesses item in inventory | 4 req / sec | Audible fail cue |
| `UpgradeCampfireRequest` | `targetTier: number` | Player alive, in shelter, party has required wood/scrap, `targetTier == currentTier + 1` | 1 req / 5 sec | UI error banner |
| `PlaceNetworkNodeRequest` | `nodeType: number, position: Vector3` | Player alive, distance to pos <= 10 studs, clear LoS to parent node, has crafting items | 1 req / sec | Red holographic cancel |
| `RevivePlayerRequest` | `targetPlayerId: number` | Requester alive, target in downed state, distance <= 6 studs, 4.0s channel verified | 1 req / 4 sec | Interrupt channel |
| `PingLocationRequest` | `pingType: number, position: Vector3` | Rate limited to prevent visual spam, coordinates within map bounds | 2 req / sec | Drop packet |
| `TradeRequest` | `recipeId: string` | Trader present, player within 10 studs of cart, inventory contains exact inputs | 2 req / sec | UI error shake |
| `SleepSofaRequest` | `none` | Night successfully completed (Dawn active), player within 6 studs of sofa | 1 req / 10 sec | Ignore |

### 2.2 Server ──► Client (Signals & Feedback)

| Remote Name | Payload Parameters | Target Audience | Purpose |
|-------------|--------------------|-----------------|---------|
| `GameStateChanged` | `stateId: number, dayNumber: number, timeOfDay: number` | All Players | Transitions HUD, day clock, lighting |
| `CampfireStateUpdated` | `fuelPercent: number, tier: number, isExtinguished: boolean` | All Players | Tweens flame height, point light, and audio |
| `MonsterAudioAlert` | `soundId: number, position: Vector3, volume: number` | Nearby / All Players | Triggers directional audio roar / screech |
| `PlayerDownedAlert` | `victimUserId: number, position: Vector3` | All Teammates | Spawns emergency medical HUD marker |
| `PlayerRevivedFeedback`| `revivedUserId: number` | All Teammates | Clears marker, plays relief sound cue |
| `InventorySync` | `packedSlots: buffer` | Individual Player | Authoritative sync of personal inventory slots |
| `ObjectiveBanner` | `objectiveId: string, isComplete: boolean` | All Players | Animates on-screen quest updates |

---

## 3. Payload Packing via Luau Buffers

For high-frequency inventory synchronization, instead of sending large Lua tables containing string keys:
- The server serializes the 9-slot inventory into a compact 18-byte Luau buffer (`buffer.create(18)`).
- Each slot uses 2 bytes:
  - Byte 0: `ItemId` (0–255)
  - Byte 1: `StackCount` (0–255)
- **Bandwidth Reduction:** Shrinks inventory sync packet from ~450 bytes (JSON table) to under 25 bytes over the wire.

---

## 4. Rate Limiting Implementation

```lua
-- Server rate limiter snippet
local playerBuckets = {}

local function CheckRateLimit(player: Player, cost: number, maxTokens: number, refillRate: number): boolean
    local bucket = playerBuckets[player]
    if not bucket then
        bucket = { tokens = maxTokens, lastCheck = os.clock() }
        playerBuckets[player] = bucket
    end
    
    local now = os.clock()
    local elapsed = now - bucket.lastCheck
    bucket.lastCheck = now
    bucket.tokens = math.min(maxTokens, bucket.tokens + elapsed * refillRate)
    
    if bucket.tokens >= cost then
        bucket.tokens -= cost
        return true
    end
    return false -- Exceeded rate limit!
end
```

---

## 5. Acceptance Criteria

- [ ] **AC-NET-01:** Remote events are organized in `ReplicatedStorage.Shared.Remotes` upon server initialization.
- [ ] **AC-NET-02:** Flooding `ChopTreeRequest` with 50 calls in 1 frame results in 48 dropped packets without server lag.
- [ ] **AC-NET-03:** Client attempting to fire `AddFuelRequest` while 200 studs away fails silently without modifying campfire state.
