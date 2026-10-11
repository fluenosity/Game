--!strict
--[[
    tools/SetupWoodPiles.lua
    Standalone Studio Command Bar runner to immediately find, tag, and rig ALL Wood Piles
    in the game with a responsive ProximityPrompt.
    
    Can be run directly in the Roblox Studio Command Bar (Edit Mode or Play Mode).
]]

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

print("----------------------------------------------------------------------")
print("🪵 [FLUENOSITY STUDIO] Rigging All Wood Piles Across Game...")
print("----------------------------------------------------------------------")

local function isBlacklisted(inst: Instance): boolean
    local current: Instance? = inst
    while current and current ~= Workspace do
        local l = current.Name:lower()
        if l:find("barrel") or l:find("tent") or l:find("trader") or l:find("silas")
            or l:find("merchant") or l:find("house") or l:find("cabin") or l:find("shop")
            or l:find("camp") or l:find("bench") or l:find("chair") or l:find("seat")
            or l:find("table") or l:find("counter") or l:find("shelf") or l:find("crate")
            or l:find("chest") or l:find("torch") or l:find("lantern") or l:find("matchbox")
            or l:find("dropped") then
            return true
        end
        if CollectionService:HasTag(current, "ChoppableTree") or CollectionService:HasTag(current, "TraderHouse") then
            return true
        end
        if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
            return true
        end
        current = current.Parent
    end
    return false
end

local function isWoodPile(inst: Instance): boolean
    if isBlacklisted(inst) then return false end
    if CollectionService:HasTag(inst, "WoodPile") then return true end

    local name = inst.Name:lower()
    local exactNames = {
        ["woodlandlogpile"] = true,
        ["woodpile"] = true,
        ["wood pile"] = true,
        ["wood_pile"] = true,
        ["logpile"] = true,
        ["log pile"] = true,
        ["log_pile"] = true,
        ["firewoodpile"] = true,
        ["stackedlogs"] = true,
        ["logstack"] = true,
        ["woodstack"] = true,
        ["logs"] = true,
        ["woodlogs"] = true,
        ["wood_logs"] = true,
        ["cutlogs"] = true,
        ["firewood"] = true,
        ["timberpile"] = true,
        ["timberlogs"] = true,
    }
    if exactNames[name] then return true end

    if inst:IsA("Model") then
        local woodPartCount = 0
        local logNameCount = 0
        for _, child in ipairs(inst:GetDescendants()) do
            if child:IsA("BasePart") then
                local cName = child.Name:lower()
                if cName:find("log") or cName:find("timber") or cName:find("cord") or cName:find("firewood") or cName:find("wood") then
                    logNameCount += 1
                end
                if child.Material == Enum.Material.Wood or child.Material == Enum.Material.WoodPlanks or child.Shape == Enum.PartType.Cylinder then
                    woodPartCount += 1
                end
            end
        end
        if logNameCount >= 2 or woodPartCount >= 4 then return true end

        local pivot = inst:GetPivot()
        local dist = (pivot.Position - Vector3.new(188.3, 33.8, -39.7)).Magnitude
        if dist < 45.0 and woodPartCount >= 1 then return true end
    end

    return false
end

local riggedCount = 0

for _, obj in ipairs(Workspace:GetDescendants()) do
    if (obj:IsA("Model") or obj:IsA("BasePart")) and isWoodPile(obj) then
        CollectionService:AddTag(obj, "WoodPile")
        
        local interactionPart: BasePart? = nil
        if obj:IsA("Model") then
            local cf, size = obj:GetBoundingBox()
            for _, desc in ipairs(obj:GetDescendants()) do
                if desc:IsA("BasePart") and desc.Name ~= "WoodInteractionPromptPart" then
                    desc.Anchored = true
                end
            end

            interactionPart = obj:FindFirstChild("WoodInteractionPromptPart") :: BasePart?
            local hitboxSize = Vector3.new(
                math.clamp(size.X + 4, 8, 26),
                math.clamp(size.Y + 3, 5, 14),
                math.clamp(size.Z + 4, 8, 26)
            )
            if not interactionPart then
                interactionPart = Instance.new("Part")
                interactionPart.Name = "WoodInteractionPromptPart"
                interactionPart.Size = hitboxSize
                interactionPart.CFrame = cf + Vector3.new(0, 0.5, 0)
                interactionPart.Transparency = 1
                interactionPart.CanCollide = false
                interactionPart.CanTouch = false
                interactionPart.CanQuery = true
                interactionPart.Anchored = true
                interactionPart.Parent = obj
            else
                interactionPart.Size = hitboxSize
                interactionPart.CFrame = cf + Vector3.new(0, 0.5, 0)
                interactionPart.Transparency = 1
                interactionPart.CanCollide = false
                interactionPart.CanTouch = false
                interactionPart.CanQuery = true
                interactionPart.Anchored = true
            end
        elseif obj:IsA("BasePart") then
            interactionPart = obj
        end

        if interactionPart then
            local prompt = interactionPart:FindFirstChild("WoodGatherPrompt") :: ProximityPrompt?
            if not prompt then
                prompt = Instance.new("ProximityPrompt")
                prompt.Name = "WoodGatherPrompt"
                prompt.Parent = interactionPart
            end
            prompt.ActionText = "Take Wood Log"
            prompt.ObjectText = "Wood Pile (Max 5)"
            prompt.KeyboardKeyCode = Enum.KeyCode.E
            prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
            prompt.HoldDuration = 0.2
            prompt.MaxActivationDistance = 20.0
            prompt.RequiresLineOfSight = false
            prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
            prompt.Enabled = true

            riggedCount += 1
            print(string.format("  ✅ [RIGGED] '%s' at Vector3.new(%.1f, %.1f, %.1f) - Prompt Ready!",
                obj:GetFullName(),
                interactionPart.Position.X,
                interactionPart.Position.Y,
                interactionPart.Position.Z
            ))
        end
    end
end

-- Clean up any stray prompts on barrels, furniture, tents
local purgedCount = 0
for _, prompt in ipairs(Workspace:GetDescendants()) do
    if prompt:IsA("ProximityPrompt") and (prompt.Name == "WoodGatherPrompt" or prompt.ActionText:find("Wood")) then
        if isBlacklisted(prompt) then
            prompt:Destroy()
            purgedCount += 1
        end
    end
end

print(string.format("🎉 [COMPLETE] Successfully rigged %d wood piles! (Purged %d stray prompts)", riggedCount, purgedCount))
