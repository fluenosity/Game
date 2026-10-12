# Don't Let the Fire Die — Project Directives & Behavioral Constraints

This file defines mandatory project rules for AI pair-programming and autonomous tasks in this workspace.

## 1. World Generation & Spawners Policy
- **NEVER** run world generation, terrain scripts, rock placers, tree spawners, or environment generators (`EnvironmentGenerator.lua`, `RockPlacer.lua`, etc.) automatically.
- Only run them if the user explicitly types a command like `"run world gen"`, `"spawn rocks"`, or `"regenerate map"`.
- Preserve existing place geometry in `Place1.rbxl`.

## 2. Dev Environment Settings
- **Daylight:** Keep the day/night cycle stuck at daytime (`ClockTime = 14:00`, `DAY_ONLY_DEV = true`) for clear visibility during development.
- **Stamina:** Unlimited player stamina in dev mode (`UNLIMITED_STAMINA_DEV = true`).
- **Sprint Indicator:** The half-circle Genshin-style sprint bar over the character's head is permanently removed. Do not restore it.

## 3. First-Person Perspective (FPP) & GTA V Reticle
- Game is strictly First-Person Perspective (`CameraMode = Enum.CameraMode.LockFirstPerson`, zoom distance strictly locked to `0.5`).
- Active gameplay has locked cursor (`MouseBehavior = LockCenter`, `MouseIconEnabled = false`) and displays the GTA V 5x5 center dot reticle (`HUDCrosshair.lua`).

## 4. Cursor Freedom & Modals (ModalManager Architecture)
- Pressing or holding `[Alt]` or opening ANY modal (Backpack `[B]`, Settings Menu `[ESC]`, Silas Barter `[E]`, Dialogue, etc.) must freeze camera look (`CameraType = Scriptable` attached to character head) and unlock the cursor (`MouseBehavior = Default`, `MouseIconEnabled = true`), hiding the reticle.
- Closing ANY modal or releasing `[Alt]` must immediately restore `CameraType = Custom`, `MouseBehavior = LockCenter`, `MouseIconEnabled = false`, and display the GTA V reticle without requiring an extra mouse click.
- **For future modals/dialogues:** Always use `ModalManager.lua` (`ModalManager.Register` or `ModalManager.SetOpen`). Never write ad-hoc cursor lock logic.

## 5. Audio & Sensitivity Architecture
- 4-Tier SoundGroup hierarchy rooted under `MasterSoundGroup`:
  - `MasterSoundGroup` (Global Volume)
  - `SFXSoundGroup` (UI clicks, hovers, inventory, tool swings, footsteps)
  - `MusicSoundGroup` (BGM, main menu theme, ambient tracks)
  - `EnvironmentSoundGroup` (Nature, wind, campfire fire crackle, crickets)
- Look Sensitivity slider drives `UserInputService.MouseDeltaSensitivity` directly via `UITheme.SetMouseSensitivity(val)`.

## 6. Proximity Prompt Mouse-Trap Prevention
- All `ProximityPrompt` instances must have `ClickablePrompt = false` to prevent mouse trapping in FPP.

## 7. UI Design & Luxury Aesthetics
- Glassmorphic obsidian/ember aesthetic with rounded corners and subtle border strokes.
- Never use plain default boxes or raw Roblox primitives.
- Micro-animations and audio cues (`AudioManager.Play("Hover")`, `AudioManager.Play("Click")`) on all interactive buttons.
