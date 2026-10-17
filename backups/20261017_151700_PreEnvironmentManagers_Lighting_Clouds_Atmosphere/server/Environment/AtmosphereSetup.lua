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
    
    Lighting.Brightness = lightCfg.Brightness or 2.8
    Lighting.Ambient = lightCfg.Ambient or Color3.fromRGB(75, 90, 110)
    Lighting.OutdoorAmbient = lightCfg.OutdoorAmbient or Color3.fromRGB(115, 132, 150)
    Lighting.ShadowSoftness = lightCfg.ShadowSoftness or 0.15
    Lighting.ClockTime = lightCfg.ClockTime or 14.5
    Lighting.GeographicLatitude = lightCfg.GeographicLatitude or 48.0
    Lighting.ExposureCompensation = lightCfg.ExposureCompensation or 0.02
    Lighting.EnvironmentDiffuseScale = lightCfg.EnvironmentDiffuseScale or 1.0
    Lighting.EnvironmentSpecularScale = lightCfg.EnvironmentSpecularScale or 0.85
    Lighting.FogEnd = lightCfg.FogEnd or 2400.0 -- High FogEnd so terrain is never washed out
    
    -- 2. Volumetric Atmosphere (Reduced haze: hills & vegetation are vividly clear!)
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "ForestAtmosphere"
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = atmoCfg.Density or 0.34
    atmosphere.Offset = atmoCfg.Offset or 0.18
    atmosphere.Color = atmoCfg.Color or Color3.fromRGB(175, 200, 225)
    atmosphere.Decay = atmoCfg.Decay or Color3.fromRGB(95, 120, 145)
    atmosphere.Glare = atmoCfg.Glare or 0.25
    atmosphere.Haze = atmoCfg.Haze or 1.80 -- Soft mountain horizon mist matching Editor view!
    
    -- 3. ColorCorrectionEffect (Rich alpine depth, lush conifer greens, warm amber firelight)
    local cc = Lighting:FindFirstChild("ForestColorCorrection") :: ColorCorrectionEffect?
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "ForestColorCorrection"
        cc.Parent = Lighting
    end
    cc.Brightness = ccCfg.Brightness or 0.02
    cc.Contrast = ccCfg.Contrast or 0.06
    cc.Saturation = ccCfg.Saturation or 0.15
    cc.TintColor = ccCfg.TintColor or Color3.fromRGB(255, 252, 246)
    cc.Enabled = true

    -- 3B. Production High-Res Celestial Skybox & Stars
    local skyCfg = (EnvironmentConfig and EnvironmentConfig.SKY and EnvironmentConfig.SKY.Day) or {}
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Name = "Sky"
        sky.Parent = Lighting
    end
    sky.SkyboxBk = skyCfg.SkyboxBk or "http://www.roblox.com/asset/?id=91458024"
    sky.SkyboxDn = skyCfg.SkyboxDn or "http://www.roblox.com/asset/?id=91457980"
    sky.SkyboxFt = skyCfg.SkyboxFt or "http://www.roblox.com/asset/?id=91458024"
    sky.SkyboxLf = skyCfg.SkyboxLf or "http://www.roblox.com/asset/?id=91458024"
    sky.SkyboxRt = skyCfg.SkyboxRt or "http://www.roblox.com/asset/?id=91458024"
    sky.SkyboxUp = skyCfg.SkyboxUp or "http://www.roblox.com/asset/?id=91458002"
    sky.SunTextureId = "rbxassetid://6281397916"
    sky.MoonTextureId = "rbxassetid://2626744426"
    sky.SunAngularSize = 21
    sky.MoonAngularSize = 12
    sky.CelestialBodiesShown = true
    
    -- 3C. Animated Volumetric Clouds (Parented under Workspace.Terrain for engine visibility!)
    -- Purge any duplicate clouds under Lighting
    for _, ch in ipairs(Lighting:GetChildren()) do
        if ch:IsA("Clouds") then
            ch:Destroy()
        end
    end
    local terrain = workspace.Terrain
    local clouds = terrain:FindFirstChildOfClass("Clouds")
    if not clouds then
        clouds = Instance.new("Clouds")
        clouds.Name = "VolumetricClouds"
        clouds.Parent = terrain
    end
    clouds.Cover = 0.32
    clouds.Density = 0.55
    clouds.Color = Color3.fromRGB(245, 248, 255)
    -- GlobalWind physically animates realistic continuous cloud drift across the sky!
    workspace.GlobalWind = Vector3.new(16, 0, 10)
    
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
    
    -- 6. DepthOfFieldEffect (Pin-sharp valley interior, softly blends distant jagged mountains)
    local dof = Lighting:FindFirstChild("ForestDepthOfField") :: DepthOfFieldEffect?
    if not dof then
        dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "ForestDepthOfField"
        dof.Parent = Lighting
    end
    dof.FarIntensity = dofCfg.FarIntensity or 0.20 -- Softens distant low-poly mountain polygon silhouette
    dof.FocusDistance = dofCfg.FocusDistance or 280.0 -- Full interior basin in crisp focus
    dof.InFocusRadius = dofCfg.InFocusRadius or 240.0 -- 0 to 520 studs is crystal clear
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
            light.Color = Color3.fromRGB(255, 142, 42) -- Rich warm amber flame (Matching Reference Image 2)
            light.Range = 55.0                        -- Full campsite illumination
            light.Brightness = 3.5                    -- Warm radiant glow
            light.Shadows = true                      -- Real-time contact shadows on rocks & fence
            light.Parent = primaryFirePart
        end
    end)
    
    print("[AtmosphereSetup] Applied cozy campfire illumination, soft bloom, and balanced forest lighting.")
end

return AtmosphereSetup
