--!strict
--[[
    AtmosphereSetup.lua
    Atmospheric Lighting, Horizon Depth Fog, and Post-Processing Engine.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    V2 Enhancements:
    - Lifted Ambient & OutdoorAmbient (Prevents tree canopies from becoming pitch black voids)
    - Volumetric Mountain Horizon Mist (Atmosphere Haze + Density naturally conceals world edges)
    - Low-contrast ColorCorrection (Preserves bark texture and foliage needle definition)
    - SunRays godbeams streaming through the conifer canopy
    - 100% resilient defaults to handle studio module cache transitions
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EnvironmentConfig = require(ReplicatedStorage:WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig"))

local AtmosphereSetup = {}

function AtmosphereSetup.Apply()
    local cfg = (EnvironmentConfig and EnvironmentConfig.POST_PROCESSING) or {}
    local lightCfg = (cfg and cfg.Lighting) or (EnvironmentConfig and EnvironmentConfig.Lighting) or {}
    local atmoCfg = (cfg and cfg.Atmosphere) or (EnvironmentConfig and EnvironmentConfig.Atmosphere) or {}
    local ccCfg = (cfg and cfg.ColorCorrection) or (EnvironmentConfig and EnvironmentConfig.ColorCorrection) or {}
    local bloomCfg = (cfg and cfg.Bloom) or (EnvironmentConfig and EnvironmentConfig.Bloom) or {}
    local raysCfg = (cfg and cfg.SunRays) or (EnvironmentConfig and EnvironmentConfig.SunRays) or {}
    local dofCfg = (cfg and cfg.DepthOfField) or (EnvironmentConfig and EnvironmentConfig.DepthOfField) or {}
    
    -- 1. Lighting Technology & Core Ambient Illumination
    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)
    
    Lighting.Brightness = lightCfg.Brightness or 2.2
    Lighting.Ambient = lightCfg.Ambient or Color3.fromRGB(115, 118, 128)
    Lighting.OutdoorAmbient = lightCfg.OutdoorAmbient or Color3.fromRGB(118, 122, 132)
    Lighting.ShadowSoftness = lightCfg.ShadowSoftness or 0.35
    Lighting.ClockTime = lightCfg.ClockTime or 10.5
    Lighting.GeographicLatitude = lightCfg.GeographicLatitude or 48.0
    Lighting.ExposureCompensation = lightCfg.ExposureCompensation or 0.02
    
    -- 2. Volumetric Atmosphere (Conceals map edges with realistic horizon mountain mist)
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "ForestAtmosphere"
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = atmoCfg.Density or 0.25
    atmosphere.Offset = atmoCfg.Offset or 0.12
    atmosphere.Color = atmoCfg.Color or Color3.fromRGB(175, 195, 220)
    atmosphere.Decay = atmoCfg.Decay or Color3.fromRGB(100, 120, 145)
    atmosphere.Glare = atmoCfg.Glare or 0.15
    atmosphere.Haze = atmoCfg.Haze or 2.0
    
    -- 3. ColorCorrectionEffect (Restrained contrast so tree bark & needles stay readable)
    local cc = Lighting:FindFirstChild("ForestColorCorrection") :: ColorCorrectionEffect?
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "ForestColorCorrection"
        cc.Parent = Lighting
    end
    cc.Brightness = ccCfg.Brightness or 0.01
    cc.Contrast = ccCfg.Contrast or 0.03
    cc.Saturation = ccCfg.Saturation or 0.02
    cc.TintColor = ccCfg.TintColor or Color3.fromRGB(248, 246, 242)
    cc.Enabled = true
    
    -- 4. BloomEffect (Soft gentle highlight bleed, high threshold so props don't shine like neon)
    local bloom = Lighting:FindFirstChild("ForestBloom") :: BloomEffect?
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "ForestBloom"
        bloom.Parent = Lighting
    end
    bloom.Intensity = bloomCfg.Intensity or 0.22
    bloom.Size = bloomCfg.Size or 12
    bloom.Threshold = bloomCfg.Threshold or 1.40
    bloom.Enabled = true
    
    -- 5. SunRaysEffect (Godbeams filtering through tall pines)
    local sunRays = Lighting:FindFirstChild("ForestSunRays") :: SunRaysEffect?
    if not sunRays then
        sunRays = Instance.new("SunRaysEffect")
        sunRays.Name = "ForestSunRays"
        sunRays.Parent = Lighting
    end
    sunRays.Intensity = raysCfg.Intensity or 0.15
    sunRays.Spread = raysCfg.Spread or 0.70
    sunRays.Enabled = true
    
    -- 6. DepthOfFieldEffect (Foreground clarity, distant mountain depth)
    local dof = Lighting:FindFirstChild("ForestDepthOfField") :: DepthOfFieldEffect?
    if not dof then
        dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "ForestDepthOfField"
        dof.Parent = Lighting
    end
    dof.FarIntensity = dofCfg.FarIntensity or 0.28
    dof.FocusDistance = dofCfg.FocusDistance or 50.0
    dof.InFocusRadius = dofCfg.InFocusRadius or 75.0
    dof.NearIntensity = dofCfg.NearIntensity or 0.0
    dof.Enabled = true
    
    -- 7. Controlled Campfire Warmth (Prevents multiple stacked lights and blinding over-illumination)
    pcall(function()
        local ws = game:GetService("Workspace")
        -- 1. Purge ALL existing CampfireGlow lights to prevent brightness stacking
        for _, obj in ipairs(ws:GetDescendants()) do
            if obj.Name == "CampfireGlow" and obj:IsA("PointLight") then
                obj:Destroy()
            end
        end
        
        -- 2. Find ONE primary fire part in the campsite
        local primaryFirePart: BasePart? = nil
        for _, obj in ipairs(ws:GetDescendants()) do
            if obj:IsA("Fire") and obj.Parent and obj.Parent:IsA("BasePart") then
                primaryFirePart = obj.Parent :: BasePart
                break
            end
        end
        if not primaryFirePart then
            for _, obj in ipairs(ws:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name:lower() == "campfire" or obj.Name:lower() == "firepit") then
                    primaryFirePart = obj
                    break
                end
            end
        end
        
        -- 3. Create a single cozy, warm campfire light (not blinding!)
        if primaryFirePart then
            local light = Instance.new("PointLight")
            light.Name = "CampfireGlow"
            light.Color = Color3.fromRGB(255, 138, 48) -- Rich warm amber flame
            light.Range = 34.0                        -- Cozy circle around fire pit
            light.Brightness = 1.15                   -- Soft natural flicker brightness
            light.Shadows = true
            light.Parent = primaryFirePart
        end
    end)
    
    print("[AtmosphereSetup] Applied cozy campfire illumination, soft bloom, and balanced forest lighting.")
end

return AtmosphereSetup
