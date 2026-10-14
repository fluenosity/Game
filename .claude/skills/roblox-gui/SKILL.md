---
name: roblox-gui
description: "Use when building Roblox menus, HUDs, shops, notifications, dialogs, or responsive cross-platform UI."
last_reviewed: 2026-10-02
sources:
  - https://create.roblox.com/docs/ui
  - https://create.roblox.com/docs/ui/position-and-size
  - https://create.roblox.com/docs/ui/styling
  - https://create.roblox.com/docs/ui/list-flex-layouts
  - https://create.roblox.com/docs/input
  - https://create.roblox.com/docs/reference/engine/classes/GuiService
  - https://create.roblox.com/docs/reference/engine/classes/GuiObject
  - https://create.roblox.com/docs/reference/engine/classes/ScreenGui
  - https://create.roblox.com/docs/projects/server-authority
  - https://create.roblox.com/docs/input/input-action-system
  - https://create.roblox.com/docs/reference/engine/classes/ReplicatedFirst
  - https://create.roblox.com/docs/reference/engine/classes/ContentProvider
  - https://create.roblox.com/docs/reference/engine/classes/UIPageLayout
  - https://create.roblox.com/docs/reference/engine/classes/SelectionBox
  - https://create.roblox.com/docs/reference/engine/classes/Decal
  - https://create.roblox.com/docs/reference/engine/classes/VideoPlayer
  - https://raw.githubusercontent.com/Roblox/focus-navigation/main/README.md
  - https://devforum.roblox.com/t/introducing-improvements-to-directional-ui-selection-on-gamepad/3864317
  - https://devforum.roblox.com/t/what-are-the-best-ui-screeninset-settings-for-buttons/3519333
  - https://devforum.roblox.com/t/screenguiscreeninsets-topbarinsets-regression/4047230
  - https://raw.githubusercontent.com/Roblox/react-luau/main/README.md
  - https://raw.githubusercontent.com/dphfox/Fusion/main/README.md
  - https://raw.githubusercontent.com/centau/vide/main/README.md
  - https://raw.githubusercontent.com/ffrostfall/fluid/main/README.md
  - original
---

# roblox gui

## When to Load

Load for HUDs, menus, shops, dialogs, notifications, or world-space UI.

## Quick Reference

- `ScreenGui` overlays; `SurfaceGui` on surfaces; `BillboardGui` for world labels.
- Let layouts and constraints own repeated layout; avoid per-frame pixel positioning.
- `Scale` for responsive structure; `Offset` for padding/fixed-size details.
- Design for touch/gamepad too. Use `ContextActionService` for gameplay bindings where appropriate.
- Test directional focus; set `GuiService.SelectedObject` for gamepad entry.
- Follow existing visual language and owner art direction; test UI over the game world.
- UI displays server state; a button is not an authority boundary.
- Reactive UI: own per-screen cleanup separately from session state; repeat open/close to test leaks (full.md).
- Server Authority: display confirmed inventory/currency; route gameplay input through Input Actions.
- Resolve scrolling, text growth, clipping, and safe areas before polish.
- Loading UI belongs in `ReplicatedFirst`; client character teleports are not readiness gates.

> Layout and lifecycle examples: [references/full.md](references/full.md)
