# Don't Let the Fire Die — Architectural Rules & Guidelines

> **Notice for AI Assistants & Developers:**  
> These rules are the single source of truth for all game development, scripting, and UI architecture in this repository. Follow all rules strictly without deviation unless explicitly instructed by the project lead.

---

## 1. World Generation & Spawners Policy
- **DO NOT run procedural world generation, terrain generators, rock placers, tree spawners, or environment generators automatically.**
- Never trigger or invoke scripts like `EnvironmentGenerator.lua`, `RockPlacer.lua`, or batch vegetation spawners on Studio start, Play solo, or during routine tasks.
- Only run environment generation commands when the project lead explicitly commands it (e.g., `"run world gen"`, `"spawn rocks"`, or `"regenerate map"`).
- Existing place geometry in `Place1.rbxl` is carefully tuned. Preserve manually placed scene assets.

---

## 2. Development Environment Presets
- **Day/Night Cycle:** The day/night cycle must remain frozen at daytime (`ClockTime = 14:00` / `DAY_ONLY_DEV = true`) during development for maximum scene visibility.
- **Player Stamina:** Developer mode has unlimited stamina enabled (`UNLIMITED_STAMINA_DEV = true`).
- **Player Visuals:** The circular Genshin-style sprint/stamina bar over the character's head is **permanently disabled**. Stamina is tracked cleanly in the bottom-right HUD vitals pill.

---

## 3. Camera & First-Person Perspective (FPP)
- **Strict First-Person Perspective (FPP):**
  - `player.CameraMode = Enum.CameraMode.LockFirstPerson`
  - `player.CameraMinZoomDistance = 0.5`
  - `player.CameraMaxZoomDistance = 0.5`
  - Mouse wheel scrolling into third-person (TPP) is disabled.
- **Active Gameplay State:**
  - Mouse cursor is locked to the center of the screen (`UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter`).
  - OS cursor arrow is hidden (`UserInputService.MouseIconEnabled = false`).
  - A minimalist **GTA V style center dot reticle** (5×5 px white circle with a 1px dark contrast border) is displayed at the screen center (`HUDCrosshair.lua`).
  - When looking at interactables with enabled ProximityPrompts within 14 studs, the reticle dot dynamically pulses with an amber focus ring.

---

## 4. Cursor Freedom & Modal Architecture (ModalManager)
### The Problem & Solution
In Roblox first-person mode, any mouse movement deltas rotate the camera by default. To allow free mouse usage without spinning the camera:
1. Whenever the mouse is freed, `workspace.CurrentCamera.CameraType` **MUST be set to `Enum.CameraType.Scriptable`** with orientation anchored to the character's `Head.Position`.
2. When returning to gameplay, `CameraType` is restored to `Enum.CameraType.Custom` and `CameraMode = Enum.CameraMode.LockFirstPerson`.
3. Every modal backdrop/veil must use a `TextButton` with `Modal = true` to signal the Roblox engine to route clicks directly to GUI elements.

### Rules for All Modals:
- **Alt Key Mouse Ejection:**
  - Pressing or holding `[LeftAlt]` or `[RightAlt]` frees the cursor (`MouseBehavior = Default`, `MouseIconEnabled = true`), freezes camera look, and hides the reticle.
  - Releasing `[Alt]` immediately restores locked FPP look and displays the GTA V reticle **without requiring any extra mouse click**.
- **Modal Opening & Closing:**
  - Opening ANY modal (Backpack `[B]`, Settings Menu `[ESC]`, Silas Barter `[E]`, Dialogue, etc.) automatically unlocks the cursor, freezes camera look, and hides the reticle.
  - Closing ANY modal immediately restores locked FPP look and displays the GTA V reticle.
- **Extending to Future Systems (Dialogue, Quests, Crafting, Looting):**
  - **Always use `ModalManager.lua`:**
    ```lua
    local ModalManager = require(game.Players.LocalPlayer.PlayerScripts.Source.client.ModalManager)
    
    -- Method A: Dynamic Query Registration
    ModalManager.Register("DialogueSystem", function()
        return dialogueGui.Visible
    end)
    
    -- Method B: Direct State Toggle
    ModalManager.SetOpen("DialogueSystem", true)  -- Automatically frees cursor & freezes camera look
    ModalManager.SetOpen("DialogueSystem", false) -- Automatically locks cursor & restores GTA V dot
    ```
  - **Never** implement custom or duplicate mouse lock / camera code in individual UI scripts.

---

## 5. Audio Hierarchy & Look Sensitivity
### 4-Tier SoundGroup Architecture
All in-game audio instances **MUST** route through the centralized `MasterSoundGroup`:
```
SoundService
└── MasterSoundGroup (Master Volume)
    ├── SFXSoundGroup (UI hover, clicks, inventory, tool swings, footsteps)
    ├── MusicSoundGroup (Main menu theme, daytime ambient music, nightfall music)
    └── EnvironmentSoundGroup (Wind, nature, campfire fire crackle, crickets)
```
- **Volume Settings:** Volume sliders in the Settings Menu and Main Menu directly call:
  - `UITheme.SetMasterVolume(val)` (0.0 – 1.0)
  - `UITheme.SetSFXVolume(val)` (0.0 – 1.0)
  - `UITheme.SetMusicVolume(val)` (0.0 – 1.0)
  - `UITheme.SetEnvironmentVolume(val)` (0.0 – 1.0)
- **Look Sensitivity:** The Look Sensitivity slider controls `UserInputService.MouseDeltaSensitivity` directly:
  - Default: `1.0x`
  - Range: `0.2x` to `3.0x` (step `0.1x`)
  - Function: `UITheme.SetMouseSensitivity(val)`

---

## 6. Proximity Prompt Mouse-Trap Prevention
- All in-game `ProximityPrompt` instances (Wood piles, Silas the Trader, Campfire, Containers) **MUST have `ClickablePrompt = false`**.
- This prevents the Roblox engine from capturing the mouse cursor or trapping camera look when the center reticle sweeps across interactable objects.
- Interaction is strictly keyboard-driven (e.g. `[E]` Hold/Tap).

---

## 7. UI Design System & Aesthetics
- **Dark Glassmorphic Theme:**
  - Backgrounds: Obsidian black (`#060608`), elevated surface (`#141216`), deep charcoal (`#1C1A22`).
  - Transparencies: `0.15` to `0.45` with subtle background blur where applicable.
  - Corners: `UICorner` with radii between `6px` and `14px`.
  - Borders: `UIStroke` with 1px thickness and `0.3` to `0.8` transparency.
  - Accents: Frontier Gold / Amber (`#F5A028`, `#FFA040`), Ember Crimson (`#E63946`).
- **Zero Chunky Boxes:** Avoid plain, unrounded boxes, stark white frames, or raw Roblox defaults.
- **Micro-Interactions & Audio Feedback:**
  - Every button must include smooth `TweenService` hover/leave state transitions.
  - Hover triggers `AudioManager.Play("Hover")`.
  - Click triggers `AudioManager.Play("Click")`.
