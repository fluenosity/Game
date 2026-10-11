# Trading and Economy System — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **System Owner:** Economy & Systems Designer  
> **Related Documents:** [RESOURCES_AND_GATHERING.md](file:///i:/RobloxDev/docs/systems/RESOURCES_AND_GATHERING.md), [CRAFTING_AND_UPGRADES.md](file:///i:/RobloxDev/docs/systems/CRAFTING_AND_UPGRADES.md), [DAY_03_SCAVENGING_AND_DISCOVERY.md](file:///i:/RobloxDev/docs/campaign/DAY_03_SCAVENGING_AND_DISCOVERY.md)

---

## 1. System Vision & Economy Model

The economy of *Project: Undecided* is a **closed-loop barter system** designed specifically for high-tension survival. There is no fiat money or persistent currency that can be bought with real money (Robux). Every transaction is a tangible exchange of survival goods scavenged from the ruined world.

### Key Goals
1. **Meaningful Resource Scarcity:** No player or team should ever be able to stockpile infinite reserves.
2. **Dynamic Adaptation:** If players gather excessive wood but suffer a shortage of metal, the Wandering Trader provides an outlet to rebalance assets.
3. **High Stakes Interaction:** The Trader appears during specific day hours and departs before dusk, creating strict time windows for commerce.

---

## 2. The Wandering Trader ("The Scavenger")

### Identity & Arrival Timing
- **NPC Name:** Silas, the Ash Trader.
- **Arrival Schedule:**
  - **Day 1 & Day 2:** Does not appear (players must master raw gathering first).
  - **Day 3:** Arrives at 09:00 in-game time; departs at 17:30 (before dusk).
  - **Day 4 & Day 5:** Arrives at 10:00; departs at 16:30 (harsher weather, shorter window).
- **Shelter Approach:** Silas pulls a reinforced handcart, knocks on the shelter fence gate, and sets up near the workbench. Silas is neutral and cannot be harmed by players.
- **Departure Warning:** At 30 minutes before departure, Silas packs his cart and calls out: *"Night's creeping in, folks. Last calls before I lock up."*

---

## 3. Barter Rate Matrix & Inventory Stock

Silas carries limited daily inventory. Items purchased by any party member deduct from the shared session stock.

| Offered by Trader | Daily Stock (1–3 Players) | Daily Stock (4–5 Players) | Cost to Buy (Player Gives) | Player Sell Value (Trader Gives) |
|-------------------|--------------------------|--------------------------|----------------------------|-----------------------------------|
| **Dry Hardwood (High-Calorie Fuel)** | 6 units | 10 units | 3 Standard Wood OR 1 Metal Scrap | 1 Wood = 1 Common Scrap |
| **Metal Scrap** | 8 units | 14 units | 4 Wood OR 2 Plastic Scrap | 1 Metal Scrap = 2 Wood |
| **Heavy Rope** | 4 units | 7 units | 3 Plastic Scrap OR 2 Metal Scrap | 1 Rope = 2 Plastic Scrap |
| **Tempered Nails** | 10 units | 16 units | 1 Metal Scrap | 1 Nail = 0.5 Wood |
| **Signal Tower Battery Cell (Day 5 only)** | 1 unit | 1 unit | 6 Metal Scrap + 4 Plastic + 2 Rope | Not Sellable |
| **First Aid Bandage** | 3 units | 5 units | 2 Plastic Scrap + 1 Clean Cloth | 1 Bandage = 1 Clean Cloth |

*(All numbers marked `INITIAL_BALANCE_PROPOSAL`)*

---

## 4. Transaction State Machine & Validation

```text
[Idle] ──Player Interacts──► [Inspect Inventory]
                                  │
                             Select Trade
                                  │
                        [Client Validates Local]
                                  │ Send TradeRequest
                        [Server Authoritative Check]
                         ├─ In range of Trader? (≤ 10 studs)
                         ├─ Trader present & open?
                         ├─ Stock available?
                         ├─ Player has exact inputs?
                         └─ Transaction locked (mutex)?
                                  │
                       Success: Deduct & Grant
                                  │
                         [Replicate State]
```

### Mutex & Race Condition Prevention
In a co-op party of 5 players, two players may click "Buy Last Metal Scrap" at the exact same millisecond. The server wraps stock decrements in an atomic Lua transaction:
- The first processed request decrements stock from 1 to 0 and grants the item.
- The second request evaluates `CurrentStock == 0` and returns `TradeFailed: OUT_OF_STOCK` without consuming the player's payment resources.

---

## 5. Security & Exploit Protection

1. **Server Inventory Validation:** Client only sends `{ TransactionId, RecipeKey }`. The client never specifies quantities or results.
2. **No Negative Inventories:** Server rejects any trade where current balance minus cost is less than zero.
3. **No Distance Exploits:** Transactions fail immediately if the requesting character is dead, ragdolled, or farther than 10 studs from the trader cart.
4. **No Trade While Monster Hunting:** If the Trader is somehow caught during nightfall (due to an anomaly or delayed trigger), the Trader immediately locks doors and refuses all input.

---

## 6. Acceptance Criteria

- [ ] **AC-TE-01:** Trader arrives at Day 3 at 09:00 and despawns safely at 17:30.
- [ ] **AC-TE-02:** Players can exchange 3 Wood for 1 Dry Hardwood; both player inventory and trader stock update instantaneously.
- [ ] **AC-TE-03:** When stock reaches zero, the trade button grays out and is disabled for all clients in the session.
- [ ] **AC-TE-04:** Attempting to trade without required resources yields an audible rejection cue and clear red feedback text.
