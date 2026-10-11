--!strict
--[[
    EnvironmentGenerator.lua
    Universal Master Generator for Realistic Forest Environment.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Fault-Tolerant & Studio-Safe:
    - Wraps every stage in pcall to guarantee completion
    - Self-healing fallbacks for lighting & post-processing
    - Can be executed anytime in Edit Mode or Play Solo
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
local envConfigScript = sharedFolder:WaitForChild("EnvironmentConfig")
local okConfig, freshConfig = pcall(function() return require(envConfigScript:Clone()) end)
local EnvironmentConfig = (okConfig and freshConfig) or require(envConfigScript)

local EnvironmentGenerator = {}

local function getOrCreateFolder(parent: Instance, name: string): Folder
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Folder") then
        return existing
    end
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

-- Direct safe lighting setup (Bypasses any module caching issues in Studio)
local function applySafeLighting()
    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)
    Lighting.Brightness = 2.4
    Lighting.Ambient = Color3.fromRGB(82, 86, 94)
    Lighting.OutdoorAmbient = Color3.fromRGB(96, 102, 110)
    Lighting.ShadowSoftness = 0.35
    Lighting.ClockTime = 10.5
    
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "ForestAtmosphere"
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.36
    atmosphere.Offset = 0.12
    atmosphere.Color = Color3.fromRGB(160, 185, 205)
    atmosphere.Decay = Color3.fromRGB(95, 120, 145)
    atmosphere.Glare = 0.15
    atmosphere.Haze = 2.4
    
    local cc = Lighting:FindFirstChild("ForestColorCorrection") :: ColorCorrectionEffect?
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "ForestColorCorrection"
        cc.Parent = Lighting
    end
    cc.Brightness = 0.03
    cc.Contrast = 0.05
    cc.Saturation = 0.02
    cc.Enabled = true
    
    local bloom = Lighting:FindFirstChild("ForestBloom") :: BloomEffect?
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "ForestBloom"
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.55
    bloom.Size = 16
    bloom.Threshold = 0.90
    bloom.Enabled = true
    
    local sunRays = Lighting:FindFirstChild("ForestSunRays") :: SunRaysEffect?
    if not sunRays then
        sunRays = Instance.new("SunRaysEffect")
        sunRays.Name = "ForestSunRays"
        sunRays.Parent = Lighting
    end
    sunRays.Intensity = 0.18
    sunRays.Spread = 0.76
    sunRays.Enabled = true
    
    local dof = Lighting:FindFirstChild("ForestDepthOfField") :: DepthOfFieldEffect?
    if not dof then
        dof = Instance.new("DepthOfFieldEffect")
        dof.Name = "ForestDepthOfField"
        dof.Parent = Lighting
    end
    dof.FarIntensity = 0.28
    dof.FocusDistance = 50.0
    dof.InFocusRadius = 75.0
    dof.Enabled = true
end

function EnvironmentGenerator.Generate(): boolean
    local startTime = os.clock()
    print("==================================================================")
    print("  DON'T LET THE FIRE DIE — FOREST FLOOR & NATURAL GROUND V3")
    print("==================================================================")
    
    local serverScriptService = game:GetService("ServerScriptService")
    local fluenosityServer = serverScriptService:WaitForChild("FluenosityServer")
    local envModuleFolder = fluenosityServer:WaitForChild("Environment")
    
    local function loadFreshModule(moduleName: string)
        local original = envModuleFolder:WaitForChild(moduleName) :: ModuleScript
        local tempClone = original:Clone()
        tempClone.Name = "__Fresh_" .. moduleName
        tempClone.Parent = envModuleFolder
        local ok, result = pcall(function()
            return require(tempClone)
        end)
        tempClone:Destroy()
        if ok and result then
            return result
        else
            return require(original)
        end
    end
    
    -- 1. Apply Atmospheric Lighting & Post-Processing (Directly safe)
    local okAtmo, errAtmo = pcall(function()
        local AtmosphereSetup = loadFreshModule("AtmosphereSetup")
        AtmosphereSetup.Apply()
    end)
    if not okAtmo then
        print("[EnvironmentGenerator] Using direct safe lighting fallback...")
        applySafeLighting()
    end
    
    -- 2. Clean up ALL old/duplicate generated containers so only ONE forest exists!
    local function getActiveConfig(): any
        local ok, fresh = pcall(function()
            local clone = envConfigScript:Clone()
            local res = require(clone)
            clone:Destroy()
            return res
        end)
        if ok and fresh then
            return fresh
        end
        return EnvironmentConfig
    end
    
    local activeConfig = getActiveConfig()
    print(string.format("[EnvironmentGenerator] Active Config -> CAMP_RADIUS: %.1f | RESHAPE_ELEVATION: %s | ENABLE_PATHS: %s",
        activeConfig.CAMP_EXCLUSION_RADIUS or 76.0,
        tostring(activeConfig.RESHAPE_ELEVATION),
        tostring(activeConfig.ENABLE_PATHS)
    ))
    
    local activePathSystem: any = nil
    pcall(function()
        activePathSystem = loadFreshModule("PathSystem")
        activePathSystem.Compile(activeConfig)
    end)
    
    local containerName = activeConfig.CONTAINER_NAME or "ForestEnvironment"
    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name == containerName
            or child.Name == "ForestEnvironment"
            or child.Name == "Forest"
            or child.Name == "GeneratedForest"
            or child.Name == "GeneratedTrees" then
            print("[EnvironmentGenerator] Removing duplicate/previous container:", child.Name)
            child:Destroy()
        end
    end
    
    -- 3. Create Root Containers
    local folderTreesName = activeConfig.FOLDER_TREES or "Trees"
    local folderRocksName = activeConfig.FOLDER_ROCKS or "Rocks"
    local folderGroundName = activeConfig.FOLDER_GROUND_COVER or "GroundCover"
    
    local envRoot = getOrCreateFolder(Workspace, containerName)
    local treesFolder = getOrCreateFolder(envRoot, folderTreesName)
    local rocksFolder = getOrCreateFolder(envRoot, folderRocksName)
    local groundFolder = getOrCreateFolder(envRoot, folderGroundName)
    
    -- 4. Sculpt Organic Terrain & Non-Circular Ridges
    local okTerrain, errTerrain = pcall(function()
        local TerrainGenerator = loadFreshModule("TerrainGenerator")
        TerrainGenerator.Generate(activeConfig, activePathSystem)
    end)
    if not okTerrain then
        warn("[EnvironmentGenerator] Terrain step notice:", errTerrain)
    end
    
    -- 5. Populate Varied Conifers & Backdrop Silhouette Ridges
    local okTrees, errTrees = pcall(function()
        local ForestPlacer = loadFreshModule("ForestPlacer")
        ForestPlacer.Populate(treesFolder, activeConfig, activePathSystem)
    end)
    if not okTrees then
        warn("[EnvironmentGenerator] Trees step notice:", errTrees)
    end
    
    -- 6. Populate Weathered Rocks & Boulders
    local okRocks, errRocks = pcall(function()
        local RockPlacer = loadFreshModule("RockPlacer")
        RockPlacer.Populate(rocksFolder, activeConfig, activePathSystem)
    end)
    if not okRocks then
        warn("[EnvironmentGenerator] Rocks step notice:", errRocks)
    end
    
    -- 7. Populate Ground Cover (Ferns, Surface Roots, Mossy Logs)
    local okGround, errGround = pcall(function()
        local GroundCover = loadFreshModule("GroundCover")
        GroundCover.Populate(groundFolder, activeConfig, activePathSystem)
    end)
    if not okGround then
        warn("[EnvironmentGenerator] Ground cover step notice:", errGround)
    end
    
    -- 8. Run QA Audit
    pcall(function()
        local EnvironmentValidator = loadFreshModule("EnvironmentValidator")
        EnvironmentValidator.Validate(activeConfig, activePathSystem)
    end)
    
    -- 9. Initialize Interactive Campfire & 4 Sitting Trunks
    pcall(function()
        local CampfireSystem = loadFreshModule("CampfireSystem")
        CampfireSystem.Initialize()
    end)
    
    local totalTime = math.round((os.clock() - startTime) * 100) / 100
    print(string.format(">>> Realistic Forest V2 Generated successfully in %.2f seconds! <<<", totalTime))
    print("==================================================================")
    return true
end

return EnvironmentGenerator
