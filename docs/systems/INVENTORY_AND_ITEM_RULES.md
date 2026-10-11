# Inventory and Item Rules — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **System Owner:** Gameplay Systems & UX Lead  
> **Related Documents:** [RESOURCES_AND_GATHERING.md](file:///i:/RobloxDev/docs/systems/RESOURCES_AND_GATHERING.md), [CRAFTING_AND_UPGRADES.md](file:///i:/RobloxDev/docs/systems/CRAFTING_AND_UPGRADES.md), [SERVER_AUTHORITY_AND_SECURITY.md](file:///i:/RobloxDev/docs/technical/SERVER_AUTHORITY_AND_SECURITY.md)

---

## 1. System Vision & Constraints

Inventory management in *Project: Undecided* is deliberately constrained to create acute survival tension. Players cannot act as bottomless walking warehouses. Every expedition outside the campfire perimeter forces decisions:
- "Do I drop my emergency flare to bring back two extra pieces of scrap metal?"
- "Do we designate one player as the dedicated hauler while another carries defense tools?"

---

## 2. Inventory Slot Architecture

Every player possesses a grid-free, slot-based inventory designed for quick mobile accessibility and zero cumbersome sorting micro-management:

```text
┌────────────────────────────────────────────────────────┐
│                   PLAYER INVENTORY                     │
│  [ QuickSlot 1 ]  [ QuickSlot 2 ]  [ QuickSlot 3 ]     │  ◄ Active Hands / Hotbar
│  [ Backpack 1  ]  [ Backpack 2  ]  [ Backpack 3  ]     │  ◄ Storage Slots
│  [ Backpack 4  ]  [ Backpack 5  ]  [ Backpack 6  ]     │
└────────────────────────────────────────────────────────┘
```

### Slot Allocations
- **Hotbar (Slots 1–3):** Instantly selectable with number keys (1–3), controller D-pad, or direct screen tap. Supports held tools, torches, bandages, flares.
- **Backpack (Slots 4–9):** Passive carrying capacity for raw materials, scrap, and quest components.
- **Total Personal Slots:** 9 slots (`INITIAL_BALANCE_PROPOSAL`).
- **Base Shelter Storage Chest:** 18 shared slots located at the shelter table.

---

## 3. Item Categories & Stack Limits

| Category | Examples | Stack Limit | Equippable in Hand? | Droppable? | Drop Behavior on Death |
|----------|----------|-------------|---------------------|------------|------------------------|
| **Fuel Resources** | Standard Wood, Dry Hardwood, Pine Cones | 10 per slot | Yes (carrying log) | Yes | Drops 100% on ground |
| **Salvage / Scrap** | Metal Scrap, Plastic Bottles, Wire, Nails | 8 per slot | No | Yes | Drops 100% on ground |
| **Tools & Gear** | Stone Hatchet, Firebrand Torch, Flare Stick | 1 (Non-stackable) | Yes | Yes | Retains Hatchet, drops consumable gear |
| **Medical** | Herbal Ointment, Bandage | 3 per slot | Yes | Yes | Drops 50% on ground |
| **Quest Components**| Tower Battery, Antenna Transmitter, Fuse | 1 per slot | Yes (two-handed carry)| Yes | Drops at death location |

---

## 4. Item Interactions & Server Rules

### 1. Pickup & Gathering
- When a resource node is depleted or an item is picked up from the ground, the server first checks if an existing inventory stack has room (`CurrentCount < MaxStack`).
- If yes, increments that stack; if no, claims the first available empty slot.
- If inventory is 100% full, the item remains on the ground with an audible rejection buzz and floating message: *"Inventory Full"*.

### 2. Dropping Items
- Dropping an item spawns a physical `DroppedItem` model in front of the player (replicated from server).
- Dropped items despawn only if the server reaches the global dropped entity cap (200 items), prioritizing despawning oldest low-tier wood. Important quest items NEVER despawn.

### 3. Shelter Storage Trunk
- Interacting with the shelter storage trunk opens a split modal: Player Inventory (Left) and Shelter Trunk (Right).
- One-tap / one-click quick transfer moves stacks without tedious dragging.

---

## 5. Death & Disconnect Rules

1. **Player Downed (Bleedout state):** Inventory remains on player during bleedout.
2. **Player Killed (Respawn / Spectate):** All carried scrap, quest items, and fuel spill into a loot bag at the death coordinate.
3. **Player Disconnect:** If a player disconnects unexpectedly, their carried items are immediately deposited into the Shelter Storage Trunk (or dropped at shelter doorstep if trunk is full) so the remaining team isn't softlocked by a missing quest component.

---

## 6. Mobile & Console UX Guidelines

- **Touch Controls:** Large, distinct buttons (minimum 48x48 dp touch target). Tapping an item opens a circular context action: `Use`, `Equip`, `Drop 1`, `Drop All`.
- **Controller Support:** Bumpers (L1/R1) cycle hotbar slots; D-Pad navigates inventory screen; 'X' button drops, 'A' equips.
- **Haptic Feedback:** Subtle vibration when picking up metal or quest items.

---

## 7. Acceptance Criteria

- [ ] **AC-INV-01:** Collecting 11 wood creates one stack of 10 and one stack of 1 across two slots.
- [ ] **AC-INV-02:** Attempting to pick up an item with 9 full slots preserves the world item and shows "Inventory Full".
- [ ] **AC-INV-03:** Dropping a quest item places it safely on the terrain with collision enabled and an orange beacon beaconing its position.
- [ ] **AC-INV-04:** On sudden player disconnect, carried items safely transfer to the shelter chest without data loss.
