# Audio & Lighting Pipeline — Project: Undecided

> **Status:** `PROPOSED`  
> **Last updated:** 2026-10-11  
> **Technical Lead:** Audio Engineer & Lighting Technical Artist  
> **Related Documents:** [ART_DIRECTION.md](file:///i:/RobloxDev/docs/production/ART_DIRECTION.md), [PERFORMANCE_AND_MOBILE.md](file:///i:/RobloxDev/docs/technical/PERFORMANCE_AND_MOBILE.md)

---

## 1. System Vision & Atmosphere Goals

Survival horror is 60% sound and light. The audio and lighting pipelines are engineered in tandem to create an oppressive, reactive atmosphere where light represents life, and darkness is an active, predatory force.

---

## 2. Lighting Engine Configuration

Roblox engine settings configured under `Lighting`:

- **Technology:** `Enum.LightingTechnology.Future` (High/PC devices) with automatic fallback to `ShadowMap` on budget mobile devices.
- **GlobalShadows:** `true`.
- **ClockTime:** Driven continuously by `CampaignService` (06:00 Dawn, 12:00 Midday, 18:00 Dusk, 20:00 Night).
- **Ambient & OutdoorAmbient:**
  - Day: `Color3.fromRGB(80, 85, 75)`
  - Night: `Color3.fromRGB(2, 2, 5)` (True pitch black outside light cones).

### Post-Processing Stack
```text
Lighting/
├── Atmosphere          --> Density = 0.42, Offset = 0.25, Haze = 1.8 (Foreboding fog)
├── BloomEffect         --> Intensity = 0.65, Size = 24, Threshold = 1.8 (Ember glows)
├── ColorCorrection     --> Tint = Color3.fromRGB(240, 245, 255), Saturation = -0.15
├── DepthOfFieldEffect  --> FarIntensity = 0.4, FocusDistance = 35 (Subtle cinematic depth)
└── SunRaysEffect       --> Intensity = 0.15, Spread = 0.6 (Morning dawn beams)
```

### Dynamic Campfire Light Behavior
```lua
-- Campfire light controller client interpolation
local TweenService = game:GetService("TweenService")

function UpdateCampfireLight(light: PointLight, fuelPercent: number, tier: number)
    local targetRadius = 16 + (fuelPercent * 14) + (tier * 4) -- 16 to 34 studs
    local targetBrightness = 1.2 + (fuelPercent * 1.8)
    
    TweenService:Create(light, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
        Range = targetRadius,
        Brightness = targetBrightness
    }):Play()
end
```

---

## 3. Spatial Audio Hierarchy & Sound Groups

All audio assets route through a dedicated `SoundService` mix hierarchy to ensure sound readability during frantic monster encounters:

```text
SoundService/
└── MasterSoundGroup
    ├── MusicSoundGroup (Drums, ambient stingers) [Volume = 0.7]
    ├── AmbientSoundGroup (Wind, rain, distant crickets) [Volume = 0.8]
    ├── SFXSoundGroup (Chopping, fire crackle, UI ticks) [Volume = 1.0]
    └── MonsterSoundGroup (Screeches, footsteps, growls) [Volume = 1.2, Priority ducking]
```

### Priority Audio Ducking
When The Hollow emits an attack roar:
- `MonsterSoundGroup` plays at full volume.
- `AmbientSoundGroup` and `MusicSoundGroup` are instantly ducked by -6dB over 0.1s to guarantee maximum clarity and startle factor.

---

## 4. Acoustic Occlusion & Raycast Dampening

To prevent players from hearing monster footsteps through solid concrete walls or thick boulders as if they were in the same room:
- `AudioController` casts a light raycast from player camera to the monster sound origin.
- If an opaque part obstructs the ray:
  - Low-pass filter (EqualizerSoundEffect) cuts frequencies above 1,200 Hz.
  - Sound volume is reduced by 40%.
- Gives players a realistic, muffled cue: *"It's on the other side of the fence!"*

---

## 5. Acceptance Criteria

- [ ] **AC-AL-01:** Nighttime lighting reaches near-zero ambient illumination; objects outside campfire radius are completely black silhouettes.
- [ ] **AC-AL-02:** Campfire point light smoothly adjusts range and brightness as fuel changes without visual popping.
- [ ] **AC-AL-03:** Monster audio roars correctly duck background ambient sounds by -6dB.
- [ ] **AC-AL-04:** Acoustic raycasts muffle monster sounds behind solid shelter walls.
