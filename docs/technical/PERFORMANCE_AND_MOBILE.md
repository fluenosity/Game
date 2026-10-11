# Performance Budgets & Mobile Optimization — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Optimization & Platform Performance Lead  
> **Related Documents:** [ROBLOX_ARCHITECTURE.md](file:///i:/RobloxDev/docs/technical/ROBLOX_ARCHITECTURE.md), [UI_AND_INPUT_ARCHITECTURE.md](file:///i:/RobloxDev/docs/technical/UI_AND_INPUT_ARCHITECTURE.md)

---

## 1. Technical Mandate & Target Hardware

Over 60% of Roblox active users access games on mobile devices (smartphones, budget tablets) with constrained RAM, passive cooling, and thermal throttling limits. *Project: Undecided* must maintain rock-solid performance across all target tiers.

### Target Device Profiles

| Profile Tier | Representative Devices | Target Frame Rate | Max Memory Cap | Lighting Tech |
|--------------|------------------------|-------------------|----------------|---------------|
| **Low-End Mobile** | iPhone 8 / Galaxy A14 (2–3 GB RAM) | 30 FPS stable | < 900 MB | ShadowMap / Low FX |
| **Mid-End Mobile** | iPhone 12 / Galaxy S21 (4–6 GB RAM) | 45–60 FPS | < 1,200 MB | Future / Medium FX |
| **PC & Console** | GTX 1060+ / PS4 / Xbox One / Mac M1 | 60 FPS locked | < 2,000 MB | Future / Full FX |

---

## 2. Hard Performance Budgets

1. **Draw Calls & Mesh Triangles:**
   - Shelter compound total triangles: < 45,000 tris.
   - Individual choppable tree: < 1,200 tris.
   - Monster model ("The Hollow"): < 6,500 tris.
2. **Texture Memory & Resolution:**
   - Textures capped at 512×512 for foliage, bark, and ground.
   - Max 1024×1024 reserved only for key narrative props (Signal Tower, Silas Cart, Campfire).
3. **Audio Voice Budget:**
   - Maximum 16 concurrent audio channels active simultaneously.
4. **Active Particle Emitters:**
   - Total active particles on screen: < 250 particles.
   - Rain weather uses camera-attached localized emitter (rate = 60 particles/sec) instead of world-wide volume spawning.

---

## 3. StreamingEnabled & Memory Eviction Strategy

- **StreamingMinRadius:** 96 studs.
- **StreamingTargetRadius:** 320 studs.
- **StreamOutBehavior:** `Enum.StreamOutBehavior.LowMemory`.
- **Garbage Collection Policy:**
  - Destroyed trees and gathered scrap nodes are immediately parented to `nil` and dereferenced.
  - No permanent table caches holding player character references after disconnection.

---

## 4. Mobile Quality Setting Auto-Detection

Upon player initialization, the client runs a 3-second hardware capability heuristic:

```lua
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

function GetOptimalQualityProfile(): "Low" | "Medium" | "High"
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    
    if isMobile then
        -- Check available system memory if platform exposes or infer via screen resolution
        local viewport = workspace.CurrentCamera.ViewportSize
        if viewport.X < 1400 then
            return "Low"
        else
            return "Medium"
        end
    end
    
    return "High"
end
```

### Quality Scaler Toggles
- **Low Profile:** Disables volumetric fog, caps particle count by 50%, reduces point light update frequency to 15 Hz, disables depth of field.
- **High Profile:** Full volumetric atmosphere, 60 Hz point light tweens, high-res audio reverb.

---

## 5. Acceptance Criteria

- [ ] **AC-PERF-01:** Low-end mobile profile runs at >= 30 FPS inside the shelter during full night campfire defense.
- [ ] **AC-PERF-02:** Total client memory footprint remains below 900 MB across a full 5-day campaign.
- [ ] **AC-PERF-03:** World assets beyond 320 studs stream out cleanly without lingering memory leaks.
- [ ] **AC-PERF-04:** Device thermal throttling does not drop frame rate below 25 FPS during 30-minute play sessions.
