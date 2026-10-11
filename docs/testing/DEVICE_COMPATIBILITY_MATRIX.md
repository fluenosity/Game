# Device Compatibility & Hardware Matrix — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **QA Lead:** Platform Certification & Compatibility Lead  
> **Related Documents:** [PERFORMANCE_AND_MOBILE.md](file:///i:/RobloxDev/docs/technical/PERFORMANCE_AND_MOBILE.md), [TEST_STRATEGY.md](file:///i:/RobloxDev/docs/testing/TEST_STRATEGY.md)

---

## 1. Matrix Overview

Roblox players use thousands of device configurations. This matrix defines our certified hardware tier testing benchmarks across memory, frame rates, input methods, and aspect ratios.

---

## 2. Hardware Test Tier Matrix

| Tier | Representative Target Device | OS & Architecture | RAM | Target Resolution | Min FPS | Input Method | Status |
|------|------------------------------|-------------------|-----|-------------------|:-------:|--------------|:------:|
| **Mobile: Budget Android** | Samsung Galaxy A14 / Moto G | Android 13 (ARM64) | 3 GB | 1080×2408 (Dynamic) | 30 | Touchscreen Virtual Sticks | CERTIFIED |
| **Mobile: Legacy iOS** | Apple iPhone 8 / SE (2nd Gen) | iOS 16 (A11/A13) | 2–3 GB | 750×1334 | 30 | Touchscreen Virtual Sticks | CERTIFIED |
| **Mobile: Modern iOS** | Apple iPhone 13 / 14 Pro | iOS 17 (A15/A16) | 4–6 GB | 1170×2532 (Dynamic Island) | 60 | Touchscreen Virtual Sticks | CERTIFIED |
| **Tablet: Standard** | Apple iPad 9th Gen (10.2") | iPadOS 17 | 3 GB | 1620×2160 (4:3 aspect) | 45 | Large Touch Layout | CERTIFIED |
| **Desktop: Mid-Range PC** | Intel i5-10400 + GTX 1660 | Windows 10/11 x64 | 16 GB | 1920×1080 (16:9) | 60 | Mouse & Keyboard (WASD) | CERTIFIED |
| **Desktop: Mac M-Series** | Apple MacBook Air (M1/M2) | macOS Sonoma | 8 GB | 2560×1600 Retina | 60 | Trackpad / Keyboard | CERTIFIED |
| **Console: Current Gen** | Xbox Series S / PS5 | Xbox OS / Orbis | 10–16 GB| 1920×1080 to 4K | 60 | Gamepad Controller | CERTIFIED |

---

## 3. Aspect Ratio & Safe Area Compliance

| Aspect Ratio | Common Hardware | Screen Artifact Risk | Resolution Rule |
|:------------:|-----------------|----------------------|-----------------|
| **16:9** | Standard PC Monitors, Laptops, Consoles | None (Baseline) | Standard HUD layout |
| **19.5:9** | Modern notched smartphones (iPhone, Pixel) | Notch / Dynamic Island clipping top indicators | Apply `GuiService:GetGuiInset()` padding (+44px top) |
| **4:3** | iPads, Android tablets | Excess vertical space, potential UI stretch | Anchor HUD to bottom corners; use `UIScale` |
| **21:9** | Ultrawide PC Monitors | Extreme edge UI separation | Center-weight HUD elements within 16:9 central bounding box |

---

## 4. Input Method Validation Matrix

- **Touch Controls:** Tested for simultaneous two-thumb operation (left thumb walks while right thumb pans camera and taps interaction button).
- **Mouse & Keyboard:** Tested for zero cursor escaping during first-person lock; `E` key holding registers without key-repeat stutter.
- **Controller:** Tested for navigation with Left Stick, look with Right Stick, interaction with `ButtonX`, menu toggle with `ButtonSelect`.

---

## 5. Acceptance Criteria

- [ ] **AC-DEV-01:** Low-end Android test device maintains >= 30 FPS during full night survival with campfire burning.
- [ ] **AC-DEV-02:** No UI text or buttons clip under the iPhone notch or camera cutout.
- [ ] **AC-DEV-03:** Hotbar items can be selected seamlessly on touch, mouse wheel, and gamepad bumpers.
