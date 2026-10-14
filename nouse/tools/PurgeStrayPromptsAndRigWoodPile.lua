--!strict
-- tools/PurgeStrayPromptsAndRigWoodPile.lua
-- ============================================================================
-- PRODUCTION-GRADE STUDIO COMMAND BAR SCRIPT
-- 1. Purges ALL stray wood prompts from Barrels, Tents, Trader House, etc.
-- 2. Strictly rigs ONLY the designated Forest Wood Pile with ONE prompt.
-- 3. Locates and tags the Trader House for upcoming objectives.
-- Run in Roblox Studio Command Bar (Edit Mode or Play Mode).
-- ============================================================================

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")

print("----------------------------------------------------------------------")
print("🔥 [FLUENOSITY CLEANUP] Running Production-Grade Studio Cleanup & Rig...")
print("----------------------------------------------------------------------")

-- 1. Helper to determine if a prompt is a wood gathering prompt
local function isWoodGatherPrompt(prompt: ProximityPrompt): boolean
    if prompt.Name == "WoodGatherPrompt" or prompt.Name == "WoodPilePrompt" then
        return true
    end
    if prompt.ActionText == "Take Wood Log" or prompt.ActionText == "Gather Wood" then
        return true
    end
    local objText = prompt.ObjectText
    if objText and (objText:find("Wood Pile") or objText:find("Wood Log")) then
        return true
    end
    return false
end

-- 2. Identify the single designated forest wood pile
local selectedObjects = Selection:Get()
local designatedWoodPile: Instance? = nil

-- Check if developer currently has the wood pile selected in Studio
if #selectedObjects > 0 then
    local sel = selectedObjects[1]
    local lName = sel.Name:lower()
    if not lName:find("barrel") and not lName:find("tent") and not lName:find("trader") and not lName:find("house") then
        designatedWoodPile = sel
        print(string.format("📌 Using Studio Selected Object as Designated Wood Pile: '%s' (%s)", sel.Name, sel:GetFullName()))
    end
end

-- Fallback 1: Search for existing tag
if not designatedWoodPile then
    local tagged = CollectionService:GetTagged("WoodPile")
    for _, inst in ipairs(tagged) do
        local l = inst.Name:lower()
        if not l:find("barrel") and not l:find("tent") and not l:find("trader") and not l:find("house") and not l:find("camp") and not l:find("shelf") and not l:find("counter") then
            designatedWoodPile = inst
            print(string.format("📌 Found Tagged Wood Pile: '%s'", inst:GetFullName()))
            break
        end
    end
end

-- Fallback 2: Search descendants by name
if not designatedWoodPile then
    local targetNames = {
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
    }
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local l = obj.Name:lower()
            if targetNames[l] and not l:find("barrel") and not l:find("tent") and not l:find("trader") and not l:find("house") and not l:find("camp") then
                designatedWoodPile = obj
                print(string.format("📌 Found Wood Pile by Name: '%s'", obj:GetFullName()))
                break
            end
        end
    end
end

-- Fallback 3: Search for stacked log cylinders in the forest
if not designatedWoodPile then
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local l = obj.Name:lower()
            if (l:find("log") or l:find("wood")) and not l:find("barrel") and not l:find("tent") and not l:find("trader") and not l:find("house") and not l:find("camp") then
                designatedWoodPile = obj
                print(string.format("📌 Found Candidate Forest Log Model: '%s'", obj:GetFullName()))
                break
            end
        end
    end
end

-- Fallback 4: Exact known coordinates Vector3.new(188.3, 33.8, -39.7)
if not designatedWoodPile then
    local targetPos = Vector3.new(188.3, 33.8, -39.7)
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") then
            local pivot = obj:GetPivot()
            if (pivot.Position - targetPos).Magnitude < 15.0 then
                designatedWoodPile = obj
                print(string.format("📌 Found Forest Wood Pile by Coordinates (188.3, 33.8, -39.7): '%s'", obj:GetFullName()))
                break
            end
        end
    end
end

-- 3. PURGE ALL STRAY PROMPTS ACROSS ENTIRE WORKSPACE
local purgedCount = 0
for _, desc in ipairs(Workspace:GetDescendants()) do
    if desc:IsA("ProximityPrompt") and isWoodGatherPrompt(desc) then
        if not designatedWoodPile or not desc:IsDescendantOf(designatedWoodPile) then
            local parentName = desc.Parent and desc.Parent:GetFullName() or "Unknown"
            desc:Destroy()
            purgedCount += 1
            print(string.format("  🧹 [PURGED] Removed stray prompt from: %s", parentName))
        end
    end
end
print(string.format("✅ Total stray wood prompts purged: %d", purgedCount))

-- 4. CONFIGURE STRICTLY ONE PROMPT ON DESIGNATED WOOD PILE
if designatedWoodPile then
    -- Clean up temporary locator highlight if present
    local tempHl = designatedWoodPile:FindFirstChild("LocateHighlight")
    if tempHl then tempHl:Destroy() end

    designatedWoodPile.Name = "WoodlandLogPile"
    CollectionService:AddTag(designatedWoodPile, "WoodPile")

    local interactionPart = designatedWoodPile:FindFirstChild("WoodInteractionPromptPart") :: BasePart?
    if not interactionPart then
        local cf, size = designatedWoodPile:GetBoundingBox()
        interactionPart = Instance.new("Part")
        interactionPart.Name = "WoodInteractionPromptPart"
        interactionPart.Size = Vector3.new(math.clamp(size.X, 4, 16), 3, math.clamp(size.Z, 4, 16))
        interactionPart.CFrame = cf + Vector3.new(0, 1.2, 0)
        interactionPart.Transparency = 1
        interactionPart.CanCollide = false
        interactionPart.CanTouch = false
        interactionPart.CanQuery = true
        interactionPart.Anchored = true
        interactionPart.Parent = designatedWoodPile
    end

    if interactionPart then
        -- Remove any duplicate prompts so there is STRICTLY ONE
        for _, p in ipairs(designatedWoodPile:GetDescendants()) do
            if p:IsA("ProximityPrompt") and isWoodGatherPrompt(p) then
                p:Destroy()
            end
        end

        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "WoodGatherPrompt"
        prompt.ActionText = "Take Wood Log"
        prompt.ObjectText = "Wood Pile (Max 5)"
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
        prompt.HoldDuration = 0.25
        prompt.MaxActivationDistance = 16.0
        prompt.RequiresLineOfSight = false
        prompt.Parent = interactionPart

        print(string.format("🪵 [WOOD PILE CONFIGURED] Strictly ONE prompt attached to '%s' at: %s (Radius: 16 studs)", interactionPart.Name, tostring(interactionPart.Position)))
    end
else
    warn("⚠️ No designated Wood Pile found yet. Please SELECT the forest wood pile in Studio and re-run this script!")
end

-- 5. LOCATE AND TAG TRADER HOUSE FOR UPCOMING OBJECTIVE
local traderHouse: Model? = nil
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("Model") then
        local l = obj.Name:lower()
        if l:find("trader") or l:find("merchant") or l:find("shop") or l:find("cabin") then
            traderHouse = obj
            break
        end
    end
end

if traderHouse then
    CollectionService:AddTag(traderHouse, "TraderHouse")
    local pivot = traderHouse:GetPivot()
    print(string.format("🏠 [TRADER HOUSE LOCATED] Model: '%s' | Position: Vector3.new(%.1f, %.1f, %.1f)", traderHouse.Name, pivot.Position.X, pivot.Position.Y, pivot.Position.Z))
    print(string.format("   Full path: %s", traderHouse:GetFullName()))
else
    print("ℹ️ Trader House not auto-detected by name. If it has a different name, select it in Studio and add tag 'TraderHouse'.")
end

print("----------------------------------------------------------------------")
print("🎉 [FINISHED] Stray prompts purged. Forest wood pile secured. Ready!")
print("----------------------------------------------------------------------")
