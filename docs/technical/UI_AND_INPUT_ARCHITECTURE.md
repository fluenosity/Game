# UI and Input Architecture — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** UI/UX Lead & Client Architect  
> **Related Documents:** [INTERACTION_FRAMEWORK.md](file:///i:/RobloxDev/docs/technical/INTERACTION_FRAMEWORK.md), [PERFORMANCE_AND_MOBILE.md](file:///i:/RobloxDev/docs/technical/PERFORMANCE_AND_MOBILE.md)

---

## 1. System Vision & Aesthetic Design

The User Interface of *Project: Undecided* is designed to maximize horror immersion. Screen clutter is aggressively minimized. Survival data is communicated through **diegetic world cues** (campfire height, watch faces, breathing audio) and sleek, minimalist HUD elements that fade when unneeded.

### Key Visual Principles
- **Atmospheric Palette:** Warm embers (`#E06D28`), cold ash grey (`#2C2F33`), and warning crimson (`#C0392B`).
- **Typography:** Modern, clean sans-serif (Gotham / Inter) with high contrast for readability across low-resolution mobile devices.
- **Dynamic Opacity:** HUD elements drop to 30% opacity when the player is safely sitting by the fire with full stats.

---

## 2. HUD Screen Hierarchy & Layout

```text
┌─────────────────────────────────────────────────────────────┐
│ [Day 3 - 14:20] ☀️                      [Team Status: 4/5] │ ◄ Top Bar
│ Objective: "Fortify Shelter Fence" (2/4)                    │
│                                                             │
│                                                             │
│                          [ + ] Reticle                      │ ◄ Center (Reticle & Prompts)
│                     (E) Chop Deadfall                       │
│                                                             │
│                                                             │
│ [HP: 100%] ❤️                                                │ ◄ Bottom Bar
│ [Campfire: 74%] 🔥                                          │
│                               [ 1 ] [ 2 ] [ 3 ] [Backpack] │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Mobile-First Ergonomics & Safe Area Support

Over 60% of players interact via mobile phones and tablets. The interface strictly complies with mobile hardware constraints:

1. **Safe Area Insets:** All UI frames anchor within `GuiService:GetGuiInset()` and dynamic notch cutouts to prevent controls from clipping under camera holes or speaker bars.
2. **Dynamic Touch Targets:**
   - Movement: Left screen half activates dynamic virtual thumbstick.
   - Look / Camera: Right screen half controls camera rotation.
   - Interaction Button: 68×68 dp thumb button located in lower-right thumb sweep arc.
   - Hotbar: Large bottom-center slots (56×56 dp) easily reachable with right thumb.
3. **Screen Size Adaptation:** All frames use `UIScale` driven by viewport aspect ratios, ensuring crisp rendering on screens from 4.7-inch phones to 32-inch 4K monitors.

---

## 4. Input Abstraction Layer (`InputController`)

Rather than scattering `UserInputService` listeners across multiple scripts, all hardware inputs are routed through a centralized `InputController`:

```lua
-- Centralized input mapping table
local InputMappings = {
    Interact = {
        Keyboard = Enum.KeyCode.E,
        Gamepad = Enum.KeyCode.ButtonX,
        Touch = "OnScreenActionButton"
    },
    Sprint = {
        Keyboard = Enum.KeyCode.LeftShift,
        Gamepad = Enum.KeyCode.ButtonL3,
        Touch = "SprintToggleTouch"
    },
    ToggleInventory = {
        Keyboard = Enum.KeyCode.Tab,
        Gamepad = Enum.KeyCode.ButtonSelect,
        Touch = "InventoryButtonTouch"
    },
    Ping = {
        Keyboard = Enum.UserInputType.MouseButton3,
        Gamepad = Enum.KeyCode.ButtonR1,
        Touch = "PingButtonTouch"
    }
}
```

---

## 5. First-Person Camera Architecture

- **Camera Mode:** `Player.CameraMode = Enum.CameraMode.LockFirstPerson`.
- **Head Bob & Breathing:** Subtle procedurally generated Sine-wave offset applied to camera CFrame during walking and sprinting.
- **Low-Health Vignette:** When HP < 30%, a pulsating dark-red vignette surrounds the screen accompanied by an audible heartbeat.
- **Darkness Pupil Dilation:** Looking into complete darkness slightly increases exposure over 3.0s; turning back to the campfire creates a brief, realistic glare blindness before adapting.

---

## 6. Acceptance Criteria

- [ ] **AC-UI-01:** HUD scales dynamically on mobile without clipping against hardware notches or device edges.
- [ ] **AC-UI-02:** First-person camera remains locked without allowing accidental third-person clipping through walls.
- [ ] **AC-UI-03:** Hotbar keys 1–3, D-pad, and touch taps instantly equip the selected item.
- [ ] **AC-UI-04:** Radial interaction gauges render at 60 FPS without stutter or GC pauses.
