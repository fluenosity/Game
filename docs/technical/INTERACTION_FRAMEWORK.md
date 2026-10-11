# Interaction Framework — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** UX & Gameplay Framework Engineer  
> **Related Documents:** [UI_AND_INPUT_ARCHITECTURE.md](file:///i:/RobloxDev/docs/technical/UI_AND_INPUT_ARCHITECTURE.md), [SERVER_AUTHORITY_AND_SECURITY.md](file:///i:/RobloxDev/docs/technical/SERVER_AUTHORITY_AND_SECURITY.md)

---

## 1. System Vision & Cross-Platform Goals

The interaction framework is the primary physical bridge between players and the survival world. It must feel instantaneous, tactile, and completely reliable across PC keyboard/mouse, touchscreen mobile devices, and console gamepads.

### Core Requirements
1. **Low Latency Feedback:** Client provides immediate visual feedback (radial progress circle, sound tick) while the server strictly authorizes completion.
2. **Clear Interaction Hierarchy:** If a fallen teammate and a dropped stick are 2 studs apart, the framework prioritizes the critical action (Revive > Campfire > Fuel > Pickup).
3. **Exploit-Proof Channels:** Long interactions (chopping, reviving) require continuous server-verified channel heartbeats.

---

## 2. Interaction Engine: Hybrid Proximity System

To balance native Roblox engine performance with custom horror UI styling:
- Utilizes customized **`ProximityPrompt`** objects wrapped with custom UI styling (`PromptStyle = Enum.ProximityPromptStyle.Custom`).
- The client `InteractionController` renders a sleek, circular progress gauge directly in screen space above the interactable object.

```text
┌────────────────────────────────────────────────────────┐
│                   INTERACTION TYPES                    │
├────────────────────────────────────────────────────────┤
│  1. INSTANT TAP (HoldDuration = 0s)                    │
│     - Pick up scrap / wood from ground                 │
│     - Open shelter door / gate                         │
│                                                        │
│  2. SHORT CHANNEL (HoldDuration = 1.5s - 2.5s)         │
│     - Stoking campfire with wood                       │
│     - Repairing fence section                          │
│                                                        │
│  3. LONG CHANNEL (HoldDuration = 4.0s - 5.0s)          │
│     - Chopping tree                                    │
│     - Reviving downed teammate                         │
│     - Activating Signal Tower generator                │
└────────────────────────────────────────────────────────┘
```

---

## 3. Interaction Priority Matrix

When multiple prompts overlap within the player's interaction sphere (8 studs):

| Priority Rank | Object Category | Reason |
|:-------------:|-----------------|--------|
| **1 (Highest)** | Downed Teammate | Life-or-death emergency; takes precedence over everything |
| **2** | Monster Defense (Flare drop, Gate latch) | Immediate safety |
| **3** | Campfire Fuel Stoking | Preventing extinction |
| **4** | Crafting Station / Storage Trunk | Base management |
| **5 (Lowest)** | Ground Resource Pickup (Wood, Scrap) | Routine scavenging |

---

## 4. Server Authority & Anti-Cheat Validation

```lua
-- Server interaction channel validator
local ActiveChannels = {}

function InteractionService.StartChannel(player: Player, targetId: string, duration: number)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local targetInstance = GetTargetInstance(targetId)
    if not targetInstance then return end
    
    -- Validate initial distance
    local dist = (character.HumanoidRootPart.Position - targetInstance:GetPivot().Position).Magnitude
    if dist > 9.0 then return end
    
    ActiveChannels[player] = {
        TargetId = targetId,
        StartTime = os.clock(),
        Duration = duration,
        OriginPos = character.HumanoidRootPart.Position
    }
end

function InteractionService.CompleteChannel(player: Player, targetId: string): boolean
    local channel = ActiveChannels[player]
    if not channel or channel.TargetId ~= targetId then return false end
    
    local elapsed = os.clock() - channel.StartTime
    if elapsed < (channel.Duration - 0.25) then -- Allowed latency tolerance
        warn("Channel completed too fast! Suspected speed hack from:", player.Name)
        ActiveChannels[player] = nil
        return false
    end
    
    ActiveChannels[player] = nil
    return true -- Validated!
end
```

---

## 5. Cross-Platform Input Binding

| Action | Keyboard / Mouse | Touchscreen Mobile | Gamepad / Console |
|--------|------------------|--------------------|-------------------|
| **Interact / Start Channel** | `E` key (Hold) | Dedicated large `[ Action ]` touch button | `X` button (Xbox) / `Square` (PlayStation) |
| **Secondary Action (Drop/Alt)** | `Q` key | Context radial tap | `Y` button / `Triangle` |
| **Cancel Channel** | Move away or press `Space` | Move thumbstick | Left Stick move |

---

## 6. Acceptance Criteria

- [ ] **AC-ACT-01:** Holding `E` on a tree shows a smooth 4-second circular fill and grants 2 wood upon server validation.
- [ ] **AC-ACT-02:** Moving beyond 9 studs immediately cancels the interaction channel on both client and server.
- [ ] **AC-ACT-03:** When a downed teammate is near a dropped stick, the revive prompt always highlights first.
- [ ] **AC-ACT-04:** Mobile touch target for interactions is at least 64x64 dp for effortless one-thumb tapping.
