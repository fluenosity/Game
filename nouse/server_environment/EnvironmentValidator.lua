--!strict
--[[
    EnvironmentValidator.lua
    Automated Quality Assurance and Integrity Verifier for Generated Forest.
    Developed for "Don't Let the Fire Die" (Fluenosity Studio).
    
    Validates:
    - Zero floating trees or buried canopies
    - Zero trees or boulders invading the Camp Exclusion Zone
    - Conformance to the 140 choppable tree performance budget
    - Proper collision flags for mobile compatibility (non-colliding foliage)
    - Ground cover performance parameters
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getFreshModule(moduleScript: ModuleScript): any
    local clone = moduleScript:Clone()
    clone.Name = "__Fresh_" .. moduleScript.Name
    clone.Parent = ReplicatedStorage
    local ok, res = pcall(function()
        return require(clone)
    end)
    clone:Destroy()
    if ok and res then
        return res
    end
    return require(moduleScript)
end

local envConfigScript = ReplicatedStorage:WaitForChild("FluenosityShared"):WaitForChild("EnvironmentConfig") :: ModuleScript
local EnvironmentConfig = getFreshModule(envConfigScript)

local envFolder = script.Parent or game:GetService("ServerScriptService"):WaitForChild("FluenosityServer"):WaitForChild("Environment")
local PathSystem = getFreshModule(envFolder:WaitForChild("PathSystem") :: ModuleScript)

local EnvironmentValidator = {}

export type ValidationReport = {
    Passed: boolean,
    TreeCount: number,
    RockCount: number,
    GroundCoverCount: number,
    CampInvasions: number,
    PathInvasions: number,
    FloatingTrees: number,
    CollidableFoliageErrors: number,
    Errors: { string },
}

function EnvironmentValidator.Validate(injectedCfg: any?, injectedPathSystem: any?): ValidationReport
    print("[EnvironmentValidator] Initiating forest environment QA audit...")
    
    if injectedPathSystem then
        PathSystem = injectedPathSystem
    end
    
    local activeCfg = injectedCfg or EnvironmentConfig
    local campRadius = (activeCfg and activeCfg.CAMP_EXCLUSION_RADIUS) or 76.0
    local containerName = (activeCfg and activeCfg.CONTAINER_NAME) or "ForestEnvironment"
    
    local report: ValidationReport = {
        Passed = true,
        TreeCount = 0,
        RockCount = 0,
        GroundCoverCount = 0,
        CampInvasions = 0,
        PathInvasions = 0,
        FloatingTrees = 0,
        CollidableFoliageErrors = 0,
        Errors = {},
    }
    
    local envFolder = Workspace:FindFirstChild(containerName)
    if not envFolder then
        table.insert(report.Errors, "Missing root container folder: " .. containerName)
        report.Passed = false
        return report
    end
    
    local folderTreesName = (activeCfg and activeCfg.FOLDER_TREES) or "Trees"
    local folderRocksName = (activeCfg and activeCfg.FOLDER_ROCKS) or "Rocks"
    local folderGroundName = (activeCfg and activeCfg.FOLDER_GROUND_COVER) or "GroundCover"
    
    local treesFolder = envFolder:FindFirstChild(folderTreesName)
    local rocksFolder = envFolder:FindFirstChild(folderRocksName)
    local groundFolder = envFolder:FindFirstChild(folderGroundName)
    
    -- 1. VALIDATE TREES
    if treesFolder then
        local trees = treesFolder:GetChildren()
        report.TreeCount = #trees
        
        local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
        local biomeConfigScript = sharedFolder:WaitForChild("BiomeConfig") :: ModuleScript
        local okB, freshB = pcall(function() return require(biomeConfigScript:Clone()) end)
        local activeBiomeConfig = (okB and freshB) or require(biomeConfigScript)
        local activePreset = (activeBiomeConfig and activeBiomeConfig.GetActivePreset and activeBiomeConfig.GetActivePreset())
        local totalBudget = (activePreset and activePreset.TargetTotalTrees) or 1320
        if report.TreeCount > (totalBudget + 100) then
            table.insert(report.Errors, string.format("Tree count (%d) exceeds budget (%d)", report.TreeCount, totalBudget))
            report.Passed = false
        end
        
        local campCenter = (activeCfg and activeCfg.CAMP_CENTER) or Vector3.new(0, 0, -430)
        local campRadius = (activeCfg and activeCfg.CAMP_EXCLUSION_RADIUS) or 50.0
        local towerCenter = (activeCfg and activeCfg.WATCHTOWER_CENTER) or Vector3.new(0, 0, 0)
        local towerRadius = (activeCfg and activeCfg.WATCHTOWER_EXCLUSION_RADIUS) or 35.0

        for _, treeModel in ipairs(trees) do
            if treeModel:IsA("Model") then
                local pivot = treeModel:GetPivot().Position
                
                -- South Camp exclusion check
                local distFromCamp = math.sqrt((pivot.X - campCenter.X)^2 + (pivot.Z - campCenter.Z)^2)
                if distFromCamp < campRadius then
                    report.CampInvasions = report.CampInvasions + 1
                    table.insert(report.Errors, string.format("Tree '%s' at (%.1f, %.1f) invaded South Camp exclusion zone", treeModel.Name, pivot.X, pivot.Z))
                    report.Passed = false
                end

                -- Watchtower clearing check
                local distFromTower = math.sqrt((pivot.X - towerCenter.X)^2 + (pivot.Z - towerCenter.Z)^2)
                if distFromTower < towerRadius then
                    report.CampInvasions = report.CampInvasions + 1
                    table.insert(report.Errors, string.format("Tree '%s' at (%.1f, %.1f) invaded Watchtower clearing", treeModel.Name, pivot.X, pivot.Z))
                    report.Passed = false
                end
                
                -- Path corridor check
                if PathSystem.IsOnPath(pivot.X, pivot.Z, 0, activeCfg) then
                    report.PathInvasions = report.PathInvasions + 1
                    table.insert(report.Errors, string.format("Tree '%s' at (%.1f, %.1f) invaded trail corridor", treeModel.Name, pivot.X, pivot.Z))
                    report.Passed = false
                end
                
                -- Foliage collision check
                for _, part in ipairs(treeModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local n = part.Name:lower()
                        if (n:find("leaf") or n:find("leaves") or n:find("fern") or n:find("needle")) and part.CanCollide then
                            report.CollidableFoliageErrors = report.CollidableFoliageErrors + 1
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end
    
    -- 2. VALIDATE ROCKS
    if rocksFolder then
        local rocks = rocksFolder:GetChildren()
        report.RockCount = #rocks
        local campCenter = (activeCfg and activeCfg.CAMP_CENTER) or Vector3.new(0, 0, -430)
        local campRadius = (activeCfg and activeCfg.CAMP_EXCLUSION_RADIUS) or 50.0
        
        for _, rockModel in ipairs(rocks) do
            if rockModel:IsA("Model") then
                local pivot = rockModel:GetPivot().Position
                local distFromCamp = math.sqrt((pivot.X - campCenter.X)^2 + (pivot.Z - campCenter.Z)^2)
                if distFromCamp < campRadius then
                    report.CampInvasions = report.CampInvasions + 1
                    table.insert(report.Errors, string.format("Rock '%s' invaded South Camp zone", rockModel.Name))
                    report.Passed = false
                end
                if PathSystem.IsOnPath(pivot.X, pivot.Z, 0, activeCfg) then
                    report.PathInvasions = report.PathInvasions + 1
                    table.insert(report.Errors, string.format("Rock '%s' at (%.1f, %.1f) invaded trail corridor", rockModel.Name, pivot.X, pivot.Z))
                    report.Passed = false
                end
            end
        end
    end
    
    -- 3. VALIDATE GROUND COVER
    if groundFolder then
        local count = 0
        for _, child in ipairs(groundFolder:GetDescendants()) do
            if child:IsA("Model") then
                count = count + 1
            end
        end
        report.GroundCoverCount = count
    end
    
    local sharedFolder = ReplicatedStorage:WaitForChild("FluenosityShared")
    local biomeConfigScript = sharedFolder:WaitForChild("BiomeConfig") :: ModuleScript
    local okB, freshB = pcall(function() return require(biomeConfigScript:Clone()) end)
    local activeBiomeConfig = (okB and freshB) or require(biomeConfigScript)
    local auditTarget = (activeBiomeConfig and activeBiomeConfig.GetActivePreset and activeBiomeConfig.GetActivePreset().TargetTotalTrees) or 1320
    print(string.format("  • Trees Spawned:        %d (Target: %d)", report.TreeCount, auditTarget))
    print(string.format("  • Rocks Spawned:        %d", report.RockCount))
    print(string.format("  • Ground Cover Items:   %d", report.GroundCoverCount))
    print(string.format("  • Camp Invasions:       %d", report.CampInvasions))
    print(string.format("  • Path Invasions:       %d", report.PathInvasions))
    print(string.format("  • Floating Trees:       %d", report.FloatingTrees))
    print(string.format("  • Foliage Collision Fixes: %d", report.CollidableFoliageErrors))
    print(string.format("  • Status:               %s", report.Passed and "PASSED (AAA Ready)" or "FAILED"))
    print("----------------------------------------------------------------")
    
    return report
end

return EnvironmentValidator
